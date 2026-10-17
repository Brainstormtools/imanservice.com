begin;
alter table public.crm_client_charter_publications add column client_terms jsonb,add column publication_sequence integer;
with ordered as (select id,row_number() over(partition by project_id order by published_at,id)::integer n from public.crm_client_charter_publications) update public.crm_client_charter_publications p set publication_sequence=o.n from ordered o where p.id=o.id;
alter table public.crm_client_charter_publications alter column publication_sequence set not null,add unique(project_id,publication_sequence);
-- Historical publications stay unchanged: missing new fields are never invented or backfilled.
create function portal_private.charter_client_wording(input jsonb) returns jsonb language plpgsql immutable set search_path='' as $$
declare k text;d jsonb:='{}';
begin
 if jsonb_typeof(input) is distinct from 'object' or (select count(*) from jsonb_object_keys(input))<>13 or (input-array['title','objectives','scope','deliverables','communication','product_lines','milestones_dates','contract_value','payment_milestones','responsibilities','document_kind','supersedes_publication_id','change_summary'])<>'{}'::jsonb then raise exception 'Exact expanded manual client charter fields required';end if;
 foreach k in array array['title','objectives','scope','deliverables','communication','product_lines','milestones_dates','contract_value','payment_milestones','responsibilities','document_kind','supersedes_publication_id','change_summary'] loop
  if jsonb_typeof(input->k) is distinct from 'string' or length(trim(input->>k))>(case when k='title' then 160 else 4000 end) then raise exception 'Bounded manual client wording required';end if;
  d:=d||jsonb_build_object(k,trim(input->>k));
 end loop;
 foreach k in array array['title','objectives','scope','deliverables','communication','product_lines','milestones_dates','contract_value','payment_milestones','responsibilities'] loop
  if length(d->>k)<3 then raise exception 'Every actual client-facing approval field is required';end if;
 end loop;
 if d->>'document_kind'='Original' then
  if d->>'supersedes_publication_id'<>'' or d->>'change_summary'<>'' then raise exception 'Original has no predecessor or change summary';end if;
 elsif d->>'document_kind'='Change order' then
  if length(d->>'change_summary')<3 or (d->>'supersedes_publication_id')!~'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then raise exception 'Change order requires actual predecessor and change summary';end if;
 else raise exception 'Explicit Original or Change order required';end if;
 return d;
