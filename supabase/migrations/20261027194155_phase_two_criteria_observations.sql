-- APPLIED via native connected migration 20261027194155. Unreviewed internal observations and text references, not acceptance.
create table portal_private.crm_criteria_observations(id uuid primary key,project_id uuid not null references public.projects,definition_id uuid not null references portal_private.crm_project_criteria_versions,review_id uuid not null references portal_private.crm_project_criteria_reviews,position integer not null check(position between 1 and 100),sequence integer not null,previous_id uuid references portal_private.crm_criteria_observations,result text not null check(result in ('Pass','Fail','Not tested')),observed_on date not null,observer_id uuid not null references public.profiles,observer_name text not null,actual text not null,evidence_reference text not null,reason text not null,basis jsonb not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),payload jsonb not null,unique(definition_id,position,sequence));
create index crm_criteria_observations_project on portal_private.crm_criteria_observations(project_id);
create index crm_criteria_observations_review on portal_private.crm_criteria_observations(review_id);
create index crm_criteria_observations_observer on portal_private.crm_criteria_observations(observer_id);
create index crm_criteria_observations_actor on portal_private.crm_criteria_observations(actor_id);
create index crm_criteria_observations_previous on portal_private.crm_criteria_observations(previous_id);
alter table portal_private.crm_criteria_observations enable row level security;
revoke all on portal_private.crm_criteria_observations from public,anon,authenticated;
create trigger crm_criteria_observation_immutable before update or delete on portal_private.crm_criteria_observations for each row execute function portal_private.lead_api_evidence_immutable();
create function portal_private.criteria_observer_eligible(p_project uuid,p_user uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles u join public.projects p on p.id=p_project where u.id=p_user and u.active and u.role in ('admin','team') and (u.role='admin' or p.manager_id=u.id or exists(select 1 from public.project_assignments a where a.project_id=p.id and a.technician_id=u.id)));
$$;
revoke all on function portal_private.criteria_observer_eligible(uuid,uuid) from public,anon,authenticated;
create function public.criteria_observations_context(p_project uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare c jsonb;begin
 c:=public.project_criteria_review_context(p_project);
 return c||jsonb_build_object('basis',case when c->'current_review'->>'decision'='Approved' then jsonb_build_object('definition',c->'versions'->0,'review',c->'current_review') else null end,'observers',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name,id) from public.profiles where portal_private.criteria_observer_eligible(p_project,id)),'[]'),'observations',coalesce((select jsonb_agg(to_jsonb(o)-'payload' order by created_at desc,sequence desc,id) from portal_private.crm_criteria_observations o where project_id=p_project),'[]'));
end$$;
create function public.record_criteria_observation(p_request uuid,p_project uuid,p_definition uuid,p_review uuid,p_position integer,p_previous uuid,p_source jsonb,p_observer uuid,p_observed_on date,p_result text,p_actual text,p_evidence text,p_reason text,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$
declare receipt portal_private.crm_criteria_observations;previous portal_private.crm_criteria_observations;context jsonb;basis jsonb;payload jsonb;actual_observer_name text;project_status text;begin
 perform 1 from public.profiles where id=auth.uid() and active and role in ('admin','team') for share;if not found then raise exception 'Current criteria recording authority required';end if;
 perform 1 from public.crm_memberships where user_id=auth.uid() order by role_id,team_id for share;perform 1 from public.crm_roles order by id for share;perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id=auth.uid()) order by id for share;
 if p_request is null or p_project is null then raise exception 'Actual project and request identity required';end if;
 perform pg_advisory_xact_lock(hashtext('criteria-observation:'||p_request));select status into project_status from public.projects where id=p_project for update;
 if not found or not portal_private.project_criteria_access(p_project) then raise exception 'Current Admin or assigned PM required after waiting';end if;
 payload:=jsonb_build_object('project',p_project,'definition',p_definition,'review',p_review,'position',p_position,'previous',p_previous,'source',p_source,'observer',p_observer,'observed_on',p_observed_on,'result',p_result,'actual',p_actual,'evidence',p_evidence,'reason',p_reason,'confirmed',p_confirm);
 select * into receipt from portal_private.crm_criteria_observations where id=p_request;
 if found then if receipt.actor_id<>auth.uid() or receipt.payload is distinct from payload then raise exception 'Observation retry meaning changed';end if;return receipt.id;end if;
 if project_status='Completed' then raise exception 'Closed project observations remain historical';end if;
 context:=public.project_criteria_review_context(p_project);
 basis:=jsonb_build_object('definition',context->'versions'->0,'review',context->'current_review');
 if context->'current_review'->>'decision' is distinct from 'Approved' or p_definition is distinct from (basis->'definition'->>'id')::uuid or p_review is distinct from (basis->'review'->>'id')::uuid or p_source is distinct from basis then raise exception 'Current approved criteria source changed or approval withdrawn; refresh';end if;
 if p_position is null or p_position<1 or p_position>jsonb_array_length(basis->'definition'->'criteria') then raise exception 'Actual approved criterion position required';end if;
 if p_confirm is distinct from true or p_observed_on is null or not isfinite(p_observed_on) or p_result is null or p_result not in ('Pass','Fail','Not tested') or length(trim(coalesce(p_actual,''))) not between 3 and 4000 or length(trim(coalesce(p_evidence,''))) not between 3 and 4000 or length(trim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'Actual observation date, result, notes, evidence reference, reason and confirmation required';end if;
 select name into actual_observer_name from public.profiles where id=p_observer for share;
 if not found then raise exception 'Actual internal observer required';end if;
 perform 1 from public.project_assignments where project_id=p_project and technician_id=p_observer for share;
 if not portal_private.criteria_observer_eligible(p_project,p_observer) then raise exception 'Actual active internal project observer required';end if;
 select * into previous from portal_private.crm_criteria_observations where definition_id=p_definition and position=p_position order by sequence desc limit 1;
 if p_previous is distinct from previous.id then raise exception 'Criterion observation changed; refresh latest record';end if;
 insert into portal_private.crm_criteria_observations(id,project_id,definition_id,review_id,position,sequence,previous_id,result,observed_on,observer_id,observer_name,actual,evidence_reference,reason,basis,actor_id,payload) values(p_request,p_project,p_definition,p_review,p_position,coalesce(previous.sequence,0)+1,previous.id,p_result,p_observed_on,p_observer,actual_observer_name,trim(p_actual),trim(p_evidence),trim(p_reason),basis,auth.uid(),payload);
 return p_request;
end$$;
revoke all on function public.criteria_observations_context(uuid),public.record_criteria_observation(uuid,uuid,uuid,uuid,integer,uuid,jsonb,uuid,date,text,text,text,text,boolean) from public,anon;
grant execute on function public.criteria_observations_context(uuid),public.record_criteria_observation(uuid,uuid,uuid,uuid,integer,uuid,jsonb,uuid,date,text,text,text,text,boolean) to authenticated;
