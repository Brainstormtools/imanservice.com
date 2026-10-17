begin;
create table portal_private.charter_approval_gateway(id text primary key check(id='approval'),token_hash text not null check(length(token_hash)=64));
revoke all on portal_private.charter_approval_gateway from public,anon,authenticated;
alter table portal_private.charter_approval_gateway enable row level security;
create table public.crm_client_charter_approvals(
 id uuid primary key,publication_id uuid not null references public.crm_client_charter_publications,project_id uuid not null references public.projects,
 company_id uuid not null references public.companies,publication_version integer not null,actor_id uuid not null references public.profiles,
 full_name text not null,note text not null,consent boolean not null check(consent),request_ip inet not null,
 snapshot jsonb not null,request jsonb not null,created_at timestamptz not null default now(),unique(publication_id,actor_id)
);
create index charter_approval_project on public.crm_client_charter_approvals(project_id);
create index charter_approval_company on public.crm_client_charter_approvals(company_id);
create index charter_approval_actor on public.crm_client_charter_approvals(actor_id);
alter table public.crm_client_charter_approvals enable row level security;
revoke all on public.crm_client_charter_approvals from public,anon,authenticated;
grant select on public.crm_client_charter_approvals to authenticated;
create policy charter_approval_read on public.crm_client_charter_approvals for select to authenticated using(portal_private.execution_manager(project_id) or (actor_id=auth.uid() and exists(select 1 from public.profiles u join public.projects p on p.id=crm_client_charter_approvals.project_id where u.id=auth.uid() and u.active and u.role='client' and u.company_id=crm_client_charter_approvals.company_id and p.company_id=u.company_id)));
create function public.approve_client_charter(p_id uuid,p_publication uuid,p_version integer,p_consent boolean,p_full_name text,p_note text,p_request_ip text,p_gateway_token text)
returns uuid language plpgsql security definer set search_path='' as $$
declare p public.crm_client_charter_publications;retry public.crm_client_charter_approvals;req jsonb;ip inet;
begin
 if auth.uid() is null or not exists(select 1 from portal_private.charter_approval_gateway where id='approval' and token_hash=encode(sha256(convert_to(coalesce(p_gateway_token,''),'UTF8')),'hex')) then raise exception 'Trusted approval endpoint required';end if;
 select * into p from public.crm_client_charter_publications where id=p_publication;
 perform 1 from public.projects where id=p.project_id for update;
 if not found then raise exception 'Existing published charter required';end if;
 select * into p from public.crm_client_charter_publications where id=p_publication for update;
 perform 1 from public.profiles where id=auth.uid() for share;
 if not portal_private.charter_signatory(p.project_id) or not exists(select 1 from public.profiles where id=auth.uid() and company_id=p.company_id) then raise exception 'Current project authorized client signatory required';end if;
 if p_id is null or p_version is null or p_consent is distinct from true or length(trim(coalesce(p_full_name,''))) not between 3 and 160 or p_note is null or length(trim(p_note))>2000 then raise exception 'Exact identity/version, I agree and actual full name required; note is optional';end if;
 if p_request_ip is null or position('/' in p_request_ip)>0 then raise exception 'Trusted request IP required';end if;
 ip:=p_request_ip::inet;
 req:=jsonb_build_object('publication_id',p_publication,'version',p_version,'consent',true,'full_name',trim(p_full_name),'note',trim(p_note));
 select * into retry from public.crm_client_charter_approvals where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=req then return retry.id;end if;
  raise exception 'Approval identity records a different request';
 end if;
 if p.status is distinct from 'Published' or p.version is distinct from p_version or p.client_terms is null or p.publication_sequence is distinct from (select max(publication_sequence) from public.crm_client_charter_publications where project_id=p.project_id) then raise exception 'Exact latest expanded Published charter required';end if;
 perform portal_private.charter_client_wording(jsonb_build_object('title',p.title,'objectives',p.objectives,'scope',p.scope,'deliverables',p.deliverables,'communication',p.communication)||p.client_terms);
 if exists(select 1 from public.crm_client_charter_approvals where publication_id=p.id and actor_id=auth.uid()) then raise exception 'This account already approved this published charter';end if;
 insert into public.crm_client_charter_approvals(id,publication_id,project_id,company_id,publication_version,actor_id,full_name,note,consent,request_ip,snapshot,request)
 values(p_id,p.id,p.project_id,p.company_id,p.version,auth.uid(),trim(p_full_name),trim(p_note),true,ip,to_jsonb(p),req);
 return p_id;
end$$;
create function public.client_charter_approval_context(p_publication uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare p public.crm_client_charter_publications;manager boolean;items jsonb;
begin
 select * into p from public.crm_client_charter_publications where id=p_publication;
 manager:=portal_private.execution_manager(p.project_id);
 if p.id is null or auth.uid() is null or not(manager or exists(select 1 from public.profiles u join public.projects j on j.id=p.project_id where u.id=auth.uid() and u.active and u.role='client' and u.company_id=p.company_id and j.company_id=p.company_id)) then raise exception 'Current project charter access required';end if;
 select coalesce(jsonb_agg(to_jsonb(a) order by created_at),'[]') into items from public.crm_client_charter_approvals a where publication_id=p.id and (manager or actor_id=auth.uid());
 return jsonb_build_object('eligible',portal_private.charter_signatory(p.project_id) and p.status='Published' and p.client_terms is not null and p.publication_sequence=(select max(publication_sequence) from public.crm_client_charter_publications where project_id=p.project_id),'approvals',items);
end$$;
revoke all on function public.approve_client_charter(uuid,uuid,integer,boolean,text,text,text,text),public.client_charter_approval_context(uuid) from public,anon;
grant execute on function public.approve_client_charter(uuid,uuid,integer,boolean,text,text,text,text),public.client_charter_approval_context(uuid) to authenticated;
notify pgrst,'reload schema';
commit;
