begin;
-- Issue only approved billed debit allocations, atomically per original invoice. Unbilled classification is not posted.
create table public.fin_boq_allocation_postings(
 id uuid primary key,allocation_id uuid not null unique references public.fin_boq_invoice_allocations,
 review_id uuid not null unique references public.fin_boq_invoice_allocation_reviews,company_id uuid not null references public.companies,
 project_id uuid not null references public.projects,request jsonb not null,receipt jsonb not null,
 reason text not null check(length(trim(reason)) between 3 and 2000),issued_by uuid not null references public.profiles,issued_at timestamptz not null default now()
);
create index allocation_posting_company on public.fin_boq_allocation_postings(company_id);
create index allocation_posting_project on public.fin_boq_allocation_postings(project_id);
create index allocation_posting_actor on public.fin_boq_allocation_postings(issued_by);
create table public.fin_boq_allocation_documents(
 id uuid primary key default gen_random_uuid(),posting_id uuid not null references public.fin_boq_allocation_postings,
 original_invoice_id uuid not null references public.invoices,supplementary_invoice_id uuid not null unique references public.invoices,
 net numeric(14,2) not null check(net>0),tax numeric(14,2) not null check(tax>=0),gross numeric(14,2) not null check(gross=net+tax),
 receipt jsonb not null,unique(posting_id,original_invoice_id)
);
create index allocation_document_original on public.fin_boq_allocation_documents(original_invoice_id);
do $$declare t text;begin
 foreach t in array array['fin_boq_allocation_postings','fin_boq_allocation_documents'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on public.%I from public,anon,authenticated',t);
  execute format('grant select on public.%I to authenticated',t);
  execute format('create policy allocation_posting_private_read on public.%I for select to authenticated using(portal_private.adjustment_access())',t);
  execute format('create trigger allocation_posting_immutable before update or delete on public.%I for each row execute function portal_private.boq_line_evidence_immutable()',t);
 end loop;
end$$;
create function portal_private.allocation_debit_basis(p_allocation uuid,p_review uuid) returns jsonb language plpgsql set search_path='' as $$
declare alloc public.fin_boq_invoice_allocations;decision public.fin_boq_invoice_allocation_reviews;s jsonb;
begin
 select * into alloc from public.fin_boq_invoice_allocations where id=p_allocation;
 select * into decision from public.fin_boq_invoice_allocation_reviews where allocation_id=alloc.id;
 if alloc.id is null or decision.id is distinct from p_review or decision.outcome is distinct from 'Approved' or decision.receipt->'allocation' is distinct from to_jsonb(alloc) then raise exception 'Exact immutable Manager-Approved allocation required';end if;
 perform 1 from public.companies where id=(alloc.snapshot->'source'->>'company_id')::uuid for update;
 if alloc.snapshot->>'kind' is distinct from 'Debit note' then raise exception 'Only billed debit allocations are supported in this issuance increment';end if;
 if exists(select 1 from public.fin_boq_allocation_postings where allocation_id=alloc.id) then raise exception 'Approved billed allocation already issued';end if;
 s:=portal_private.boq_invoice_allocation_preview(alloc.publication_id,alloc.lines,alloc.unbilled_net);
 if s is distinct from alloc.snapshot then raise exception 'Approved invoice allocation source changed; return/reconciliation required';end if;
 return jsonb_build_object('allocation',to_jsonb(alloc),'review',to_jsonb(decision),'snapshot',s,'effect','Issue approved billed debit portions only; unbilled classification/tax and contract remain unposted');
end$$;
create function public.preview_boq_allocation_debit(p_allocation uuid,p_review uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare p public.fin_boq_allocation_postings;
begin
 if not portal_private.adjustment_access() then raise exception 'Current Accounts or designated Manager access required';end if;
 select * into p from public.fin_boq_allocation_postings where allocation_id=p_allocation;
 if p.id is not null then
  if p.review_id is distinct from p_review then raise exception 'Exact issued approval required';end if;
  return jsonb_build_object('posting',to_jsonb(p),'documents',coalesce((select jsonb_agg(to_jsonb(d)||jsonb_build_object('number',i.number) order by d.original_invoice_id) from public.fin_boq_allocation_documents d join public.invoices i on i.id=d.supplementary_invoice_id where d.posting_id=p.id),'[]'::jsonb));
 end if;return portal_private.allocation_debit_basis(p_allocation,p_review);
end$$;
create function public.post_boq_allocation_debit(p_id uuid,p_allocation uuid,p_review uuid,p_expected jsonb,p_details jsonb,p_reason text,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$
declare old public.fin_boq_allocation_postings;s jsonb;req jsonb;grouped record;details jsonb;line jsonb;i public.invoices;original public.invoices;idx integer;issue_date date;due_date date;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Current Accounts issuance access required';end if;
 if p_id is null or p_confirm is distinct from true or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Explicit billed issuance confirmation and actual client-visible reason required';end if;
 req:=jsonb_build_object('allocation',p_allocation,'review',p_review,'expected',p_expected,'details',p_details,'reason',trim(p_reason),'confirmed',true);
 select * into old from public.fin_boq_allocation_postings where id=p_id;
 if old.id is not null then
  if old.request=req and old.issued_by=auth.uid() then return old.id;end if;raise exception 'Posting ID already has different immutable evidence';
 end if;
 s:=portal_private.allocation_debit_basis(p_allocation,p_review);
 if s is distinct from p_expected then raise exception 'Exact current approved billed-allocation preview required';end if;
 if jsonb_typeof(p_details) is distinct from 'array' or jsonb_array_length(p_details)<>(select count(distinct (x->>'invoice_id')::uuid) from jsonb_array_elements(s->'snapshot'->'lines') x)
  or exists(select 1 from jsonb_array_elements(p_details) x group by (x->>'invoice_id')::uuid having count(*)>1)
  or exists(select 1 from jsonb_array_elements(p_details) d where not exists(select 1 from jsonb_array_elements(s->'snapshot'->'lines') l where (l->>'invoice_id')::uuid=(d->>'invoice_id')::uuid)) then raise exception 'One explicit payment-details record per actual original invoice required';end if;
 insert into public.fin_boq_allocation_postings(id,allocation_id,review_id,company_id,project_id,request,receipt,reason,issued_by)
 values(p_id,p_allocation,p_review,(s->'snapshot'->'source'->>'company_id')::uuid,(s->'allocation'->>'project_id')::uuid,req,s,trim(p_reason),auth.uid());
 for grouped in select (x->>'invoice_id')::uuid original_id,sum((x->>'net')::numeric) net,sum((x->>'tax')::numeric) tax,sum((x->>'gross')::numeric) gross from jsonb_array_elements(s->'snapshot'->'lines') x group by (x->>'invoice_id')::uuid order by 1 loop
  select value into details from jsonb_array_elements(p_details) where (value->>'invoice_id')::uuid=grouped.original_id;
  if jsonb_typeof(details) is distinct from 'object' or (select count(*) from jsonb_object_keys(details))<>4 or not(details ?& array['invoice_id','issued_on','due_on','bank_instructions'])
   or coalesce(details->>'issued_on','') !~ '^\d{4}-\d{2}-\d{2}$' or coalesce(details->>'due_on','') !~ '^\d{4}-\d{2}-\d{2}$' or jsonb_typeof(details->'bank_instructions') is distinct from 'string' or length(trim(details->>'bank_instructions')) not between 1 and 4000 then raise exception 'Actual per-invoice issue/due dates and bank instructions required';end if;
  issue_date:=(details->>'issued_on')::date;due_date:=(details->>'due_on')::date;if due_date<issue_date then raise exception 'Due date cannot precede issue date';end if;
  select * into original from public.invoices where id=grouped.original_id;
  insert into public.invoices(company_id,company_name,currency,issued_on,due_on,notes,bank_instructions,subtotal,tax_total,total,author_id)
  values(original.company_id,original.company_name,'PKR',issue_date,due_date,'Supplementary invoice for '||original.number||' · accepted change order '||(s->'snapshot'->'source'->>'change_id')||E'\n'||trim(p_reason),trim(details->>'bank_instructions'),grouped.net,grouped.tax,grouped.gross,auth.uid()) returning * into i;
  idx:=0;for line in select value from jsonb_array_elements(s->'snapshot'->'lines') where (value->>'invoice_id')::uuid=grouped.original_id loop
   idx:=idx+1;insert into public.invoice_items(invoice_id,description,quantity,unit_price,tax_percent,net,tax,position)
   values(i.id,line->>'description',1,(line->>'net')::numeric,(line->>'tax_percent')::numeric,(line->>'net')::numeric,(line->>'tax')::numeric,idx);
  end loop;
  insert into public.fin_invoice_projects(id,project_id,linked_by) values(i.id,(s->'allocation'->>'project_id')::uuid,auth.uid());
  update public.invoices set status='Issued' where id=i.id returning * into i;
  insert into public.fin_boq_allocation_documents(posting_id,original_invoice_id,supplementary_invoice_id,net,tax,gross,receipt)
  values(p_id,original.id,i.id,grouped.net,grouped.tax,grouped.gross,jsonb_build_object('original_invoice',to_jsonb(original),'issued_invoice',to_jsonb(i),'payment_details',details));
  insert into public.billing_events(invoice_id,action,detail,actor_id) values(i.id,'Issued – approved billed BOQ allocation','Original '||original.number||' · change order '||(s->'snapshot'->'source'->>'change_id'),auth.uid());
 end loop;return p_id;
end$$;
create function portal_private.allocation_source_guard() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if tg_table_name='crm_boq_adjustment_preparations' then
  if exists(select 1 from public.fin_boq_allocation_documents where supplementary_invoice_id=new.invoice_id) then raise exception 'Allocated supplementary invoices require separate change-chain reconciliation';end if;
 else
  if exists(select 1 from jsonb_array_elements(new.lines) l join public.fin_boq_allocation_documents d on d.supplementary_invoice_id=(l->>'invoice_id')::uuid) then raise exception 'Allocated supplementary invoices require separate change-chain reconciliation';end if;
 end if;return new;
end$$;
create trigger allocation_single_source_guard before insert on public.crm_boq_adjustment_preparations for each row execute function portal_private.allocation_source_guard();
create trigger allocation_multiple_source_guard before insert on public.fin_boq_invoice_allocations for each row execute function portal_private.allocation_source_guard();
create function portal_private.allocation_document_guard() returns trigger language plpgsql security definer set search_path='' as $$
declare src uuid;dest uuid;
begin
 if tg_table_name='invoices' then src:=old.id;
 elsif tg_table_name='invoice_items' then
  if tg_op<>'INSERT' then src:=old.invoice_id;end if;if tg_op<>'DELETE' then dest:=new.invoice_id;end if;
  perform 1 from public.invoices where id in(src,dest) order by id for update;
 else if tg_op<>'INSERT' then src:=old.id;end if;if tg_op<>'DELETE' then dest:=new.id;end if;
 end if;
 if exists(select 1 from public.fin_boq_allocation_documents where original_invoice_id in(src,dest) or supplementary_invoice_id in(src,dest)) then raise exception 'Allocated original/supplementary invoice and attribution evidence is immutable';end if;
 if tg_op='DELETE' then return old;end if;return new;
end$$;
create trigger allocation_document_header_guard before update or delete on public.invoices for each row execute function portal_private.allocation_document_guard();
create trigger allocation_document_items_guard before insert or update or delete on public.invoice_items for each row execute function portal_private.allocation_document_guard();
create trigger allocation_document_project_guard before insert or update or delete on public.fin_invoice_projects for each row execute function portal_private.allocation_document_guard();
alter function public.save_invoice_schedule(uuid,text,date,integer) rename to save_invoice_schedule_before_allocation_debit;
revoke all on function public.save_invoice_schedule_before_allocation_debit(uuid,text,date,integer) from public,anon,authenticated;
create function public.save_invoice_schedule(p_source uuid,p_title text,p_start date,p_due integer) returns uuid language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required';end if;
 perform 1 from public.invoices where id=p_source for update;
 if exists(select 1 from public.fin_boq_allocation_documents where supplementary_invoice_id=p_source) then raise exception 'Allocated supplementary invoices require separate recurring-billing reconciliation';end if;
 return public.save_invoice_schedule_before_allocation_debit(p_source,p_title,p_start,p_due);
end$$;
create function public.boq_allocation_document_register() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare internal boolean:=portal_private.adjustment_access();company uuid;
begin
 if not internal then select company_id into company from public.profiles where id=auth.uid() and active and role='client';if company is null then raise exception 'Current Accounts, designated Manager or own-company client access required';end if;end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',d.id,'posting_id',p.id,'invoice_id',i.id,'number',i.number,'original_number',o.number,'change_id',p.receipt->'snapshot'->'source'->>'change_id','reason',p.reason,'net',d.net,'tax',d.tax,'gross',d.gross,'currency','PKR','issued_on',i.issued_on,'due_on',i.due_on,'bank_instructions',i.bank_instructions,'lines',coalesce((select jsonb_agg(jsonb_build_object('description',l.description,'net',l.net,'tax_percent',l.tax_percent,'tax',l.tax) order by l.position,l.id) from public.invoice_items l where l.invoice_id=i.id),'[]'::jsonb),'issued_by',p.issued_by,'issued_at',p.issued_at)
 ||case when internal then jsonb_build_object('private_receipt',p.receipt,'private_document',d.receipt) else '{}'::jsonb end order by p.issued_at,d.original_invoice_id)
 from public.fin_boq_allocation_documents d join public.fin_boq_allocation_postings p on p.id=d.posting_id join public.invoices i on i.id=d.supplementary_invoice_id join public.invoices o on o.id=d.original_invoice_id where internal or (p.company_id=company and public.can_invoice(i.id))),'[]'::jsonb);
end$$;
revoke all on function portal_private.allocation_debit_basis(uuid,uuid),portal_private.allocation_source_guard(),portal_private.allocation_document_guard() from public,anon,authenticated;
revoke all on function public.preview_boq_allocation_debit(uuid,uuid),public.post_boq_allocation_debit(uuid,uuid,uuid,jsonb,jsonb,text,boolean),public.boq_allocation_document_register(),public.save_invoice_schedule(uuid,text,date,integer) from public,anon,authenticated;
grant execute on function public.preview_boq_allocation_debit(uuid,uuid),public.post_boq_allocation_debit(uuid,uuid,uuid,jsonb,jsonb,text,boolean),public.boq_allocation_document_register(),public.save_invoice_schedule(uuid,text,date,integer) to authenticated;
commit;
