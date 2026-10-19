begin;
-- Manual assignments and assessor-entered outcomes only; no review/certificate/skill credit.
create table public.competence_assessments(
 id uuid primary key,employee_id uuid not null references public.profiles,assessor_id uuid not null references public.profiles,
 definition_revision_id uuid not null references public.competence_definition_revisions,
 assignment_snapshot jsonb not null,request jsonb not null,reason text not null check(length(reason) between 3 and 2000),
 created_by uuid not null references public.profiles,created_at timestamptz not null default now(),version integer not null default 1,
 status text not null default 'Assigned' check(status in ('Assigned','Draft','Recorded','Cancelled'))
);
create index competence_assessment_employee on public.competence_assessments(employee_id);
create index competence_assessment_assessor on public.competence_assessments(assessor_id);
create index competence_assessment_definition on public.competence_assessments(definition_revision_id);
create index competence_assessment_creator on public.competence_assessments(created_by);
create table public.competence_assessment_events(
 id uuid primary key,assessment_id uuid not null references public.competence_assessments,version integer not null,
 action text not null check(action in ('Assigned','Draft saved','Recorded','Cancelled')),request jsonb not null,snapshot jsonb not null,
 reason text not null check(length(reason) between 3 and 2000),actor_id uuid not null references public.profiles,
 created_at timestamptz not null default now(),unique(assessment_id,version)
);
create index competence_assessment_event_actor on public.competence_assessment_events(actor_id);
create function portal_private.competence_assessor_current(p_user uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles p where p.id=p_user and p.active and p.role in ('admin','team')) and coalesce((select d.active from public.competence_assessor_designations d where d.user_id=p_user order by d.revision desc limit 1),false);
$$;
create function portal_private.competence_basis_current(p_revision uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.competence_definition_revisions d where d.id=p_revision and d.active and not exists(select 1 from public.competence_definition_revisions n where n.definition_id=d.definition_id and n.revision>d.revision));
$$;
create function portal_private.competence_assessment_read(p_assessment uuid) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and public.is_staff() and exists(select 1 from public.competence_assessments a where a.id=p_assessment and (portal_private.hr_access() or a.employee_id=auth.uid() or (a.assessor_id=auth.uid() and portal_private.competence_assessor_current(auth.uid()) and exists(select 1 from public.profiles p where p.id=a.employee_id and p.active and p.role in ('admin','team')))));
$$;
create function portal_private.competence_assessment_edit(a public.competence_assessments) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and public.is_staff() and a.assessor_id=auth.uid() and a.status in ('Assigned','Draft') and portal_private.competence_assessor_current(auth.uid()) and portal_private.competence_basis_current(a.definition_revision_id) and exists(select 1 from public.profiles p where p.id=a.employee_id and p.active and p.role in ('admin','team'));
$$;
revoke all on function portal_private.competence_assessor_current(uuid),portal_private.competence_basis_current(uuid),portal_private.competence_assessment_read(uuid),portal_private.competence_assessment_edit(public.competence_assessments) from public,anon,authenticated;
grant execute on function portal_private.competence_assessment_read(uuid) to authenticated;
alter table public.competence_assessments enable row level security;
alter table public.competence_assessment_events enable row level security;
revoke all on public.competence_assessments,public.competence_assessment_events from public,anon,authenticated;
grant select on public.competence_assessments,public.competence_assessment_events to authenticated;
create policy competence_assessment_scope on public.competence_assessments for select to authenticated using(portal_private.competence_assessment_read(id));
create policy competence_assessment_event_scope on public.competence_assessment_events for select to authenticated using(portal_private.competence_assessment_read(assessment_id));
create function portal_private.competence_assessment_immutable() returns trigger language plpgsql set search_path='' as $$
begin
 if tg_table_name='competence_assessment_events' then raise exception 'Competence assessment history is immutable';end if;
 if row(new.id,new.employee_id,new.assessor_id,new.definition_revision_id,new.assignment_snapshot,new.request,new.reason,new.created_by,new.created_at) is distinct from row(old.id,old.employee_id,old.assessor_id,old.definition_revision_id,old.assignment_snapshot,old.request,old.reason,old.created_by,old.created_at) then raise exception 'Original assessment identity, assignment and criteria are immutable';end if;
 return new;
