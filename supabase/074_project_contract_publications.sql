begin;
create table public.crm_project_contract_publications(
 id uuid primary key,draft_id uuid not null references public.crm_project_contract_drafts,project_id uuid not null references public.projects,
 offer_id uuid not null references public.crm_boq_offer_publications,company_id uuid not null references public.companies,
 draft_version integer not null,project_title text not null,company_name text not null,currency text not null,
 title text not null,summary text not null,terms text not null,payment_terms text not null,commercial_source jsonb not null,
 status text not null default 'Published' check(status in ('Published','Withdrawn')),version integer not null default 1,
 published_at timestamptz not null default now(),withdrawn_at timestamptz,unique(draft_id,draft_version)
);
create unique index contract_publication_one_open on public.crm_project_contract_publications(draft_id) where status='Published';
create index contract_publication_project on public.crm_project_contract_publications(project_id);
create index contract_publication_offer on public.crm_project_contract_publications(offer_id);
create index contract_publication_company on public.crm_project_contract_publications(company_id);
create table public.crm_project_contract_publication_history(
 id uuid primary key,publication_id uuid not null references public.crm_project_contract_publications,draft_id uuid not null references public.crm_project_contract_drafts,
 project_id uuid not null references public.projects,review_id uuid references public.crm_project_contract_reviews,
 action text not null check(action in ('Published','Withdrawn')),private_snapshot jsonb not null,before_record jsonb,after_record jsonb not null,
 request jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now()
);
create index contract_publication_history_parent on public.crm_project_contract_publication_history(publication_id);
create index contract_publication_history_draft on public.crm_project_contract_publication_history(draft_id);
create index contract_publication_history_project on public.crm_project_contract_publication_history(project_id);
create index contract_publication_history_review on public.crm_project_contract_publication_history(review_id);
create index contract_publication_history_actor on public.crm_project_contract_publication_history(actor_id);
alter table public.crm_project_contract_publications enable row level security;
alter table public.crm_project_contract_publication_history enable row level security;
revoke all on public.crm_project_contract_publications,public.crm_project_contract_publication_history from public,anon,authenticated;
grant select on public.crm_project_contract_publications,public.crm_project_contract_publication_history to authenticated;
create policy contract_publication_read on public.crm_project_contract_publications for select to authenticated using(public.is_admin() or exists(select 1 from public.profiles u join public.projects p on p.id=crm_project_contract_publications.project_id where u.id=auth.uid() and u.active and u.role='client' and u.company_id=crm_project_contract_publications.company_id and p.company_id=crm_project_contract_publications.company_id));
create policy contract_publication_history_read on public.crm_project_contract_publication_history for select to authenticated using(public.is_admin());

