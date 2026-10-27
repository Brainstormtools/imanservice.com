-- APPLIED via native connected migration 20261027194200 local UTC scaffold; CLI unavailable. Manual route definitions, not execution.
create table portal_private.crm_project_routes(id uuid primary key,project_id uuid not null references public.projects,revision integer not null check(revision>0),code text not null);
create unique index crm_project_routes_code on portal_private.crm_project_routes(project_id,lower(code));
create table portal_private.crm_project_route_versions(id uuid primary key,route_id uuid not null references portal_private.crm_project_routes,revision integer not null,details jsonb not null,state text not null check(state in ('Active','Archived')),reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),payload jsonb not null,unique(route_id,revision));
create index crm_project_route_versions_actor on portal_private.crm_project_route_versions(actor_id);
alter table portal_private.crm_project_routes enable row level security;alter table portal_private.crm_project_route_versions enable row level security;
revoke all on portal_private.crm_project_routes,portal_private.crm_project_route_versions from public,anon,authenticated,service_role;
create trigger crm_project_route_version_immutable before update or delete on portal_private.crm_project_route_versions for each row execute function portal_private.lead_api_evidence_immutable();
create function portal_private.protect_project_route_identity() returns trigger language plpgsql security definer set search_path='' as $$begin if new.id is distinct from old.id or new.project_id is distinct from old.project_id then raise exception 'Original route identity/project cannot be rebound';end if;return new;end$$;
revoke all on function portal_private.protect_project_route_identity() from public,anon,authenticated,service_role;
create trigger crm_project_route_identity before update on portal_private.crm_project_routes for each row execute function portal_private.protect_project_route_identity();
create function public.project_route_context(p_project uuid default null,p_route uuid default null) returns jsonb language plpgsql stable security definer set search_path='' as $$declare c jsonb;begin
 c:=public.project_criteria_context(p_project);
 if p_project is null then if p_route is not null then raise exception 'Actual route project required';end if;return jsonb_build_object('projects',c->'projects');end if;
 if p_route is not null and not exists(select 1 from portal_private.crm_project_routes where id=p_route and project_id=p_project) then raise exception 'Actual route in selected project required';end if;
 return jsonb_build_object('project',c->'project','routes',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'code',r.code,'revision',r.revision,'state',v.state) order by r.code,r.id) from portal_private.crm_project_routes r join portal_private.crm_project_route_versions v on v.route_id=r.id and v.revision=r.revision where r.project_id=p_project),'[]'),'versions',coalesce((select jsonb_agg(to_jsonb(v)-'payload' order by revision desc) from portal_private.crm_project_route_versions v where route_id=p_route),'[]'));
end$$;
create function public.save_project_route(p_request uuid,p_project uuid,p_route uuid,p_version integer,p_source jsonb,p_details jsonb,p_state text,p_reason text,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$declare r portal_private.crm_project_routes;v portal_private.crm_project_route_versions;receipt portal_private.crm_project_route_versions;details jsonb:='{}';field text;value text;payload jsonb;project_status text;begin
 perform 1 from public.profiles where id=auth.uid() and active and role in ('admin','team') for share;if not found then raise exception 'Current route authority required';end if;
 perform 1 from public.crm_memberships where user_id=auth.uid() order by role_id,team_id for share;perform 1 from public.crm_roles order by id for share;perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id=auth.uid()) order by id for share;
 if p_request is null or p_project is null or p_route is null then raise exception 'Actual route project and request required';end if;
 perform pg_advisory_xact_lock(hashtextextended('project-route:'||p_request,0));select status into project_status from public.projects where id=p_project for update;
 if not found or not portal_private.project_criteria_access(p_project) then raise exception 'Current actual Admin or assigned PM required after waiting';end if;
 payload:=jsonb_build_object('project',p_project,'route',p_route,'version',p_version,'source',p_source,'details',p_details,'state',p_state,'reason',p_reason,'confirmed',p_confirm);
 select * into receipt from portal_private.crm_project_route_versions where id=p_request;
 if found then if receipt.actor_id<>auth.uid() or receipt.payload is distinct from payload then raise exception 'Route retry meaning changed';end if;return receipt.id;end if;
 if project_status='Completed' then raise exception 'Completed project routes remain historical';end if;
 if p_confirm is distinct from true or p_state is null or p_state not in ('Active','Archived') or length(trim(coalesce(p_reason,''))) not between 3 and 1000 or jsonb_typeof(p_details) is distinct from 'object' then raise exception 'Actual route details state reason and confirmation required';end if;
 if exists(select 1 from jsonb_object_keys(p_details) k where k not in ('code','floor','start','end','containment','specification','length','unit','notes')) then raise exception 'Unrecognized route field';end if;
 foreach field in array array['code','floor','start','end','containment','specification','length','unit','notes'] loop
 if jsonb_typeof(p_details->field) is distinct from 'string' then raise exception 'Explicit text route fields required, including blank unknown values';end if;
 value:=trim(p_details->>field);if length(value)>(case when field='code' then 80 when field='unit' then 40 when field='notes' then 2000 else 300 end) then raise exception 'Route field exceeds technical limit';end if;
 details:=details||jsonb_build_object(field,value);end loop;
 if details->>'code'='' then raise exception 'Actual route code required';end if;
 if (details->>'length'='')<>(details->>'unit'='') or (details->>'length'<>'' and details->>'length'!~'^(0|[1-9][0-9]{0,11})(\.[0-9]{1,4})?$') then raise exception 'Optional actual length needs an explicit unit and lossless decimal text (12 integer/4 fractional digits)';end if;
 select * into r from portal_private.crm_project_routes where id=p_route for update;
 if found then
 if r.project_id<>p_project then raise exception 'Route cannot be rebound to another project';end if;
 select * into v from portal_private.crm_project_route_versions where route_id=r.id and revision=r.revision;
 if p_version is distinct from r.revision or p_source is distinct from to_jsonb(v)-'payload' then raise exception 'Route source/revision changed; refresh';end if;
 else if p_version is not null or p_source is not null or p_state<>'Active' then raise exception 'New route requires blank source and explicit Active state';end if;end if;
 if exists(select 1 from portal_private.crm_project_routes where project_id=p_project and id<>p_route and lower(code)=lower(details->>'code')) then raise exception 'Route code already retained in this project';end if;
 if r.id is null then insert into portal_private.crm_project_routes values(p_route,p_project,1,details->>'code');else update portal_private.crm_project_routes set revision=revision+1,code=details->>'code' where id=p_route;end if;
 insert into portal_private.crm_project_route_versions(id,route_id,revision,details,state,reason,actor_id,payload) values(p_request,p_route,coalesce(r.revision,0)+1,details,p_state,trim(p_reason),auth.uid(),payload);return p_request;
end$$;
revoke all on function public.project_route_context(uuid,uuid),public.save_project_route(uuid,uuid,uuid,integer,jsonb,jsonb,text,text,boolean) from public,anon,service_role;
grant execute on function public.project_route_context(uuid,uuid),public.save_project_route(uuid,uuid,uuid,integer,jsonb,jsonb,text,text,boolean) to authenticated;
