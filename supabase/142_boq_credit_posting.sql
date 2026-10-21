begin;
-- Approved credit-note posting and same-company PKR settlement credit. No cash/refund/WHT/debit posting.
create table public.crm_boq_credit_postings (
 id uuid primary key,preparation_id uuid not null unique references public.crm_boq_adjustment_preparations,
 review_id uuid not null unique references public.crm_boq_adjustment_reviews,invoice_id uuid not null references public.invoices,
 company_id uuid not null references public.companies,project_id uuid not null references public.projects,
 credit_note_id uuid not null unique references public.credit_notes deferrable initially deferred,
 gross numeric(14,2) not null check(gross>0),invoice_balance_reduction numeric(14,2) not null check(invoice_balance_reduction>=0),
 client_credit numeric(14,2) not null check(client_credit>=0),request jsonb not null,receipt jsonb not null,
 reason text not null check(length(trim(reason)) between 3 and 2000),issued_by uuid not null references public.profiles,
 issued_at timestamptz not null default now(),check(gross=invoice_balance_reduction+client_credit)
);
create index boq_credit_invoice on public.crm_boq_credit_postings(invoice_id);
create index boq_credit_company on public.crm_boq_credit_postings(company_id);
create index boq_credit_project on public.crm_boq_credit_postings(project_id);
create index boq_credit_actor on public.crm_boq_credit_postings(issued_by);
create sequence public.client_credit_application_numbers;
create table public.fin_client_credit_applications (
 id uuid primary key,number text not null unique,origin_id uuid not null references public.crm_boq_credit_postings,
 invoice_id uuid not null references public.invoices,credit_note_id uuid not null unique references public.credit_notes deferrable initially deferred,
 company_id uuid not null references public.companies,amount numeric(14,2) not null check(amount>0),
 receipt jsonb not null,applied_by uuid not null references public.profiles,applied_at timestamptz not null default now(),unique(origin_id,invoice_id)
);
create index client_credit_application_invoice on public.fin_client_credit_applications(invoice_id);
create index client_credit_application_company on public.fin_client_credit_applications(company_id);
create index client_credit_application_actor on public.fin_client_credit_applications(applied_by);
alter table public.credit_notes add column boq_posting_id uuid unique references public.crm_boq_credit_postings,
 add column client_credit_application_id uuid unique references public.fin_client_credit_applications,
 add constraint credit_purpose_pair check(boq_posting_id is null or client_credit_application_id is null);
