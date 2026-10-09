begin;
create table public.crm_project_charters(id uuid primary key,project_id uuid not null references public.projects,details jsonb not null check(jsonb_typeof(details)='object'),version integer not null default 1,reason text not null check(length(trim(reason)) between 3 and 2000),created_by uuid not null references public.profiles,created_at timestamptz not null default now());
create unique index crm_charter_current on public.crm_project_charters(project_id) where details->>'status'<>'Archived';
create index crm_charter_project on public.crm_project_charters(project_id);
create index crm_charter_author on public.crm_project_charters(created_by);
create table public.crm_project_charter_history(id uuid primary key default gen_random_uuid(),charter_id uuid not null references public.crm_project_charters,project_id uuid not null references public.projects,revision integer not null,before_charter jsonb,after_charter jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(charter_id,revision));
create index crm_charter_history_project on public.crm_project_charter_history(project_id);
create index crm_charter_history_actor on public.crm_project_charter_history(actor_id);
alter table public.crm_project_charters enable row level security;
alter table public.crm_project_charter_history enable row level security;
revoke all on public.crm_project_charters,public.crm_project_charter_history from public,anon,authenticated;
grant select on public.crm_project_charters,public.crm_project_charter_history to authenticated;
create policy project_charter_read on public.crm_project_charters for select to authenticated using(portal_private.execution_manager(project_id));
create policy project_charter_history_read on public.crm_project_charter_history for select to authenticated using(portal_private.execution_manager(project_id));
create function public.save_project_charter(p_id uuid,p_version integer,p_project uuid,p_details jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare old public.crm_project_charters;newrow public.crm_project_charters;d jsonb;k text;
begin
 if not portal_private.execution_manager(p_project) then raise exception 'Assigned project manager access required';end if;
 perform 1 from public.projects where id=p_project for update;if not found then raise exception 'Project required';end if;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Charter ID and revision reason required';end if;
 if p_details is null or jsonb_typeof(p_details)<>'object' or (select count(*) from jsonb_object_keys(p_details))<>7 then raise exception 'Complete charter details required';end if;
 d:='{}'::jsonb;
 foreach k in array array['title','objectives','scope','deliverables','communication','status','stakeholders'] loop
  if jsonb_typeof(p_details->k) is distinct from 'string' then raise exception 'Complete text charter fields required';end if;
  d:=d||jsonb_build_object(k,trim(p_details->>k));
 end loop;
 if length(d->>'title') not between 3 and 160 or length(d->>'objectives') not between 3 and 4000 or length(d->>'scope')>4000 or length(d->>'deliverables')>4000 or length(d->>'communication')>4000 or length(d->>'stakeholders')>4000 or d->>'status' not in ('Draft','Reviewed','Archived') then raise exception 'Bounded charter objectives and valid status required';end if;
 if d->>'status' in ('Reviewed','Archived') then
  if not public.is_admin() then raise exception 'Administrator reviews or archives charters';end if;
  if length(d->>'scope')<3 or length(d->>'deliverables')<3 or length(d->>'communication')<3 then raise exception 'Review requires scope, deliverables and communication';end if;
 end if;
 select * into old from public.crm_project_charters where id=p_id for update;
 if old.id is not null then
  if p_version is null then
   if old.created_by=auth.uid() and old.version=1 and old.project_id=p_project and old.details=d and old.reason=trim(p_reason) then return old.id;end if;
   raise exception 'Charter ID already used with different data';
  end if;
  if old.project_id<>p_project or old.version is distinct from p_version then raise exception 'Current charter version and fixed project required';end if;
  if old.details->>'status'='Archived' then raise exception 'Archived charter is immutable';end if;
  if old.details->>'status'='Reviewed' and not public.is_admin() then raise exception 'Administrator must revise or withdraw charter review';end if;
  if d->>'status'='Archived' and old.details->>'status'<>'Reviewed' then raise exception 'Review charter before archiving';end if;
  update public.crm_project_charters set details=d,reason=trim(p_reason),version=version+1 where id=p_id returning * into newrow;
 else
  if p_version is not null or d->>'status'<>'Draft' then raise exception 'New charter must start Draft without a saved version';end if;
  if exists(select 1 from public.crm_project_charters where project_id=p_project and details->>'status'<>'Archived') then raise exception 'Revise or archive the existing project charter before replacement';end if;
  insert into public.crm_project_charters(id,project_id,details,reason,created_by) values(p_id,p_project,d,trim(p_reason),auth.uid()) returning * into newrow;
 end if;
 insert into public.crm_project_charter_history(charter_id,project_id,revision,before_charter,after_charter,reason,actor_id) values(p_id,p_project,newrow.version,case when old.id is null then null else to_jsonb(old) end,to_jsonb(newrow),trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.save_project_charter(uuid,integer,uuid,jsonb,text) from public,anon;
grant execute on function public.save_project_charter(uuid,integer,uuid,jsonb,text) to authenticated;
commit;
