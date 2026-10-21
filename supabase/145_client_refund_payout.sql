begin;
-- Record actual approved cash refunds atomically with consumption of carried PKR client credit. No bank dispatch.
create sequence public.client_refund_payout_numbers;
create table public.fin_client_refund_payouts(
 id uuid primary key,number text not null unique default ('RFND-'||lpad(nextval('public.client_refund_payout_numbers')::text,6,'0')),
 request_id uuid not null unique references public.fin_client_refund_requests,review_id uuid not null unique references public.fin_client_refund_reviews,
 origin_id uuid not null references public.crm_boq_credit_postings,company_id uuid not null references public.companies,project_id uuid not null references public.projects,
 amount numeric(14,2) not null check(amount>0 and amount<100000000),paid_on date not null,method text not null check(method in ('Cash','Bank transfer','Cheque','Mobile wallet')),
 reference text not null check(length(trim(reference)) between 1 and 160),evidence text not null check(length(trim(evidence)) between 3 and 2000),
 request jsonb not null,receipt jsonb not null,recorded_by uuid not null references public.profiles,recorded_at timestamptz not null default now()
);
create index refund_payout_origin on public.fin_client_refund_payouts(origin_id);
create index refund_payout_company on public.fin_client_refund_payouts(company_id);
create index refund_payout_project on public.fin_client_refund_payouts(project_id);
create index refund_payout_actor on public.fin_client_refund_payouts(recorded_by);
alter table public.fin_client_refund_payouts enable row level security;
revoke all on public.fin_client_refund_payouts from public,anon,authenticated;
grant select on public.fin_client_refund_payouts to authenticated;
create policy refund_payout_private_read on public.fin_client_refund_payouts for select to authenticated using(portal_private.refund_access());
create trigger refund_payout_immutable before update or delete on public.fin_client_refund_payouts for each row execute function portal_private.boq_line_evidence_immutable();
alter function portal_private.refund_credit_basis(uuid) rename to refund_credit_basis_before_payout;
revoke all on function portal_private.refund_credit_basis_before_payout(uuid) from public,anon,authenticated;
create function portal_private.refund_credit_basis(p_origin uuid) returns jsonb language plpgsql set search_path='' as $$
declare b jsonb;n numeric;rows jsonb;
begin
 b:=portal_private.refund_credit_basis_before_payout(p_origin);
 select coalesce(sum(amount),0),coalesce(jsonb_agg(jsonb_build_object('id',id,'number',number,'amount',amount,'paid_on',paid_on,'recorded_at',recorded_at) order by id),'[]'::jsonb) into n,rows from public.fin_client_refund_payouts where origin_id=p_origin;
 return b||jsonb_build_object('available',(b->>'available')::numeric-n)||case when n>0 then jsonb_build_object('payouts',rows) else '{}'::jsonb end;
end$$;
create function portal_private.refund_payout_basis(p_request uuid) returns jsonb language plpgsql set search_path='' as $$
declare r public.fin_client_refund_requests;v public.fin_client_refund_reviews;s jsonb;
begin
 select * into r from public.fin_client_refund_requests where id=p_request;
 select * into v from public.fin_client_refund_reviews where request_id=r.id;
 if r.id is null or v.outcome is distinct from 'Approved' or v.receipt->'expected'->'request' is distinct from to_jsonb(r) then raise exception 'Exact actual client request and Owner/Director approval required';end if;
 perform 1 from public.companies where id=r.company_id for update;
 if exists(select 1 from public.fin_client_refund_payouts where request_id=r.id) then raise exception 'Approved refund already paid/recorded';end if;
 if not exists(select 1 from public.profiles where id=r.requested_by and active and role='client' and company_id=r.company_id) then raise exception 'Requesting client is no longer eligible';end if;
 if v.receipt->'designation' is distinct from (select to_jsonb(d) from public.fin_refund_approver_designations d where id=v.designation_id and user_id=v.reviewed_by and active) then raise exception 'Immutable actual Owner/Director approval evidence required';end if;
 s:=portal_private.refund_credit_basis(r.origin_id);
 if s is distinct from v.receipt->'expected'->'credit' or r.amount>(s->>'available')::numeric then raise exception 'Approval credit basis changed; a fresh actual request/approval is required';end if;
 return jsonb_build_object('request',to_jsonb(r),'review',to_jsonb(v),'credit',s,'amount',r.amount,'currency','PKR','direction','Out');