end$$;
revoke all on function portal_private.charter_client_wording(jsonb) from public,anon,authenticated;
create or replace function public.save_client_charter_draft(p_id uuid,p_version integer,p_project uuid,p_charter uuid,p_charter_version integer,p_details jsonb,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare c public.crm_project_charters;old public.crm_client_charter_drafts;saved public.crm_client_charter_drafts;d jsonb:='{}';k text;req jsonb;
begin
 if auth.uid() is null or not portal_private.execution_manager(p_project) then raise exception 'Active assigned project manager access required';end if;
 perform 1 from public.projects where id=p_project for update;if not found then raise exception 'Existing project required';end if;
 if p_id is null or p_charter is null or p_charter_version is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit identity/charter version/manual reason required';end if;
 d:=portal_private.charter_client_wording(p_details);
 req:=jsonb_build_object('version',p_version,'project_id',p_project,'charter_id',p_charter,'charter_version',p_charter_version,'details',d,'reason',trim(p_reason));
 select * into old from public.crm_client_charter_drafts where id=p_id for update;
 if old.id is not null then
  if old.project_id is distinct from p_project or old.charter_id is distinct from p_charter then raise exception 'Project and source charter cannot change';end if;
  if exists(select 1 from public.crm_client_charter_history h where h.plan_id=old.id and h.actor_id=auth.uid() and h.request=req and h.revision=coalesce(p_version,0)+1) then return old.id;end if;
  if p_version is null or old.version is distinct from p_version then raise exception 'Client charter copy changed; refresh version';end if;
 elsif p_version is not null then raise exception 'Unknown client charter copy cannot be revised';end if;
 select * into c from public.crm_project_charters where id=p_charter for share;
 if c.id is null or c.project_id is distinct from p_project or c.version is distinct from p_charter_version or c.details->>'status' is distinct from 'Reviewed' then raise exception 'Exact current Reviewed project charter required';end if;
 if old.id is null then
  insert into public.crm_client_charter_drafts(id,project_id,charter_id,charter_version,source_snapshot,details,reason,created_by)
  values(p_id,p_project,c.id,c.version,to_jsonb(c),d,trim(p_reason),auth.uid()) returning * into saved;
 else
  update public.crm_client_charter_drafts set charter_version=c.version,source_snapshot=to_jsonb(c),details=d,version=version+1,reason=trim(p_reason) where id=old.id returning * into saved;
 end if;
 insert into public.crm_client_charter_history(plan_id,project_id,revision,before_record,after_record,request,reason,actor_id)
 values(saved.id,saved.project_id,saved.version,case when old.id is null then null else to_jsonb(old) end,to_jsonb(saved),req,trim(p_reason),auth.uid());
 return saved.id;
end$$;
create or replace function public.publish_client_charter_copy(p_id uuid,p_copy uuid,p_version integer,p_review uuid,p_company uuid,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare d public.crm_client_charter_drafts;c public.crm_project_charters;p public.projects;r public.crm_client_charter_reviews;
 retry public.crm_client_charter_publication_history;saved public.crm_client_charter_publications;req jsonb;client_name text;terms jsonb;previous public.crm_client_charter_publications;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator publishes reviewed client charter copies';end if;
 select * into d from public.crm_client_charter_drafts where id=p_copy;
 select * into p from public.projects where id=d.project_id for update;
 if p.id is null then raise exception 'Existing project required';end if;
 select * into d from public.crm_client_charter_drafts where id=p_copy for update;
 if p_id is null or p_version is null or p_review is null or p_company is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit publication identity/version/review/destination/manual reason required';end if;
 req:=jsonb_build_object('copy_id',p_copy,'version',p_version,'review_id',p_review,'company_id',p_company,'reason',trim(p_reason));
 select * into retry from public.crm_client_charter_publication_history where id=p_id;
 if retry.id is not null then
  if retry.action='Published' and retry.actor_id=auth.uid() and retry.request=req then return retry.publication_id;end if;
  raise exception 'Publication identity records a different request';
 end if;
 if p.company_id is distinct from p_company then raise exception 'Project client changed; refresh destination';end if;
 select name into client_name from public.companies where id=p_company for share;
 if not found then raise exception 'Existing project client required';end if;
 select * into c from public.crm_project_charters where id=d.charter_id for share;
 select * into r from public.crm_client_charter_reviews where copy_id=d.id and copy_version=d.version order by sequence desc limit 1;
 if d.version is distinct from p_version or r.id is null or r.id is distinct from p_review or r.action is distinct from 'Reviewed' or r.snapshot is distinct from to_jsonb(d) or c.id is null or c.details->>'status' is distinct from 'Reviewed' or d.source_snapshot is distinct from to_jsonb(c) then raise exception 'Exact current Reviewed copy and unchanged Reviewed charter required';end if;
 if exists(select 1 from public.crm_client_charter_publications where copy_id=d.id and (copy_version=d.version or status='Published')) then raise exception 'Version already published or open publication requires explicit withdrawal';end if;
 terms:=portal_private.charter_client_wording(d.details);
 select * into previous from public.crm_client_charter_publications where project_id=d.project_id order by publication_sequence desc limit 1;
 if previous.id is null then
  if terms->>'document_kind'<>'Original' then raise exception 'First charter publication must be Original';end if;
 else
  if exists(select 1 from public.crm_client_charter_publications where project_id=d.project_id and status='Published') or previous.status<>'Withdrawn' or terms->>'document_kind'<>'Change order' or terms->>'supersedes_publication_id'<>previous.id::text then raise exception 'Withdraw prior project publication and explicitly reference its exact identity as a new change order';end if;
 end if;
 -- Only the five manually written client fields are exposed. Full source/review/request/reason/actor remain private.
 insert into public.crm_client_charter_publications(id,copy_id,project_id,company_id,copy_version,project_title,company_name,title,objectives,scope,deliverables,communication,client_terms,publication_sequence)
 values(p_id,d.id,d.project_id,p_company,d.version,p.title,client_name,d.details->>'title',d.details->>'objectives',d.details->>'scope',d.details->>'deliverables',d.details->>'communication',terms-array['title','objectives','scope','deliverables','communication'],coalesce(previous.publication_sequence,0)+1) returning * into saved;
 insert into public.crm_client_charter_publication_history(id,publication_id,copy_id,project_id,review_id,action,private_snapshot,after_record,request,reason,actor_id)
 values(p_id,saved.id,d.id,d.project_id,r.id,'Published',to_jsonb(r),to_jsonb(saved),req,trim(p_reason),auth.uid());
 return saved.id;
end$$;
drop policy client_charter_publication_read on public.crm_client_charter_publications;
create policy client_charter_publication_read on public.crm_client_charter_publications for select to authenticated using(portal_private.execution_manager(project_id) or exists(select 1 from public.profiles u join public.projects p on p.id=crm_client_charter_publications.project_id where u.id=auth.uid() and u.active and u.role='client' and u.company_id=crm_client_charter_publications.company_id and p.company_id=crm_client_charter_publications.company_id));
notify pgrst,'reload schema';
commit;
