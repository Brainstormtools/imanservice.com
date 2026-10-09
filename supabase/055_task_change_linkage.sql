begin;
alter table public.crm_task_plan_history add column change_id uuid references public.crm_project_changes,add column change_version integer,add constraint crm_plan_change_pair check((change_id is null and change_version is null) or (change_id is not null and change_version is not null and change_version>0));
create index crm_plan_history_change on public.crm_task_plan_history(change_id);
create function public.apply_crm_task_change(p_change uuid,p_change_version integer,p_task uuid,p_version integer,p_quantity numeric,p_duration numeric,p_crew integer,p_tools text,p_preconditions text,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare pid uuid;c public.crm_project_changes;
begin
 if not public.is_admin() then raise exception 'Administrator applies approved task changes';end if;
 select project_id into pid from public.tasks where id=p_task;
 perform 1 from public.projects where id=pid for update;if not found then raise exception 'Task project required';end if;
 select * into c from public.crm_project_changes where id=p_change for update;
 if c.id is null or c.project_id is distinct from pid or c.version is distinct from p_change_version or c.details->>'status'<>'Approved' then raise exception 'Current approved change for this task project required';end if;
 perform public.adjust_crm_task_plan(p_task,p_version,p_quantity,p_duration,p_crew,p_tools,p_preconditions,p_reason);
 update public.crm_task_plan_history set change_id=c.id,change_version=c.version where task_id=p_task and revision=p_version+1;
 if not found then raise exception 'Atomic task revision linkage required';end if;
end$$;
revoke all on function public.apply_crm_task_change(uuid,integer,uuid,integer,numeric,numeric,integer,text,text,text) from public,anon;
grant execute on function public.apply_crm_task_change(uuid,integer,uuid,integer,numeric,numeric,integer,text,text,text) to authenticated;
commit;
