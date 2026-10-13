begin;
alter table public.crm_project_contract_publications drop constraint crm_project_contract_publications_status_check;
alter table public.crm_project_contract_publications add constraint crm_project_contract_publications_status_check check(status in ('Published','Withdrawn','Accepted','Declined'));
create table public.crm_project_contract_decisions(
 id uuid primary key,publication_id uuid not null unique references public.crm_project_contract_publications,
 project_id uuid not null references public.projects,company_id uuid not null references public.companies,
 publication_version integer not null,action text not null check(action in ('Accepted','Declined')),
 snapshot jsonb not null,request jsonb not null,note text not null,consent boolean not null check(consent),
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now()
);
create index contract_decision_project on public.crm_project_contract_decisions(project_id);
create index contract_decision_company on public.crm_project_contract_decisions(company_id);
create index contract_decision_actor on public.crm_project_contract_decisions(actor_id);
alter table public.crm_project_contract_decisions enable row level security;
revoke all on public.crm_project_contract_decisions from public,anon,authenticated;
grant select on public.crm_project_contract_decisions to authenticated;
create policy contract_decision_read on public.crm_project_contract_decisions for select to authenticated using(public.is_admin() or exists(select 1 from public.profiles u join public.projects p on p.id=crm_project_contract_decisions.project_id where u.id=auth.uid() and u.active and u.role='client' and u.company_id=crm_project_contract_decisions.company_id and p.company_id=crm_project_contract_decisions.company_id));
create function public.decide_project_contract_publication(p_id uuid,p_publication uuid,p_version integer,p_action text,p_note text,p_consent boolean)
returns uuid language plpgsql security definer set search_path='' as $$
declare p public.crm_project_contract_publications;b public.crm_boq_offer_publications;s public.crm_sales;
 d public.crm_project_contract_drafts;retry public.crm_project_contract_decisions;request_data jsonb;target text;
begin
 select * into p from public.crm_project_contract_publications where id=p_publication;
 if auth.uid() is null or not exists(select 1 from public.profiles where id=auth.uid() and active and role='client' and company_id=p.company_id) then raise exception 'Active original client company decision required';end if;
 perform 1 from public.projects where id=p.project_id and company_id=p.company_id and status not in ('Completed','Cancelled') for update;
 if not found or exists(select 1 from public.crm_handovers where project_id=p.project_id and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Active original customer project without released handover required';end if;
 select * into b from public.crm_boq_offer_publications where id=p.offer_id for update;
 select * into d from public.crm_project_contract_drafts where id=p.draft_id;
 select * into s from public.crm_sales where id=d.sale_id for update;
 select * into p from public.crm_project_contract_publications where id=p_publication for update;
 if not exists(select 1 from public.profiles where id=auth.uid() and active and role='client' and company_id=p.company_id) then raise exception 'Current client company access required';end if;
 if b.status is distinct from 'Accepted' or b.consent is distinct from true or b.version is distinct from (d.source_snapshot->>'version')::integer
  or b.project_id is distinct from p.project_id or b.company_id is distinct from p.company_id or s.company_id is distinct from p.company_id
  or s.project_id is distinct from p.project_id or s.currency is distinct from p.currency or b.currency is distinct from p.currency
 then raise exception 'Original accepted commercial source/customer/sale/currency required';end if;
 if p_id is null or p_version is null or p_action is null or p_action not in ('accept','decline') or p_consent is distinct from true or length(trim(coalesce(p_note,''))) not between 3 and 2000 then raise exception 'Exact decision identity/version/action, explicit consent and manual note required';end if;
 target:=case p_action when 'accept' then 'Accepted' else 'Declined' end;
 request_data:=jsonb_build_object('publication_id',p_publication,'version',p_version,'action',p_action,'note',trim(p_note),'consent',p_consent);
 select * into retry from public.crm_project_contract_decisions where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=request_data then return retry.id;end if;
  raise exception 'Decision identity already records a different request';
 end if;
 if p.status is distinct from 'Published' or p.version is distinct from p_version then raise exception 'Only the exact open fixed publication can receive a client decision';end if;
 -- Decision records the fixed public proposal; later private drafts/reviews never replace that wording.
 update public.crm_project_contract_publications set status=target,version=version+1 where id=p.id;
 insert into public.crm_project_contract_decisions(id,publication_id,project_id,company_id,publication_version,action,snapshot,request,note,consent,actor_id)
 values(p_id,p.id,p.project_id,p.company_id,p.version,target,to_jsonb(p),request_data,trim(p_note),true,auth.uid());
 return p_id;
end$$;
revoke all on function public.decide_project_contract_publication(uuid,uuid,integer,text,text,boolean) from public,anon;
grant execute on function public.decide_project_contract_publication(uuid,uuid,integer,text,text,boolean) to authenticated;
notify pgrst,'reload schema';
commit;
