begin;
alter table public.crm_internal_training_submissions alter column training_id drop not null;
alter table public.crm_internal_training_submissions add column source_kind text not null default 'Internal',add column project_definition_id uuid references public.crm_training_session_definitions,add column project_id uuid references public.projects;
alter table public.crm_internal_training_submissions add constraint internal_training_submission_source_shape check((source_kind='Internal' and training_id is not null and project_definition_id is null and project_id is null) or (source_kind='Project' and training_id is null and project_definition_id is not null and project_id is not null));
create index internal_training_submission_definition on public.crm_internal_training_submissions(project_definition_id);
create index internal_training_submission_project on public.crm_internal_training_submissions(project_id);
create or replace function portal_private.internal_training_reviewer(p_register uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.crm_training_attendee_registers r
 left join public.crm_internal_training i on i.id=r.internal_training_id
 left join public.crm_training_session_definitions d on d.id=r.project_definition_id
 where r.id=p_register and (r.source_kind='Internal' or r.source_kind='Project' and d.training_type='Internal') and
 (portal_private.hr_access() or (portal_private.crm_permission('team.own')
 and case r.source_kind when 'Internal' then i.created_by=auth.uid() when 'Project' then exists(select 1 from public.project_assignments pa where pa.project_id=d.project_id and pa.technician_id=auth.uid()) else false end
 and (coalesce(i.facilitator_id,d.facilitator_id)=auth.uid() or portal_private.hr_supervisor(coalesce(i.facilitator_id,d.facilitator_id),(now() at time zone 'Asia/Karachi')::date,'Lead'))
 and not exists(select 1 from public.crm_training_attendee_accounts a where a.register_id=r.id and a.profile_id<>auth.uid() and not coalesce(portal_private.hr_supervisor(a.profile_id,(now() at time zone 'Asia/Karachi')::date,'Lead'),false)))));
$$;
create or replace function portal_private.internal_training_current(p_attendance uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.crm_training_attendance a join public.crm_training_attendee_registers r on r.id=a.register_id
 left join public.crm_internal_training i on i.id=r.internal_training_id
 left join public.crm_training_session_definitions d on d.id=r.project_definition_id
 left join public.crm_project_training t on t.id=d.training_id
 where a.id=p_attendance and case r.source_kind when 'Internal' then r.source_version=i.version and i.status='Draft' when 'Project' then d.training_type='Internal' and d.training_version=t.version and r.source_version=t.version and t.details->>'status'='Draft' and not exists(select 1 from public.crm_training_session_definitions n where n.training_id=d.training_id and n.sequence>d.sequence) else false end
 and not exists(select 1 from public.crm_training_attendance n where n.register_id=r.id and n.sequence>a.sequence)
 and not exists(select 1 from public.crm_training_attendee_registers n where n.source_kind=r.source_kind and n.source_id=r.source_id and n.sequence>r.sequence));
$$;
-- Match attendance, roster, definition, evidence and source revision lock ordering.
create function portal_private.internal_training_lock_source(p_register uuid) returns void language plpgsql security definer set search_path='' as $$
declare r public.crm_training_attendee_registers;d public.crm_training_session_definitions;
begin
 select * into r from public.crm_training_attendee_registers where id=p_register;
 if r.source_kind='Project' then
  select * into d from public.crm_training_session_definitions where id=r.project_definition_id;
  perform 1 from public.projects where id=d.project_id for update;
  perform 1 from public.crm_project_training where id=d.training_id for update;
  perform 1 from public.project_assignments where project_id=d.project_id and technician_id=auth.uid() for share;
 else perform 1 from public.crm_internal_training where id=r.internal_training_id for update;end if;
 perform 1 from public.profiles where id=auth.uid() for share;
 perform 1 from public.crm_memberships where user_id=auth.uid() for share;
 perform 1 from public.hr_terms where user_id in (select profile_id from public.crm_training_attendee_accounts where register_id=r.id) or user_id=coalesce(d.facilitator_id,(select facilitator_id from public.crm_internal_training where id=r.internal_training_id)) for share;