create function public.publish_project_contract_draft(p_id uuid,p_draft uuid,p_version integer,p_review uuid,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare d public.crm_project_contract_drafts;b public.crm_boq_offer_publications;s public.crm_sales;r public.crm_project_contract_reviews;
 retry public.crm_project_contract_publication_history;saved public.crm_project_contract_publications;request_data jsonb;source jsonb;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator publishes reviewed contract proposals';end if;
 select * into d from public.crm_project_contract_drafts where id=p_draft;
 perform 1 from public.projects where id=d.project_id and status not in ('Completed','Cancelled') for update;
 if not found or exists(select 1 from public.crm_handovers where project_id=d.project_id and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Active project without released handover required';end if;
 select * into b from public.crm_boq_offer_publications where id=d.offer_id for update;
 select * into s from public.crm_sales where id=d.sale_id for update;
 select * into d from public.crm_project_contract_drafts where id=p_draft for update;
 if b.status is distinct from 'Accepted' or b.consent is distinct from true or b.version is distinct from (d.source_snapshot->>'version')::integer
  or b.project_id is distinct from d.project_id or b.company_id is distinct from s.company_id or s.project_id is distinct from d.project_id
  or s.currency is distinct from d.currency or b.currency is distinct from d.currency
  or not exists(select 1 from public.projects where id=d.project_id and company_id=b.company_id)
 then raise exception 'Exact accepted source and original project sale/customer/currency required';end if;
 if p_id is null or p_version is null or p_review is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit publication identity/version/review and manual reason required';end if;
 request_data:=jsonb_build_object('draft_id',p_draft,'version',p_version,'review_id',p_review,'reason',trim(p_reason));
 select * into retry from public.crm_project_contract_publication_history where id=p_id;
 if retry.id is not null then
  if retry.action='Published' and retry.actor_id=auth.uid() and retry.request=request_data then return retry.publication_id;end if;
  raise exception 'Publication identity already records a different request';
 end if;
 if d.version is distinct from p_version then raise exception 'Contract wording changed; refresh and review current version';end if;
 select * into r from public.crm_project_contract_reviews where draft_id=d.id and draft_version=d.version order by sequence desc limit 1;
 if r.id is distinct from p_review or r.action is distinct from 'Reviewed' or r.snapshot is distinct from to_jsonb(d) then raise exception 'Exact latest reviewed contract proposal required';end if;
 if exists(select 1 from public.crm_project_contract_publications where draft_id=d.id and (draft_version=d.version or status='Published')) then raise exception 'Version already published or an open publication requires explicit withdrawal';end if;
 -- Deliberate allowlist: never copy original Sale, private cost/budget, review actor/reason or complete private review snapshot.
 source:=jsonb_build_object('offer_id',b.id,'number',b.number,'revision',b.revision,'title',b.title,'currency',b.currency,'terms',b.terms,'items',b.items,'subtotal',b.subtotal,'service_tax_base',b.service_tax_base,'pra_percent',b.pra_percent,'tax_total',b.tax_total,'total',b.total,'wht_percent',b.wht_percent,'wht_total',b.wht_total,'receivable',b.receivable,'accepted_at',b.decided_at);
 insert into public.crm_project_contract_publications(id,draft_id,project_id,offer_id,company_id,draft_version,project_title,company_name,currency,title,summary,terms,payment_terms,commercial_source)
 values(p_id,d.id,d.project_id,b.id,b.company_id,d.version,b.project_title,b.company_name,b.currency,d.data->>'title',d.data->>'summary',d.data->>'terms',d.data->>'payment_terms',source) returning * into saved;
 insert into public.crm_project_contract_publication_history(id,publication_id,draft_id,project_id,review_id,action,private_snapshot,after_record,request,reason,actor_id)
 values(p_id,saved.id,d.id,d.project_id,r.id,'Published',to_jsonb(r),to_jsonb(saved),request_data,trim(p_reason),auth.uid());
 return saved.id;
end$$;

create function public.withdraw_project_contract_publication(p_id uuid,p_publication uuid,p_version integer,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare old public.crm_project_contract_publications;saved public.crm_project_contract_publications;retry public.crm_project_contract_publication_history;request_data jsonb;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator withdraws contract publications';end if;
 select * into old from public.crm_project_contract_publications where id=p_publication;
 perform 1 from public.projects where id=old.project_id for update;if not found then raise exception 'Publication unavailable';end if;
 select * into old from public.crm_project_contract_publications where id=p_publication for update;
 if p_id is null or p_version is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit withdrawal identity/version and manual reason required';end if;
 request_data:=jsonb_build_object('publication_id',p_publication,'version',p_version,'reason',trim(p_reason));
 select * into retry from public.crm_project_contract_publication_history where id=p_id;
 if retry.id is not null then
  if retry.action='Withdrawn' and retry.actor_id=auth.uid() and retry.request=request_data then return retry.publication_id;end if;
  raise exception 'Withdrawal identity already records a different request';
 end if;
 if old.version is distinct from p_version or old.status is distinct from 'Published' then raise exception 'Only the exact open publication can be withdrawn';end if;
 update public.crm_project_contract_publications set status='Withdrawn',version=version+1,withdrawn_at=now() where id=old.id returning * into saved;
 insert into public.crm_project_contract_publication_history(id,publication_id,draft_id,project_id,action,private_snapshot,before_record,after_record,request,reason,actor_id)
 values(p_id,old.id,old.draft_id,old.project_id,'Withdrawn','{}',to_jsonb(old),to_jsonb(saved),request_data,trim(p_reason),auth.uid());
 return old.id;
end$$;
revoke all on function public.publish_project_contract_draft(uuid,uuid,integer,uuid,text),public.withdraw_project_contract_publication(uuid,uuid,integer,text) from public,anon;
grant execute on function public.publish_project_contract_draft(uuid,uuid,integer,uuid,text),public.withdraw_project_contract_publication(uuid,uuid,integer,text) to authenticated;
notify pgrst,'reload schema';
commit;
