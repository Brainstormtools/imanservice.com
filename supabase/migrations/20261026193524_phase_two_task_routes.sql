-- UNAPPLIED local UTC scaffold; CLI unavailable. Manual task/route references, not execution.
create table portal_private.crm_task_route_history(id uuid primary key,project_id uuid not null references public.projects,task_id uuid not null references public.tasks,sequence integer not null,previous_id uuid references portal_private.crm_task_route_history,action text not null check(action in ('Linked','Unlinked')),route_id uuid not null references portal_private.crm_project_routes,route_version uuid not null references portal_private.crm_project_route_versions,task_source jsonb not null,route_source jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),payload jsonb not null,unique(task_id,sequence));
create index crm_task_route_history_project on portal_private.crm_task_route_history(project_id);
create index crm_task_route_history_previous on portal_private.crm_task_route_history(previous_id);
create index crm_task_route_history_route on portal_private.crm_task_route_history(route_id);
create index crm_task_route_history_version on portal_private.crm_task_route_history(route_version);
create index crm_task_route_history_actor on portal_private.crm_task_route_history(actor_id);
alter table portal_private.crm_task_route_history enable row level security;
revoke all on portal_private.crm_task_route_history from public,anon,authenticated,service_role;
create trigger crm_task_route_history_immutable before update or delete on portal_private.crm_task_route_history for each row execute function portal_private.lead_api_evidence_immutable();
create function portal_private.route_task_basis(p_task uuid) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('task',to_jsonb(t),'plan',(select to_jsonb(p)||jsonb_build_object('quantity',p.quantity::text,'duration_minutes',p.duration_minutes::text) from public.crm_task_plans p where p.task_id=t.id),'checklist',coalesce((select jsonb_agg(to_jsonb(i) order by id) from public.task_items i where task_id=t.id),'[]')) from public.tasks t where id=p_task;
$$;
create function portal_private.route_task_blocked(p_task uuid) returns text language plpgsql stable security definer set search_path='' as $$declare t public.tasks;r record;linked boolean;begin
 select * into t from public.tasks where id=p_task;if not found then return 'Actual task required';end if;
 if t.status<>'To do' then return 'Task is not unstarted';end if;
 if exists(select 1 from public.task_items where task_id=p_task and done) then return 'Checklist work already recorded';end if;
 for r in select c.conrelid::regclass rel,a.attname col from pg_catalog.pg_constraint c join pg_catalog.pg_attribute a on a.attrelid=c.conrelid and a.attnum=c.conkey[1] where c.contype='f' and c.confrelid='public.tasks'::regclass and cardinality(c.conkey)=1 and c.conrelid not in ('public.crm_task_plans'::regclass,'public.task_items'::regclass,'public.crm_task_plan_history'::regclass,'portal_private.crm_task_route_history'::regclass) loop
 execute format('select exists(select 1 from %s where %I=$1)',r.rel,r.col) into linked using t.id;if linked then return 'Linked work, cost or operational record requires separate reconciliation';end if;end loop;return '';
end$$;
revoke all on function portal_private.route_task_basis(uuid),portal_private.route_task_blocked(uuid) from public,anon,authenticated,service_role;
create function public.project_task_route_context(p_project uuid default null,p_task uuid default null) returns jsonb language plpgsql stable security definer set search_path='' as $$declare c jsonb;n public.tasks;h portal_private.crm_task_route_history;begin
 c:=public.project_route_context(p_project);
 if p_project is null then if p_task is not null then raise exception 'Actual task project required';end if;return jsonb_build_object('projects',c->'projects');end if;
 if p_task is not null then select * into n from public.tasks where id=p_task and project_id=p_project;if not found then raise exception 'Actual task in selected project required';end if;select * into h from portal_private.crm_task_route_history where task_id=p_task and project_id=p_project order by sequence desc limit 1;end if;
 return jsonb_build_object('project',c->'project','can_edit',(c->'project'->>'status')<>'Completed' and not exists(select 1 from public.crm_phases where project_id=p_project and status<>'Draft') and not exists(select 1 from public.crm_handovers where project_id=p_project and status in ('Awaiting signatures','Signed','Closed')),'tasks',coalesce((select jsonb_agg(jsonb_build_object('id',id,'title',title,'status',status) order by title,id) from public.tasks where project_id=p_project),'[]'),'routes',coalesce((select jsonb_agg(to_jsonb(v)-'payload' order by r.code,r.id) from portal_private.crm_project_routes r join portal_private.crm_project_route_versions v on v.route_id=r.id and v.revision=r.revision where r.project_id=p_project and v.state='Active'),'[]'),'task',case when n.id is not null then to_jsonb(n) else null end,'task_basis',case when n.id is not null then portal_private.route_task_basis(n.id) else null end,'blocked',case when n.id is not null then portal_private.route_task_blocked(n.id) else '' end,'task_can_edit',n.id is not null and portal_private.route_task_blocked(n.id)='' and (c->'project'->>'status')<>'Completed' and not exists(select 1 from public.crm_phases where project_id=p_project and status<>'Draft') and not exists(select 1 from public.crm_handovers where project_id=p_project and status in ('Awaiting signatures','Signed','Closed')),'history',coalesce((select jsonb_agg(to_jsonb(x)-'payload' order by sequence desc) from portal_private.crm_task_route_history x where task_id=p_task and project_id=p_project),'[]'),'current_link',case when h.id is not null then to_jsonb(h)-'payload' else null end,'matches_current_sources',coalesce(h.action='Linked' and h.task_source=portal_private.route_task_basis(n.id) and exists(select 1 from portal_private.crm_project_routes r join portal_private.crm_project_route_versions v on v.route_id=r.id and v.revision=r.revision where r.id=h.route_id and r.project_id=p_project and v.id=h.route_version and v.state='Active' and h.route_source=to_jsonb(v)-'payload'),false));
