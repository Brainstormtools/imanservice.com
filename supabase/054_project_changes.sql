begin;
create table public.crm_project_changes(id uuid primary key,project_id uuid not null references public.projects,details jsonb not null check(jsonb_typeof(details)='object'),version integer not null default 1,reason text not null check(length(trim(reason)) between 3 and 2000),created_by uuid not null references public.profiles,submitted_by uuid references public.profiles,created_at timestamptz not null default now());
create index crm_changes_project on public.crm_project_changes(project_id);
create index crm_changes_author on public.crm_project_changes(created_by);
create index crm_changes_submitter on public.crm_project_changes(submitted_by);
create table public.crm_project_changes_history(id uuid primary key default gen_random_uuid(),change_id uuid not null references public.crm_project_changes,project_id uuid not null references public.projects,revision integer not null,before_change jsonb,after_change jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(change_id,revision));
create index crm_changes_history_project on public.crm_project_changes_history(project_id);
create index crm_changes_history_actor on public.crm_project_changes_history(actor_id);
alter table public.crm_project_changes enable row level security;
alter table public.crm_project_changes_history enable row level security;
revoke all on public.crm_project_changes,public.crm_project_changes_history from public,anon,authenticated;
grant select on public.crm_project_changes,public.crm_project_changes_history to authenticated;
create policy project_changes_read on public.crm_project_changes for select to authenticated using(portal_private.execution_manager(project_id));
create policy project_changes_history_read on public.crm_project_changes_history for select to authenticated using(portal_private.execution_manager(project_id));
create function public.save_project_change(p_id uuid,p_version integer,p_project uuid,p_details jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare old public.crm_project_changes;newrow public.crm_project_changes;d jsonb;k text;
begin
 if not portal_private.execution_manager(p_project) then raise exception 'Assigned project manager access required';end if;
 perform 1 from public.projects where id=p_project for update;if not found then raise exception 'Project required';end if;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Change ID and revision reason required';end if;
 if p_details is null or jsonb_typeof(p_details)<>'object' or (select count(*) from jsonb_object_keys(p_details))<>8 then raise exception 'Complete change details required';end if;
 d:='{}'::jsonb;
 foreach k in array array['title','proposed_scope','justification','cost_impact','schedule_impact','evidence','status','decision_note'] loop
  if jsonb_typeof(p_details->k) is distinct from 'string' then raise exception 'Complete text change fields required';end if;
  d:=d||jsonb_build_object(k,trim(p_details->>k));
 end loop;
 if length(d->>'title') not between 3 and 160 or length(d->>'proposed_scope') not between 3 and 4000 or length(d->>'justification')>4000 or length(d->>'cost_impact')>4000 or length(d->>'schedule_impact')>4000 or length(d->>'evidence')>4000 or length(d->>'decision_note')>4000 or d->>'status' not in ('Draft','Submitted','Approved','Rejected') then raise exception 'Bounded proposed scope and valid status required';end if;
 if d->>'status'<>'Draft' then
  foreach k in array array['justification','cost_impact','schedule_impact','evidence'] loop
   if length(d->>k)<3 then raise exception 'Submission requires justification, cost impact, schedule impact and evidence';end if;
  end loop;
 end if;
 if d->>'status' in ('Draft','Submitted') and d->>'decision_note'<>'' then raise exception 'Decision note is reserved for the administrator decision';end if;
 select * into old from public.crm_project_changes where id=p_id for update;
 if old.id is not null then
  if p_version is null then
   if old.created_by=auth.uid() and old.version=1 and old.project_id=p_project and old.details=d and old.reason=trim(p_reason) then return old.id;end if;
   raise exception 'Change ID already used with different data';
  end if;
  if old.project_id<>p_project or old.version is distinct from p_version then raise exception 'Current change version and fixed project required';end if;
  if old.details->>'status' in ('Approved','Rejected') then raise exception 'Decided change is immutable';end if;
  if old.details->>'status'='Draft' and d->>'status' not in ('Draft','Submitted') then raise exception 'Submit change before decision';end if;
  if old.details->>'status'='Submitted' then
   if not public.is_admin() or auth.uid() in (old.created_by,old.submitted_by) then raise exception 'Separate administrator decision required';end if;
   if d->>'status' not in ('Approved','Rejected') or length(d->>'decision_note')<3 then raise exception 'Approval or rejection with decision note required';end if;
   if (d-array['status','decision_note']) is distinct from (old.details-array['status','decision_note']) then raise exception 'Submitted request evidence is frozen';end if;
  end if;
  update public.crm_project_changes set details=d,reason=trim(p_reason),version=version+1,submitted_by=case when old.details->>'status'='Draft' and d->>'status'='Submitted' then auth.uid() else submitted_by end where id=p_id returning * into newrow;
 else
  if p_version is not null or d->>'status'<>'Draft' then raise exception 'New change must start Draft without a saved version';end if;
  insert into public.crm_project_changes(id,project_id,details,reason,created_by) values(p_id,p_project,d,trim(p_reason),auth.uid()) returning * into newrow;
 end if;
 insert into public.crm_project_changes_history(change_id,project_id,revision,before_change,after_change,reason,actor_id) values(p_id,p_project,newrow.version,case when old.id is null then null else to_jsonb(old) end,to_jsonb(newrow),trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.save_project_change(uuid,integer,uuid,jsonb,text) from public,anon;
grant execute on function public.save_project_change(uuid,integer,uuid,jsonb,text) to authenticated;
commit;