end$$;
create function public.preview_client_refund_payout(p_request uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare p public.fin_client_refund_payouts;
begin
 if not portal_private.refund_access() then raise exception 'Current Accounts or designated Owner/Director access required';end if;
 select * into p from public.fin_client_refund_payouts where request_id=p_request;
 if p.id is not null then return jsonb_build_object('payout',to_jsonb(p));end if;
 return portal_private.refund_payout_basis(p_request);
end$$;
create function public.record_client_refund_payout(p_id uuid,p_request uuid,p_expected jsonb,p_details jsonb,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$
declare old public.fin_client_refund_payouts;s jsonb;req jsonb;paid date;origin public.crm_boq_credit_postings;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Current Accounts payout recording access required';end if;
 if p_id is null or p_confirm is distinct from true then raise exception 'Actual completed refund payment confirmation required';end if;
 if jsonb_typeof(p_details) is distinct from 'object' or (select count(*) from jsonb_object_keys(p_details))<>4 or not(p_details ?& array['paid_on','method','reference','evidence'])
  or coalesce(p_details->>'paid_on','') !~ '^\d{4}-\d{2}-\d{2}$' or coalesce(p_details->>'method','') not in ('Cash','Bank transfer','Cheque','Mobile wallet')
  or jsonb_typeof(p_details->'reference') is distinct from 'string' or length(trim(p_details->>'reference')) not between 1 and 160
  or jsonb_typeof(p_details->'evidence') is distinct from 'string' or length(trim(p_details->>'evidence')) not between 3 and 2000 then raise exception 'Actual payment date, method, reference and private evidence reference required';end if;
 paid:=(p_details->>'paid_on')::date;
 req:=jsonb_build_object('request',p_request,'expected',p_expected,'details',p_details,'confirmed',true);
 select * into old from public.fin_client_refund_payouts where id=p_id;
 if old.id is not null then
  if old.request=req and old.recorded_by=auth.uid() then return old.id;end if;raise exception 'Payout ID already has different immutable evidence';
 end if;
 s:=portal_private.refund_payout_basis(p_request);
 if s is distinct from p_expected then raise exception 'Exact current approved refund payout evidence required';end if;
 if not isfinite(paid) or paid>(now() at time zone 'Asia/Karachi')::date or paid<((s->'review'->>'reviewed_at')::timestamptz at time zone 'Asia/Karachi')::date then raise exception 'Actual nonfuture payment date on/after refund approval required';end if;
 select * into origin from public.crm_boq_credit_postings where id=(s->'request'->>'origin_id')::uuid;
 insert into public.fin_client_refund_payouts(id,request_id,review_id,origin_id,company_id,project_id,amount,paid_on,method,reference,evidence,request,receipt,recorded_by)
 values(p_id,p_request,(s->'review'->>'id')::uuid,origin.id,origin.company_id,origin.project_id,(s->>'amount')::numeric,paid,p_details->>'method',trim(p_details->>'reference'),trim(p_details->>'evidence'),req,s||jsonb_build_object('available_after',(s->'credit'->>'available')::numeric-(s->>'amount')::numeric),auth.uid());
 return p_id;
end$$;
alter function public.client_refund_access() rename to client_refund_access_before_payout;
revoke all on function public.client_refund_access_before_payout() from public,anon,authenticated;
create function public.client_refund_access() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin return public.client_refund_access_before_payout()||jsonb_build_object('pay',portal_private.payables_access());end$$;
alter function public.client_refund_register() rename to client_refund_register_before_payout;
revoke all on function public.client_refund_register_before_payout() from public,anon,authenticated;
create function public.client_refund_register() returns jsonb language plpgsql security definer set search_path='' as $$
declare d jsonb;rows jsonb;internal boolean:=portal_private.refund_access();
begin
 d:=public.client_refund_register_before_payout();
 select coalesce(jsonb_agg(r||jsonb_build_object('payout',case when p.id is null then null else jsonb_build_object('id',p.id,'number',p.number,'amount',p.amount,'paid_on',p.paid_on,'method',p.method,'reference',p.reference,'recorded_by',p.recorded_by,'recorded_at',p.recorded_at)||case when internal then jsonb_build_object('private_evidence',p.evidence,'private_receipt',p.receipt) else '{}'::jsonb end end) order by r->>'requested_at',r->>'id'),'[]'::jsonb) into rows from jsonb_array_elements(d->'requests') r left join public.fin_client_refund_payouts p on p.request_id=(r->>'id')::uuid;
 return d||jsonb_build_object('requests',rows);
end$$;
create or replace function portal_private.apply_future_client_credit() returns trigger language plpgsql security definer set search_path='' as $$
declare lot record;needed numeric;available numeric;n numeric;app uuid;note uuid;num text;
begin
 if new.status<>'Issued' or (tg_op='UPDATE' and old.status='Issued') then return new;end if;
 perform 1 from public.companies where id=new.company_id for update;
 if new.currency<>'PKR' then return new;end if;
 needed:=greatest(0,new.total-coalesce((select sum(amount) from public.payment_claims where invoice_id=new.id and status in ('Pending','Verified')),0)-coalesce((select sum(amount) from public.credit_notes where invoice_id=new.id and status='Issued'),0));
 -- Stable chronological provenance for fungible same-company/currency credit; no expiry/priority policy.
 for lot in select b.*,b.client_credit-coalesce((select sum(a.amount) from public.fin_client_credit_applications a where a.origin_id=b.id),0)-coalesce((select sum(p.amount) from public.fin_client_refund_payouts p where p.origin_id=b.id),0) available
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
create or replace function public.boq_client_credit_ledger() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare internal boolean:=portal_private.adjustment_access();company uuid;
begin
 if not internal then
  select company_id into company from public.profiles where id=auth.uid() and active and role='client';
  if company is null then raise exception 'Current Accounts, designated Manager or own-company client access required';end if;
 end if;
 return jsonb_build_object('balances',coalesce((select jsonb_agg(to_jsonb(x) order by x.company_id) from
  (select b.company_id,c.name company,'PKR' currency,sum(b.client_credit) created,sum(b.client_credit-coalesce(a.used,0)-coalesce(f.paid,0)) available,sum(coalesce(f.paid,0)) refunded
   from public.crm_boq_credit_postings b join public.companies c on c.id=b.company_id left join lateral(select sum(amount) used from public.fin_client_credit_applications where origin_id=b.id) a on true left join lateral(select sum(amount) paid from public.fin_client_refund_payouts where origin_id=b.id) f on true
   where internal or b.company_id=company group by b.company_id,c.name)x),'[]'::jsonb),
 'documents',coalesce((select jsonb_agg(jsonb_build_object('id',b.id,'number',n.number,'company_id',b.company_id,'invoice_id',i.id,'invoice_number',i.number,'change_id',p.snapshot->'source'->>'change_id','client_title',p.snapshot->'source'->'client_data'->>'title','currency','PKR','net',p.snapshot->'net','tax',p.snapshot->'tax','gross',b.gross,'lines',p.snapshot->'lines','balance_reduction',b.invoice_balance_reduction,'client_credit',b.client_credit,'reason',b.reason,'issued_by',b.issued_by,'issued_at',b.issued_at)
 ||case when internal then jsonb_build_object('private_receipt',b.receipt) else '{}'::jsonb end order by b.issued_at,b.id)
 from public.crm_boq_credit_postings b join public.crm_boq_adjustment_preparations p on p.id=b.preparation_id join public.credit_notes n on n.id=b.credit_note_id join public.invoices i on i.id=b.invoice_id where internal or (b.company_id=company and public.can_invoice(i.id))),'[]'::jsonb),
 'applications',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'number',a.number,'company_id',a.company_id,'source_number',n.number,'invoice_id',i.id,'invoice_number',i.number,'amount',a.amount,'currency','PKR','applied_by',a.applied_by,'applied_at',a.applied_at,'purpose','Settlement only; no additional tax credit or cash movement') order by a.applied_at,a.id)
 from public.fin_client_credit_applications a join public.crm_boq_credit_postings b on b.id=a.origin_id join public.credit_notes n on n.id=b.credit_note_id join public.invoices i on i.id=a.invoice_id where internal or (a.company_id=company and public.can_invoice(i.id))),'[]'::jsonb));