end$$;
create function public.save_task_route_link(p_request uuid,p_project uuid,p_task uuid,p_previous uuid,p_action text,p_route uuid,p_task_source jsonb,p_route_source jsonb,p_reason text,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$declare n public.tasks;r portal_private.crm_project_routes;v portal_private.crm_project_route_versions;previous portal_private.crm_task_route_history;receipt portal_private.crm_task_route_history;payload jsonb;actual_route_source jsonb;actual_route uuid;actual_route_version uuid;project_status text;begin
 perform 1 from public.profiles where id=auth.uid() and active and role in ('admin','team') for share;if not found then raise exception 'Current task/route authority required';end if;
 perform 1 from public.crm_memberships where user_id=auth.uid() order by role_id,team_id for share;perform 1 from public.crm_roles order by id for share;perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id=auth.uid()) order by id for share;
 if p_request is null or p_project is null or p_task is null then raise exception 'Actual project task and request required';end if;
 perform pg_advisory_xact_lock(hashtextextended('task-route-link:'||p_request,0));select status into project_status from public.projects where id=p_project for update;
 if not found or not portal_private.project_criteria_access(p_project) then raise exception 'Current actual Admin or assigned PM required after waiting';end if;
 select * into n from public.tasks where id=p_task and project_id=p_project for update;if not found then raise exception 'Actual task must belong to selected project';end if;
 perform 1 from public.crm_task_plans where task_id=p_task for share;perform 1 from public.task_items where task_id=p_task order by id for share;
 payload:=jsonb_build_object('project',p_project,'task',p_task,'previous',p_previous,'action',p_action,'route',p_route,'task_source',p_task_source,'route_source',p_route_source,'reason',p_reason,'confirmed',p_confirm);
 select * into receipt from portal_private.crm_task_route_history where id=p_request;
 if found then if receipt.actor_id<>auth.uid() or receipt.payload is distinct from payload then raise exception 'Task/route retry meaning changed';end if;return receipt.id;end if;
 if project_status='Completed' or exists(select 1 from public.crm_phases where project_id=p_project and status<>'Draft') or exists(select 1 from public.crm_handovers where project_id=p_project and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Phase review, completed project or released handover keeps task/route links read-only';end if;
 if portal_private.route_task_blocked(p_task)<>'' then raise exception 'Only unstarted tasks without operational/work/cost evidence can change planning references';end if;
 if p_confirm is distinct from true or p_action is null or p_action not in ('Linked','Unlinked') or length(trim(coalesce(p_reason,''))) not between 3 and 1000 or p_task_source is distinct from portal_private.route_task_basis(n.id) then raise exception 'Exact current task, actual link action, reason and confirmation required';end if;
 select * into previous from portal_private.crm_task_route_history where task_id=p_task order by sequence desc limit 1;
 if p_previous is distinct from previous.id or previous.project_id is not null and previous.project_id<>p_project then raise exception 'Task route history/project changed; refresh latest reference';end if;
 if p_action='Linked' then
 select * into r from portal_private.crm_project_routes where id=p_route and project_id=p_project for share;
 if not found then raise exception 'Actual route must belong to selected project';end if;
 select * into v from portal_private.crm_project_route_versions where route_id=r.id and revision=r.revision;
 if v.state is distinct from 'Active' or p_route_source is distinct from to_jsonb(v)-'payload' then raise exception 'Current Active route revision changed; refresh selected source';end if;
 actual_route:=r.id;actual_route_version:=v.id;actual_route_source:=to_jsonb(v)-'payload';
 else
 if previous.action is distinct from 'Linked' or p_route is not null or p_route_source is not null then raise exception 'Unlink must explicitly target latest saved reference without a new route';end if;
 actual_route:=previous.route_id;actual_route_version:=previous.route_version;actual_route_source:=previous.route_source;
 end if;
 insert into portal_private.crm_task_route_history(id,project_id,task_id,sequence,previous_id,action,route_id,route_version,task_source,route_source,reason,actor_id,payload) values(p_request,p_project,p_task,coalesce(previous.sequence,0)+1,previous.id,p_action,actual_route,actual_route_version,portal_private.route_task_basis(n.id),actual_route_source,trim(p_reason),auth.uid(),payload);return p_request;
end$$;
revoke all on function public.project_task_route_context(uuid,uuid),public.save_task_route_link(uuid,uuid,uuid,uuid,text,uuid,jsonb,jsonb,text,boolean) from public,anon,service_role;
grant execute on function public.project_task_route_context(uuid,uuid),public.save_task_route_link(uuid,uuid,uuid,uuid,text,uuid,jsonb,jsonb,text,boolean) to authenticated;

-- Additive planning evidence: unchanged BOQ snapshot shape when no route references exist.
create or replace function portal_private.boq_removal_task(p_task uuid,p_project uuid) returns jsonb language plpgsql set search_path='' as $$
declare t public.tasks;plan public.crm_task_plans;r record;linked boolean;blocked text:='';result jsonb;
begin
 select * into t from public.tasks where id=p_task and project_id=p_project for update;
 select * into plan from public.crm_task_plans where task_id=t.id for update;
 if t.id is null or plan.task_id is null or not exists(select 1 from public.crm_project_workstreams w join public.crm_sales s on s.id=w.sale_id where w.id=plan.workstream_id and w.project_id=p_project and s.project_id=p_project) then raise exception 'Actual generated task on this sale project required';end if;
 if t.status<>'To do' then blocked:='Task is not unstarted';
 elsif exists(select 1 from public.task_items where task_id=t.id and done) then blocked:='Checklist work already recorded';
 elsif exists(select 1 from public.crm_task_plans where t.id=any(dependencies)) then blocked:='Dependent tasks require separate reconciliation';
 elsif exists(select 1 from public.crm_phases where project_id=p_project and phase=plan.phase and status<>'Draft') then blocked:='Phase has entered review';
 end if;
 -- Any operational/financial reference blocks this narrow increment, including drafts.
 -- Planning history and untouched checklists are frozen instead of deleted.
 for r in select c.conrelid::regclass rel,a.attname col from pg_catalog.pg_constraint c join pg_catalog.pg_attribute a on a.attrelid=c.conrelid and a.attnum=c.conkey[1]
  where c.contype='f' and c.confrelid='public.tasks'::regclass and cardinality(c.conkey)=1
   and c.conrelid not in ('public.crm_task_plans'::regclass,'public.task_items'::regclass,'public.crm_task_plan_history'::regclass,'portal_private.crm_task_route_history'::regclass)
 loop
  execute format('select exists(select 1 from %s where %I=$1)',r.rel,r.col) into linked using t.id;
  if linked then blocked:='Linked work, cost or operational record requires separate reconciliation';exit;end if;
 end loop;
 result:=jsonb_build_object('id',t.id,'title',t.title,'blocked',blocked,'snapshot',jsonb_build_object('task',to_jsonb(t),'plan',to_jsonb(plan),
  'checklist',coalesce((select jsonb_agg(to_jsonb(i) order by i.id) from public.task_items i where task_id=t.id),'[]'::jsonb),
  'plan_history',coalesce((select jsonb_agg(to_jsonb(h) order by h.revision) from public.crm_task_plan_history h where task_id=t.id),'[]'::jsonb)));
 if exists(select 1 from portal_private.crm_task_route_history where task_id=t.id) then result:=jsonb_set(result,'{snapshot,route_planning_history}',(select jsonb_agg(to_jsonb(h)-'payload' order by sequence) from portal_private.crm_task_route_history h where task_id=t.id));end if;
 return result;
end$$;
