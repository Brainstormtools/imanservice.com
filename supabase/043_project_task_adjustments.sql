begin;
alter table public.crm_task_plans add column version integer not null default 0;
create table public.crm_task_plan_history(id uuid primary key default gen_random_uuid(),task_id uuid not null references public.tasks,project_id uuid not null references public.projects,revision integer not null,before_plan jsonb not null,after_plan jsonb not null,reason text not null check(length(trim(reason)) between 3 and 2000),actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(task_id,revision));
create index crm_plan_history_project on public.crm_task_plan_history(project_id);
create index crm_plan_history_actor on public.crm_task_plan_history(actor_id);
alter table public.crm_task_plan_history enable row level security;
revoke all on public.crm_task_plan_history from public,anon,authenticated;
grant select on public.crm_task_plan_history to authenticated;
create policy plan_history_read on public.crm_task_plan_history for select to authenticated using(portal_private.execution_manager(project_id));
-- Serialize activity creation with planning adjustments, including simultaneous starts.
create function portal_private.activity_plan_lock() returns trigger language plpgsql security definer set search_path='' as $$begin
if new.task_id is not null then
 perform 1 from public.projects where id=new.project_id for update;
 perform 1 from public.tasks where id=new.task_id for update;
end if;return new;end$$;
revoke all on function portal_private.activity_plan_lock() from public,anon,authenticated;
create trigger activity_plan_lock before insert or update on public.work_activities for each row execute function portal_private.activity_plan_lock();
create function public.adjust_crm_task_plan(p_task uuid,p_version integer,p_quantity numeric,p_duration numeric,p_crew integer,p_tools text,p_preconditions text,p_reason text) returns void language plpgsql security definer set search_path='' as $$declare t public.tasks;old_plan public.crm_task_plans;new_plan public.crm_task_plans;pid uuid;begin
if not public.is_admin() then raise exception 'Administrator adjusts project task plans';end if;
select project_id into pid from public.tasks where id=p_task;
perform 1 from public.projects where id=pid and status<>'Completed' for update;if not found then raise exception 'Open project required';end if;
select * into t from public.tasks where id=p_task for update;
select * into old_plan from public.crm_task_plans where task_id=p_task for update;
if old_plan.task_id is null or old_plan.version is distinct from p_version or not exists(select 1 from public.crm_project_workstreams where id=old_plan.workstream_id and project_id=pid) then raise exception 'Current generated task plan required';end if;
if t.status<>'To do' or exists(select 1 from public.work_activities where task_id=p_task) or exists(select 1 from public.work_logs where task_id=p_task) or exists(select 1 from public.task_completions where task_id=p_task) or exists(select 1 from public.task_items where task_id=p_task and done) or exists(select 1 from public.crm_phases where project_id=pid and phase=old_plan.phase and status<>'Draft') or exists(select 1 from public.crm_handovers where project_id=pid and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Started, reviewed or handover-locked work cannot be replanned';end if;
if p_quantity is null or not(p_quantity>0 and p_quantity<=100000) or p_duration is null or not(p_duration>0 and p_duration<=1000000) or p_crew is null or p_crew not between 1 and 100 or p_tools is null or length(p_tools)>2000 or p_preconditions is null or length(p_preconditions)>2000 or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Bounded quantity, duration, crew, notes and reason required';end if;
update public.crm_task_plans set quantity=p_quantity,duration_minutes=p_duration,crew=p_crew,tools=p_tools,preconditions=p_preconditions,version=version+1 where task_id=p_task returning * into new_plan;
insert into public.crm_task_plan_history(task_id,project_id,revision,before_plan,after_plan,reason,actor_id) values(p_task,pid,new_plan.version,to_jsonb(old_plan),to_jsonb(new_plan),trim(p_reason),auth.uid());
end$$;
revoke all on function public.adjust_crm_task_plan(uuid,integer,numeric,numeric,integer,text,text,text) from public,anon;
grant execute on function public.adjust_crm_task_plan(uuid,integer,numeric,numeric,integer,text,text,text) to authenticated;
commit;
