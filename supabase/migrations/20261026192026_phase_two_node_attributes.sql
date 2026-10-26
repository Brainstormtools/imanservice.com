-- UNAPPLIED local UTC scaffold; CLI unavailable. Manual device metadata, not inventory or execution.
create table portal_private.crm_node_attribute_history(id uuid primary key,project_id uuid not null references public.projects,node_id uuid not null references public.crm_nodes,revision integer not null,previous_id uuid references portal_private.crm_node_attribute_history,node_source jsonb not null,attributes jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),payload jsonb not null,unique(node_id,revision));
create index crm_node_attribute_history_project on portal_private.crm_node_attribute_history(project_id);
create index crm_node_attribute_history_previous on portal_private.crm_node_attribute_history(previous_id);
create index crm_node_attribute_history_actor on portal_private.crm_node_attribute_history(actor_id);
alter table portal_private.crm_node_attribute_history enable row level security;
revoke all on portal_private.crm_node_attribute_history from public,anon,authenticated,service_role;
create trigger crm_node_attribute_history_immutable before update or delete on portal_private.crm_node_attribute_history for each row execute function portal_private.lead_api_evidence_immutable();
create function public.node_attributes_context(p_project uuid default null,p_node uuid default null) returns jsonb language plpgsql stable security definer set search_path='' as $$declare c jsonb;h portal_private.crm_node_attribute_history;begin
 c:=public.project_node_route_context(p_project,p_node);
 if p_project is null then return c;end if;
 select * into h from portal_private.crm_node_attribute_history where node_id=p_node and project_id=p_project order by revision desc limit 1;
 return (c-'routes'-'history'-'current_link'-'matches_current_sources')||jsonb_build_object('current_attributes',case when h.id is not null then to_jsonb(h)-'payload' else null end,'attributes_current',coalesce(h.node_source=c->'node',false),'history',coalesce((select jsonb_agg(to_jsonb(x)-'payload' order by revision desc) from portal_private.crm_node_attribute_history x where node_id=p_node and project_id=p_project),'[]'));
end$$;
create function public.save_node_attributes(p_request uuid,p_project uuid,p_node uuid,p_previous uuid,p_node_source jsonb,p_previous_source jsonb,p_attributes jsonb,p_reason text,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$declare n public.crm_nodes;previous portal_private.crm_node_attribute_history;receipt portal_private.crm_node_attribute_history;payload jsonb;attributes jsonb:='[]';item jsonb;normalized jsonb;field text;value text;project_status text;begin
 perform 1 from public.profiles where id=auth.uid() and active and role in ('admin','team') for share;if not found then raise exception 'Current device metadata authority required';end if;
 perform 1 from public.crm_memberships where user_id=auth.uid() order by role_id,team_id for share;perform 1 from public.crm_roles order by id for share;perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id=auth.uid()) order by id for share;
 if p_request is null or p_project is null or p_node is null then raise exception 'Actual project node and request required';end if;
 perform pg_advisory_xact_lock(hashtextextended('node-attributes:'||p_request,0));select status into project_status from public.projects where id=p_project for update;
 if not found or not portal_private.project_criteria_access(p_project) then raise exception 'Current actual Admin or assigned PM required after waiting';end if;
 select * into n from public.crm_nodes where id=p_node and project_id=p_project for share;if not found then raise exception 'Actual node must belong to selected project';end if;
 payload:=jsonb_build_object('project',p_project,'node',p_node,'previous',p_previous,'node_source',p_node_source,'previous_source',p_previous_source,'attributes',p_attributes,'reason',p_reason,'confirmed',p_confirm);
 select * into receipt from portal_private.crm_node_attribute_history where id=p_request;
 if found then if receipt.actor_id<>auth.uid() or receipt.payload is distinct from payload then raise exception 'Device metadata retry meaning changed';end if;return receipt.id;end if;
 if project_status='Completed' or exists(select 1 from public.crm_phases where project_id=p_project and status<>'Draft') or exists(select 1 from public.crm_handovers where project_id=p_project and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Phase review, completed project or released handover keeps device metadata read-only';end if;
 if p_confirm is distinct from true or length(trim(coalesce(p_reason,''))) not between 3 and 1000 or p_node_source is distinct from to_jsonb(n) or jsonb_typeof(p_attributes) is distinct from 'array' then raise exception 'Exact current node, actual attribute list, reason and confirmation required';end if;
 if jsonb_array_length(p_attributes)>50 then raise exception 'Technical limit of 50 device attributes';end if;
 for item in select v from jsonb_array_elements(p_attributes) v loop
 if jsonb_typeof(item) is distinct from 'object' then raise exception 'Explicit named attribute object required';end if;
 if exists(select 1 from jsonb_object_keys(item) k where k not in ('name','value','unit')) then raise exception 'Unrecognized device attribute field';end if;
 normalized:='{}';foreach field in array array['name','value','unit'] loop
 if jsonb_typeof(item->field) is distinct from 'string' then raise exception 'Actual attribute name/value/unit must remain text';end if;
 value:=trim(item->>field);if length(value)>(case when field='name' then 100 when field='unit' then 40 else 2000 end) or field in ('name','value') and value='' then raise exception 'Actual name/value required within technical text bounds';end if;
 normalized:=normalized||jsonb_build_object(field,value);end loop;
 if exists(select 1 from jsonb_array_elements(attributes) a where lower(a->>'name')=lower(normalized->>'name')) then raise exception 'Attribute names must be unique within this device revision';end if;
 attributes:=attributes||jsonb_build_array(normalized);end loop;
 select * into previous from portal_private.crm_node_attribute_history where node_id=p_node order by revision desc limit 1;
 if p_previous is distinct from previous.id or p_previous_source is distinct from (case when previous.id is not null then to_jsonb(previous)-'payload' else null end) or previous.project_id is not null and previous.project_id<>p_project then raise exception 'Previous device metadata/project changed; refresh latest source';end if;
 insert into portal_private.crm_node_attribute_history(id,project_id,node_id,revision,previous_id,node_source,attributes,reason,actor_id,payload) values(p_request,p_project,p_node,coalesce(previous.revision,0)+1,previous.id,to_jsonb(n),attributes,trim(p_reason),auth.uid(),payload);return p_request;
end$$;
revoke all on function public.node_attributes_context(uuid,uuid),public.save_node_attributes(uuid,uuid,uuid,uuid,jsonb,jsonb,jsonb,text,boolean) from public,anon,service_role;
grant execute on function public.node_attributes_context(uuid,uuid),public.save_node_attributes(uuid,uuid,uuid,uuid,jsonb,jsonb,jsonb,text,boolean) to authenticated;
