begin;
create table public.crm_project_contract_drafts(
 id uuid primary key,offer_id uuid not null unique references public.crm_boq_offer_publications,project_id uuid not null references public.projects,
 sale_id uuid not null references public.crm_sales,currency text not null,source_snapshot jsonb not null,baseline_snapshot jsonb not null,
 data jsonb not null,version integer not null default 1,
 reason text not null,created_by uuid not null references public.profiles,created_at timestamptz not null default now()
);
create table public.crm_project_contract_draft_history(
 id uuid primary key default gen_random_uuid(),draft_id uuid not null references public.crm_project_contract_drafts,project_id uuid not null references public.projects,
 revision integer not null,before_record jsonb,after_record jsonb not null,request jsonb not null,reason text not null,
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(draft_id,revision)
);
create index contract_draft_project on public.crm_project_contract_drafts(project_id);
create index contract_draft_sale on public.crm_project_contract_drafts(sale_id);
create index contract_draft_author on public.crm_project_contract_drafts(created_by);
create index contract_draft_history_project on public.crm_project_contract_draft_history(project_id);
create index contract_draft_history_actor on public.crm_project_contract_draft_history(actor_id);
do $$declare t text;begin foreach t in array array['crm_project_contract_drafts','crm_project_contract_draft_history'] loop execute format('alter table public.%I enable row level security',t);execute format('revoke all on public.%I from public,anon,authenticated',t);execute format('grant select on public.%I to authenticated',t);execute format('create policy contract_draft_read on public.%I for select to authenticated using(public.is_admin())',t);end loop;end$$;

create function public.save_project_contract_draft(p_id uuid,p_version integer,p_offer uuid,p_offer_version integer,p_data jsonb,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare pub public.crm_boq_offer_publications;s public.crm_sales;o public.crm_boq_offers;old public.crm_project_contract_drafts;saved public.crm_project_contract_drafts;
 d jsonb;v_request jsonb;key text;limit_length integer;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator prepares private contract revision drafts';end if;
 select * into pub from public.crm_boq_offer_publications where id=p_offer;
 perform 1 from public.projects where id=pub.project_id and status not in ('Completed','Cancelled') for update;
 if not found or exists(select 1 from public.crm_handovers where project_id=pub.project_id and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Active project without released handover required';end if;
 select * into pub from public.crm_boq_offer_publications where id=p_offer for update;
 if pub.status is distinct from 'Accepted' or pub.consent is distinct from true or pub.version is distinct from p_offer_version then raise exception 'Exact client-approved additional offer required';end if;
 select * into o from public.crm_boq_offers where id=pub.id;select * into s from public.crm_sales where id=o.sale_id for update;
 if s.id is null or s.project_id is distinct from pub.project_id or s.company_id is distinct from pub.company_id or s.currency is distinct from pub.currency or not exists(select 1 from public.projects where id=pub.project_id and company_id=pub.company_id) then raise exception 'Original project sale/customer/currency must match';end if;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Draft ID and explicit revision reason required';end if;
 if jsonb_typeof(p_data) is distinct from 'object' or (p_data-array['title','summary','terms','payment_terms'])<>'{}'::jsonb then raise exception 'Bounded manual contract proposal fields required';end if;
 d:='{}';
 foreach key in array array['title','summary','terms','payment_terms'] loop
  limit_length:=case key when 'title' then 160 when 'terms' then 20000 else 4000 end;
  if jsonb_typeof(p_data->key) is distinct from 'string' or length(trim(p_data->>key)) not between 3 and limit_length then raise exception 'Explicit bounded title, summary, terms and payment wording required';end if;
  d:=d||jsonb_build_object(key,trim(p_data->>key));
 end loop;
 v_request:=jsonb_build_object('offer_id',p_offer,'offer_version',p_offer_version,'version',p_version,'data',d,'reason',trim(p_reason));
 select * into old from public.crm_project_contract_drafts where id=p_id for update;
 if old.id is not null then
  if old.offer_id is distinct from p_offer then raise exception 'Contract draft source cannot change';end if;
  if exists(select 1 from public.crm_project_contract_draft_history h where h.draft_id=old.id and h.actor_id=auth.uid() and h.request=v_request and h.revision=coalesce(p_version,0)+1) then return old.id;end if;
  if p_version is null or old.version is distinct from p_version then raise exception 'Contract draft changed; refresh before revising';end if;
  update public.crm_project_contract_drafts set data=d,version=version+1,reason=trim(p_reason) where id=old.id returning * into saved;
 else
  if p_version is not null then raise exception 'Unknown draft cannot be revised';end if;
  insert into public.crm_project_contract_drafts(id,offer_id,project_id,sale_id,currency,source_snapshot,baseline_snapshot,data,reason,created_by)
   values(p_id,pub.id,pub.project_id,s.id,s.currency,to_jsonb(pub),to_jsonb(s),d,trim(p_reason),auth.uid()) returning * into saved;
 end if;
 insert into public.crm_project_contract_draft_history(draft_id,project_id,revision,before_record,after_record,request,reason,actor_id)
  values(saved.id,saved.project_id,saved.version,case when old.id is null then null else to_jsonb(old) end,to_jsonb(saved),v_request,trim(p_reason),auth.uid());
 return saved.id;
end$$;
revoke all on function public.save_project_contract_draft(uuid,integer,uuid,integer,jsonb,text) from public,anon;
grant execute on function public.save_project_contract_draft(uuid,integer,uuid,integer,jsonb,text) to authenticated;
notify pgrst,'reload schema';
commit;
