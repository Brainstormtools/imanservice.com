-- APPLIED via native connected migration 20261027194207 UTC scaffold, CLI unavailable. New records only; never backfill old work.
create table portal_private.crm_activity_route_basis(
 activity_id uuid primary key references public.work_activities,
 project_id uuid not null references public.projects,
 task_id uuid not null references public.tasks,
 worker_id uuid not null references public.profiles,
 recorded_by uuid references public.profiles,
 captured_at timestamptz not null default clock_timestamp(),
 reference_id uuid references portal_private.crm_task_route_history,
 reference_state text not null check(reference_state in ('No reference','Unlinked','Current at capture','Stale at capture')),
 task_source jsonb not null,
 planning_reference jsonb,
 route_at_capture jsonb
);
create index crm_activity_route_project on portal_private.crm_activity_route_basis(project_id);
create index crm_activity_route_task on portal_private.crm_activity_route_basis(task_id);
create index crm_activity_route_worker on portal_private.crm_activity_route_basis(worker_id);
create index crm_activity_route_actor on portal_private.crm_activity_route_basis(recorded_by);
create index crm_activity_route_reference on portal_private.crm_activity_route_basis(reference_id);
alter table portal_private.crm_activity_route_basis enable row level security;
revoke all on portal_private.crm_activity_route_basis from public,anon,authenticated,service_role;
create trigger crm_activity_route_basis_immutable before update or delete on portal_private.crm_activity_route_basis for each row execute function portal_private.lead_api_evidence_immutable();
create function portal_private.capture_activity_route_basis() returns trigger language plpgsql security definer set search_path='' as $$
declare h portal_private.crm_task_route_history;r portal_private.crm_project_routes;v portal_private.crm_project_route_versions;basis jsonb;actual_route jsonb;state text;
begin
 if new.task_id is null or new.project_id is null then return new;end if;
 -- Existing BEFORE activity_plan_lock locks project/task in this order.
 perform 1 from public.projects where id=new.project_id for update;
 perform 1 from public.tasks where id=new.task_id and project_id=new.project_id for update;
 if not found then raise exception 'Actual activity task must belong to its project';end if;
 perform 1 from public.crm_task_plans where task_id=new.task_id for share;
 perform 1 from public.task_items where task_id=new.task_id order by id for share;
 basis:=portal_private.route_task_basis(new.task_id);
 select * into h from portal_private.crm_task_route_history where task_id=new.task_id and project_id=new.project_id order by sequence desc limit 1;
 if h.id is null then state:='No reference';
 elsif h.action='Unlinked' then state:='Unlinked';
 else
  select * into r from portal_private.crm_project_routes where id=h.route_id and project_id=new.project_id for share;
  select * into v from portal_private.crm_project_route_versions where route_id=r.id and revision=r.revision;
  actual_route:=to_jsonb(v)-'payload';
  state:=case when h.task_source=basis and v.state='Active' and v.id=h.route_version and h.route_source=actual_route then 'Current at capture' else 'Stale at capture' end;
 end if;
 insert into portal_private.crm_activity_route_basis(activity_id,project_id,task_id,worker_id,recorded_by,reference_id,reference_state,task_source,planning_reference,route_at_capture)
 values(new.id,new.project_id,new.task_id,new.user_id,auth.uid(),h.id,state,basis,case when h.id is not null then to_jsonb(h)-'payload' end,actual_route);
 return new;
end$$;
revoke all on function portal_private.capture_activity_route_basis() from public,anon,authenticated,service_role;
create trigger capture_activity_route_basis after insert on public.work_activities for each row execute function portal_private.capture_activity_route_basis();
-- Approval/status/intervals remain live facts; source evidence stays frozen.
create function public.project_activity_route_context(p_project uuid default null) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare c jsonb;rows jsonb;
begin
 c:=public.project_route_context(p_project);
 if p_project is null then return jsonb_build_object('projects',c->'projects');end if;
 select coalesce(jsonb_agg(jsonb_build_object('activity_id',a.id,'task_id',a.task_id,'worker_id',a.user_id,'activity_status',a.status,'actual_start',a.actual_start,'actual_end',a.actual_end,'basis',to_jsonb(b),'capture_state',coalesce(b.reference_state,'Not captured (historical record)')) order by a.actual_start desc,a.id),'[]') into rows
 from public.work_activities a left join portal_private.crm_activity_route_basis b on b.activity_id=a.id
 where a.project_id=p_project and a.task_id is not null;
 return jsonb_build_object('project',c->'project','activities',rows);
end$$;
revoke all on function public.project_activity_route_context(uuid) from public,anon,service_role;
grant execute on function public.project_activity_route_context(uuid) to authenticated;
