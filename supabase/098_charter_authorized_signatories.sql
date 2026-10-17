begin;
create table public.crm_charter_signatories(
 id uuid primary key,project_id uuid not null references public.projects,client_id uuid not null references public.profiles,
 authorized boolean not null,version integer not null default 1,reason text not null,actor_id uuid not null references public.profiles,
 updated_at timestamptz not null default now(),unique(project_id,client_id)
);
create index charter_signatory_client on public.crm_charter_signatories(client_id);
create index charter_signatory_actor on public.crm_charter_signatories(actor_id);
create table public.crm_charter_signatory_history(
 id uuid primary key,signatory_id uuid not null references public.crm_charter_signatories,project_id uuid not null references public.projects,
 revision integer not null,before_record jsonb,after_record jsonb not null,request jsonb not null,reason text not null,
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(signatory_id,revision)
);
create index charter_signatory_history_project on public.crm_charter_signatory_history(project_id);
create index charter_signatory_history_actor on public.crm_charter_signatory_history(actor_id);
alter table public.crm_charter_signatories enable row level security;
alter table public.crm_charter_signatory_history enable row level security;
revoke all on public.crm_charter_signatories,public.crm_charter_signatory_history from public,anon,authenticated;
grant select on public.crm_charter_signatories,public.crm_charter_signatory_history to authenticated;
create policy charter_signatory_read on public.crm_charter_signatories for select to authenticated using(portal_private.execution_manager(project_id));
create policy charter_signatory_history_read on public.crm_charter_signatory_history for select to authenticated using(portal_private.execution_manager(project_id));
create function public.charter_signatory_candidates(p_project uuid) returns table(id uuid,name text)
language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not portal_private.execution_manager(p_project) then raise exception 'Assigned project manager access required';end if;
 return query select u.id,u.name from public.profiles u join public.projects p on p.id=p_project and p.company_id=u.company_id where u.active and u.role='client' order by u.name,u.id;
end$$;
create function portal_private.charter_signatory(p_project uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.crm_charter_signatories s join public.projects p on p.id=s.project_id join public.profiles u on u.id=s.client_id where s.project_id=p_project and s.authorized and u.id=auth.uid() and u.active and u.role='client' and u.company_id=p.company_id);
$$;
create function public.set_charter_signatory(p_id uuid,p_signatory uuid,p_project uuid,p_client uuid,p_version integer,p_authorized boolean,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare old public.crm_charter_signatories;saved public.crm_charter_signatories;retry public.crm_charter_signatory_history;req jsonb;company uuid;
begin
 if auth.uid() is null or not portal_private.execution_manager(p_project) then raise exception 'Assigned project manager access required';end if;
 select company_id into company from public.projects where id=p_project for update;
 if not found then raise exception 'Existing project required';end if;
 if p_id is null or p_signatory is null or p_client is null or p_authorized is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit identity/client/authority/manual reason required';end if;
 req:=jsonb_build_object('signatory_id',p_signatory,'project_id',p_project,'client_id',p_client,'version',p_version,'authorized',p_authorized,'reason',trim(p_reason));
 select * into retry from public.crm_charter_signatory_history where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=req then return retry.signatory_id;end if;
  raise exception 'Decision identity records a different request';
 end if;
 select * into old from public.crm_charter_signatories where id=p_signatory for update;
 if old.id is null then
  if p_version is not null or not p_authorized then raise exception 'New authority requires explicit grant and no prior version';end if;
 else
  if old.project_id is distinct from p_project or old.client_id is distinct from p_client or old.version is distinct from p_version then raise exception 'Fixed project/contact and exact authority version required';end if;
  if old.authorized=p_authorized then raise exception 'Authority already has that state';end if;
 end if;
 -- Revocation stays possible if the contact was disabled or moved. Fresh grants require current eligibility.
 if p_authorized then
  perform 1 from public.profiles where id=p_client and active and role='client' and company_id=company for share;
  if not found then raise exception 'Active client contact of this project company required';end if;
 end if;
 if old.id is null then
  insert into public.crm_charter_signatories(id,project_id,client_id,authorized,reason,actor_id) values(p_signatory,p_project,p_client,true,trim(p_reason),auth.uid()) returning * into saved;
 else
  update public.crm_charter_signatories set authorized=p_authorized,version=version+1,reason=trim(p_reason),actor_id=auth.uid(),updated_at=now() where id=old.id returning * into saved;
 end if;
 insert into public.crm_charter_signatory_history(id,signatory_id,project_id,revision,before_record,after_record,request,reason,actor_id) values(p_id,saved.id,p_project,saved.version,case when old.id is not null then to_jsonb(old) end,to_jsonb(saved),req,trim(p_reason),auth.uid());
 return saved.id;
end$$;
revoke all on function public.charter_signatory_candidates(uuid),public.set_charter_signatory(uuid,uuid,uuid,uuid,integer,boolean,text),portal_private.charter_signatory(uuid) from public,anon;
grant execute on function public.charter_signatory_candidates(uuid),public.set_charter_signatory(uuid,uuid,uuid,uuid,integer,boolean,text),portal_private.charter_signatory(uuid) to authenticated;
notify pgrst,'reload schema';
commit;