do $$declare t text;begin
 foreach t in array array['crm_boq_credit_postings','fin_client_credit_applications'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on public.%I from public,anon,authenticated',t);
  execute format('grant select on public.%I to authenticated',t);
  execute format('create policy private_credit_read on public.%I for select to authenticated using(portal_private.adjustment_access())',t);
  execute format('create trigger credit_evidence_immutable before update or delete on public.%I for each row execute function portal_private.boq_line_evidence_immutable()',t);
 end loop;
end$$;

create function portal_private.boq_credit_preview(p_preparation uuid,p_review uuid) returns jsonb language plpgsql set search_path='' as $$
declare p public.crm_boq_adjustment_preparations;r public.crm_boq_adjustment_reviews;i public.invoices;s jsonb;lines jsonb;x jsonb;remaining numeric;paid numeric;credits numeric;unpaid numeric;gross numeric;
begin
 select * into p from public.crm_boq_adjustment_preparations where id=p_preparation;
 select * into r from public.crm_boq_adjustment_reviews where preparation_id=p.id;
 if p.id is null or r.id is distinct from p_review or r.outcome is distinct from 'Approved' or r.receipt->'preparation' is distinct from to_jsonb(p) then raise exception 'Exact immutable Manager-Approved preparation required';end if;
 if p.snapshot->>'kind' is distinct from 'Credit note' or p.snapshot->'manual_wht' is distinct from 'null'::jsonb then raise exception 'Only credit preparations without a manual WHT adjustment are supported for posting';end if;
 perform 1 from public.companies where id=(p.snapshot->'source'->>'company_id')::uuid for update;
 select jsonb_agg(jsonb_build_object('item_id',a->>'item_id','net',a->>'net') order by a->>'item_id') into lines from jsonb_array_elements(p.snapshot->'lines') a;
 s:=portal_private.boq_adjustment_preview(p.publication_id,p.invoice_id,lines,null);
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
create function public.preview_boq_credit_posting(p_preparation uuid,p_review uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare b public.crm_boq_credit_postings;
begin
 if not portal_private.adjustment_access() then raise exception 'Current Accounts or designated Manager access required';end if;
 select * into b from public.crm_boq_credit_postings where preparation_id=p_preparation;
 if b.id is not null then
  if b.review_id is distinct from p_review then raise exception 'Exact posted approval receipt required';end if;
  return jsonb_build_object('posting',to_jsonb(b)||jsonb_build_object('number',(select number from public.credit_notes where id=b.credit_note_id)));
 end if;
 return portal_private.boq_credit_preview(p_preparation,p_review);
end$$;
create function public.post_boq_credit(p_id uuid,p_preparation uuid,p_review uuid,p_expected jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare old public.crm_boq_credit_postings;s jsonb;req jsonb;note public.credit_notes;p public.crm_boq_adjustment_preparations;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Current Accounts posting access required';end if;
 if p_id is null or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Posting ID and actual client-visible credit-note reason required';end if;
 req:=jsonb_build_object('preparation',p_preparation,'review',p_review,'expected',p_expected,'reason',trim(p_reason));
 select * into old from public.crm_boq_credit_postings where id=p_id;
 if old.id is not null then
  if old.request=req and old.issued_by=auth.uid() then return old.id;end if;
  raise exception 'Posting ID already has different immutable evidence';
 end if;
 s:=portal_private.boq_credit_preview(p_preparation,p_review);
 if s is distinct from p_expected then raise exception 'Payment or source changed; review the current posting preview again';end if;
 select * into p from public.crm_boq_adjustment_preparations where id=p_preparation;
 insert into public.crm_boq_credit_postings(id,preparation_id,review_id,invoice_id,company_id,project_id,credit_note_id,gross,invoice_balance_reduction,client_credit,request,receipt,reason,issued_by)
 values(p_id,p.id,p_review,p.invoice_id,(s->'invoice'->>'company_id')::uuid,p.project_id,p_id,(s->>'gross')::numeric,(s->>'invoice_balance_reduction')::numeric,(s->>'client_credit')::numeric,req,s,trim(p_reason),auth.uid());
 insert into public.credit_notes(id,invoice_id,amount,reason,boq_posting_id) values(p_id,p.invoice_id,(s->>'gross')::numeric,trim(p_reason),p_id) returning * into note;
 insert into public.billing_events(invoice_id,action,detail,actor_id) values(p.invoice_id,'BOQ credit note issued',note.number||' · change order '||(p.snapshot->'source'->>'change_id'),auth.uid());
 return p_id;
end$$;

create function portal_private.apply_future_client_credit() returns trigger language plpgsql security definer set search_path='' as $$
declare lot record;needed numeric;available numeric;n numeric;app uuid;note uuid;num text;
begin
 if new.status<>'Issued' or (tg_op='UPDATE' and old.status='Issued') then return new;end if;
 perform 1 from public.companies where id=new.company_id for update;
 if new.currency<>'PKR' then return new;end if;
 needed:=greatest(0,new.total-coalesce((select sum(amount) from public.payment_claims where invoice_id=new.id and status in ('Pending','Verified')),0)-coalesce((select sum(amount) from public.credit_notes where invoice_id=new.id and status='Issued'),0));
 -- Stable chronological provenance for fungible same-company/currency credit; no expiry/priority policy.
 for lot in select b.*,b.client_credit-coalesce((select sum(a.amount) from public.fin_client_credit_applications a where a.origin_id=b.id),0) available
  from public.crm_boq_credit_postings b where b.company_id=new.company_id and b.client_credit>0 order by b.issued_at,b.id loop
  exit when needed<=0;
  available:=lot.available;if available<=0 then continue;end if;
  if auth.uid() is null or not public.is_staff() then raise exception 'Actual current internal issuer required for automatic client-credit application';end if;
  n:=least(needed,available);app:=gen_random_uuid();note:=gen_random_uuid();num:='CCA-'||lpad(nextval('public.client_credit_application_numbers')::text,6,'0');
  insert into public.fin_client_credit_applications(id,number,origin_id,invoice_id,credit_note_id,company_id,amount,receipt,applied_by)
  values(app,num,lot.id,new.id,note,new.company_id,n,jsonb_build_object('source_credit_note',lot.credit_note_id,'source_posting',lot.id,'source_invoice',lot.invoice_id,'target_invoice',to_jsonb(new),'available_before',available,'outstanding_before',needed,'purpose','Settlement only; no additional tax credit or cash movement'),auth.uid());
  insert into public.credit_notes(id,invoice_id,number,amount,reason,client_credit_application_id)
   values(note,new.id,num,n,'Client credit applied from '||(select number from public.credit_notes where id=lot.credit_note_id),app);
  insert into public.billing_events(invoice_id,action,detail,actor_id) values(new.id,'Client credit applied',num||' · PKR '||n,auth.uid());
  needed:=needed-n;
 end loop;return new;
end$$;
create trigger apply_future_client_credit after insert or update of status on public.invoices for each row execute function portal_private.apply_future_client_credit();

create function portal_private.credit_posting_protect() returns trigger language plpgsql security definer set search_path='' as $$
declare src uuid;dest uuid;p public.crm_boq_credit_postings;a public.fin_client_credit_applications;
begin
 if tg_table_name='credit_notes' then
  if tg_op<>'INSERT' and (old.boq_posting_id is not null or old.client_credit_application_id is not null) then raise exception 'Posted BOQ credit and client-credit settlement evidence is immutable';end if;
  if tg_op='UPDATE' and (new.boq_posting_id is not null or new.client_credit_application_id is not null) then raise exception 'Credit provenance cannot be attached to an existing note';end if;
  if tg_op='INSERT' and new.boq_posting_id is not null then
   select * into p from public.crm_boq_credit_postings where id=new.boq_posting_id;
   if p.id is null or p.credit_note_id<>new.id or p.invoice_id<>new.invoice_id or p.gross<>new.amount or new.status<>'Issued' then raise exception 'Exact immutable BOQ credit document required';end if;
  elsif tg_op='INSERT' and new.client_credit_application_id is not null then
   select * into a from public.fin_client_credit_applications where id=new.client_credit_application_id;
   if a.id is null or a.credit_note_id<>new.id or a.invoice_id<>new.invoice_id or a.amount<>new.amount or a.number<>new.number or new.status<>'Issued' then raise exception 'Exact immutable client-credit settlement required';end if;
  end if;
 elsif tg_table_name='payment_claims' then
  if old.status='Verified' and (tg_op='DELETE' or new.status<>'Verified' or new.invoice_id<>old.invoice_id or new.amount<>old.amount)
   and exists(select 1 from public.crm_boq_credit_postings where invoice_id=old.invoice_id and client_credit>0) then raise exception 'Client-credit origin needs separate reconciliation before verified payment reversal or alteration';end if;
 elsif tg_table_name='invoices' then
  if exists(select 1 from public.crm_boq_credit_postings where invoice_id=old.id) or exists(select 1 from public.fin_client_credit_applications where invoice_id=old.id) then raise exception 'Issued invoice with posted BOQ/client credit is immutable';end if;
 else
  if tg_op<>'INSERT' then src:=old.invoice_id;end if;if tg_op<>'DELETE' then dest:=new.invoice_id;end if;
  perform 1 from public.invoices where id in(src,dest) order by id for update;
  if exists(select 1 from public.crm_boq_credit_postings where invoice_id in(src,dest)) or exists(select 1 from public.fin_client_credit_applications where invoice_id in(src,dest)) then raise exception 'Posted invoice lines are immutable';end if;
 end if;
 if tg_op='DELETE' then return old;end if;return new;
end$$;
create trigger posted_credit_guard before insert or update or delete on public.credit_notes for each row execute function portal_private.credit_posting_protect();
create trigger client_credit_payment_guard before update or delete on public.payment_claims for each row execute function portal_private.credit_posting_protect();
create trigger posted_invoice_guard before update or delete on public.invoices for each row execute function portal_private.credit_posting_protect();
create trigger posted_invoice_items_guard before insert or update or delete on public.invoice_items for each row execute function portal_private.credit_posting_protect();

create function public.boq_client_credit_ledger() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare internal boolean:=portal_private.adjustment_access();company uuid;
begin
 if not internal then
  select company_id into company from public.profiles where id=auth.uid() and active and role='client';
  if company is null then raise exception 'Current Accounts, designated Manager or own-company client access required';end if;
 end if;
 return jsonb_build_object('balances',coalesce((select jsonb_agg(to_jsonb(x) order by x.company_id) from
  (select b.company_id,c.name company,'PKR' currency,sum(b.client_credit) created,sum(b.client_credit-coalesce(a.used,0)) available
   from public.crm_boq_credit_postings b join public.companies c on c.id=b.company_id left join lateral(select sum(amount) used from public.fin_client_credit_applications where origin_id=b.id) a on true
   where internal or b.company_id=company group by b.company_id,c.name)x),'[]'::jsonb),
 'documents',coalesce((select jsonb_agg(jsonb_build_object('id',b.id,'number',n.number,'company_id',b.company_id,'invoice_id',i.id,'invoice_number',i.number,'change_id',p.snapshot->'source'->>'change_id','client_title',p.snapshot->'source'->'client_data'->>'title','currency','PKR','net',p.snapshot->'net','tax',p.snapshot->'tax','gross',b.gross,'lines',p.snapshot->'lines','balance_reduction',b.invoice_balance_reduction,'client_credit',b.client_credit,'reason',b.reason,'issued_by',b.issued_by,'issued_at',b.issued_at)
 ||case when internal then jsonb_build_object('private_receipt',b.receipt) else '{}'::jsonb end order by b.issued_at,b.id)
 from public.crm_boq_credit_postings b join public.crm_boq_adjustment_preparations p on p.id=b.preparation_id join public.credit_notes n on n.id=b.credit_note_id join public.invoices i on i.id=b.invoice_id where internal or (b.company_id=company and public.can_invoice(i.id))),'[]'::jsonb),
 'applications',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'number',a.number,'company_id',a.company_id,'source_number',n.number,'invoice_id',i.id,'invoice_number',i.number,'amount',a.amount,'currency','PKR','applied_by',a.applied_by,'applied_at',a.applied_at,'purpose','Settlement only; no additional tax credit or cash movement') order by a.applied_at,a.id)
 from public.fin_client_credit_applications a join public.crm_boq_credit_postings b on b.id=a.origin_id join public.credit_notes n on n.id=b.credit_note_id join public.invoices i on i.id=a.invoice_id where internal or (a.company_id=company and public.can_invoice(i.id))),'[]'::jsonb));
