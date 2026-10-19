begin;
-- Manual provenance only. Never creates activities/costs or changes learning credit.
create table public.crm_training_activity_links(
 id uuid primary key,submission_id uuid not null references public.crm_internal_training_submissions,
 activity_id uuid not null references public.work_activities,user_id uuid not null references public.profiles,
 sequence integer not null check(sequence>0),previous_id uuid references public.crm_training_activity_links,
 action text not null check(action in ('Linked','Unlinked')),snapshot jsonb not null,request jsonb not null,
 reason text not null check(length(reason) between 3 and 2000),actor_id uuid not null references public.profiles,
 created_at timestamptz not null default now(),unique(submission_id,activity_id,sequence)
);
create index training_activity_link_activity on public.crm_training_activity_links(activity_id);
create index training_activity_link_user on public.crm_training_activity_links(user_id);
create index training_activity_link_previous on public.crm_training_activity_links(previous_id);
create index training_activity_link_actor on public.crm_training_activity_links(actor_id);
create function portal_private.training_activity_authorized(p_submission uuid,p_activity uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and public.is_staff() and exists(
 select 1 from public.crm_internal_training_submissions s cross join public.work_activities a
 where s.id=p_submission and a.id=p_activity and portal_private.internal_training_reviewer(s.register_id)
 and portal_private.activity_read(a) and portal_private.activity_reviewer(a));
$$;
revoke all on function portal_private.training_activity_authorized(uuid,uuid) from public,anon;
grant execute on function portal_private.training_activity_authorized(uuid,uuid) to authenticated;
alter table public.crm_training_activity_links enable row level security;
revoke all on public.crm_training_activity_links from public,anon,authenticated;
grant select on public.crm_training_activity_links to authenticated;
create policy training_activity_link_read on public.crm_training_activity_links for select to authenticated
 using(portal_private.training_activity_authorized(submission_id,activity_id));
create function portal_private.training_activity_link_current(p public.crm_training_activity_links) returns boolean
language sql stable security definer set search_path='' as $$
 select p.action='Linked' and exists(select 1 from public.profiles u where u.id=p.user_id and u.active and u.role in ('admin','team')) and not exists(select 1 from public.crm_training_activity_links n where n.submission_id=p.submission_id and n.activity_id=p.activity_id and n.sequence>p.sequence)
 and exists(select 1 from public.work_activities a where a.id=p.activity_id and a.user_id=p.user_id and a.status='Approved' and a.activity_type='Training' and a.version=(p.snapshot->'activity'->>'version')::integer)
 and exists(select 1 from portal_private.internal_learning_receipts(p.user_id) r where r.submission_id=p.submission_id and r.current_receipt and r.receipt->>'approval_id'=p.snapshot->'receipt'->>'approval_id');
$$;
revoke all on function portal_private.training_activity_link_current(public.crm_training_activity_links) from public,anon,authenticated;
create function public.training_activity_associations(p_submission uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare s public.crm_internal_training_submissions;candidates jsonb;history jsonb;
begin
 select * into s from public.crm_internal_training_submissions where id=p_submission;
 if auth.uid() is null or not public.is_staff() or s.id is null or not coalesce(portal_private.internal_training_reviewer(s.register_id),false) then raise exception 'Current Internal training review authority required';end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',a.id,'user_id',a.user_id,'name',u.name,'version',a.version,'project_id',a.project_id,'link_kind',a.link_kind,'check_in',a.actual_start,'check_out',a.actual_end,'receipt',r.receipt,
 'previous_id',(select l.id from public.crm_training_activity_links l where l.submission_id=s.id and l.activity_id=a.id order by l.sequence desc limit 1)) order by a.actual_start,a.id),'[]') into candidates
 from public.crm_training_attendee_accounts ac join public.profiles u on u.id=ac.profile_id and u.active and u.role in ('admin','team')
 join public.work_activities a on a.user_id=u.id and a.status='Approved' and a.activity_type='Training'
 join lateral portal_private.internal_learning_receipts(u.id) r on r.submission_id=s.id and r.current_receipt
 where ac.register_id=s.register_id and portal_private.activity_read(a) and portal_private.activity_reviewer(a)
 and not exists(select 1 from public.crm_training_activity_links l where l.submission_id=s.id and l.activity_id=a.id and l.action='Linked' and not exists(select 1 from public.crm_training_activity_links n where n.submission_id=s.id and n.activity_id=a.id and n.sequence>l.sequence));
 select coalesce(jsonb_agg(to_jsonb(l)||jsonb_build_object('effective',portal_private.training_activity_link_current(l),'latest',not exists(select 1 from public.crm_training_activity_links n where n.submission_id=l.submission_id and n.activity_id=l.activity_id and n.sequence>l.sequence)) order by l.created_at,l.id),'[]') into history
 from public.crm_training_activity_links l where l.submission_id=s.id and portal_private.training_activity_authorized(s.id,l.activity_id);
 return jsonb_build_object('candidates',candidates,'history',history);