end$$;
alter function public.finance_dashboard() rename to finance_dashboard_before_refund_payout;
revoke all on function public.finance_dashboard_before_refund_payout() from public,anon,authenticated;
create function public.finance_dashboard() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare d jsonb;n numeric;months jsonb;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Accounts access required';end if;
 d:=public.finance_dashboard_before_refund_payout();select coalesce(sum(amount),0) into n from public.fin_client_refund_payouts;
 select coalesce(jsonb_agg(to_jsonb(t) order by t.month_key desc,t.currency),'[]'::jsonb) into months from (
 select month_key,currency,sum(customer_in) customer_in,sum(supplier_out) supplier_out,sum(expense_out) expense_out,sum(loan_in) loan_in,sum(loan_out) loan_out,sum(refund_out) refund_out from (
 select r->>'month_key' month_key,r->>'currency' currency,coalesce((r->>'customer_in')::numeric,0) customer_in,coalesce((r->>'supplier_out')::numeric,0) supplier_out,coalesce((r->>'expense_out')::numeric,0) expense_out,coalesce((r->>'loan_in')::numeric,0) loan_in,coalesce((r->>'loan_out')::numeric,0) loan_out,0::numeric refund_out from jsonb_array_elements(d->'cash_by_month') r
 union all select to_char(paid_on,'YYYY-MM'),'PKR',0,0,0,0,0,amount from public.fin_client_refund_payouts) movements group by month_key,currency)t;
 return d||jsonb_build_object('available_client_credit',(d->>'available_client_credit')::numeric-n,'pkr_net_trade_position',(d->>'pkr_net_trade_position')::numeric+n,'client_refund_cash_out',n,'cash_by_month',months,'note',(d->>'note')||' Actual approved client refunds reduce remaining credit liability once and are separate cash outflows, not expense/loan costs or new invoice credits.');
