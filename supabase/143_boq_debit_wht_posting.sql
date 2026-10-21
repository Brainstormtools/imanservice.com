begin;
-- Supplementary invoices and explicitly entered WHT evidence. WHT never fabricates cash or invoice credits.
create table public.crm_boq_debit_postings (
 id uuid primary key,preparation_id uuid not null unique references public.crm_boq_adjustment_preparations,
 review_id uuid not null unique references public.crm_boq_adjustment_reviews,invoice_id uuid not null references public.invoices,
 supplementary_invoice_id uuid not null unique references public.invoices,company_id uuid not null references public.companies,
 project_id uuid not null references public.projects,request jsonb not null,receipt jsonb not null,
 reason text not null check(length(trim(reason)) between 3 and 2000),issued_by uuid not null references public.profiles,
 issued_at timestamptz not null default now()
);
create index boq_debit_original on public.crm_boq_debit_postings(invoice_id);
create index boq_debit_company on public.crm_boq_debit_postings(company_id);
create index boq_debit_project on public.crm_boq_debit_postings(project_id);
create index boq_debit_actor on public.crm_boq_debit_postings(issued_by);
create table public.fin_boq_wht_adjustments (
 id uuid primary key default gen_random_uuid(),preparation_id uuid not null unique references public.crm_boq_adjustment_preparations,
 review_id uuid not null unique references public.crm_boq_adjustment_reviews,invoice_id uuid not null references public.invoices,
 company_id uuid not null references public.companies,document_type text not null check(document_type in ('Credit note','Supplementary invoice')),
 document_id uuid not null,amount numeric(14,2) not null check(amount<>0 and abs(amount)<100000000),
 certificate_reference text not null check(length(trim(certificate_reference)) between 1 and 200),receipt jsonb not null,
 recorded_by uuid not null references public.profiles,recorded_at timestamptz not null default now(),unique(document_type,document_id)
);
create index boq_wht_invoice on public.fin_boq_wht_adjustments(invoice_id);
create index boq_wht_company on public.fin_boq_wht_adjustments(company_id);
create index boq_wht_actor on public.fin_boq_wht_adjustments(recorded_by);
do $$declare t text;begin
 foreach t in array array['crm_boq_debit_postings','fin_boq_wht_adjustments'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on public.%I from public,anon,authenticated',t);
  execute format('grant select on public.%I to authenticated',t);
  execute format('create policy private_adjustment_read on public.%I for select to authenticated using(portal_private.adjustment_access())',t);
  execute format('create trigger adjustment_posting_immutable before update or delete on public.%I for each row execute function portal_private.boq_line_evidence_immutable()',t);
 end loop;
end$$;
create function portal_private.approved_adjustment(p_preparation uuid,p_review uuid) returns jsonb language plpgsql set search_path='' as $$
declare p public.crm_boq_adjustment_preparations;r public.crm_boq_adjustment_reviews;s jsonb;lines jsonb;
begin
 select * into p from public.crm_boq_adjustment_preparations where id=p_preparation;
 select * into r from public.crm_boq_adjustment_reviews where preparation_id=p.id;
 if p.id is null or r.id is distinct from p_review or r.outcome is distinct from 'Approved' or r.receipt->'preparation' is distinct from to_jsonb(p) then raise exception 'Exact immutable Manager-Approved preparation required';end if;
 perform 1 from public.companies where id=(p.snapshot->'source'->>'company_id')::uuid for update;
 if exists(select 1 from public.crm_boq_debit_postings where supplementary_invoice_id=p.invoice_id) then raise exception 'Supplementary invoices cannot be reused as original invoice bases';end if;
 select jsonb_agg(jsonb_build_object('item_id',a->>'item_id','net',a->>'net') order by a->>'item_id') into lines from jsonb_array_elements(p.snapshot->'lines') a;
 s:=portal_private.boq_adjustment_preview(p.publication_id,p.invoice_id,lines,p.snapshot->'manual_wht');
 if s is distinct from p.snapshot then raise exception 'Approved economic source changed; reconciliation required';end if;
 return jsonb_build_object('preparation',to_jsonb(p),'review',to_jsonb(r),'snapshot',s);
end$$;
create function portal_private.record_adjustment_wht(p_preparation uuid,p_review uuid,p_type text,p_document uuid) returns void language plpgsql set search_path='' as $$
declare p public.crm_boq_adjustment_preparations;w jsonb;
begin
 select * into p from public.crm_boq_adjustment_preparations where id=p_preparation;w:=p.snapshot->'manual_wht';
 if w is null or w='null'::jsonb then return;end if;
 if not exists(select 1 from public.fin_boq_wht_adjustments where preparation_id=p.id) then
  insert into public.fin_boq_wht_adjustments(preparation_id,review_id,invoice_id,company_id,document_type,document_id,amount,certificate_reference,receipt,recorded_by)
  values(p.id,p_review,p.invoice_id,(p.snapshot->'source'->>'company_id')::uuid,p_type,p_document,(w->>'amount')::numeric,w->>'certificate_reference',
   jsonb_build_object('preparation',to_jsonb(p),'review',(select to_jsonb(r) from public.crm_boq_adjustment_reviews r where id=p_review),'manual_wht',w,'effect','Manual tax evidence only; no automatic WHT reversal, cash or invoice-balance settlement'),auth.uid());
 end if;
end$$;
create function portal_private.boq_debit_preview(p_preparation uuid,p_review uuid,p_details jsonb) returns jsonb language plpgsql set search_path='' as $$
declare s jsonb;issue_date date;due_date date;
begin
 s:=portal_private.approved_adjustment(p_preparation,p_review);
 if s->'snapshot'->>'kind' is distinct from 'Debit note' then raise exception 'Approved debit preparation required';end if;
 if exists(select 1 from public.crm_boq_debit_postings where preparation_id=p_preparation) then raise exception 'Approved preparation already issued';end if;
 if jsonb_typeof(p_details) is distinct from 'object' or (select count(*) from jsonb_object_keys(p_details))<>3 or not(p_details ?& array['issued_on','due_on','bank_instructions'])
  or coalesce(p_details->>'issued_on','') !~ '^\d{4}-\d{2}-\d{2}$' or coalesce(p_details->>'due_on','') !~ '^\d{4}-\d{2}-\d{2}$'
  or jsonb_typeof(p_details->'bank_instructions') is distinct from 'string' or length(trim(p_details->>'bank_instructions')) not between 1 and 4000 then raise exception 'Actual issue date, due date and bank instructions required';end if;
 issue_date:=(p_details->>'issued_on')::date;due_date:=(p_details->>'due_on')::date;
 if due_date<issue_date then raise exception 'Due date cannot precede issue date';end if;
 return s||jsonb_build_object('details',jsonb_build_object('issued_on',issue_date,'due_on',due_date,'bank_instructions',trim(p_details->>'bank_instructions')),'currency','PKR');
end$$;
create function public.preview_boq_debit_posting(p_preparation uuid,p_review uuid,p_details jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare b public.crm_boq_debit_postings;
begin
 if not portal_private.adjustment_access() then raise exception 'Current Accounts or designated Manager access required';end if;
 select * into b from public.crm_boq_debit_postings where preparation_id=p_preparation;
 if b.id is not null then
  if b.review_id is distinct from p_review then raise exception 'Exact posted approval receipt required';end if;
  return jsonb_build_object('posting',to_jsonb(b)||jsonb_build_object('number',(select number from public.invoices where id=b.supplementary_invoice_id)));
 end if;
 return portal_private.boq_debit_preview(p_preparation,p_review,p_details);
end$$;
create function public.post_boq_debit(p_id uuid,p_preparation uuid,p_review uuid,p_details jsonb,p_expected jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare old public.crm_boq_debit_postings;s jsonb;req jsonb;inv public.invoices;original public.invoices;p public.crm_boq_adjustment_preparations;x jsonb;idx integer:=0;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Current Accounts posting access required';end if;
 if p_id is null or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Posting ID and actual client-visible reason required';end if;
 req:=jsonb_build_object('preparation',p_preparation,'review',p_review,'details',p_details,'expected',p_expected,'reason',trim(p_reason));
 select * into old from public.crm_boq_debit_postings where id=p_id;
 if old.id is not null then
  if old.request=req and old.issued_by=auth.uid() then return old.id;end if;raise exception 'Posting ID already has different immutable evidence';
 end if;
 s:=portal_private.boq_debit_preview(p_preparation,p_review,p_details);
 if s is distinct from p_expected then raise exception 'Source or payment details changed; load a fresh debit preview';end if;
 select * into p from public.crm_boq_adjustment_preparations where id=p_preparation;
 select * into original from public.invoices where id=p.invoice_id;
 insert into public.invoices(company_id,company_name,currency,issued_on,due_on,notes,bank_instructions,subtotal,tax_total,total,author_id)
 values(original.company_id,original.company_name,'PKR',(s->'details'->>'issued_on')::date,(s->'details'->>'due_on')::date,
  'Supplementary invoice for '||original.number||' · change order '||(p.snapshot->'source'->>'change_id')||E'\n'||trim(p_reason),s->'details'->>'bank_instructions',
  (p.snapshot->>'net')::numeric,(p.snapshot->>'tax')::numeric,(p.snapshot->>'gross')::numeric,auth.uid()) returning * into inv;
 for x in select value from jsonb_array_elements(p.snapshot->'lines') loop
  idx:=idx+1;insert into public.invoice_items(invoice_id,description,quantity,unit_price,tax_percent,net,tax,position)
  values(inv.id,x->>'description',1,(x->>'net')::numeric,(x->>'tax_percent')::numeric,(x->>'net')::numeric,(x->>'tax')::numeric,idx);
 end loop;
 insert into public.fin_invoice_projects(id,project_id,linked_by) values(inv.id,p.project_id,auth.uid());
 update public.invoices set status='Issued' where id=inv.id returning * into inv;
 insert into public.crm_boq_debit_postings(id,preparation_id,review_id,invoice_id,supplementary_invoice_id,company_id,project_id,request,receipt,reason,issued_by)
 values(p_id,p.id,p_review,p.invoice_id,inv.id,inv.company_id,p.project_id,req,s||jsonb_build_object('issued_invoice',to_jsonb(inv)),trim(p_reason),auth.uid());
 perform portal_private.record_adjustment_wht(p.id,p_review,'Supplementary invoice',inv.id);
 insert into public.billing_events(invoice_id,action,detail,actor_id) values(inv.id,'BOQ supplementary invoice issued','Original '||original.number||' · change order '||(p.snapshot->'source'->>'change_id'),auth.uid());
 return p_id;
end$$;
-- Extend the previously prepared credit flow without changing its balance/capacity/pending-claim safeguards.
create or replace function portal_private.boq_credit_preview(p_preparation uuid,p_review uuid) returns jsonb language plpgsql set search_path='' as $$
declare p public.crm_boq_adjustment_preparations;r public.crm_boq_adjustment_reviews;i public.invoices;s jsonb;lines jsonb;x jsonb;remaining numeric;paid numeric;credits numeric;unpaid numeric;gross numeric;
begin
 select * into p from public.crm_boq_adjustment_preparations where id=p_preparation;
 select * into r from public.crm_boq_adjustment_reviews where preparation_id=p.id;
 if p.id is null or r.id is distinct from p_review or r.outcome is distinct from 'Approved' or r.receipt->'preparation' is distinct from to_jsonb(p) then raise exception 'Exact immutable Manager-Approved preparation required';end if;
 if p.snapshot->>'kind' is distinct from 'Credit note' then raise exception 'Approved credit preparation required';end if;
 perform portal_private.approved_adjustment(p_preparation,p_review);
 perform 1 from public.companies where id=(p.snapshot->'source'->>'company_id')::uuid for update;
 select jsonb_agg(jsonb_build_object('item_id',a->>'item_id','net',a->>'net') order by a->>'item_id') into lines from jsonb_array_elements(p.snapshot->'lines') a;
 s:=portal_private.boq_adjustment_preview(p.publication_id,p.invoice_id,lines,p.snapshot->'manual_wht');
 if s is distinct from p.snapshot then raise exception 'Approved economic source changed; posting requires reconciliation';end if;
 if exists(select 1 from public.crm_boq_credit_postings where preparation_id=p.id) then raise exception 'Approved preparation already posted';end if;
 select * into i from public.invoices where id=p.invoice_id for update;
 if exists(select 1 from public.payment_claims where invoice_id=i.id and status='Pending') then raise exception 'Resolve pending payment claims before credit posting';end if;
 if exists(select 1 from public.credit_notes where invoice_id=i.id and status='Issued' and boq_posting_id is null) then raise exception 'Existing unmapped credit or client-credit settlement requires separate reconciliation';end if;
 for x in select value from jsonb_array_elements(s->'lines') loop
  select l.net-coalesce((select sum((a->>'net')::numeric) from public.crm_boq_credit_postings b cross join lateral jsonb_array_elements(b.receipt->'preparation'->'snapshot'->'lines') a where b.invoice_id=i.id and a->>'item_id'=l.id::text),0)
   into remaining from public.invoice_items l where l.id=(x->>'item_id')::uuid;
  if remaining is null or remaining<(x->>'net')::numeric then raise exception 'Original invoice-line credit capacity already consumed';end if;
 end loop;
 select coalesce(sum(amount),0) into paid from public.payment_claims where invoice_id=i.id and status='Verified';
 select coalesce(sum(amount),0) into credits from public.credit_notes where invoice_id=i.id and status='Issued';
 gross:=(s->>'gross')::numeric;
 if gross>i.total-credits then raise exception 'Gross credit exceeds remaining original invoice amount';end if;
 unpaid:=greatest(0,i.total-paid-credits);
 return jsonb_build_object('preparation',to_jsonb(p),'review',to_jsonb(r),'invoice',to_jsonb(i),'verified_paid',paid,'prior_issued_credits',credits,
  'verified_payments',coalesce((select jsonb_agg(to_jsonb(c) order by c.id) from public.payment_claims c where invoice_id=i.id and status='Verified'),'[]'::jsonb),'prior_credit_notes',coalesce((select jsonb_agg(to_jsonb(c) order by c.id) from public.credit_notes c where invoice_id=i.id and status='Issued'),'[]'::jsonb),'unpaid_before',unpaid,'gross',gross,'invoice_balance_reduction',least(gross,unpaid),'client_credit',greatest(0,gross-unpaid),'currency','PKR');
end$$;
alter function public.post_boq_credit(uuid,uuid,uuid,jsonb,text) rename to post_boq_credit_before_wht;
revoke all on function public.post_boq_credit_before_wht(uuid,uuid,uuid,jsonb,text) from public,anon,authenticated;
create function public.post_boq_credit(p_id uuid,p_preparation uuid,p_review uuid,p_expected jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare id uuid;
begin
 id:=public.post_boq_credit_before_wht(p_id,p_preparation,p_review,p_expected,p_reason);
 perform portal_private.record_adjustment_wht(p_preparation,p_review,'Credit note',id);return id;
end$$;
create function portal_private.debit_invoice_guard() returns trigger language plpgsql security definer set search_path='' as $$
declare src uuid;dest uuid;
begin
 if tg_table_name='invoices' then
  if exists(select 1 from public.crm_boq_debit_postings where invoice_id=old.id or supplementary_invoice_id=old.id) then raise exception 'Original and supplementary issued invoices are immutable';end if;
 elsif tg_table_name='fin_invoice_projects' then
  if tg_op<>'INSERT' then src:=old.id;end if;if tg_op<>'DELETE' then dest:=new.id;end if;
  if exists(select 1 from public.crm_boq_debit_postings b where b.supplementary_invoice_id in(src,dest) or b.invoice_id in(src,dest)) or exists(select 1 from public.crm_boq_credit_postings where invoice_id in(src,dest)) or exists(select 1 from public.fin_client_credit_applications where invoice_id in(src,dest)) then raise exception 'Posted BOQ invoice project links are immutable';end if;
 else
  if tg_op<>'INSERT' then src:=old.invoice_id;end if;if tg_op<>'DELETE' then dest:=new.invoice_id;end if;
  perform 1 from public.invoices where id in(src,dest) order by id for update;
  if exists(select 1 from public.crm_boq_debit_postings where invoice_id in(src,dest) or supplementary_invoice_id in(src,dest)) then raise exception 'Original and supplementary issued invoice lines are immutable';end if;
 end if;
 if tg_op='DELETE' then return old;end if;return new;
end$$;
create trigger boq_debit_invoice_guard before update or delete on public.invoices for each row execute function portal_private.debit_invoice_guard();
create trigger boq_debit_items_guard before insert or update or delete on public.invoice_items for each row execute function portal_private.debit_invoice_guard();
create trigger boq_debit_project_guard before insert or update or delete on public.fin_invoice_projects for each row execute function portal_private.debit_invoice_guard();
create function public.boq_debit_wht_ledger() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare internal boolean:=portal_private.adjustment_access();company uuid;
begin
 if not internal then
  select company_id into company from public.profiles where id=auth.uid() and active and role='client';
  if company is null then raise exception 'Current Accounts, designated Manager or own-company client access required';end if;
 end if;
 return jsonb_build_object('documents',coalesce((select jsonb_agg(jsonb_build_object('id',b.id,'invoice_id',i.id,'number',i.number,'original_number',o.number,'change_id',p.snapshot->'source'->>'change_id','title',p.snapshot->'source'->'client_data'->>'title','reason',b.reason,'currency',i.currency,'net',i.subtotal,'tax',i.tax_total,'gross',i.total,'issued_on',i.issued_on,'due_on',i.due_on,'bank_instructions',i.bank_instructions,'lines',p.snapshot->'lines','issued_by',b.issued_by,'issued_at',b.issued_at)
  ||case when internal then jsonb_build_object('private_receipt',b.receipt) else '{}'::jsonb end order by b.issued_at,b.id)
  from public.crm_boq_debit_postings b join public.invoices i on i.id=b.supplementary_invoice_id join public.invoices o on o.id=b.invoice_id join public.crm_boq_adjustment_preparations p on p.id=b.preparation_id where internal or (b.company_id=company and public.can_invoice(i.id))),'[]'::jsonb),
 'wht',coalesce((select jsonb_agg(jsonb_build_object('id',w.id,'document_type',w.document_type,'document_id',w.document_id,'number',case when w.document_type='Credit note' then n.number else i.number end,'original_number',o.number,'amount',w.amount,'certificate_reference',w.certificate_reference,'recorded_by',w.recorded_by,'recorded_at',w.recorded_at,'effect','Manual tax evidence only; no automatic WHT reversal, cash or invoice-balance settlement')
  ||case when internal then jsonb_build_object('private_receipt',w.receipt) else '{}'::jsonb end order by w.recorded_at,w.id)
  from public.fin_boq_wht_adjustments w join public.invoices o on o.id=w.invoice_id left join public.credit_notes n on w.document_type='Credit note' and n.id=w.document_id left join public.invoices i on w.document_type='Supplementary invoice' and i.id=w.document_id where internal or (w.company_id=company and public.can_invoice(o.id))),'[]'::jsonb));
end$$;
revoke all on function portal_private.approved_adjustment(uuid,uuid),portal_private.record_adjustment_wht(uuid,uuid,text,uuid),portal_private.boq_debit_preview(uuid,uuid,jsonb),portal_private.debit_invoice_guard() from public,anon,authenticated;
revoke all on function public.preview_boq_debit_posting(uuid,uuid,jsonb),public.post_boq_debit(uuid,uuid,uuid,jsonb,jsonb,text),public.post_boq_credit(uuid,uuid,uuid,jsonb,text),public.boq_debit_wht_ledger() from public,anon,authenticated;
grant execute on function public.preview_boq_debit_posting(uuid,uuid,jsonb),public.post_boq_debit(uuid,uuid,uuid,jsonb,jsonb,text),public.post_boq_credit(uuid,uuid,uuid,jsonb,text),public.boq_debit_wht_ledger() to authenticated;
commit;
