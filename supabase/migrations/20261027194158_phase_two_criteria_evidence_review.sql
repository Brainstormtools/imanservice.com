-- APPLIED via native connected migration 20261027194158 local UTC scaffold; CLI unavailable. Evidence review is not work/client acceptance.
create table portal_private.crm_criteria_evidence_reviews(id uuid primary key,observation_id uuid not null references portal_private.crm_criteria_observations,sequence integer not null,previous_id uuid references portal_private.crm_criteria_evidence_reviews,decision text not null check(decision in ('Approved','Changes requested','Withdrawn')),file_ids uuid[] not null,source jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),payload jsonb not null,unique(observation_id,sequence));
create index crm_criteria_evidence_reviews_actor on portal_private.crm_criteria_evidence_reviews(actor_id);
create index crm_criteria_evidence_reviews_previous on portal_private.crm_criteria_evidence_reviews(previous_id);
alter table portal_private.crm_criteria_evidence_reviews enable row level security;
revoke all on portal_private.crm_criteria_evidence_reviews from public,anon,authenticated,service_role;
create trigger crm_criteria_evidence_reviews_immutable before update or delete on portal_private.crm_criteria_evidence_reviews for each row execute function portal_private.lead_api_evidence_immutable();
create function portal_private.criteria_evidence_basis(p_observation uuid,p_files uuid[]) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('observation',(select to_jsonb(o)-'payload' from portal_private.crm_criteria_observations o where id=p_observation),'files',coalesce((select jsonb_agg((to_jsonb(f)-'payload')||jsonb_build_object('stored_metadata_matches',s.id is not null and s.owner_id=f.actor_id::text and s.metadata->>'size'=f.size::text and s.metadata->>'mimetype'=f.mime) order by f.id) from portal_private.crm_criteria_files f left join storage.objects s on s.bucket_id='crm-criteria-files' and s.name=f.path where f.observation_id=p_observation and f.id=any(p_files)),'[]'));
$$;
revoke all on function portal_private.criteria_evidence_basis(uuid,uuid[]) from public,anon,authenticated,service_role;
create function public.criteria_evidence_review_context(p_observation uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$declare c jsonb;r portal_private.crm_criteria_evidence_reviews;begin
 c:=public.criteria_file_context(p_observation);
 select * into r from portal_private.crm_criteria_evidence_reviews where observation_id=p_observation order by sequence desc limit 1;
 return c||jsonb_build_object('reviews',coalesce((select jsonb_agg(to_jsonb(x)-'payload' order by sequence desc) from portal_private.crm_criteria_evidence_reviews x where observation_id=p_observation),'[]'),'current_review',case when r.id is not null then to_jsonb(r)-'payload' else null end,'approval_current',coalesce(r.decision='Approved' and (c->>'can_attach')::boolean and r.source=portal_private.criteria_evidence_basis(p_observation,r.file_ids) and not exists(select 1 from jsonb_array_elements(r.source->'files') f where (f->>'stored_metadata_matches')::boolean is distinct from true),false));
end$$;
create function public.review_criteria_evidence(p_request uuid,p_observation uuid,p_previous uuid,p_files uuid[],p_source jsonb,p_decision text,p_reason text,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$declare o portal_private.crm_criteria_observations;previous portal_private.crm_criteria_evidence_reviews;receipt portal_private.crm_criteria_evidence_reviews;source jsonb;payload jsonb;selected_ids uuid[];begin
 perform 1 from public.profiles where id=auth.uid() and active and role in ('admin','team') for share;if not found then raise exception 'Current evidence review authority required';end if;
 perform 1 from public.crm_memberships where user_id=auth.uid() order by role_id,team_id for share;perform 1 from public.crm_roles order by id for share;perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id=auth.uid()) order by id for share;
 if p_request is null or p_observation is null then raise exception 'Actual observation and request required';end if;
 perform pg_advisory_xact_lock(hashtextextended('criteria-evidence-review:'||p_request,0));select * into o from portal_private.crm_criteria_observations where id=p_observation;
 if not found then raise exception 'Actual observation required';end if;perform 1 from public.projects where id=o.project_id for update;
 if not portal_private.project_criteria_access(o.project_id) then raise exception 'Current actual Admin or assigned PM required after waiting';end if;
 if p_files is null or coalesce(array_ndims(p_files),1)<>1 or cardinality(p_files)>20 or cardinality(p_files)<>(select count(distinct id) from unnest(p_files) id) then raise exception 'Explicit unique selected file identities required';end if;
 select coalesce(array_agg(id order by id),'{}') into selected_ids from unnest(p_files) id;
 payload:=jsonb_build_object('observation',p_observation,'previous',p_previous,'files',selected_ids,'source',p_source,'decision',p_decision,'reason',p_reason,'confirmed',p_confirm);
 select * into receipt from portal_private.crm_criteria_evidence_reviews where id=p_request;
 if found then if receipt.actor_id<>auth.uid() or receipt.payload is distinct from payload then raise exception 'Evidence review retry meaning changed';end if;return receipt.id;end if;
 if not portal_private.criteria_file_current(p_observation) then raise exception 'Current approved criteria and latest observation required; historical evidence is read-only';end if;
 if p_confirm is distinct from true or p_decision is null or p_decision not in ('Approved','Changes requested','Withdrawn') or length(trim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'Explicit evidence decision reason and confirmation required';end if;
 if cardinality(selected_ids)<>(select count(*) from portal_private.crm_criteria_files where observation_id=p_observation and id=any(selected_ids)) then raise exception 'Selected files must belong to this exact observation';end if;
 perform 1 from storage.objects where bucket_id='crm-criteria-files' and name in(select path from portal_private.crm_criteria_files where id=any(selected_ids)) order by name for share;
 source:=portal_private.criteria_evidence_basis(p_observation,selected_ids);
 if p_source is distinct from source then raise exception 'Exact observation or selected evidence source changed; refresh';end if;
 if p_decision='Approved' and exists(select 1 from jsonb_array_elements(source->'files') f where (f->>'stored_metadata_matches')::boolean is distinct from true) then raise exception 'Selected stored evidence metadata must match before approval';end if;
 select * into previous from portal_private.crm_criteria_evidence_reviews where observation_id=p_observation order by sequence desc limit 1;
 if p_previous is distinct from previous.id then raise exception 'Evidence review changed; refresh latest decision';end if;
 if p_decision='Withdrawn' and (previous.decision is distinct from 'Approved' or selected_ids is distinct from previous.file_ids) then raise exception 'Withdrawal must target current approval and its exact file selection';end if;
 insert into portal_private.crm_criteria_evidence_reviews(id,observation_id,sequence,previous_id,decision,file_ids,source,reason,actor_id,payload) values(p_request,p_observation,coalesce(previous.sequence,0)+1,previous.id,p_decision,selected_ids,source,trim(p_reason),auth.uid(),payload);return p_request;
end$$;
revoke all on function public.criteria_evidence_review_context(uuid),public.review_criteria_evidence(uuid,uuid,uuid,uuid[],jsonb,text,text,boolean) from public,anon,service_role;
grant execute on function public.criteria_evidence_review_context(uuid),public.review_criteria_evidence(uuid,uuid,uuid,uuid[],jsonb,text,text,boolean) to authenticated;
