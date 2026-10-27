-- APPLIED via native connected migration 20261027194153. Explicit criteria-definition review, not project/client acceptance.
create table portal_private.crm_project_criteria_reviews(id uuid primary key,project_id uuid not null references public.projects,definition_id uuid not null references portal_private.crm_project_criteria_versions,sequence integer not null,previous_id uuid references portal_private.crm_project_criteria_reviews,decision text not null check(decision in ('Approved','Changes requested','Withdrawn')),definition jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),payload jsonb not null,unique(definition_id,sequence));
create index crm_project_criteria_review_project on portal_private.crm_project_criteria_reviews(project_id);
create index crm_project_criteria_review_actor on portal_private.crm_project_criteria_reviews(actor_id);
create index crm_project_criteria_review_previous on portal_private.crm_project_criteria_reviews(previous_id);
alter table portal_private.crm_project_criteria_reviews enable row level security;
revoke all on portal_private.crm_project_criteria_reviews from public,anon,authenticated;
create trigger crm_project_criteria_review_immutable before update or delete on portal_private.crm_project_criteria_reviews for each row execute function portal_private.lead_api_evidence_immutable();
create function public.project_criteria_review_context(p_project uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare basis jsonb;current_definition uuid;begin
 if p_project is null then raise exception 'Actual project required';end if;
 basis:=public.project_criteria_context(p_project);current_definition:=(basis->'versions'->0->>'id')::uuid;
 return basis||jsonb_build_object('reviews',coalesce((select jsonb_agg(jsonb_build_object('id',id,'definition_id',definition_id,'sequence',sequence,'previous_id',previous_id,'decision',decision,'definition',r.definition,'reason',reason,'actor_id',actor_id,'created_at',created_at) order by created_at desc,sequence desc,id) from portal_private.crm_project_criteria_reviews r where project_id=p_project),'[]'),'current_review',(select jsonb_build_object('id',id,'decision',decision,'sequence',sequence,'reason',reason,'actor_id',actor_id,'created_at',created_at) from portal_private.crm_project_criteria_reviews where definition_id=current_definition order by sequence desc limit 1));
end$$;
create function public.review_project_criteria(p_request uuid,p_project uuid,p_definition uuid,p_previous uuid,p_source jsonb,p_decision text,p_reason text,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$
declare previous portal_private.crm_project_criteria_reviews;receipt portal_private.crm_project_criteria_reviews;v portal_private.crm_project_criteria_versions;source jsonb;payload jsonb;project_status text;begin
 perform 1 from public.profiles where id=auth.uid() and active and role in ('admin','team') for share;if not found then raise exception 'Current criteria review authority required';end if;
 perform 1 from public.crm_memberships where user_id=auth.uid() order by role_id,team_id for share;perform 1 from public.crm_roles order by id for share;perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id=auth.uid()) order by id for share;
 if p_request is null or p_project is null or p_definition is null then raise exception 'Actual project, definition and request identity required';end if;
 perform pg_advisory_xact_lock(hashtext('criteria-review:'||p_request));
 select status into project_status from public.projects where id=p_project for update;
 if not found or not portal_private.project_criteria_access(p_project) then raise exception 'Current Admin or assigned PM required after waiting';end if;
 payload:=jsonb_build_object('project',p_project,'definition',p_definition,'previous',p_previous,'source',p_source,'decision',p_decision,'reason',p_reason,'confirmed',p_confirm);
 select * into receipt from portal_private.crm_project_criteria_reviews where id=p_request;
 if found then if receipt.actor_id<>auth.uid() or receipt.payload is distinct from payload then raise exception 'Review retry meaning changed';end if;return receipt.id;end if;
 if project_status='Completed' then raise exception 'Closed project review remains historical';end if;
 if p_confirm is distinct from true or p_decision is null or p_decision not in ('Approved','Changes requested','Withdrawn') or length(trim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'Explicit review decision, reason and confirmation required';end if;
 select d.* into v from portal_private.crm_project_criteria_versions d join portal_private.crm_project_criteria c on c.project_id=d.project_id and c.revision=d.revision where d.id=p_definition and d.project_id=p_project;
 if not found then raise exception 'Criteria definition changed; refresh current source';end if;
 source:=jsonb_build_object('id',v.id,'revision',v.revision,'criteria',v.criteria,'reason',v.reason,'actor_id',v.actor_id,'created_at',v.created_at);
 if source is distinct from p_source then raise exception 'Exact reviewed criteria source changed';end if;
 select * into previous from portal_private.crm_project_criteria_reviews where definition_id=v.id order by sequence desc limit 1;
 if p_previous is distinct from previous.id then raise exception 'Review decision changed; refresh current review';end if;
 if p_decision='Withdrawn' and previous.decision is distinct from 'Approved' then raise exception 'Only current approval can be withdrawn';end if;
 insert into portal_private.crm_project_criteria_reviews(id,project_id,definition_id,sequence,previous_id,decision,definition,reason,actor_id,payload) values(p_request,p_project,v.id,coalesce(previous.sequence,0)+1,previous.id,p_decision,source,trim(p_reason),auth.uid(),payload);
 return p_request;
end$$;
revoke all on function public.project_criteria_review_context(uuid),public.review_project_criteria(uuid,uuid,uuid,uuid,jsonb,text,text,boolean) from public,anon;
grant execute on function public.project_criteria_review_context(uuid),public.review_project_criteria(uuid,uuid,uuid,uuid,jsonb,text,text,boolean) to authenticated;