end$$;
alter function public.project_financials(uuid) rename to project_financials_before_refund_payout;
revoke all on function public.project_financials_before_refund_payout(uuid) from public,anon,authenticated;
create function public.project_financials(p_project uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare d jsonb;n numeric;
begin
 d:=public.project_financials_before_refund_payout(p_project);
 select coalesce(sum(amount),0) into n from public.fin_client_refund_payouts where project_id=p_project;
 return d||jsonb_build_object('customer_refund_cash_out',n,'operating_cash_position',(d->>'operating_cash_position')::numeric-n,'cash_position_including_loans',(d->>'cash_position_including_loans')::numeric-n,'note',(d->>'note')||' Actual client refunds are separate cash outflows, attributed to the original credit project; they do not add work costs or change gross verified receipts.');
end$$;
revoke all on function portal_private.refund_credit_basis(uuid),portal_private.refund_payout_basis(uuid) from public,anon,authenticated;
revoke all on function public.preview_client_refund_payout(uuid),public.record_client_refund_payout(uuid,uuid,jsonb,jsonb,boolean),public.client_refund_access(),public.client_refund_register(),public.boq_client_credit_ledger(),public.finance_dashboard(),public.project_financials(uuid) from public,anon,authenticated;
grant execute on function public.preview_client_refund_payout(uuid),public.record_client_refund_payout(uuid,uuid,jsonb,jsonb,boolean),public.client_refund_access(),public.client_refund_register(),public.boq_client_credit_ledger(),public.finance_dashboard(),public.project_financials(uuid) to authenticated;
commit;