end$$;
create trigger competence_assessment_identity before update on public.competence_assessments for each row execute function portal_private.competence_assessment_immutable();
create trigger competence_assessment_history before update or delete on public.competence_assessment_events for each row execute function portal_private.competence_assessment_immutable();
revoke all on function portal_private.competence_assessment_immutable() from public,anon,authenticated;
create function public.competence_assessment_options() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.is_staff() or not portal_private.hr_access() then raise exception 'Current HR or administrator assessment coordination required';end if;
 return jsonb_build_object('definitions',coalesce((select jsonb_agg(jsonb_build_object('id',d.id,'definition_id',d.definition_id,'revision',d.revision,'title',d.title,'skill',d.skill,'checklist',d.checklist,'quiz_enabled',d.quiz_enabled,'pass_mark',d.pass_mark,'validity_months',d.validity_months,'warning_days',d.warning_days) order by d.title,d.id) from public.competence_definition_revisions d where portal_private.competence_basis_current(d.id)),'[]'::jsonb),
 'people',coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'name',p.name) order by p.name,p.id) from public.profiles p where p.active and p.role in ('admin','team')),'[]'::jsonb),
 'assessors',coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'name',p.name,'designation',d.designation,'designation_revision',d.revision) order by p.name,p.id) from public.profiles p join lateral(select * from public.competence_assessor_designations r where r.user_id=p.id order by r.revision desc limit 1)d on true where p.active and p.role in ('admin','team') and d.active),'[]'::jsonb));
end$$;
create function public.competence_assessment_queue() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.is_staff() then raise exception 'Current internal staff assessment access required';end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'version',a.version,'status',a.status,'employee',a.assignment_snapshot->'employee','assessor',a.assignment_snapshot->'assessor','title',a.assignment_snapshot->'criteria'->>'title','criteria_revision',a.assignment_snapshot->'criteria'->'revision','outcome',r.snapshot->'result'->'outcome') order by a.created_at,a.id) from public.competence_assessments a left join lateral(select e.snapshot from public.competence_assessment_events e where e.assessment_id=a.id and e.action in ('Draft saved','Recorded') order by e.version desc limit 1)r on true where portal_private.competence_assessment_read(a.id)),'[]'::jsonb);
end$$;
create function public.competence_assessment_context(p_assessment uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare a public.competence_assessments;
begin
 if not coalesce(portal_private.competence_assessment_read(p_assessment),false) then raise exception 'Current scoped competence assessment access required';end if;
 select * into a from public.competence_assessments where id=p_assessment;
 return jsonb_build_object('assessment',to_jsonb(a),'basis_current',portal_private.competence_basis_current(a.definition_revision_id),'can_record',portal_private.competence_assessment_edit(a),'can_cancel',portal_private.hr_access() and a.status<>'Cancelled',
 'latest_result',(select to_jsonb(e) from public.competence_assessment_events e where e.assessment_id=a.id and e.action in ('Draft saved','Recorded') order by e.version desc limit 1),
 'history',coalesce((select jsonb_agg(to_jsonb(e) order by e.version) from public.competence_assessment_events e where e.assessment_id=a.id),'[]'::jsonb));
end$$;
create function public.create_competence_assessment(p_id uuid,p_employee uuid,p_assessor uuid,p_definition uuid,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare a public.competence_assessments;d public.competence_definition_revisions;grant_row public.competence_assessor_designations;req jsonb;assignment jsonb;
begin
 if auth.uid() is null or not public.is_staff() or not portal_private.hr_access() then raise exception 'Current HR or administrator assessment coordination required';end if;
 if p_id is null or p_employee is null or p_assessor is null or p_definition is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit actual employee, assessor, criteria revision and assignment reason required';end if;
 perform 1 from public.profiles where id in(auth.uid(),p_employee,p_assessor) order by id for share;
 perform 1 from public.crm_memberships m join public.crm_roles r on r.id=m.role_id join public.crm_teams t on t.id=m.team_id where m.user_id=auth.uid() for share of m,r,t;
 if not public.is_staff() or not portal_private.hr_access() then raise exception 'Current assessment coordinator authority required';end if;
 req:=jsonb_build_object('employee_id',p_employee,'assessor_id',p_assessor,'definition_revision_id',p_definition,'reason',trim(p_reason));
 perform pg_advisory_xact_lock(hashtextextended(p_id::text,124));
 select * into a from public.competence_assessments where id=p_id;
 if a.id is not null then
  if a.created_by=auth.uid() and a.request=req then return a.id;end if;
  raise exception 'Assessment request records different content or account';
 end if;
 select * into d from public.competence_definition_revisions where id=p_definition;
 if d.id is null then raise exception 'Actual current available competency revision required';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_assessor::text,123));
 perform pg_advisory_xact_lock(hashtextextended(d.definition_id::text,122));
 if not portal_private.competence_basis_current(d.id) or not portal_private.competence_assessor_current(p_assessor) or not exists(select 1 from public.profiles p where p.id=p_employee and p.active and p.role in ('admin','team')) then raise exception 'Actual current staff, designated assessor and available criteria required';end if;
 select * into grant_row from public.competence_assessor_designations where user_id=p_assessor order by revision desc limit 1;
 assignment:=jsonb_build_object('criteria',jsonb_build_object('id',d.id,'definition_id',d.definition_id,'revision',d.revision,'title',d.title,'skill',d.skill,'checklist',d.checklist,'quiz_enabled',d.quiz_enabled,'pass_mark',d.pass_mark,'validity_months',d.validity_months,'warning_days',d.warning_days),
 'employee',(select jsonb_build_object('id',p.id,'name',p.name) from public.profiles p where p.id=p_employee),'assessor',(select jsonb_build_object('id',p.id,'name',p.name) from public.profiles p where p.id=p_assessor),'assessor_designation',jsonb_build_object('id',grant_row.id,'user_id',grant_row.user_id,'revision',grant_row.revision,'designation',grant_row.designation,'actor_id',grant_row.actor_id,'created_at',grant_row.created_at));
 insert into public.competence_assessments(id,employee_id,assessor_id,definition_revision_id,assignment_snapshot,request,reason,created_by) values(p_id,p_employee,p_assessor,d.id,assignment,req,trim(p_reason),auth.uid()) returning * into a;
 insert into public.competence_assessment_events(id,assessment_id,version,action,request,snapshot,reason,actor_id) values(p_id,a.id,a.version,'Assigned',req,jsonb_build_object('assessment',to_jsonb(a)),trim(p_reason),auth.uid());
 return a.id;
