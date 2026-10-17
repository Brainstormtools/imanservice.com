begin;
create table public.crm_client_charter_drafts(
 id uuid primary key,project_id uuid not null references public.projects,charter_id uuid not null references public.crm_project_charters,
 charter_version integer not null,source_snapshot jsonb not null,details jsonb not null,version integer not null default 1,
 reason text not null,created_by uuid not null references public.profiles,created_at timestamptz not null default now()
);
create index client_charter_draft_project on public.crm_client_charter_drafts(project_id);
create index client_charter_draft_charter on public.crm_client_charter_drafts(charter_id);
create index client_charter_draft_author on public.crm_client_charter_drafts(created_by);
create table public.crm_client_charter_history(
 id uuid primary key default gen_random_uuid(),plan_id uuid not null references public.crm_client_charter_drafts,project_id uuid not null references public.projects,
 revision integer not null,before_record jsonb,after_record jsonb not null,request jsonb not null,reason text not null,
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(plan_id,revision)
);
create index client_charter_history_project on public.crm_client_charter_history(project_id);
create index client_charter_history_actor on public.crm_client_charter_history(actor_id);
do $$declare t text;begin foreach t in array array['crm_client_charter_drafts','crm_client_charter_history'] loop execute format('alter table public.%I enable row level security',t);execute format('revoke all on public.%I from public,anon,authenticated',t);execute format('grant select on public.%I to authenticated',t);execute format('create policy client_charter_draft_read on public.%I for select to authenticated using(portal_private.execution_manager(project_id))',t);end loop;end$$;
create function public.save_client_charter_draft(p_id uuid,p_version integer,p_project uuid,p_charter uuid,p_charter_version integer,p_details jsonb,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare c public.crm_project_charters;old public.crm_client_charter_drafts;saved public.crm_client_charter_drafts;d jsonb:='{}';k text;req jsonb;
begin
 if auth.uid() is null or not portal_private.execution_manager(p_project) then raise exception 'Active assigned project manager access required';end if;
 perform 1 from public.projects where id=p_project for update;if not found then raise exception 'Existing project required';end if;
 if p_id is null or p_charter is null or p_charter_version is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit identity/charter version/manual reason required';end if;
 if jsonb_typeof(p_details) is distinct from 'object' or (select count(*) from jsonb_object_keys(p_details))<>5 or (p_details-array['title','objectives','scope','deliverables','communication'])<>'{}'::jsonb then raise exception 'Exact manual client charter copy fields required';end if;
 foreach k in array array['title','objectives','scope','deliverables','communication'] loop
  if jsonb_typeof(p_details->k) is distinct from 'string' or length(trim(p_details->>k)) not between 3 and (case when k='title' then 160 else 4000 end) then raise exception 'Bounded actual client-facing wording required';end if;
  d:=d||jsonb_build_object(k,trim(p_details->>k));
 end loop;
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
revoke all on function public.save_client_charter_draft(uuid,integer,uuid,uuid,integer,jsonb,text) from public,anon;
grant execute on function public.save_client_charter_draft(uuid,integer,uuid,uuid,integer,jsonb,text) to authenticated;
notify pgrst,'reload schema';
commit;
