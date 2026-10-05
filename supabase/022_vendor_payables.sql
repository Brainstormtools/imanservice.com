begin;
-- Purchase bills use PKR material values. Taxes, advances and credit notes have separate future workflows.
create table public.sc_bills(
 id uuid primary key default gen_random_uuid(),number text not null unique default ('BILL-'||lpad(nextval('public.sc_numbers')::text,6,'0')),
 order_id uuid not null references public.sc_orders,vendor_id uuid not null references public.sc_vendors,project_id uuid references public.projects,
 vendor_invoice text not null check(length(trim(vendor_invoice)) between 1 and 160),invoice_date date not null,due_date date not null check(due_date>=invoice_date),
 quantity numeric(12,3) not null check(quantity>0 and quantity<=100000),rate numeric(14,2) not null check(rate>0 and rate<100000000),total numeric(14,2) not null check(total>0),
 evidence text not null check(length(trim(evidence)) between 3 and 2000),note text not null default '' check(length(note)<=2000),
 status text not null default 'Draft' check(status in ('Draft','Held','Matched','Approved','Cancelled')),match_note text not null default '',match_snapshot jsonb,
 matched_by uuid references public.profiles,matched_at timestamptz,approved_by uuid references public.profiles,approved_at timestamptz,
 created_by uuid not null references public.profiles,created_at timestamptz not null default now(),version integer not null default 1
);
create unique index sc_vendor_invoice_unique on public.sc_bills(vendor_id,lower(trim(vendor_invoice)));
create index sc_bill_order on public.sc_bills(order_id);
create index sc_bill_project on public.sc_bills(project_id);
create table public.sc_bill_receipts(id uuid primary key default gen_random_uuid(),bill_id uuid not null references public.sc_bills,receipt_id uuid not null references public.sc_receipts,quantity numeric(12,3) not null check(quantity>0 and quantity<=100000),unique(bill_id,receipt_id));
create table public.sc_vendor_payments(
 id uuid primary key default gen_random_uuid(),number text not null unique default ('VPAY-'||lpad(nextval('public.sc_numbers')::text,6,'0')),
 bill_id uuid not null references public.sc_bills,amount numeric(14,2) not null check(amount>0 and amount<100000000),payment_date date not null,
 method text not null check(method in ('Cash','Bank transfer','Cheque','Mobile wallet')),reference text not null check(length(trim(reference)) between 1 and 160),evidence text not null check(length(trim(evidence)) between 3 and 2000),
 created_by uuid not null references public.profiles,created_at timestamptz not null default now(),reversed_by uuid references public.profiles,reversed_at timestamptz,reversal_reason text check(length(trim(reversal_reason)) between 3 and 2000),
 check((reversed_by is null)=(reversed_at is null)),check((reversed_by is null)=(reversal_reason is null))
);
create unique index sc_payment_reference_unique on public.sc_vendor_payments(bill_id,method,lower(trim(reference)));
create table public.sc_bill_history(id uuid primary key default gen_random_uuid(),bill_id uuid not null references public.sc_bills,action text not null,note text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now());
create index sc_bill_history_parent on public.sc_bill_history(bill_id);
create function portal_private.payables_access() returns boolean language sql stable security definer set search_path='' as $$select public.is_admin() or portal_private.crm_permission('finance.manage');$$;
create function portal_private.bill_read(p_bill uuid) returns boolean language sql stable security definer set search_path='' as $$select portal_private.payables_access() or portal_private.crm_permission('purchase.manage');$$;
create function portal_private.bill_audit(p_bill uuid,p_action text,p_note text) returns void language sql security definer set search_path='' as $$insert into public.sc_bill_history(bill_id,action,note,actor_id) values(p_bill,p_action,p_note,auth.uid());$$;
-- Lock the PO before the bill everywhere, including returns, to serialize receipt allocations and payments.
create function portal_private.bill_lock(p_bill uuid,p_version integer) returns public.sc_bills language plpgsql security definer set search_path='' as $$declare b public.sc_bills;po uuid;begin
 select order_id into po from public.sc_bills where id=p_bill;if not found then raise exception 'Bill unavailable';end if;
 perform 1 from public.sc_orders where id=po for update;select * into b from public.sc_bills where id=p_bill for update;
 if b.version is distinct from p_version then raise exception 'Bill changed. Refresh first';end if;return b;end$$;