end$$;
create function public.record_competence_assessment(p_id uuid,p_assessment uuid,p_version integer,p_action text,p_results jsonb,p_quiz_score numeric,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare a public.competence_assessments;old public.competence_assessment_events;d public.competence_definition_revisions;req jsonb;item jsonb;step jsonb;result text;normalized jsonb:='[]';passing boolean:=true;outcome text;grant_row public.competence_assessor_designations;
begin
 select * into a from public.competence_assessments where id=p_assessment;
 if a.id is null or auth.uid() is null or not public.is_staff() or a.assessor_id<>auth.uid() then raise exception 'Actual assigned assessor required';end if;
 perform 1 from public.profiles where id in(auth.uid(),a.employee_id) order by id for share;
 perform pg_advisory_xact_lock(hashtextextended(a.assessor_id::text,123));
 select * into d from public.competence_definition_revisions where id=a.definition_revision_id;
 perform pg_advisory_xact_lock(hashtextextended(d.definition_id::text,122));
 select * into a from public.competence_assessments where id=p_assessment for update;
 if not portal_private.competence_assessor_current(auth.uid()) or not portal_private.competence_basis_current(a.definition_revision_id) or not public.is_staff() or not exists(select 1 from public.profiles p where p.id=a.employee_id and p.active and p.role in ('admin','team')) then raise exception 'Current assessor eligibility, actual staff and exact current criteria required';end if;
 if p_id is null or p_version is null or p_action is null or p_action not in ('Save draft','Record') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 or jsonb_typeof(p_results) is distinct from 'array' then raise exception 'Explicit assessment action, practical results, version and reason required';end if;
 req:=jsonb_build_object('assessment_id',a.id,'version',p_version,'action',p_action,'results',p_results,'quiz_score',p_quiz_score,'reason',trim(p_reason));
 select * into old from public.competence_assessment_events where id=p_id;
 if old.id is not null then
  if old.actor_id=auth.uid() and old.request=req then return old.id;end if;
  raise exception 'Assessment result request records different content or account';
 end if;
 if not portal_private.competence_assessment_edit(a) or a.version<>p_version then raise exception 'Exact current editable assessment version required';end if;
 if jsonb_array_length(p_results)<>jsonb_array_length(d.checklist) then raise exception 'Every actual practical step must be explicitly represented';end if;
 for item in select value from jsonb_array_elements(p_results) loop
  if jsonb_typeof(item)<>'object' then raise exception 'Actual step result object required';end if;
  if exists(select 1 from jsonb_object_keys(item) k where k not in ('id','result')) or jsonb_typeof(item->'id') is distinct from 'string' or not (item ? 'result') or (item->'result'<>'null'::jsonb and (jsonb_typeof(item->'result')<>'string' or item->>'result' not in ('Pass','Fail'))) then raise exception 'Only actual step ID and Pass/Fail or draft unrecorded result allowed';end if;
  if not exists(select 1 from jsonb_array_elements(d.checklist) s where (s->>'id')::uuid=(item->>'id')::uuid) then raise exception 'Result step must belong to pinned criteria';end if;
 end loop;
 if exists(select 1 from jsonb_array_elements(p_results) r group by (r->>'id')::uuid having count(*)>1) then raise exception 'Duplicate practical step result rejected';end if;
 for step in select value from jsonb_array_elements(d.checklist) loop
  select r->>'result' into result from jsonb_array_elements(p_results) r where (r->>'id')::uuid=(step->>'id')::uuid;
  if p_action='Record' and result is null then raise exception 'Record actual Pass/Fail for every practical step before completion';end if;
  if (step->>'mandatory')::boolean and result is distinct from 'Pass' then passing:=false;end if;
  normalized:=normalized||jsonb_build_array(jsonb_build_object('id',step->>'id','result',result));
 end loop;
 if p_quiz_score is not null and (p_quiz_score::text in ('NaN','Infinity','-Infinity') or p_quiz_score<0 or p_quiz_score>100) then raise exception 'Actual quiz percentage must be between 0 and 100';end if;
 if not d.quiz_enabled and p_quiz_score is not null then raise exception 'No quiz score allowed when pinned competency has no quiz';end if;
 if p_action='Record' then
  if d.quiz_enabled and p_quiz_score is null then raise exception 'Actual quiz score required for enabled quiz';end if;
  outcome:=case when passing and (not d.quiz_enabled or p_quiz_score>=d.pass_mark) then 'Pass' else 'Fail' end;
 end if;
 select * into grant_row from public.competence_assessor_designations where user_id=auth.uid() order by revision desc limit 1;
 update public.competence_assessments set version=version+1,status=case p_action when 'Record' then 'Recorded' else 'Draft' end where id=a.id returning * into a;
 insert into public.competence_assessment_events(id,assessment_id,version,action,request,snapshot,reason,actor_id) values(p_id,a.id,a.version,case p_action when 'Record' then 'Recorded' else 'Draft saved' end,req,
 jsonb_build_object('assessment',to_jsonb(a),'result',jsonb_build_object('results',normalized,'quiz_score',p_quiz_score,'outcome',outcome,'criteria_revision_id',d.id),'assessor_designation',jsonb_build_object('id',grant_row.id,'user_id',grant_row.user_id,'revision',grant_row.revision,'designation',grant_row.designation,'actor_id',grant_row.actor_id,'created_at',grant_row.created_at)),trim(p_reason),auth.uid());
 return p_id;
end$$;
create function public.cancel_competence_assessment(p_id uuid,p_assessment uuid,p_version integer,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare a public.competence_assessments;old public.competence_assessment_events;req jsonb;
begin
 if auth.uid() is null or not public.is_staff() or not portal_private.hr_access() then raise exception 'Current HR or administrator assessment coordination required';end if;
 perform 1 from public.profiles where id=auth.uid() for share;
 perform 1 from public.crm_memberships m join public.crm_roles r on r.id=m.role_id join public.crm_teams t on t.id=m.team_id where m.user_id=auth.uid() for share of m,r,t;
 if not public.is_staff() or not portal_private.hr_access() then raise exception 'Current assessment coordinator authority required';end if;
 select * into a from public.competence_assessments where id=p_assessment for update;
 if a.id is null or p_id is null or p_version is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Actual assessment, exact version and cancellation reason required';end if;
 req:=jsonb_build_object('assessment_id',a.id,'version',p_version,'reason',trim(p_reason));
 select * into old from public.competence_assessment_events where id=p_id;
 if old.id is not null then
  if old.actor_id=auth.uid() and old.request=req and old.action='Cancelled' then return old.id;end if;
  raise exception 'Assessment cancellation request records different content or account';
 end if;
 if a.version<>p_version or a.status='Cancelled' then raise exception 'Exact current noncancelled assessment version required';end if;
 update public.competence_assessments set status='Cancelled',version=version+1 where id=a.id returning * into a;
 insert into public.competence_assessment_events(id,assessment_id,version,action,request,snapshot,reason,actor_id) values(p_id,a.id,a.version,'Cancelled',req,jsonb_build_object('assessment',to_jsonb(a),'latest_result',(select to_jsonb(e) from public.competence_assessment_events e where e.assessment_id=a.id and e.action in ('Draft saved','Recorded') order by e.version desc limit 1)),trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.competence_assessment_options(),public.competence_assessment_queue(),public.competence_assessment_context(uuid),public.create_competence_assessment(uuid,uuid,uuid,uuid,text),public.record_competence_assessment(uuid,uuid,integer,text,jsonb,numeric,text),public.cancel_competence_assessment(uuid,uuid,integer,text) from public,anon;
grant execute on function public.competence_assessment_options(),public.competence_assessment_queue(),public.competence_assessment_context(uuid),public.create_competence_assessment(uuid,uuid,uuid,uuid,text),public.record_competence_assessment(uuid,uuid,integer,text,jsonb,numeric,text),public.cancel_competence_assessment(uuid,uuid,integer,text) to authenticated;
notify pgrst,'reload schema';
commit;