end$$;
create function public.set_training_activity_association(p_id uuid,p_submission uuid,p_activity uuid,p_version integer,p_approval uuid,p_previous uuid,p_action text,p_reason text) returns uuid
language plpgsql security definer set search_path='' as $$
declare s public.crm_internal_training_submissions;a public.work_activities;old public.crm_training_activity_links;retry public.crm_training_activity_links;req jsonb;receipt jsonb;activity jsonb;
begin
 select * into s from public.crm_internal_training_submissions where id=p_submission;
 select * into a from public.work_activities where id=p_activity;
 if not coalesce(portal_private.training_activity_authorized(p_submission,p_activity),false) then raise exception 'Current review authority over both training receipt and activity required';end if;
 -- Lock both projects in one order, then the training source, then the activity's
 -- existing per-worker advisory lock. No change to either approval workflow.
 perform 1 from public.projects where id in (s.project_id,a.project_id) order by id for update;
 perform portal_private.internal_training_lock_source(s.register_id);
 perform pg_advisory_xact_lock(hashtextextended(a.user_id::text,24));
 perform 1 from public.profiles where id=a.user_id for share;
 select * into a from public.work_activities where id=p_activity for update;
 if not coalesce(portal_private.training_activity_authorized(p_submission,p_activity),false) then raise exception 'Current review authority over both training receipt and activity required';end if;
 if p_id is null or p_action is null or p_action not in ('Linked','Unlinked') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit association identity/action and manual reason required';end if;
 req:=jsonb_build_object('submission_id',p_submission,'activity_id',p_activity,'activity_version',p_version,'approval_id',p_approval,'previous_id',p_previous,'action',p_action,'reason',trim(p_reason));
 select * into retry from public.crm_training_activity_links where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=req then return retry.id;end if;
  raise exception 'Association identity records a different request';
 end if;
 select * into old from public.crm_training_activity_links where submission_id=s.id and activity_id=a.id order by sequence desc limit 1;
 if old.id is distinct from p_previous then raise exception 'Association changed; refresh latest history';end if;
 if p_action='Linked' then
  if old.action='Linked' then raise exception 'Unlink the existing association before replacing it';end if;
  if a.status<>'Approved' or a.activity_type<>'Training' or a.version is distinct from p_version or not exists(select 1 from public.profiles where id=a.user_id and active and role in ('admin','team')) then raise exception 'Exact existing Approved Training activity and active internal staff account required';end if;
  perform 1 from public.crm_training_evidence e join public.crm_internal_training_submission_proof p on p.evidence_id=e.id join storage.objects o on o.bucket_id='training-evidence' and o.name=e.path where p.submission_id=s.id for share of e,o;
  select r.receipt into receipt from portal_private.internal_learning_receipts(a.user_id) r where r.submission_id=s.id and r.current_receipt and r.receipt->>'approval_id'=p_approval::text;
  if receipt is null then raise exception 'Exact current approved Internal receipt, same actual staff account and intact submitted proof required';end if;
  activity:=jsonb_build_object('id',a.id,'user_id',a.user_id,'version',a.version,'project_id',a.project_id,'link_kind',a.link_kind,'activity_type',a.activity_type,'check_in',a.actual_start,'check_out',a.actual_end,'reviewed_by',a.reviewed_by);
 else
  if old.id is null or old.action<>'Linked' then raise exception 'Latest linked association required to unlink';end if;
  -- Withdrawal/correction/voiding never prevents a reasoned unlink; retain the
  -- original approved receipt/activity snapshot, even when no longer current.
  receipt:=old.snapshot->'receipt';activity:=old.snapshot->'activity';
 end if;
 insert into public.crm_training_activity_links(id,submission_id,activity_id,user_id,sequence,previous_id,action,snapshot,request,reason,actor_id)
 values(p_id,s.id,a.id,a.user_id,coalesce(old.sequence,0)+1,old.id,p_action,jsonb_build_object('receipt',receipt,'activity',activity),req,trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.training_activity_associations(uuid),public.set_training_activity_association(uuid,uuid,uuid,integer,uuid,uuid,text,text) from public,anon;
grant execute on function public.training_activity_associations(uuid),public.set_training_activity_association(uuid,uuid,uuid,integer,uuid,uuid,text,text) to authenticated;
notify pgrst,'reload schema';
commit;