-- Returns cannot silently invalidate already matched or paid invoices. Resolve unpaid bills first.
create function portal_private.billed_return_guard() returns trigger language plpgsql security definer set search_path='' as $$declare g public.sc_receipts;used numeric;net numeric;begin
 if new.kind<>'Vendor return' then return new;end if;
 select * into g from public.sc_receipts where id=new.receipt_id;perform 1 from public.sc_orders where id=g.order_id for update;
 select coalesce(sum(l.quantity),0) into used from public.sc_bill_receipts l join public.sc_bills b on b.id=l.bill_id where l.receipt_id=g.id and b.status in ('Matched','Approved');
 select g.accepted-coalesce(sum(r.quantity),0)-new.quantity into net from public.sc_returns r where r.receipt_id=g.id;
 if net<used then raise exception 'Receipt quantity is committed to a matched bill. Cancel or rework unpaid bills before vendor return; paid bills require a credit-note workflow';end if;return new;end$$;
create trigger billed_return_guard before insert on public.sc_returns for each row execute function portal_private.billed_return_guard();
do $$declare t text;begin foreach t in array array['sc_bills','sc_bill_receipts','sc_vendor_payments','sc_bill_history'] loop execute format('alter table public.%I enable row level security',t);execute format('revoke all on public.%I from public,anon,authenticated',t);execute format('grant select on public.%I to authenticated',t);end loop;end$$;
create policy bill_read on public.sc_bills for select to authenticated using(portal_private.bill_read(id));
create policy bill_receipt_read on public.sc_bill_receipts for select to authenticated using(portal_private.bill_read(bill_id));
create policy vendor_payment_read on public.sc_vendor_payments for select to authenticated using(portal_private.payables_access());
create policy bill_history_read on public.sc_bill_history for select to authenticated using(portal_private.bill_read(bill_id));
revoke all on function portal_private.payables_access(),portal_private.bill_read(uuid),portal_private.bill_audit(uuid,text,text),portal_private.bill_lock(uuid,integer),portal_private.billed_return_guard() from public,anon,authenticated;
grant execute on function portal_private.payables_access(),portal_private.bill_read(uuid) to authenticated;

