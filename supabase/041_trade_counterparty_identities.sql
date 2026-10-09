begin;
-- Add existing customer/vendor identities to the same Accounts-only snapshot.
-- Keep document names, balances and authorization unchanged; never infer a payee identity.
create or replace function public.finance_trade_report() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb; business_date date:=(now() at time zone 'Asia/Karachi')::date;
begin
 if not portal_private.payables_access() then raise exception 'Accounts access required';end if;
 with payments as (select invoice_id,sum(amount) paid from public.payment_claims where status='Verified' group by invoice_id),
 credits as (select invoice_id,sum(amount) credit from public.credit_notes where status='Issued' group by invoice_id),
 vendor_paid as (select bill_id,sum(amount) paid from public.sc_vendor_payments where reversed_by is null group by bill_id),
 expense_paid as (select expense_id,sum(amount) paid from public.fin_cash_entries where expense_id is not null and reversed_by is null group by expense_id),
 source as (
  select i.id,'Receivable'::text direction,'Customer invoice'::text kind,i.number,i.company_name counterparty,i.currency,i.issued_on document_date,i.due_on,i.total amount,coalesce(p.paid,0) paid,coalesce(c.credit,0) credits,'Customer'::text counterparty_type,i.company_id counterparty_id,cust.name account_name
  from public.invoices i join public.companies cust on cust.id=i.company_id left join payments p on p.invoice_id=i.id left join credits c on c.invoice_id=i.id where i.status='Issued'
  union all
  select b.id,'Payable','Vendor bill',b.number,v.name,'PKR',b.invoice_date,b.due_date,b.total,coalesce(p.paid,0),0,'Vendor',b.vendor_id,v.name
  from public.sc_bills b join public.sc_vendors v on v.id=b.vendor_id left join vendor_paid p on p.bill_id=b.id where b.status='Approved'
  union all
  select e.id,'Payable','Expense',e.number,e.payee,'PKR',e.incurred_on,e.due_on,e.amount,coalesce(p.paid,0),0,case when e.vendor_id is null then 'Recorded name' else 'Vendor' end,e.vendor_id,coalesce(v.name,e.payee)
  from public.fin_expenses e left join public.sc_vendors v on v.id=e.vendor_id left join expense_paid p on p.expense_id=e.id where e.status='Approved'
 ), balances as (select *,greatest(0,amount-paid-credits) balance from source),
 documents as materialized (
  select *,case when balance=0 then 'Settled' when due_on<business_date then 'Overdue' when due_on=business_date then 'Due today' else 'Not due' end due_status,
   case when balance>0 then greatest(0,business_date-due_on) else 0 end days_overdue,
   case when balance=0 then 'Settled' when due_on>=business_date then 'Current' when business_date-due_on<=30 then '1–30 days' when business_date-due_on<=60 then '31–60 days' when business_date-due_on<=90 then '61–90 days' else '91+ days' end aging_bucket
  from balances
 ), currencies as (select currency from documents union select 'PKR'),
 summaries as (
  select c.currency,coalesce(sum(d.balance) filter(where direction='Receivable'),0) receivable,
   coalesce(sum(d.balance) filter(where direction='Payable'),0) payable,
   coalesce(sum(d.balance) filter(where direction='Receivable' and due_status='Overdue'),0) overdue_receivable,
   coalesce(sum(d.balance) filter(where direction='Payable' and due_status='Overdue'),0) overdue_payable,
   count(d.id) filter(where direction='Receivable' and balance>0) open_receivables,
   count(d.id) filter(where direction='Payable' and balance>0) open_payables
  from currencies c left join documents d on d.currency=c.currency group by c.currency
 ), buckets as (select * from (values(0,'Current'),(1,'1–30 days'),(2,'31–60 days'),(3,'61–90 days'),(4,'91+ days')) b(position,bucket)),
 aging as (
  select c.currency,b.position,b.bucket,coalesce(sum(d.balance) filter(where direction='Receivable'),0) receivable,coalesce(sum(d.balance) filter(where direction='Payable'),0) payable
  from currencies c cross join buckets b left join documents d on d.currency=c.currency and d.aging_bucket=b.bucket group by c.currency,b.position,b.bucket
 ), windows as (select * from (values(0,'Due today',0),(1,'Today through 7 days',7),(2,'Today through 30 days',30)) w(position,period,days)),
 upcoming as (
  select c.currency,w.position,w.period,coalesce(sum(d.balance) filter(where direction='Receivable'),0) receivable,coalesce(sum(d.balance) filter(where direction='Payable'),0) payable
  from currencies c cross join windows w left join documents d on d.currency=c.currency and d.balance>0 and d.due_on between business_date and business_date+w.days group by c.currency,w.position,w.period
 )
 select jsonb_build_object('business_date',business_date,'counterparty_identity_version',1,
  'summary',coalesce((select jsonb_agg(to_jsonb(s)||jsonb_build_object('net_position',s.receivable-s.payable) order by s.currency) from summaries s),'[]'::jsonb),
  'aging',coalesce((select jsonb_agg(to_jsonb(a)-'position' order by a.currency,a.position) from aging a),'[]'::jsonb),
  'upcoming',coalesce((select jsonb_agg(to_jsonb(u)-'position' order by u.currency,u.position) from upcoming u),'[]'::jsonb),
  'documents',coalesce((select jsonb_agg(to_jsonb(d) order by d.due_on,d.direction,d.number) from documents d),'[]'::jsonb),
  'note','Current outstanding trade balances only. Issued customer invoices less verified receipts and issued credits; approved vendor bills and expenses less unreversed payments. Loans and advances are separate. Each currency is separate; no exchange conversion. Upcoming windows include today and overlap; do not add them together. This is a due schedule, not a promise of future cash or a historical balance.') into result;
 return result;
end$$;
revoke all on function public.finance_trade_report() from public,anon,authenticated;
grant execute on function public.finance_trade_report() to authenticated;
commit;
