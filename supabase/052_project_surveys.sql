begin;
create table public.crm_project_surveys(id uuid primary key,project_id uuid not null references public.projects,details jsonb not null check(jsonb_typeof(details)='object'),version integer not null default 1,reason text not null check(length(trim(reason)) between 3 and 2000),created_by uuid not null references public.profiles,created_at timestamptz not null default now());
create index crm_survey_project on public.crm_project_surveys(project_id);
create index crm_survey_author on public.crm_project_surveys(created_by);
create table public.crm_project_survey_history(id uuid primary key default gen_random_uuid(),survey_id uuid not null references public.crm_project_surveys,project_id uuid not null references public.projects,revision integer not null,before_survey jsonb,after_survey jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(survey_id,revision));
create index crm_survey_history_project on public.crm_project_survey_history(project_id);
create index crm_survey_history_actor on public.crm_project_survey_history(actor_id);
alter table public.crm_project_surveys enable row level security;
alter table public.crm_project_survey_history enable row level security;
revoke all on public.crm_project_surveys,public.crm_project_survey_history from public,anon,authenticated;
grant select on public.crm_project_surveys,public.crm_project_survey_history to authenticated;
create policy project_survey_read on public.crm_project_surveys for select to authenticated using(portal_private.execution_manager(project_id));
create policy project_survey_history_read on public.crm_project_survey_history for select to authenticated using(portal_private.execution_manager(project_id));
create function public.save_project_survey(p_id uuid,p_version integer,p_project uuid,p_details jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare old public.crm_project_surveys;newrow public.crm_project_surveys;d jsonb;k text;
begin
 if not portal_private.execution_manager(p_project) then raise exception 'Assigned project manager access required';end if;
 perform 1 from public.projects where id=p_project for update;if not found then raise exception 'Project required';end if;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Survey ID and revision reason required';end if;
 if p_details is null or jsonb_typeof(p_details)<>'object' or (select count(*) from jsonb_object_keys(p_details))<>9 then raise exception 'Complete survey details required';end if;
 d:='{}'::jsonb;
 foreach k in array array['title','location','notes','method','evidence','status','unit','value','measured_on'] loop
  if jsonb_typeof(p_details->k) is distinct from 'string' then raise exception 'Complete text survey fields required';end if;
  d:=d||jsonb_build_object(k,trim(p_details->>k));
 end loop;
 if length(d->>'title') not between 3 and 160 or length(d->>'location') not between 3 and 4000 or length(d->>'notes')>4000 or length(d->>'method')>4000 or length(d->>'evidence')>4000 or length(d->>'unit') not between 1 and 80 or d->>'status' not in ('Draft','Reviewed','Archived') then raise exception 'Bounded survey location and valid status required';end if;
 if length(d->>'value')>32 or d->>'value' !~ '^-?[0-9]+(\.[0-9]{1,6})?$' then raise exception 'Explicit decimal measurement required (up to six decimal places)';end if;
 if abs((d->>'value')::numeric)>1000000000000 then raise exception 'Measurement exceeds storage range';end if;
 if d->>'measured_on' !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or (d->>'measured_on')::date>(now() at time zone 'Asia/Karachi')::date then raise exception 'Valid nonfuture measurement date required';end if;
 if d->>'status' in ('Reviewed','Archived') then
  if not public.is_admin() then raise exception 'Administrator reviews or archives surveys';end if;
  if length(d->>'method')<3 or length(d->>'evidence')<3 then raise exception 'Review requires method and evidence';end if;
 end if;
 select * into old from public.crm_project_surveys where id=p_id for update;
 if old.id is not null then
  if p_version is null then
   if old.created_by=auth.uid() and old.version=1 and old.project_id=p_project and old.details=d and old.reason=trim(p_reason) then return old.id;end if;
   raise exception 'Survey ID already used with different data';
  end if;
  if old.project_id<>p_project or old.version is distinct from p_version then raise exception 'Current survey version and fixed project required';end if;
  if old.details->>'status'='Archived' then raise exception 'Archived survey is immutable';end if;
  if old.details->>'status'='Reviewed' and not public.is_admin() then raise exception 'Administrator must revise or withdraw survey review';end if;
  if d->>'status'='Archived' and old.details->>'status'<>'Reviewed' then raise exception 'Review survey before archiving';end if;
  update public.crm_project_surveys set details=d,reason=trim(p_reason),version=version+1 where id=p_id returning * into newrow;
 else
  if p_version is not null or d->>'status'<>'Draft' then raise exception 'New survey must start Draft without a saved version';end if;
  insert into public.crm_project_surveys(id,project_id,details,reason,created_by) values(p_id,p_project,d,trim(p_reason),auth.uid()) returning * into newrow;
 end if;
 insert into public.crm_project_survey_history(survey_id,project_id,revision,before_survey,after_survey,reason,actor_id) values(p_id,p_project,newrow.version,case when old.id is null then null else to_jsonb(old) end,to_jsonb(newrow),trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.save_project_survey(uuid,integer,uuid,jsonb,text) from public,anon;
grant execute on function public.save_project_survey(uuid,integer,uuid,jsonb,text) to authenticated;
commit;