create function public.save_vendor_bill(p_id uuid,p_version integer,p_order uuid,p_data jsonb,p_receipts jsonb) returns uuid language plpgsql security definer set search_path='' as $$declare b public.sc_bills;po public.sc_orders;r public.sc_requests;doc uuid;entry jsonb;qty numeric;invoice_rate numeric;sumqty numeric:=0;g public.sc_receipts;tracking text;begin
 if not portal_private.payables_access() then raise exception 'Accounts permission required';end if;
 if jsonb_typeof(p_data) is distinct from 'object' or jsonb_typeof(p_receipts) is distinct from 'array' or jsonb_array_length(p_receipts) not between 1 and 100 then raise exception 'Bill details and one to 100 GRN lines required';end if;
 if p_id is not null then b:=portal_private.bill_lock(p_id,p_version);if b.order_id is distinct from p_order or b.status not in ('Draft','Held') then raise exception 'Only draft or held bills can be edited on the original PO';end if;else perform 1 from public.sc_orders where id=p_order for update;end if;
 select * into po from public.sc_orders where id=p_order;if not found or po.status not in ('Approved','In transit','Part received','Received') or po.approved_by is null then raise exception 'Approved purchase order required';end if;
 select * into r from public.sc_requests where id=po.request_id;select c.tracking into tracking from public.sc_request_lines l join public.crm_catalog c on c.id=l.item_id where l.id=po.line_id;
 qty:=(p_data->>'quantity')::numeric;invoice_rate:=(p_data->>'rate')::numeric;
 if qty is null or qty<=0 or qty>100000 or invoice_rate is null or invoice_rate<=0 or invoice_rate>=100000000 or round(invoice_rate,2)<>invoice_rate or round(qty,3)<>qty then raise exception 'Use positive bounded quantity and unit rate (3 and 2 decimals)';end if;
 if tracking<>'Quantity' and qty<>trunc(qty) then raise exception 'Serial and returnable item invoices require whole units';end if;
 if (p_data->>'invoice_date')::date is null or (p_data->>'due_date')::date is null or (p_data->>'invoice_date')::date>(now() at time zone 'Asia/Karachi')::date then raise exception 'Valid invoice and due dates required; invoice cannot be future dated';end if;
 if p_id is null then insert into public.sc_bills(order_id,vendor_id,project_id,vendor_invoice,invoice_date,due_date,quantity,rate,total,evidence,note,created_by) values(po.id,po.vendor_id,r.project_id,trim(p_data->>'vendor_invoice'),(p_data->>'invoice_date')::date,(p_data->>'due_date')::date,qty,invoice_rate,round(qty*invoice_rate,2),trim(p_data->>'evidence'),coalesce(p_data->>'note',''),auth.uid()) returning id into doc;
 else update public.sc_bills set vendor_invoice=trim(p_data->>'vendor_invoice'),invoice_date=(p_data->>'invoice_date')::date,due_date=(p_data->>'due_date')::date,quantity=qty,rate=invoice_rate,total=round(qty*invoice_rate,2),evidence=trim(p_data->>'evidence'),note=coalesce(p_data->>'note',''),status='Draft',match_note='',match_snapshot=null,matched_by=null,matched_at=null,version=version+1 where id=p_id returning id into doc;delete from public.sc_bill_receipts where bill_id=doc;end if;
 for entry in select * from jsonb_array_elements(p_receipts) loop
 select * into g from public.sc_receipts where id=(entry->>'receipt_id')::uuid;if not found or g.order_id<>po.id or g.accepted<=0 then raise exception 'Choose accepted GRNs from the same purchase order';end if;
 qty:=(entry->>'quantity')::numeric;if qty is null or qty<=0 or qty>100000 or qty<>round(qty,3) then raise exception 'Positive bounded GRN quantity required';end if;
 if tracking<>'Quantity' and qty<>trunc(qty) then raise exception 'Serial and returnable GRN allocations require whole units';end if;
 insert into public.sc_bill_receipts(bill_id,receipt_id,quantity) values(doc,g.id,qty);sumqty:=sumqty+qty;
 end loop;
 if sumqty<>(p_data->>'quantity')::numeric then raise exception 'GRN allocated quantities must equal invoice quantity';end if;
 perform portal_private.bill_audit(doc,case when p_id is null then 'Created' else 'Revised' end,'Vendor invoice '||trim(p_data->>'vendor_invoice'));return doc;
 end$$;

create function portal_private.bill_mismatch(p_bill uuid) returns text language plpgsql stable security definer set search_path='' as $$declare b public.sc_bills;po public.sc_orders;line record;net numeric;used numeric;begin
 select * into b from public.sc_bills where id=p_bill;select * into po from public.sc_orders where id=b.order_id;
 if po.approved_by is null or po.status not in ('Approved','In transit','Part received','Received') then return 'Purchase order is not approved';end if;
 if b.rate<>po.rate then return 'Invoice unit rate differs from approved PO rate';end if;
 if b.total<>round(b.quantity*po.rate,2) then return 'Invoice total differs from approved PO material value';end if;
 if b.quantity+coalesce((select sum(quantity) from public.sc_bills where order_id=b.order_id and id<>b.id and status in ('Matched','Approved')),0)>po.quantity then return 'Invoice quantities exceed approved PO quantity';end if;
 if not exists(select 1 from public.sc_bill_receipts where bill_id=b.id) or (select sum(quantity) from public.sc_bill_receipts where bill_id=b.id)<>b.quantity then return 'Missing or inconsistent GRN allocation';end if;
 for line in select l.*,g.accepted,g.rate,g.order_id from public.sc_bill_receipts l join public.sc_receipts g on g.id=l.receipt_id where l.bill_id=b.id loop
 if line.order_id<>po.id or line.rate<>po.rate then return 'GRN does not match approved purchase order';end if;
 select line.accepted-coalesce(sum(quantity),0) into net from public.sc_returns where receipt_id=line.receipt_id;
 select coalesce(sum(l.quantity),0) into used from public.sc_bill_receipts l join public.sc_bills x on x.id=l.bill_id where l.receipt_id=line.receipt_id and x.id<>b.id and x.status in ('Matched','Approved');
 if line.quantity+used>net then return 'Invoice quantity exceeds unbilled accepted GRN quantity after vendor returns';end if;
 end loop;return '';end$$;