end$$;
alter function public.finance_dashboard() rename to finance_dashboard_before_client_credit;
revoke all on function public.finance_dashboard_before_client_credit() from public,anon,authenticated;
create function public.finance_dashboard() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare d jsonb;available numeric;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Accounts access required';end if;
 d:=public.finance_dashboard_before_client_credit();
 select coalesce(sum(b.client_credit-coalesce(a.used,0)),0) into available from public.crm_boq_credit_postings b left join lateral(select sum(amount) used from public.fin_client_credit_applications where origin_id=b.id)a on true;
 return d||jsonb_build_object('available_client_credit',available,'pkr_net_trade_position',(d->>'pkr_net_trade_position')::numeric-available,'note',(d->>'note')||' Unapplied PKR client credit is a separate liability deducted once from net trade position. Invoice balance credits include settlement applications; applications are not additional tax credit notes.');
end$$;
revoke all on function portal_private.boq_credit_preview(uuid,uuid),portal_private.apply_future_client_credit(),portal_private.credit_posting_protect() from public,anon,authenticated;
revoke all on function public.preview_boq_credit_posting(uuid,uuid),public.post_boq_credit(uuid,uuid,uuid,jsonb,text),public.boq_client_credit_ledger(),public.finance_dashboard() from public,anon,authenticated;
grant execute on function public.preview_boq_credit_posting(uuid,uuid),public.post_boq_credit(uuid,uuid,uuid,jsonb,text),public.boq_client_credit_ledger(),public.finance_dashboard() to authenticated;
commit;
