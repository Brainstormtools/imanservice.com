begin;
create table public.crm_survey_import_reviews(
 id uuid primary key,batch_id uuid not null references public.crm_survey_import_batches,project_id uuid not null references public.projects,
 batch_version integer not null,sequence integer not null,action text not null check(action in ('Reviewed','Returned')),
 snapshot jsonb not null,request jsonb not null,reason text not null,actor_id uuid not null references public.profiles,
 created_at timestamptz not null default now(),unique(batch_id,sequence)
);
create index survey_import_review_project on public.crm_survey_import_reviews(project_id);
create index survey_import_review_actor on public.crm_survey_import_reviews(actor_id);
alter table public.crm_survey_import_reviews enable row level security;
revoke all on public.crm_survey_import_reviews from public,anon,authenticated;
grant select on public.crm_survey_import_reviews to authenticated;
create policy survey_import_review_read on public.crm_survey_import_reviews for select to authenticated using(portal_private.execution_manager(project_id));
create function public.review_project_survey_batch(p_id uuid,p_batch uuid,p_version integer,p_action text,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare d public.crm_survey_import_batches;retry public.crm_survey_import_reviews;prior public.crm_survey_import_reviews;req jsonb;next_sequence integer;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator required to review survey batches';end if;
 select * into d from public.crm_survey_import_batches where id=p_batch;
 if d.id is null then raise exception 'Existing staged survey batch required';end if;
 perform 1 from public.projects where id=d.project_id for update;
 select * into d from public.crm_survey_import_batches where id=p_batch for update;
 if p_id is null or p_version is null or p_action is null or p_action not in ('Reviewed','Returned') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit identity/version/action/manual reason required';end if;
 req:=jsonb_build_object('batch_id',p_batch,'version',p_version,'action',p_action,'reason',trim(p_reason));
 select * into retry from public.crm_survey_import_reviews where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=req then return retry.id;end if;
  raise exception 'Decision identity records a different request';
 end if;
 if d.version is distinct from p_version then raise exception 'Survey batch changed; refresh version';end if;
 -- Match the existing survey review method/evidence minimums; never invent either value.
 if p_action='Reviewed' and exists(select 1 from jsonb_array_elements(d.rows) item where length(trim(coalesce(item->'details'->>'method','')))<3 or length(trim(coalesce(item->'details'->>'evidence','')))<3) then raise exception 'Every reviewed survey row requires actual method and evidence';end if;
 select * into prior from public.crm_survey_import_reviews where batch_id=d.id and batch_version=d.version order by sequence desc limit 1;
 if prior.action=p_action then raise exception 'This batch version already has that review state';end if;
 select coalesce(max(sequence),0)+1 into next_sequence from public.crm_survey_import_reviews where batch_id=d.id;
 insert into public.crm_survey_import_reviews(id,batch_id,project_id,batch_version,sequence,action,snapshot,request,reason,actor_id)
 values(p_id,d.id,d.project_id,d.version,next_sequence,p_action,to_jsonb(d),req,trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.review_project_survey_batch(uuid,uuid,integer,text,text) from public,anon;
grant execute on function public.review_project_survey_batch(uuid,uuid,integer,text,text) to authenticated;
notify pgrst,'reload schema';
commit;
