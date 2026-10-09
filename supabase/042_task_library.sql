-- Independent, versioned reusable task standards; existing templates stay fixed.
begin;
create table public.crm_task_library(id uuid primary key default gen_random_uuid(),name text not null check(length(trim(name)) between 1 and 160),active boolean not null,version integer not null default 1);
create table public.crm_task_library_versions(id uuid primary key default gen_random_uuid(),standard_id uuid not null references public.crm_task_library,revision integer not null,name text not null,active boolean not null,parameters jsonb not null,task jsonb not null,reason text not null check(length(trim(reason)) between 3 and 2000),author_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(standard_id,revision));
create index crm_task_library_author on public.crm_task_library_versions(author_id);
alter table public.crm_task_library enable row level security;
alter table public.crm_task_library_versions enable row level security;
create policy task_library_read on public.crm_task_library for select to authenticated using(portal_private.template_access());
create policy task_library_version_read on public.crm_task_library_versions for select to authenticated using(portal_private.template_access());
revoke all on public.crm_task_library,public.crm_task_library_versions from public,anon,authenticated;
grant select on public.crm_task_library,public.crm_task_library_versions to authenticated;
create function portal_private.validate_library_task(p_parameters jsonb,p_task jsonb) returns void language plpgsql set search_path='' as $$declare p_tasks jsonb:=jsonb_build_array(p_task);parameter jsonb;task jsonb;keys text[]:='{}';task_keys text[]:='{}';key text;previous_phase integer:=-1;begin
if jsonb_typeof(p_task) is distinct from 'object' or length(p_task::text)>60000 or length(p_parameters::text)>50000 then raise exception 'Bounded task standard and parameter values required';end if;
if jsonb_typeof(p_parameters) is distinct from 'array' or jsonb_array_length(p_parameters)>30 or jsonb_typeof(p_tasks) is distinct from 'array' or jsonb_array_length(p_tasks) not between 1 and 100 then raise exception 'Use up to 30 parameters and 1–100 tasks';end if;
for parameter in select value from jsonb_array_elements(p_parameters) loop
key:=parameter->>'key';if key is null or key !~ '^[a-z][a-z0-9_]{0,39}$' or key=any(keys) or length(trim(coalesce(parameter->>'label',''))) not between 1 and 100 or not ((parameter->>'min')::numeric between 0 and 100000 and (parameter->>'max')::numeric between 0 and 100000 and (parameter->>'default')::numeric between (parameter->>'min')::numeric and (parameter->>'max')::numeric) or (parameter->>'min') is null or (parameter->>'max') is null or (parameter->>'default') is null then raise exception 'Invalid or duplicate template parameter';end if;keys:=keys||key;end loop;
for task in select value from jsonb_array_elements(p_tasks) loop
key:=task->>'key';if key is null or key !~ '^[a-z][a-z0-9_]{0,39}$' or key=any(task_keys) or (task->>'phase')::integer not between 0 and 5 or (task->>'phase')::integer<previous_phase or length(trim(coalesce(task->>'title',''))) not between 1 and 200 or length(coalesce(task->>'unit','')) not between 1 and 30 or length(coalesce(task->>'crew_role','')) not between 1 and 100 or not ((task->>'minutes')::numeric between 0 and 100000 and (task->>'fixed_minutes')::numeric between 0 and 100000 and (task->>'fixed_quantity')::numeric between 0 and 100000 and (task->>'crew')::integer between 1 and 100) or (task->>'phase') is null or (task->>'minutes') is null or (task->>'fixed_minutes') is null or (task->>'fixed_quantity') is null or (task->>'crew') is null then raise exception 'Invalid template task or phase order';end if;
if jsonb_typeof(task->'quantity_parameters') is distinct from 'array' or exists(select 1 from jsonb_array_elements_text(task->'quantity_parameters') v where not v=any(keys)) or (coalesce(task->>'factor_parameter','')<>'' and not task->>'factor_parameter'=any(keys)) or (coalesce(task->>'condition_parameter','')<>'' and not task->>'condition_parameter'=any(keys)) or jsonb_typeof(task->'depends_on') is distinct from 'array' or exists(select 1 from jsonb_array_elements_text(task->'depends_on') v where not v=any(task_keys)) or jsonb_typeof(task->'checklist') is distinct from 'array' or jsonb_array_length(task->'checklist')>30 or exists(select 1 from jsonb_array_elements_text(task->'checklist') v where length(trim(v)) not between 1 and 200) or length(coalesce(task->>'tools',''))>2000 or length(coalesce(task->>'preconditions',''))>2000 then raise exception 'Invalid task formula, checklist or predecessor';end if;
previous_phase:=(task->>'phase')::integer;task_keys:=task_keys||key;end loop;
end$$;
create function public.save_crm_task_standard(p_id uuid,p_version integer,p_name text,p_active boolean,p_parameters jsonb,p_task jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$declare s public.crm_task_library;begin
if not public.is_admin() then raise exception 'Administrator configures task library standards';end if;
if length(trim(coalesce(p_name,''))) not between 1 and 160 or p_active is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Standard name, active status and revision reason required';end if;
perform portal_private.validate_library_task(p_parameters,p_task);
if p_id is null then
 if p_version is not null then raise exception 'New standard has no prior version';end if;
 insert into public.crm_task_library(name,active) values(trim(p_name),p_active) returning * into s;
else
 select * into s from public.crm_task_library where id=p_id for update;
 if s.id is null or s.version is distinct from p_version then raise exception 'Current task-library version required';end if;
 update public.crm_task_library set name=trim(p_name),active=p_active,version=version+1 where id=p_id returning * into s;
end if;
insert into public.crm_task_library_versions(standard_id,revision,name,active,parameters,task,reason,author_id) values(s.id,s.version,s.name,s.active,p_parameters,p_task,trim(p_reason),auth.uid());return s.id;
end$$;
revoke all on function portal_private.validate_library_task(jsonb,jsonb) from public,anon,authenticated;
revoke all on function public.save_crm_task_standard(uuid,integer,text,boolean,jsonb,jsonb,text) from public,anon;
grant execute on function public.save_crm_task_standard(uuid,integer,text,boolean,jsonb,jsonb,text) to authenticated;
-- Cover foreign-key lookups identified in the preceding response/repeat release.
create index ticket_response_project on public.ticket_response_history(project_id);
create index ticket_repeat_original on public.ticket_repeat_reviews(original_ticket_id);
create index ticket_repeat_resolution on public.ticket_repeat_reviews(resolution_id);
create index ticket_repeat_reviewer on public.ticket_repeat_reviews(reviewed_by);
commit;
