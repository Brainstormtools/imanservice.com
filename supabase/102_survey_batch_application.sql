begin;
create table public.crm_survey_import_applications(
 id uuid primary key,batch_id uuid not null references public.crm_survey_import_batches,project_id uuid not null references public.projects,
 batch_version integer not null,review_id uuid not null references public.crm_survey_import_reviews,
 snapshot jsonb not null,review_snapshot jsonb not null,request jsonb not null,reason text not null,
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(batch_id,batch_version)
);
create index survey_application_project on public.crm_survey_import_applications(project_id);
create index survey_application_review on public.crm_survey_import_applications(review_id);
create index survey_application_actor on public.crm_survey_import_applications(actor_id);
create table public.crm_survey_import_measurements(
 application_id uuid not null references public.crm_survey_import_applications,project_id uuid not null references public.projects,
 row_number integer not null check(row_number between 1 and 100),survey_id uuid not null unique references public.crm_project_surveys,
 survey_snapshot jsonb not null,primary key(application_id,row_number)
);
create index survey_application_row_project on public.crm_survey_import_measurements(project_id);
alter table public.crm_survey_import_applications enable row level security;
alter table public.crm_survey_import_measurements enable row level security;
revoke all on public.crm_survey_import_applications,public.crm_survey_import_measurements from public,anon,authenticated;
grant select on public.crm_survey_import_applications,public.crm_survey_import_measurements to authenticated;
create policy survey_application_read on public.crm_survey_import_applications for select to authenticated using(portal_private.execution_manager(project_id));
create policy survey_application_row_read on public.crm_survey_import_measurements for select to authenticated using(portal_private.execution_manager(project_id));
create function public.apply_project_survey_batch(p_id uuid,p_batch uuid,p_version integer,p_review uuid,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare d public.crm_survey_import_batches;r public.crm_survey_import_reviews;retry public.crm_survey_import_applications;
 req jsonb;item jsonb;ordinal bigint;measurement uuid;frozen jsonb;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator required to apply survey batches';end if;
 select * into d from public.crm_survey_import_batches where id=p_batch;
 if d.id is null then raise exception 'Existing staged survey batch required';end if;
 perform 1 from public.projects where id=d.project_id for update;
 select * into d from public.crm_survey_import_batches where id=p_batch for update;
 if p_id is null or p_version is null or p_review is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit application identity/version/review/manual reason required';end if;
 req:=jsonb_build_object('batch_id',p_batch,'version',p_version,'review_id',p_review,'reason',trim(p_reason));
 select * into retry from public.crm_survey_import_applications where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=req then return retry.id;end if;
  raise exception 'Application identity records a different request';
 end if;
 if d.version is distinct from p_version then raise exception 'Survey batch changed; refresh version';end if;
 select * into r from public.crm_survey_import_reviews where batch_id=d.id and batch_version=d.version order by sequence desc limit 1;
 if r.id is distinct from p_review or r.action is distinct from 'Reviewed' or r.project_id is distinct from d.project_id or r.snapshot is distinct from to_jsonb(d) then raise exception 'Exact latest Reviewed unchanged batch required';end if;
 if exists(select 1 from public.crm_survey_import_applications where batch_id=d.id and batch_version=d.version) then raise exception 'This survey batch version was already applied';end if;
 if jsonb_typeof(d.rows) is distinct from 'array' or jsonb_array_length(d.rows) not between 1 and 100 or octet_length(d.rows::text)>1048576 then raise exception 'Bounded staged survey rows required';end if;
 insert into public.crm_survey_import_applications(id,batch_id,project_id,batch_version,review_id,snapshot,review_snapshot,request,reason,actor_id)
 values(p_id,d.id,d.project_id,d.version,r.id,to_jsonb(d),to_jsonb(r),req,trim(p_reason),auth.uid());
 for item,ordinal in select value,ordinality from jsonb_array_elements(d.rows) with ordinality loop
  if item->'row_number' is distinct from to_jsonb(ordinal) or item->'details'->>'status' is distinct from 'Draft' then raise exception 'Ordered Draft source rows required';end if;
  measurement:=gen_random_uuid();
  -- Reuse all current register validation and history; no batch decision approves a measurement.
  perform public.save_project_survey(measurement,null,d.project_id,item->'details',trim(p_reason));
  select to_jsonb(s) into frozen from public.crm_project_surveys s where id=measurement;
  insert into public.crm_survey_import_measurements(application_id,project_id,row_number,survey_id,survey_snapshot)
  values(p_id,d.project_id,ordinal::integer,measurement,frozen);
 end loop;
 return p_id;
end$$;
revoke all on function public.apply_project_survey_batch(uuid,uuid,integer,uuid,text) from public,anon;
grant execute on function public.apply_project_survey_batch(uuid,uuid,integer,uuid,text) to authenticated;
notify pgrst,'reload schema';
commit;