revoke all on function portal_private.bill_mismatch(uuid) from public,anon,authenticated;
create function public.vendor_bill_action(p_bill uuid,p_version integer,p_action text,p_note text default '') returns void language plpgsql security definer set search_path='' as $$declare b public.sc_bills;mismatch text;begin
 if not portal_private.payables_access() then raise exception 'Accounts permission required';end if;b:=portal_private.bill_lock(p_bill,p_version);
 if p_action='Match' then
 if b.status not in ('Draft','Held') then raise exception 'Only draft or held bills can be matched';end if;
 mismatch:=portal_private.bill_mismatch(b.id);
 update public.sc_bills set status=case when mismatch='' then 'Matched' else 'Held' end,match_note=case when mismatch='' then 'PO rate and quantity matched to net accepted GRNs' else mismatch end,match_snapshot=case when mismatch='' then jsonb_build_object('order_id',b.order_id,'rate',b.rate,'quantity',b.quantity,'total',b.total,'receipts',(select jsonb_agg(jsonb_build_object('receipt_id',receipt_id,'quantity',quantity)) from public.sc_bill_receipts where bill_id=b.id)) else null end,matched_by=auth.uid(),matched_at=now(),version=version+1 where id=b.id;
 perform portal_private.bill_audit(b.id,case when mismatch='' then 'Matched' else 'Held' end,case when mismatch='' then 'PO and accepted GRNs matched' else mismatch end);
 elsif p_action='Approve' then
 if not public.is_admin() or b.status<>'Matched' or b.created_by=auth.uid() or b.matched_by=auth.uid() or length(trim(coalesce(p_note,'')))<3 then raise exception 'Separate administrator, matched bill and approval reason required';end if;
 mismatch:=portal_private.bill_mismatch(b.id);if mismatch<>'' then raise exception '%',mismatch;end if;
 update public.sc_bills set status='Approved',approved_by=auth.uid(),approved_at=now(),version=version+1 where id=b.id;perform portal_private.bill_audit(b.id,'Approved',p_note);
 elsif p_action in ('Rework','Cancel') then
 if b.status='Cancelled' or (p_action='Rework' and b.status<>'Matched') or (b.status='Approved' and not public.is_admin()) or length(trim(coalesce(p_note,'')))<3 or exists(select 1 from public.sc_vendor_payments where bill_id=b.id and reversed_by is null) then raise exception 'Unpaid bill, authorized action and reason required';end if;
 update public.sc_bills set status=case when p_action='Cancel' then 'Cancelled' else 'Draft' end,matched_by=null,matched_at=null,match_snapshot=null,approved_by=null,approved_at=null,match_note=p_note,version=version+1 where id=b.id;perform portal_private.bill_audit(b.id,p_action,p_note);
 else raise exception 'Unsupported bill action';end if;end$$;
