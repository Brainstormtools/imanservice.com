begin;
create table public.crm_survey_import_batches(
 id uuid primary key,project_id uuid not null references public.projects,rows jsonb not null,version integer not null default 1,
 reason text not null,created_by uuid not null references public.profiles,created_at timestamptz not null default now()
);
create index survey_import_project on public.crm_survey_import_batches(project_id);
create index survey_import_author on public.crm_survey_import_batches(created_by);
create table public.crm_survey_import_history(
 id uuid primary key default gen_random_uuid(),batch_id uuid not null references public.crm_survey_import_batches,project_id uuid not null references public.projects,
 revision integer not null,before_record jsonb,after_record jsonb not null,request jsonb not null,reason text not null,
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(batch_id,revision)
);
create index survey_import_history_project on public.crm_survey_import_history(project_id);
create index survey_import_history_actor on public.crm_survey_import_history(actor_id);
do $$declare t text;begin foreach t in array array['crm_survey_import_batches','crm_survey_import_history'] loop execute format('alter table public.%I enable row level security',t);execute format('revoke all on public.%I from public,anon,authenticated',t);execute format('grant select on public.%I to authenticated',t);execute format('create policy survey_import_read on public.%I for select to authenticated using(portal_private.execution_manager(project_id))',t);end loop;end$$;
create function public.stage_project_survey_batch(p_id uuid,p_version integer,p_project uuid,p_rows jsonb,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare old public.crm_survey_import_batches;saved public.crm_survey_import_batches;item jsonb;d jsonb;k text;normalized jsonb:='[]';req jsonb;n integer:=0;day date;
begin
 if auth.uid() is null or not portal_private.execution_manager(p_project) then raise exception 'Active assigned project manager access required';end if;
 perform 1 from public.projects where id=p_project for update;if not found then raise exception 'Existing project required';end if;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit batch identity/manual reason required';end if;
 if jsonb_typeof(p_rows) is distinct from 'array' or jsonb_array_length(p_rows) not between 1 and 100 or octet_length(p_rows::text)>1000000 then raise exception '1–100 survey rows within 1 MB required';end if;
 for item in select value from jsonb_array_elements(p_rows) loop
  n:=n+1;d:='{}';
  if jsonb_typeof(item) is distinct from 'object' or (select count(*) from jsonb_object_keys(item))<>8 or (item-array['title','location','notes','method','evidence','unit','value','measured_on'])<>'{}'::jsonb then raise exception 'Row %: exact eight manual survey fields required',n;end if;
  foreach k in array array['title','location','notes','method','evidence','unit','value','measured_on'] loop
   if jsonb_typeof(item->k) is distinct from 'string' then raise exception 'Row %: survey text fields required',n;end if;
   d:=d||jsonb_build_object(k,trim(item->>k));
  end loop;
  if length(d->>'title') not between 3 and 160 or length(d->>'location') not between 3 and 4000 or length(d->>'notes')>4000 or length(d->>'method')>4000 or length(d->>'evidence')>4000 or length(d->>'unit') not between 1 and 80 then raise exception 'Row %: bounded actual survey wording/unit required',n;end if;
  if length(d->>'value')>32 or d->>'value'!~'^-?[0-9]+(\.[0-9]{1,6})?$' or abs((d->>'value')::numeric)>1000000000000 then raise exception 'Row %: explicit bounded decimal measurement required',n;end if;
  if d->>'measured_on'!~'^\d{4}-\d{2}-\d{2}$' then raise exception 'Row %: explicit ISO measurement date required',n;end if;
  day:=(d->>'measured_on')::date;
  if not isfinite(day) or to_char(day,'YYYY-MM-DD')<>d->>'measured_on' or day>(now() at time zone 'Asia/Karachi')::date then raise exception 'Row %: valid nonfuture measurement date required',n;end if;
  normalized:=normalized||jsonb_build_array(jsonb_build_object('row_number',n,'details',d||jsonb_build_object('status','Draft')));
 end loop;
 req:=jsonb_build_object('version',p_version,'project_id',p_project,'rows',normalized,'reason',trim(p_reason));
 select * into old from public.crm_survey_import_batches where id=p_id for update;
 if old.id is not null then
  if old.project_id is distinct from p_project then raise exception 'Batch project cannot change';end if;
  if exists(select 1 from public.crm_survey_import_history h where h.batch_id=old.id and h.actor_id=auth.uid() and h.request=req and h.revision=coalesce(p_version,0)+1) then return old.id;end if;
  if p_version is null or old.version is distinct from p_version then raise exception 'Survey batch changed; refresh version';end if;
 elsif p_version is not null then raise exception 'Unknown survey batch cannot be revised';end if;
 if old.id is null then
  insert into public.crm_survey_import_batches(id,project_id,rows,reason,created_by) values(p_id,p_project,normalized,trim(p_reason),auth.uid()) returning * into saved;
 else
  update public.crm_survey_import_batches set rows=normalized,version=version+1,reason=trim(p_reason) where id=old.id returning * into saved;
 end if;
 insert into public.crm_survey_import_history(batch_id,project_id,revision,before_record,after_record,request,reason,actor_id)
 values(saved.id,saved.project_id,saved.version,case when old.id is null then null else to_jsonb(old) end,to_jsonb(saved),req,trim(p_reason),auth.uid());
 return saved.id;
end$$;
revoke all on function public.stage_project_survey_batch(uuid,integer,uuid,jsonb,text) from public,anon;
grant execute on function public.stage_project_survey_batch(uuid,integer,uuid,jsonb,text) to authenticated;
notify pgrst,'reload schema';
commit;
