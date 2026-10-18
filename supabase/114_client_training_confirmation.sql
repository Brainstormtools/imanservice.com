begin;
-- 113 is reserved by the separate, unmerged website-intake branch.
create table public.crm_client_training_confirmations(
 id uuid primary key,submission_id uuid not null references public.crm_client_training_submissions,
 approval_id uuid not null references public.crm_client_training_decisions,attendance_id uuid not null references public.crm_training_attendance,
 project_id uuid not null references public.projects,company_id uuid not null references public.companies,
 actor_id uuid not null references public.profiles,signatory_id uuid not null references public.crm_training_signatories,
 signatory_version integer not null,consent boolean not null check(consent),full_name text not null,note text not null,
 client_snapshot jsonb not null,private_snapshot jsonb not null,request jsonb not null,created_at timestamptz not null default now(),
 unique(approval_id,actor_id)
);
create index training_confirmation_submission on public.crm_client_training_confirmations(submission_id);
create index training_confirmation_attendance on public.crm_client_training_confirmations(attendance_id);
create index training_confirmation_project on public.crm_client_training_confirmations(project_id);
create index training_confirmation_company on public.crm_client_training_confirmations(company_id);
create index training_confirmation_actor on public.crm_client_training_confirmations(actor_id);
create index training_confirmation_authority on public.crm_client_training_confirmations(signatory_id);
alter table public.crm_client_training_confirmations enable row level security;
revoke all on public.crm_client_training_confirmations from public,anon,authenticated;
grant select on public.crm_client_training_confirmations to authenticated;
-- Clients receive only explicitly projected receipts through the context RPC.
create policy training_confirmation_manager_read on public.crm_client_training_confirmations for select to authenticated using(portal_private.execution_manager(project_id));
create function portal_private.client_training_confirmation_current(p_submission uuid,p_approval uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.crm_client_training_submissions s join public.crm_client_training_decisions d on d.submission_id=s.id
 where s.id=p_submission and d.id=p_approval and d.action='Approved' and portal_private.client_training_current(s.attendance_id)
 and not exists(select 1 from public.crm_client_training_submissions n where n.attendance_id=s.attendance_id and n.sequence>s.sequence)
 and not exists(select 1 from public.crm_client_training_decisions n where n.submission_id=s.id and n.sequence>d.sequence)
 and portal_private.client_training_proofs(s.attendance_id,array(select evidence_id from public.crm_client_training_submission_proof where submission_id=s.id)));
$$;
create function portal_private.client_training_confirmation_view(p_submission uuid,p_approval uuid) returns jsonb
language sql stable security definer set search_path='' as $$
 select jsonb_build_object('submission_id',s.id,'approval_id',d.id,'attendance_id',s.attendance_id,'project_id',s.project_id,
 'project_title',p.title,'training_id',s.snapshot->'source'->'training_id','definition_id',s.snapshot->'source'->'definition_id',
 'version',s.snapshot->'source'->'version','type','Client','title',s.snapshot->'source'->'title','objective',s.snapshot->'source'->'objective',
 'approved_at',d.created_at,'attendance_revision',s.snapshot->'attendance'->'revision',
 'attendees',(select coalesce(jsonb_agg(jsonb_build_object('name',v.value->>'name','check_in',e.value->>'check_in','check_out',e.value->>'check_out') order by v.ordinal),'[]'::jsonb)
 from jsonb_array_elements(s.snapshot->'attendees') with ordinality v(value,ordinal)
 join lateral jsonb_array_elements(s.snapshot->'attendance'->'entries') e(value) on (e.value->>'ordinal')::integer=v.ordinal-1))
 from public.crm_client_training_submissions s join public.projects p on p.id=s.project_id join public.crm_client_training_decisions d on d.submission_id=s.id and d.id=p_approval where s.id=p_submission;
$$;
revoke all on function portal_private.client_training_confirmation_current(uuid,uuid),portal_private.client_training_confirmation_view(uuid,uuid) from public,anon,authenticated;
create function public.client_training_confirmation_queue() returns setof jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not exists(select 1 from public.profiles where id=auth.uid() and active and role='client') then raise exception 'Active client account required';end if;
 return query select jsonb_build_object('submission_id',s.id,'approval_id',d.id,'title',s.snapshot->'source'->'title','project_title',p.title)
 from public.crm_client_training_submissions s join public.projects p on p.id=s.project_id
 join lateral(select id,action from public.crm_client_training_decisions where submission_id=s.id order by sequence desc limit 1) d on true
 where exists(select 1 from public.profiles u where u.id=auth.uid() and u.company_id=p.company_id)
 and ((portal_private.training_signatory(s.project_id) and d.action='Approved' and portal_private.client_training_confirmation_current(s.id,d.id))
 or exists(select 1 from public.crm_client_training_confirmations c where c.submission_id=s.id and c.actor_id=auth.uid() and c.company_id=p.company_id))
 order by s.created_at desc,s.id;