create function public.record_vendor_payment(p_bill uuid,p_version integer,p_amount numeric,p_date date,p_method text,p_reference text,p_evidence text) returns uuid language plpgsql security definer set search_path='' as $$declare b public.sc_bills;paid numeric;doc uuid;mismatch text;begin
 if not portal_private.payables_access() then raise exception 'Accounts permission required';end if;b:=portal_private.bill_lock(p_bill,p_version);
 if b.status<>'Approved' or b.approved_by is null or b.approved_by=auth.uid() then raise exception 'Separately approved matched bill required; approver cannot record its payment';end if;
 if p_amount is null or p_amount<=0 or p_amount>=100000000 or p_amount<>round(p_amount,2) or p_date is null or p_date<b.invoice_date or p_date>(now() at time zone 'Asia/Karachi')::date then raise exception 'Valid positive amount and payment date required';end if;
 mismatch:=portal_private.bill_mismatch(b.id);if mismatch<>'' then raise exception '%',mismatch;end if;
 select coalesce(sum(amount),0) into paid from public.sc_vendor_payments where bill_id=b.id and reversed_by is null;if p_amount>b.total-paid then raise exception 'Payment exceeds outstanding bill balance';end if;
 insert into public.sc_vendor_payments(bill_id,amount,payment_date,method,reference,evidence,created_by) values(b.id,p_amount,p_date,p_method,trim(p_reference),trim(p_evidence),auth.uid()) returning id into doc;
 update public.sc_bills set version=version+1 where id=b.id;perform portal_private.bill_audit(b.id,'Payment recorded',p_amount::text||' PKR · '||p_method||' · '||trim(p_reference));return doc;end$$;
create function public.reverse_vendor_payment(p_payment uuid,p_bill_version integer,p_reason text) returns void language plpgsql security definer set search_path='' as $$declare p public.sc_vendor_payments;b public.sc_bills;begin
 if not public.is_admin() then raise exception 'Administrator required';end if;select * into p from public.sc_vendor_payments where id=p_payment;if not found then raise exception 'Payment unavailable';end if;b:=portal_private.bill_lock(p.bill_id,p_bill_version);
 select * into p from public.sc_vendor_payments where id=p_payment for update;
 if p.reversed_by is not null or p.created_by=auth.uid() or length(trim(coalesce(p_reason,'')))<3 then raise exception 'Separate administrator and documented reversal required';end if;
 update public.sc_vendor_payments set reversed_by=auth.uid(),reversed_at=now(),reversal_reason=trim(p_reason) where id=p.id;update public.sc_bills set version=version+1 where id=b.id;perform portal_private.bill_audit(b.id,'Payment reversed',p.number||' · '||trim(p_reason));end$$;
-- Checked report uses Pakistan business date and separates held/draft amounts from approved payables.
create function public.vendor_payables_report() returns table(id uuid,number text,order_id uuid,order_number text,vendor_id uuid,vendor text,project_id uuid,project text,vendor_invoice text,invoice_date date,due_date date,total numeric,paid numeric,balance numeric,status text,approval_status text,days_overdue integer,aging text,version integer) language plpgsql stable security definer set search_path='' as $$begin
 if not portal_private.payables_access() then raise exception 'Accounts permission required';end if;
 return query with amounts as (select b.*,coalesce((select sum(p.amount) from public.sc_vendor_payments p where p.bill_id=b.id and p.reversed_by is null),0) payments from public.sc_bills b), dated as (select a.*,greatest(0,((now() at time zone 'Asia/Karachi')::date-a.due_date)) days from amounts a)
 select d.id,d.number,d.order_id,o.number,d.vendor_id,coalesce(o.vendor_snapshot->>'name',v.name),d.project_id,coalesce(pr.title,'Office'),d.vendor_invoice,d.invoice_date,d.due_date,d.total,d.payments,case when d.status='Cancelled' then 0 else d.total-d.payments end,
 case when d.status<>'Approved' then d.status when d.payments=d.total then 'Paid' when d.payments>0 then 'Partially paid' else 'Unpaid' end,d.status,
 case when d.status='Approved' and d.total>d.payments then d.days else 0 end,
 case when d.status<>'Approved' then 'Not payable' when d.total=d.payments then 'Settled' when d.days=0 then 'Current' when d.days<=30 then '1–30' when d.days<=60 then '31–60' when d.days<=90 then '61–90' else '90+' end,d.version
 from dated d join public.sc_orders o on o.id=d.order_id join public.sc_vendors v on v.id=d.vendor_id left join public.projects pr on pr.id=d.project_id order by d.due_date,d.number;end$$;
do $$declare f record;begin for f in select p.oid::regprocedure sig from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('save_vendor_bill','vendor_bill_action','record_vendor_payment','reverse_vendor_payment','vendor_payables_report') loop execute format('revoke all on function %s from public,anon',f.sig);execute format('grant execute on function %s to authenticated',f.sig);end loop;end$$;
commit;
