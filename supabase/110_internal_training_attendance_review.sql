begin;
create table public.crm_internal_training_submissions(
 id uuid primary key,attendance_id uuid not null references public.crm_training_attendance,register_id uuid not null references public.crm_training_attendee_registers,
 training_id uuid not null references public.crm_internal_training,sequence integer not null,previous_id uuid references public.crm_internal_training_submissions,
 snapshot jsonb not null,request jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(attendance_id,sequence)
);
create index internal_training_submission_register on public.crm_internal_training_submissions(register_id);
create index internal_training_submission_source on public.crm_internal_training_submissions(training_id);
create index internal_training_submission_previous on public.crm_internal_training_submissions(previous_id);
create index internal_training_submission_actor on public.crm_internal_training_submissions(actor_id);
create table public.crm_internal_training_submission_proof(submission_id uuid not null references public.crm_internal_training_submissions,evidence_id uuid not null references public.crm_training_evidence,primary key(submission_id,evidence_id));
create index internal_training_submission_evidence on public.crm_internal_training_submission_proof(evidence_id);
create table public.crm_internal_training_decisions(
 id uuid primary key,submission_id uuid not null references public.crm_internal_training_submissions,sequence integer not null,
 previous_id uuid references public.crm_internal_training_decisions,action text not null check(action in ('Approved','Returned','Withdrawn')),
 request jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(submission_id,sequence)
);
create index internal_training_decision_previous on public.crm_internal_training_decisions(previous_id);
create index internal_training_decision_actor on public.crm_internal_training_decisions(actor_id);
create function portal_private.internal_training_reviewer(p_register uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.crm_training_attendee_registers r join public.crm_internal_training t on t.id=r.internal_training_id where r.id=p_register and r.source_kind='Internal' and
 (portal_private.hr_access() or (portal_private.crm_permission('team.own') and t.created_by=auth.uid()
 and (t.facilitator_id=auth.uid() or portal_private.hr_supervisor(t.facilitator_id,(now() at time zone 'Asia/Karachi')::date,'Lead'))
 and not exists(select 1 from public.crm_training_attendee_accounts a where a.register_id=r.id and a.profile_id<>auth.uid() and not coalesce(portal_private.hr_supervisor(a.profile_id,(now() at time zone 'Asia/Karachi')::date,'Lead'),false)))));
$$;
create function portal_private.internal_training_current(p_attendance uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.crm_training_attendance a join public.crm_training_attendee_registers r on r.id=a.register_id join public.crm_internal_training t on t.id=r.internal_training_id
 where a.id=p_attendance and r.source_kind='Internal' and r.source_version=t.version and t.status='Draft'
 and not exists(select 1 from public.crm_training_attendance n where n.register_id=r.id and n.sequence>a.sequence)
 and not exists(select 1 from public.crm_training_attendee_registers n where n.source_kind=r.source_kind and n.source_id=r.source_id and n.sequence>r.sequence));
$$;
create function portal_private.internal_training_read(p_register uuid,p_attendance uuid) returns boolean language sql stable security definer set search_path='' as $$select portal_private.internal_training_reviewer(p_register) or (portal_private.internal_training_current(p_attendance) and portal_private.training_facilitator_access(p_register));$$;
create function portal_private.internal_training_proofs(p_attendance uuid,p_proofs uuid[]) returns boolean language sql stable security definer set search_path='' as $$
 select cardinality(p_proofs) between 1 and 100 and cardinality(p_proofs)=(select count(distinct id) from unnest(p_proofs) v(id)) and (select count(*) from public.crm_training_evidence e join storage.objects o on o.bucket_id='training-evidence' and o.name=e.path and o.owner_id=e.actor_id::text and o.metadata->>'size'=e.size::text and o.metadata->>'mimetype'=e.mime where e.id=any(p_proofs) and e.attendance_id=p_attendance)=cardinality(p_proofs);
