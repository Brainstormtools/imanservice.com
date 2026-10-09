begin;
create table public.crm_project_risks(id uuid primary key,project_id uuid not null references public.projects,details jsonb not null check(jsonb_typeof(details)='object'),version integer not null default 1,reason text not null check(length(trim(reason)) between 3 and 2000),created_by uuid not null references public.profiles,created_at timestamptz not null default now());
create index crm_risk_project on public.crm_project_risks(project_id);
create index crm_risk_author on public.crm_project_risks(created_by);
create table public.crm_project_risk_history(id uuid primary key default gen_random_uuid(),risk_id uuid not null references public.crm_project_risks,project_id uuid not null references public.projects,revision integer not null,before_risk jsonb,after_risk jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(risk_id,revision));
create index crm_risk_history_project on public.crm_project_risk_history(project_id);
create index crm_risk_history_actor on public.crm_project_risk_history(actor_id);
alter table public.crm_project_risks enable row level security;
alter table public.crm_project_risk_history enable row level security;
revoke all on public.crm_project_risks,public.crm_project_risk_history from public,anon,authenticated;
grant select on public.crm_project_risks,public.crm_project_risk_history to authenticated;
create policy project_risk_read on public.crm_project_risks for select to authenticated using(portal_private.execution_manager(project_id));
create policy project_risk_history_read on public.crm_project_risk_history for select to authenticated using(portal_private.execution_manager(project_id));
create function public.save_project_risk(p_id uuid,p_version integer,p_project uuid,p_details jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare old public.crm_project_risks;newrow public.crm_project_risks;d jsonb;k text;
begin
 if not portal_private.execution_manager(p_project) then raise exception 'Assigned project manager access required';end if;
 perform 1 from public.projects where id=p_project for update;if not found then raise exception 'Project required';end if;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Risk ID and revision reason required';end if;
 if p_details is null or jsonb_typeof(p_details)<>'object' or (select count(*) from jsonb_object_keys(p_details))<>7 then raise exception 'Complete risk details required';end if;
 d:='{}'::jsonb;
 foreach k in array array['title','description','probability','impact','mitigation','status','resolution'] loop
  if jsonb_typeof(p_details->k) is distinct from 'string' then raise exception 'Complete text risk fields required';end if;
  d:=d||jsonb_build_object(k,trim(p_details->>k));
 end loop;
 if length(d->>'title') not between 3 and 160 or length(d->>'description') not between 3 and 4000 or length(d->>'mitigation')>4000 or length(d->>'resolution')>4000 or d->>'probability' not in ('Low','Medium','High') or d->>'impact' not in ('Low','Medium','High') or d->>'status' not in ('Open','Mitigating','Closed') then raise exception 'Bounded risk description and explicit assessment required';end if;
 if d->>'status'='Mitigating' and length(d->>'mitigation')<3 then raise exception 'Mitigation plan required';end if;
 if d->>'status'='Closed' and length(d->>'resolution')<3 then raise exception 'Closure resolution required';end if;
 select * into old from public.crm_project_risks where id=p_id for update;
 if old.id is not null then
  if p_version is null then
   if old.created_by=auth.uid() and old.version=1 and old.project_id=p_project and old.details=d and old.reason=trim(p_reason) then return old.id;end if;
   raise exception 'Risk ID already used with different data';
  end if;
  if old.project_id<>p_project or old.version is distinct from p_version then raise exception 'Current risk version and fixed project required';end if;
  update public.crm_project_risks set details=d,reason=trim(p_reason),version=version+1 where id=p_id returning * into newrow;
 else
  if p_version is not null or d->>'status'<>'Open' then raise exception 'New risk must start Open without a saved version';end if;
  insert into public.crm_project_risks(id,project_id,details,reason,created_by) values(p_id,p_project,d,trim(p_reason),auth.uid()) returning * into newrow;
 end if;
 insert into public.crm_project_risk_history(risk_id,project_id,revision,before_risk,after_risk,reason,actor_id) values(p_id,p_project,newrow.version,case when old.id is null then null else to_jsonb(old) end,to_jsonb(newrow),trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.save_project_risk(uuid,integer,uuid,jsonb,text) from public,anon;
grant execute on function public.save_project_risk(uuid,integer,uuid,jsonb,text) to authenticated;
commit;
