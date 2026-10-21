begin;
-- Private billed/unbilled allocation preparation and independent Manager review only. No posting.
create table public.fin_boq_invoice_allocations(
 id uuid primary key,publication_id uuid not null references public.crm_boq_revision_publications,project_id uuid not null references public.projects,
 revision integer not null check(revision>0),previous_id uuid references public.fin_boq_invoice_allocations,
 lines jsonb not null,unbilled_net numeric(14,2) not null check(unbilled_net>=0),snapshot jsonb not null,
 reason text not null check(length(trim(reason)) between 3 and 2000),prepared_by uuid not null references public.profiles,
 prepared_at timestamptz not null default now(),unique(publication_id,revision)
);
create index boq_allocation_project on public.fin_boq_invoice_allocations(project_id);
create index boq_allocation_previous on public.fin_boq_invoice_allocations(previous_id);
create index boq_allocation_actor on public.fin_boq_invoice_allocations(prepared_by);
create table public.fin_boq_invoice_allocation_reviews(
 id uuid primary key default gen_random_uuid(),allocation_id uuid not null unique references public.fin_boq_invoice_allocations,
 designation_id uuid not null references public.fin_adjustment_manager_designations,outcome text not null check(outcome in ('Approved','Returned')),
 reason text not null check(length(trim(reason)) between 3 and 2000),receipt jsonb not null,reviewed_by uuid not null references public.profiles,
 reviewed_at timestamptz not null default now()
);
create index boq_allocation_review_designation on public.fin_boq_invoice_allocation_reviews(designation_id);
create index boq_allocation_review_actor on public.fin_boq_invoice_allocation_reviews(reviewed_by);
do $$declare t text;begin
 foreach t in array array['fin_boq_invoice_allocations','fin_boq_invoice_allocation_reviews'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on public.%I from public,anon,authenticated',t);
  execute format('grant select on public.%I to authenticated',t);
  execute format('create policy allocation_private_read on public.%I for select to authenticated using(portal_private.adjustment_access())',t);
  execute format('create trigger allocation_immutable before update or delete on public.%I for each row execute function portal_private.boq_line_evidence_immutable()',t);
 end loop;
end$$;
create function portal_private.boq_invoice_allocation_preview(p_publication uuid,p_lines jsonb,p_unbilled numeric) returns jsonb language plpgsql set search_path='' as $$
declare pub public.crm_boq_revision_publications;b jsonb;source jsonb;r jsonb;l public.invoice_items;net numeric;tax numeric;remaining numeric;net_total numeric:=0;tax_total numeric:=0;lines jsonb:='[]';invoices jsonb:='[]';target_invoice uuid;
begin
 select * into pub from public.crm_boq_revision_publications where id=p_publication;
 if pub.id is null then raise exception 'Actual accepted BOQ publication required';end if;
 perform 1 from public.companies where id=pub.company_id for update;
 if p_unbilled is null or p_unbilled<0 or p_unbilled>=100000000 or p_unbilled<>round(p_unbilled,2) then raise exception 'Explicit nonnegative cent-precision unbilled net required';end if;
 if jsonb_typeof(p_lines) is distinct from 'array' or jsonb_array_length(p_lines) not between 1 and 100 then raise exception 'Explicit actual billed invoice-line allocations required';end if;
 if exists(select 1 from jsonb_array_elements(p_lines) x group by (x->>'item_id')::uuid having count(*)>1) then raise exception 'An actual invoice line can be allocated only once';end if;
 for target_invoice in select distinct (x->>'invoice_id')::uuid from jsonb_array_elements(p_lines) x order by 1 loop
  b:=portal_private.boq_adjustment_basis(pub.id,target_invoice);
  if source is null then source:=b-'invoice'-'invoice_items';elsif source is distinct from b-'invoice'-'invoice_items' then raise exception 'All allocations must use the same exact accepted change';end if;
  if exists(select 1 from public.crm_boq_debit_postings where supplementary_invoice_id=target_invoice) or exists(select 1 from public.fin_boq_invoice_rebills where replacement_invoice_id=target_invoice or fin_boq_invoice_rebills.invoice_id=target_invoice) then raise exception 'Supplementary/rebill change chains require separate reconciliation';end if;
  if exists(select 1 from public.credit_notes n where n.invoice_id=target_invoice and n.status='Issued' and n.boq_posting_id is null) then raise exception 'Unmapped legacy credits or settlement applications require separate reconciliation';end if;
  invoices:=invoices||jsonb_build_array(jsonb_build_object('invoice',b->'invoice','invoice_items',b->'invoice_items'));
 end loop;
 for r in select value from jsonb_array_elements(p_lines) order by (value->>'invoice_id')::uuid,(value->>'item_id')::uuid loop
  if jsonb_typeof(r) is distinct from 'object' or (select count(*) from jsonb_object_keys(r))<>3 or not(r ?& array['invoice_id','item_id','net']) or coalesce(r->>'net','') !~ '^\d{1,9}(\.\d{1,2})?$' then raise exception 'Explicit invoice ID, original line ID and positive cent-precision net required';end if;
  select * into l from public.invoice_items where id=(r->>'item_id')::uuid and public.invoice_items.invoice_id=(r->>'invoice_id')::uuid for share;
  net:=(r->>'net')::numeric;
  if l.id is null or net<=0 or net>=100000000 then raise exception 'Actual original invoice line and supported positive net required';end if;
  if source->>'kind'='Credit note' then
   select l.net-coalesce(sum((a->>'net')::numeric),0) into remaining from public.crm_boq_credit_postings posting cross join lateral jsonb_array_elements(posting.receipt->'preparation'->'snapshot'->'lines') a where posting.invoice_id=l.invoice_id and a->>'item_id'=l.id::text;
   if net>remaining then raise exception 'Original invoice-line credit capacity already consumed';end if;
  end if;
  tax:=round(net*l.tax_percent/100,2);net_total:=net_total+net;tax_total:=tax_total+tax;
  lines:=lines||jsonb_build_array(jsonb_build_object('invoice_id',l.invoice_id,'item_id',l.id,'description',l.description,'original_net',l.net,'remaining_credit_net',case when source->>'kind'='Credit note' then remaining else null end,'net',net,'tax_percent',l.tax_percent,'tax',tax,'gross',net+tax));
 end loop;
 if net_total+p_unbilled<>(source->>'difference_net')::numeric then raise exception 'Billed allocations plus explicit unbilled net must equal the full accepted net difference';end if;
 return source||jsonb_build_object('invoices',invoices,'lines',lines,'mapped_net',net_total,'mapped_tax',tax_total,'mapped_gross',net_total+tax_total,'unbilled_net',p_unbilled,'unbilled_tax',null,'posting_state','Private allocation preparation only; unbilled tax is unassessed; no invoice, balance, credit, WHT or cash posting');
end$$;
create function public.preview_boq_invoice_allocation(p_publication uuid,p_lines jsonb,p_unbilled numeric) returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Current Accounts preparation access required';end if;
 return portal_private.boq_invoice_allocation_preview(p_publication,p_lines,p_unbilled);
end$$;
create function public.prepare_boq_invoice_allocation(p_id uuid,p_publication uuid,p_previous uuid,p_lines jsonb,p_unbilled numeric,p_expected jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare s jsonb;old public.fin_boq_invoice_allocations;latest public.fin_boq_invoice_allocations;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Current Accounts preparation access required';end if;
 if p_id is null or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Actual allocation ID and reason required';end if;
 s:=portal_private.boq_invoice_allocation_preview(p_publication,p_lines,p_unbilled);
 if s is distinct from p_expected then raise exception 'Exact current invoice allocation preview required';end if;
 select * into old from public.fin_boq_invoice_allocations where id=p_id;
 if old.id is not null then
  if old.publication_id=p_publication and old.previous_id is not distinct from p_previous and old.snapshot=s and old.reason=trim(p_reason) and old.prepared_by=auth.uid() then return old.id;end if;raise exception 'Allocation ID already has different immutable evidence';
 end if;
 if exists(select 1 from public.crm_boq_adjustment_preparations p left join public.crm_boq_adjustment_reviews r on r.preparation_id=p.id where p.publication_id=p_publication and (r.id is null or r.outcome='Approved')) then raise exception 'Existing single-invoice preparation/approval requires separate reconciliation';end if;
 select * into latest from public.fin_boq_invoice_allocations where publication_id=p_publication order by revision desc limit 1;
 if latest.id is distinct from p_previous or (latest.id is not null and not exists(select 1 from public.fin_boq_invoice_allocation_reviews where allocation_id=latest.id and outcome='Returned')) then raise exception 'Exact latest Returned allocation required before correction';end if;
 insert into public.fin_boq_invoice_allocations(id,publication_id,project_id,revision,previous_id,lines,unbilled_net,snapshot,reason,prepared_by)
 values(p_id,p_publication,(s->'source'->>'project_id')::uuid,coalesce(latest.revision,0)+1,p_previous,p_lines,p_unbilled,s,trim(p_reason),auth.uid());return p_id;
end$$;
create function public.review_boq_invoice_allocation(p_allocation uuid,p_manager uuid,p_expected jsonb,p_outcome text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare p public.fin_boq_invoice_allocations;r public.fin_boq_invoice_allocation_reviews;d public.fin_adjustment_manager_designations;s jsonb;
begin
 perform 1 from public.profiles where id=auth.uid() for update;
 if auth.uid() is null or p_manager is null or portal_private.adjustment_manager(auth.uid()) is distinct from p_manager then raise exception 'Current explicit Manager designation required';end if;
 if p_outcome is null or p_outcome not in ('Approved','Returned') or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Actual approval/return and reason required';end if;
 select * into p from public.fin_boq_invoice_allocations where id=p_allocation;
 if p.id is null or p.prepared_by=auth.uid() or p.snapshot is distinct from p_expected then raise exception 'Different Manager and exact frozen allocation required';end if;
 perform 1 from public.companies where id=(p.snapshot->'source'->>'company_id')::uuid for update;
 select * into r from public.fin_boq_invoice_allocation_reviews where allocation_id=p.id;
 if r.id is not null then
  if r.reviewed_by=auth.uid() and r.designation_id=p_manager and r.outcome=p_outcome and r.reason=trim(p_reason) then return r.id;end if;raise exception 'Allocation decision is immutable';
 end if;
 if exists(select 1 from public.fin_boq_invoice_allocations where publication_id=p.publication_id and revision>p.revision) then raise exception 'Exact latest allocation required';end if;
 if p_outcome='Approved' then
  if not portal_private.crm_user_permission(p.prepared_by,'finance.manage') then raise exception 'Current Accounts preparer authority required';end if;
  s:=portal_private.boq_invoice_allocation_preview(p.publication_id,p.lines,p.unbilled_net);
  if s is distinct from p.snapshot then raise exception 'Invoice or accepted source changed; return and prepare a fresh allocation';end if;
 end if;
 select * into d from public.fin_adjustment_manager_designations where id=p_manager;
 insert into public.fin_boq_invoice_allocation_reviews(allocation_id,designation_id,outcome,reason,receipt,reviewed_by)
 values(p.id,p_manager,p_outcome,trim(p_reason),jsonb_build_object('allocation',to_jsonb(p),'manager_designation',to_jsonb(d),'posting_state','Approved/Returned private allocation only; no posting'),auth.uid()) returning * into r;return r.id;
end$$;
alter function public.prepare_boq_adjustment(uuid,uuid,uuid,uuid,jsonb,jsonb,jsonb,text) rename to prepare_boq_adjustment_before_allocation;
revoke all on function public.prepare_boq_adjustment_before_allocation(uuid,uuid,uuid,uuid,jsonb,jsonb,jsonb,text) from public,anon,authenticated;
create function public.prepare_boq_adjustment(p_id uuid,p_publication uuid,p_invoice uuid,p_previous uuid,p_lines jsonb,p_wht jsonb,p_expected jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Current Accounts preparation access required';end if;
 perform 1 from public.companies c join public.crm_boq_revision_publications p on p.company_id=c.id where p.id=p_publication for update of c;
 if exists(select 1 from public.fin_boq_invoice_allocations a left join public.fin_boq_invoice_allocation_reviews r on r.allocation_id=a.id where a.publication_id=p_publication and (r.id is null or r.outcome='Approved')) then raise exception 'Existing multi-invoice allocation requires separate reconciliation';end if;
 return public.prepare_boq_adjustment_before_allocation(p_id,p_publication,p_invoice,p_previous,p_lines,p_wht,p_expected,p_reason);
end$$;
create function public.boq_invoice_allocation_register() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare d jsonb;
begin
 if not portal_private.adjustment_access() then raise exception 'Current Accounts or designated Manager access required';end if;
 d:=jsonb_build_object('allocations',coalesce((select jsonb_agg(to_jsonb(a)||jsonb_build_object('review',(select to_jsonb(r) from public.fin_boq_invoice_allocation_reviews r where r.allocation_id=a.id)) order by a.prepared_at,a.id) from public.fin_boq_invoice_allocations a),'[]'::jsonb));
 if portal_private.payables_access() then d:=d||(public.boq_adjustment_register()-'preparations');end if;
 return d;
end$$;
revoke all on function portal_private.boq_invoice_allocation_preview(uuid,jsonb,numeric) from public,anon,authenticated;
revoke all on function public.preview_boq_invoice_allocation(uuid,jsonb,numeric),public.prepare_boq_invoice_allocation(uuid,uuid,uuid,jsonb,numeric,jsonb,text),public.review_boq_invoice_allocation(uuid,uuid,jsonb,text,text),public.boq_invoice_allocation_register(),public.prepare_boq_adjustment(uuid,uuid,uuid,uuid,jsonb,jsonb,jsonb,text) from public,anon,authenticated;
grant execute on function public.preview_boq_invoice_allocation(uuid,jsonb,numeric),public.prepare_boq_invoice_allocation(uuid,uuid,uuid,jsonb,numeric,jsonb,text),public.review_boq_invoice_allocation(uuid,uuid,jsonb,text,text),public.boq_invoice_allocation_register(),public.prepare_boq_adjustment(uuid,uuid,uuid,uuid,jsonb,jsonb,jsonb,text) to authenticated;
commit;