end$$;
create function public.client_training_confirmation_context(p_submission uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare s public.crm_client_training_submissions;d public.crm_client_training_decisions;company uuid;eligible boolean;receipts jsonb;
begin
 select * into s from public.crm_client_training_submissions where id=p_submission;
 select company_id into company from public.projects where id=s.project_id;
 if s.id is null or auth.uid() is null or not exists(select 1 from public.profiles where id=auth.uid() and active and role='client' and company_id=company)
 or not(portal_private.training_signatory(s.project_id) or exists(select 1 from public.crm_client_training_confirmations where submission_id=s.id and actor_id=auth.uid() and company_id=company)) then raise exception 'Current training signatory or own historical receipt access required';end if;
 select * into d from public.crm_client_training_decisions where submission_id=s.id order by sequence desc limit 1;
 eligible:=portal_private.training_signatory(s.project_id) and coalesce(portal_private.client_training_confirmation_current(s.id,d.id),false);
 select coalesce(jsonb_agg(jsonb_build_object('id',c.id,'submission_id',c.submission_id,'approval_id',c.approval_id,'actor_id',c.actor_id,'full_name',c.full_name,'note',c.note,'consent',c.consent,'created_at',c.created_at,'snapshot',c.client_snapshot,
 'current',portal_private.client_training_confirmation_current(c.submission_id,c.approval_id)) order by c.created_at),'[]') into receipts
 from public.crm_client_training_confirmations c where c.submission_id=s.id and c.actor_id=auth.uid() and c.company_id=company;
 return jsonb_build_object('eligible',eligible,'receipt',case when eligible then portal_private.client_training_confirmation_view(s.id,d.id) end,'confirmations',receipts);
end$$;
create function public.confirm_client_training(p_id uuid,p_submission uuid,p_approval uuid,p_consent boolean,p_full_name text,p_note text)
returns uuid language plpgsql security definer set search_path='' as $$
declare s public.crm_client_training_submissions;d public.crm_client_training_decisions;authority public.crm_training_signatories;
 retry public.crm_client_training_confirmations;company uuid;req jsonb;view jsonb;proofs uuid[];
begin
 select * into s from public.crm_client_training_submissions where id=p_submission;
 if s.id is null or auth.uid() is null then raise exception 'Client training receipt unavailable';end if;
 select company_id into company from public.projects where id=s.project_id for update;
 perform 1 from public.crm_project_training where id=(s.snapshot->'source'->>'training_id')::uuid for update;
 perform 1 from public.profiles where id=auth.uid() for share;
 select * into authority from public.crm_training_signatories where project_id=s.project_id and client_id=auth.uid() for share;
 if not portal_private.training_signatory(s.project_id) then raise exception 'Current explicitly authorized training signatory required';end if;
 if p_id is null or p_approval is null or p_consent is distinct from true or length(trim(coalesce(p_full_name,''))) not between 3 and 160 or p_note is null or length(trim(p_note))>2000 then raise exception 'Exact receipt/approval, agreement and actual full name required; note is optional';end if;
 -- Check current state even for retries: a historical acknowledgement must never masquerade as current confirmation.
 select array_agg(evidence_id) into proofs from public.crm_client_training_submission_proof where submission_id=s.id;
 perform 1 from public.crm_training_evidence e join storage.objects o on o.bucket_id='training-evidence' and o.name=e.path where e.id=any(proofs) for share of e,o;
 if not coalesce(portal_private.client_training_confirmation_current(s.id,p_approval),false) then raise exception 'Exact current PM-approved receipt and intact submitted proof required; refresh';end if;
 select * into d from public.crm_client_training_decisions where id=p_approval;
 req:=jsonb_build_object('submission_id',p_submission,'approval_id',p_approval,'consent',true,'full_name',trim(p_full_name),'note',trim(p_note));
 select * into retry from public.crm_client_training_confirmations where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=req then return retry.id;end if;
  raise exception 'Confirmation identity records a different request';
 end if;
 if exists(select 1 from public.crm_client_training_confirmations where approval_id=p_approval and actor_id=auth.uid()) then raise exception 'This account already confirmed this approval receipt';end if;
 view:=portal_private.client_training_confirmation_view(s.id,d.id);
 insert into public.crm_client_training_confirmations(id,submission_id,approval_id,attendance_id,project_id,company_id,actor_id,signatory_id,signatory_version,consent,full_name,note,client_snapshot,private_snapshot,request)
 values(p_id,s.id,d.id,s.attendance_id,s.project_id,company,auth.uid(),authority.id,authority.version,true,trim(p_full_name),trim(p_note),view,
 jsonb_build_object('submission',to_jsonb(s),'approval',to_jsonb(d),'authority',to_jsonb(authority)),req);
 return p_id;
end$$;
revoke all on function public.client_training_confirmation_queue(),public.client_training_confirmation_context(uuid),public.confirm_client_training(uuid,uuid,uuid,boolean,text,text) from public,anon;
grant execute on function public.client_training_confirmation_queue(),public.client_training_confirmation_context(uuid),public.confirm_client_training(uuid,uuid,uuid,boolean,text,text) to authenticated;
notify pgrst,'reload schema';
commit;
