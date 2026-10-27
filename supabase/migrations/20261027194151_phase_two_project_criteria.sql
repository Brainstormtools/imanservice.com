-- APPLIED via native connected migration 20261027194151. Manual project-specific criteria definitions, not acceptance decisions.
create table portal_private.crm_project_criteria(project_id uuid primary key references public.projects,revision integer not null check(revision>0));
create table portal_private.crm_project_criteria_versions(id uuid primary key,project_id uuid not null references public.projects,revision integer not null,criteria jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),payload jsonb not null,unique(project_id,revision));
create index crm_project_criteria_actor on portal_private.crm_project_criteria_versions(actor_id);
alter table portal_private.crm_project_criteria enable row level security;
alter table portal_private.crm_project_criteria_versions enable row level security;
revoke all on portal_private.crm_project_criteria,portal_private.crm_project_criteria_versions from public,anon,authenticated;
create trigger crm_project_criteria_immutable before update or delete on portal_private.crm_project_criteria_versions for each row execute function portal_private.lead_api_evidence_immutable();
create function portal_private.project_criteria_access(p_project uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles u join public.projects p on p.id=p_project where u.id=auth.uid() and u.active and (u.role='admin' or (u.role='team' and p.manager_id=u.id and portal_private.crm_user_permission(u.id,'project.own'))));
$$;
revoke all on function portal_private.project_criteria_access(uuid) from public,anon,authenticated;
create function public.project_criteria_context(p_project uuid default null) returns jsonb language plpgsql stable security definer set search_path='' as $$begin
 if not exists(select 1 from public.profiles where id=auth.uid() and active and (role='admin' or role='team' and portal_private.crm_user_permission(id,'project.own'))) then raise exception 'Current project criteria authority required';end if;
 if p_project is null then return jsonb_build_object('projects',coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'title',p.title,'status',p.status) order by p.title,p.id) from public.projects p where portal_private.project_criteria_access(p.id)),'[]'));end if;
 if not portal_private.project_criteria_access(p_project) then raise exception 'Current Admin or assigned project manager required';end if;
 return jsonb_build_object('project',(select jsonb_build_object('id',id,'title',title,'status',status) from public.projects where id=p_project),'revision',coalesce((select revision from portal_private.crm_project_criteria where project_id=p_project),0),'versions',coalesce((select jsonb_agg(jsonb_build_object('id',id,'revision',revision,'criteria',criteria,'reason',reason,'actor_id',actor_id,'created_at',created_at) order by revision desc) from portal_private.crm_project_criteria_versions where project_id=p_project),'[]'));
end$$;
create function public.save_project_criteria(p_request uuid,p_project uuid,p_version integer,p_criteria jsonb,p_reason text,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$
declare previous portal_private.crm_project_criteria_versions;current_revision integer;payload jsonb;item jsonb;field text;project_status text;begin
 perform 1 from public.profiles where id=auth.uid() and active and role in ('admin','team') for share;if not found then raise exception 'Current project criteria authority required';end if;
 perform 1 from public.crm_memberships where user_id=auth.uid() order by role_id,team_id for share;perform 1 from public.crm_roles order by id for share;perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id=auth.uid()) order by id for share;
 if p_request is null or p_project is null then raise exception 'Actual project and request identity required';end if;
 perform pg_advisory_xact_lock(hashtext('project-criteria:'||p_request));
 select status into project_status from public.projects where id=p_project for update;
 if not found or not portal_private.project_criteria_access(p_project) then raise exception 'Current Admin or assigned project manager required after waiting';end if;
 payload:=jsonb_build_object('project',p_project,'version',p_version,'criteria',p_criteria,'reason',p_reason,'confirmed',p_confirm);
 select * into previous from portal_private.crm_project_criteria_versions where id=p_request;
 if found then if previous.actor_id<>auth.uid() or previous.payload is distinct from payload then raise exception 'Criteria retry meaning changed';end if;return previous.id;end if;
 if project_status='Completed' then raise exception 'Closed project criteria remain historical; no retrospective revision';end if;
 if p_confirm is distinct from true or length(trim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'Actual reason and explicit criteria review required';end if;
 if jsonb_typeof(p_criteria) is distinct from 'array' or jsonb_array_length(p_criteria) not between 1 and 100 then raise exception 'One to 100 actual criteria required';end if;
 for item in select value from jsonb_array_elements(p_criteria) loop
  if jsonb_typeof(item) is distinct from 'object' or (select count(*) from jsonb_object_keys(item))<>3 then raise exception 'Criterion, expected result and verification method required';end if;
  foreach field in array array['statement','expected','verification'] loop
   if jsonb_typeof(item->field) is distinct from 'string' or length(trim(item->>field)) not between 1 and 2000 then raise exception 'Each criteria field needs actual bounded text';end if;
  end loop;
 end loop;
 select revision into current_revision from portal_private.crm_project_criteria where project_id=p_project for update;
 if p_version is distinct from current_revision then raise exception 'Criteria definition changed; refresh current revision';end if;
 current_revision:=coalesce(current_revision,0)+1;
 insert into portal_private.crm_project_criteria(project_id,revision) values(p_project,current_revision) on conflict(project_id) do update set revision=excluded.revision;
 insert into portal_private.crm_project_criteria_versions(id,project_id,revision,criteria,reason,actor_id,payload) values(p_request,p_project,current_revision,p_criteria,trim(p_reason),auth.uid(),payload);
 return p_request;
end$$;
revoke all on function public.project_criteria_context(uuid),public.save_project_criteria(uuid,uuid,integer,jsonb,text,boolean) from public,anon;
grant execute on function public.project_criteria_context(uuid),public.save_project_criteria(uuid,uuid,integer,jsonb,text,boolean) to authenticated;