end$$;
revoke all on function portal_private.internal_training_lock_source(uuid) from public,anon,authenticated;
create or replace function public.submit_internal_training_attendance(p_id uuid,p_attendance uuid,p_previous uuid,p_proofs uuid[],p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare a public.crm_training_attendance;r public.crm_training_attendee_registers;t public.crm_internal_training;d public.crm_training_session_definitions;pt public.crm_project_training;source jsonb;old public.crm_internal_training_submissions;retry public.crm_internal_training_submissions;decision text;req jsonb;proofs jsonb;
begin
 select * into a from public.crm_training_attendance where id=p_attendance;
 if a.id is null or not portal_private.training_facilitator_access(a.register_id) then raise exception 'Current selected facilitator or administrator required';end if;
 select * into r from public.crm_training_attendee_registers where id=a.register_id;
 if r.source_kind='Project' then select * into d from public.crm_training_session_definitions where id=r.project_definition_id;if d.training_type is distinct from 'Internal' then raise exception 'Explicit Internal training required';end if;end if;
 perform portal_private.internal_training_lock_source(r.id);
 if r.source_kind='Internal' then
  select * into t from public.crm_internal_training where id=r.internal_training_id;
  source:=jsonb_build_object('training_id',t.id,'source_kind','Internal','version',t.version,'type','Internal','title',t.title,'objective',t.objective,'facilitator_id',t.facilitator_id);
 else
  select * into pt from public.crm_project_training where id=d.training_id;
  source:=jsonb_build_object('training_id',pt.id,'definition_id',d.id,'project_id',d.project_id,'source_kind','Project','version',pt.version,'type','Internal','title',pt.details->>'title','objective',pt.details->>'objective','facilitator_id',d.facilitator_id);
 end if;
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
 insert into public.crm_internal_training_submissions(id,attendance_id,register_id,training_id,source_kind,project_definition_id,project_id,sequence,previous_id,snapshot,request,reason,actor_id)
 values(p_id,a.id,r.id,t.id,r.source_kind,d.id,d.project_id,coalesce(old.sequence,0)+1,old.id,jsonb_build_object('source',source,'attendance',jsonb_build_object('id',a.id,'register_id',r.id,'revision',a.sequence,'entries',a.entries,'actor_id',a.actor_id,'created_at',a.created_at,'reason',a.reason),'attendees',(select jsonb_agg(value-'role' order by ordinal) from jsonb_array_elements(r.attendees) with ordinality v(value,ordinal)),'proofs',proofs),req,trim(p_reason),auth.uid());
 insert into public.crm_internal_training_submission_proof select p_id,unnest(p_proofs);return p_id;
end$$;
create or replace function public.review_internal_training_attendance(p_id uuid,p_submission uuid,p_previous uuid,p_action text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare s public.crm_internal_training_submissions;r public.crm_training_attendee_registers;old public.crm_internal_training_decisions;retry public.crm_internal_training_decisions;req jsonb;reviewer boolean;admin boolean;own boolean;state text;proofs uuid[];
begin
 if p_action is null or p_action not in ('Approved','Returned','Withdrawn') then raise exception 'Explicit supported Internal attendance decision required';end if;
 select * into s from public.crm_internal_training_submissions where id=p_submission;
 if s.id is null then raise exception 'Internal training submission unavailable';end if;
 select * into r from public.crm_training_attendee_registers where id=s.register_id;
 perform portal_private.internal_training_lock_source(s.register_id);
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
  if not portal_private.internal_training_reviewer(s.register_id) then raise exception 'Current team lead reporting/project scope or HR required';end if;
  select array_agg(evidence_id order by evidence_id) into proofs from public.crm_internal_training_submission_proof where submission_id=s.id;
  perform 1 from public.crm_training_evidence e join storage.objects o on o.bucket_id='training-evidence' and o.name=e.path where e.id=any(proofs) for share of e,o;
  if not coalesce(portal_private.internal_training_proofs(s.attendance_id,proofs),false) then raise exception 'Resolve missing or changed submitted proof before approval';end if;
 end if;
 insert into public.crm_internal_training_decisions(id,submission_id,sequence,previous_id,action,request,reason,actor_id) values(p_id,s.id,coalesce(old.sequence,0)+1,old.id,p_action,req,trim(p_reason),auth.uid());return p_id;
end$$;
-- Reviewers receive only proof explicitly selected in their Internal submissions.
create function portal_private.internal_training_review_proof(p_path text) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.crm_training_evidence e join public.crm_internal_training_submission_proof p on p.evidence_id=e.id join public.crm_internal_training_submissions s on s.id=p.submission_id where e.path=p_path and s.source_kind='Project' and portal_private.internal_training_reviewer(s.register_id));
$$;
revoke all on function portal_private.internal_training_review_proof(text) from public,anon;
grant execute on function portal_private.internal_training_review_proof(text) to authenticated;
create policy internal_training_review_evidence_read on public.crm_training_evidence for select to authenticated using(portal_private.internal_training_review_proof(path));
create policy internal_training_review_proof_download on storage.objects for select to authenticated using(bucket_id='training-evidence' and portal_private.internal_training_review_proof(name));
revoke all on function portal_private.internal_training_current(uuid) from public,anon,authenticated;
revoke all on function portal_private.internal_training_reviewer(uuid),public.submit_internal_training_attendance(uuid,uuid,uuid,uuid[],text),public.review_internal_training_attendance(uuid,uuid,uuid,text,text) from public,anon;
grant execute on function portal_private.internal_training_reviewer(uuid),public.submit_internal_training_attendance(uuid,uuid,uuid,uuid[],text),public.review_internal_training_attendance(uuid,uuid,uuid,text,text) to authenticated;
notify pgrst,'reload schema';
commit;