$$;
revoke all on function portal_private.internal_training_current(uuid),portal_private.internal_training_proofs(uuid,uuid[]) from public,anon,authenticated;
revoke all on function portal_private.internal_training_reviewer(uuid),portal_private.internal_training_read(uuid,uuid) from public,anon;
grant execute on function portal_private.internal_training_reviewer(uuid),portal_private.internal_training_read(uuid,uuid) to authenticated;
alter table public.crm_internal_training_submissions enable row level security;
alter table public.crm_internal_training_submission_proof enable row level security;
alter table public.crm_internal_training_decisions enable row level security;
revoke all on public.crm_internal_training_submissions,public.crm_internal_training_submission_proof,public.crm_internal_training_decisions from public,anon,authenticated;
grant select on public.crm_internal_training_submissions,public.crm_internal_training_submission_proof,public.crm_internal_training_decisions to authenticated;
create policy internal_training_submissions_read on public.crm_internal_training_submissions for select to authenticated using(portal_private.internal_training_read(register_id,attendance_id));
create policy internal_training_proof_read on public.crm_internal_training_submission_proof for select to authenticated using(exists(select 1 from public.crm_internal_training_submissions s where s.id=submission_id));
create policy internal_training_decisions_read on public.crm_internal_training_decisions for select to authenticated using(exists(select 1 from public.crm_internal_training_submissions s where s.id=submission_id));
create function public.submit_internal_training_attendance(p_id uuid,p_attendance uuid,p_previous uuid,p_proofs uuid[],p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare a public.crm_training_attendance;r public.crm_training_attendee_registers;t public.crm_internal_training;old public.crm_internal_training_submissions;retry public.crm_internal_training_submissions;decision text;req jsonb;proofs jsonb;
begin
 select * into a from public.crm_training_attendance where id=p_attendance;
 if a.id is null or not portal_private.training_facilitator_access(a.register_id) then raise exception 'Current selected facilitator or administrator required';end if;
 select * into r from public.crm_training_attendee_registers where id=a.register_id;
 if r.source_kind<>'Internal' then raise exception 'This increment supports standalone Internal training only';end if;
 select * into t from public.crm_internal_training where id=r.internal_training_id for update;
 perform 1 from public.profiles where id=auth.uid() for share;
 if not portal_private.training_facilitator_access(r.id) or not portal_private.internal_training_current(a.id) then raise exception 'Exact current Internal attendance receipt required';end if;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 or p_proofs is null then raise exception 'Explicit submission identity/proof selection/manual reason required';end if;
 req:=jsonb_build_object('attendance_id',p_attendance,'previous_id',p_previous,'proofs',p_proofs,'reason',trim(p_reason));
 select * into retry from public.crm_internal_training_submissions where id=p_id;
 if retry.id is not null then if retry.actor_id=auth.uid() and retry.request=req then return retry.id;end if;raise exception 'Submission identity records a different request';end if;
 select * into old from public.crm_internal_training_submissions where attendance_id=a.id order by sequence desc limit 1;
 if old.id is distinct from p_previous then raise exception 'Submission changed; refresh latest revision';end if;
 if old.id is not null then select action into decision from public.crm_internal_training_decisions where submission_id=old.id order by sequence desc limit 1;if coalesce(decision,'Submitted') not in ('Returned','Withdrawn') then raise exception 'Return or withdraw the latest submission before resubmitting this receipt';end if;end if;
 if jsonb_array_length(a.entries)=0 or exists(select 1 from jsonb_array_elements(a.entries) e where e->>'check_in' is null or e->>'check_out' is null) then raise exception 'Actual check-in/out pairs required for every registered attendee';end if;
 perform 1 from public.crm_training_evidence e join storage.objects o on o.bucket_id='training-evidence' and o.name=e.path where e.id=any(p_proofs) for share of e,o;
 if not coalesce(portal_private.internal_training_proofs(a.id,p_proofs),false) then raise exception 'Select actual intact private proof for this exact receipt';end if;
 select jsonb_agg(to_jsonb(e) order by u.ordinal) into proofs from unnest(p_proofs) with ordinality u(id,ordinal) join public.crm_training_evidence e on e.id=u.id;
 insert into public.crm_internal_training_submissions(id,attendance_id,register_id,training_id,sequence,previous_id,snapshot,request,reason,actor_id)
 values(p_id,a.id,r.id,t.id,coalesce(old.sequence,0)+1,old.id,jsonb_build_object('source',jsonb_build_object('training_id',t.id,'source_kind','Internal','version',t.version,'type','Internal','title',t.title,'objective',t.objective,'facilitator_id',t.facilitator_id),'attendance',jsonb_build_object('id',a.id,'register_id',r.id,'revision',a.sequence,'entries',a.entries,'actor_id',a.actor_id,'created_at',a.created_at,'reason',a.reason),'attendees',(select jsonb_agg(value-'role' order by ordinal) from jsonb_array_elements(r.attendees) with ordinality v(value,ordinal)),'proofs',proofs),req,trim(p_reason),auth.uid());
 insert into public.crm_internal_training_submission_proof select p_id,unnest(p_proofs);return p_id;
end$$;
create function public.review_internal_training_attendance(p_id uuid,p_submission uuid,p_previous uuid,p_action text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare s public.crm_internal_training_submissions;r public.crm_training_attendee_registers;old public.crm_internal_training_decisions;retry public.crm_internal_training_decisions;req jsonb;reviewer boolean;admin boolean;own boolean;state text;proofs uuid[];
begin
 if p_action is null or p_action not in ('Approved','Returned','Withdrawn') then raise exception 'Explicit supported Internal attendance decision required';end if;
 select * into s from public.crm_internal_training_submissions where id=p_submission;
 if s.id is null then raise exception 'Internal training submission unavailable';end if;
 select * into r from public.crm_training_attendee_registers where id=s.register_id;
 perform 1 from public.crm_internal_training where id=s.training_id for update;
 perform 1 from public.profiles where id=auth.uid() for share;
 reviewer:=portal_private.internal_training_reviewer(s.register_id);admin:=portal_private.hr_access();own:=s.actor_id=auth.uid() and portal_private.training_facilitator_access(s.register_id);
 if not ((p_action='Approved' and reviewer) or (p_action in ('Returned','Withdrawn') and (reviewer or admin)) or (p_action='Withdrawn' and own)) then raise exception 'Team lead/HR review or authorized withdrawal required';end if;
 if not portal_private.internal_training_current(s.attendance_id) or exists(select 1 from public.crm_internal_training_submissions n where n.attendance_id=s.attendance_id and n.sequence>s.sequence) then raise exception 'Exact latest current Internal submission required';end if;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit decision identity/action/manual reason required';end if;
 req:=jsonb_build_object('submission_id',p_submission,'previous_id',p_previous,'action',p_action,'reason',trim(p_reason));
 select * into retry from public.crm_internal_training_decisions where id=p_id;
 if retry.id is not null then if retry.actor_id=auth.uid() and retry.request=req then return retry.id;end if;raise exception 'Decision identity records a different request';end if;
 select * into old from public.crm_internal_training_decisions where submission_id=s.id order by sequence desc limit 1;
 if old.id is distinct from p_previous then raise exception 'Decision changed; refresh latest revision';end if;state:=coalesce(old.action,'Submitted');
 if p_action in ('Approved','Returned') and state<>'Submitted' or p_action='Withdrawn' and (state not in ('Submitted','Approved') or state='Approved' and not(reviewer or admin)) then raise exception 'Invalid attendance decision transition';end if;
 if p_action='Approved' then
  perform 1 from public.hr_terms where user_id in (select profile_id from public.crm_training_attendee_accounts where register_id=s.register_id) or user_id=(select facilitator_id from public.crm_internal_training where id=s.training_id) for share;
  if not portal_private.internal_training_reviewer(s.register_id) then raise exception 'Current creating team lead reporting scope or HR required';end if;
  select array_agg(evidence_id order by evidence_id) into proofs from public.crm_internal_training_submission_proof where submission_id=s.id;
  perform 1 from public.crm_training_evidence e join storage.objects o on o.bucket_id='training-evidence' and o.name=e.path where e.id=any(proofs) for share of e,o;
  if not coalesce(portal_private.internal_training_proofs(s.attendance_id,proofs),false) then raise exception 'Resolve missing or changed submitted proof before approval';end if;
 end if;
 insert into public.crm_internal_training_decisions(id,submission_id,sequence,previous_id,action,request,reason,actor_id) values(p_id,s.id,coalesce(old.sequence,0)+1,old.id,p_action,req,trim(p_reason),auth.uid());return p_id;
end$$;
create function public.internal_training_review_queue() returns setof jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not(portal_private.hr_access() or portal_private.crm_permission('team.own')) then raise exception 'Team lead or HR access required';end if;
 return query select to_jsonb(s)||jsonb_build_object('can_approve',portal_private.internal_training_reviewer(s.register_id),'current',portal_private.internal_training_current(s.attendance_id) and not exists(select 1 from public.crm_internal_training_submissions n where n.attendance_id=s.attendance_id and n.sequence>s.sequence),'decisions',(select coalesce(jsonb_agg(to_jsonb(d) order by d.sequence),'[]') from public.crm_internal_training_decisions d where d.submission_id=s.id)) from public.crm_internal_training_submissions s where portal_private.internal_training_reviewer(s.register_id) order by s.created_at desc,s.id;
end$$;
revoke all on function public.submit_internal_training_attendance(uuid,uuid,uuid,uuid[],text),public.review_internal_training_attendance(uuid,uuid,uuid,text,text),public.internal_training_review_queue() from public,anon;
grant execute on function public.submit_internal_training_attendance(uuid,uuid,uuid,uuid[],text),public.review_internal_training_attendance(uuid,uuid,uuid,text,text),public.internal_training_review_queue() to authenticated;
notify pgrst,'reload schema';
commit;
