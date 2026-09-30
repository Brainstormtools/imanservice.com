begin;
create sequence public.credit_numbers;
create table public.credit_notes(id uuid primary key,invoice_id uuid not null references public.invoices,number text not null unique default ('CN-'||lpad(nextval('public.credit_numbers')::text,6,'0')),amount numeric(14,2) not null check(amount>0),reason text not null check(length(trim(reason)) between 3 and 2000),status text not null default 'Issued' check(status in ('Issued','Reversed')),author_id uuid not null default auth.uid() references public.profiles,created_at timestamptz not null default now(),reversed_at timestamptz);
alter table public.credit_notes enable row level security;
create policy credit_read on public.credit_notes for select to authenticated using(public.can_invoice(invoice_id));
create function public.invoice_credit(p_invoice uuid) returns numeric language sql stable security definer set search_path='' as $$select case when public.can_invoice(p_invoice) then coalesce((select sum(amount) from public.credit_notes where invoice_id=p_invoice and status='Issued'),0) else null end$$;
create function public.record_credit(p_id uuid,p_invoice uuid,p_amount numeric,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare v public.invoices;c public.credit_notes;available numeric;
begin
 if not public.is_admin() then raise exception 'Administrator access required';end if;
 if p_id is null then raise exception 'Request ID required';end if;
 select * into v from public.invoices where id=p_invoice for update;
 if not found or v.status<>'Issued' then raise exception 'Issued invoice required';end if;
 select * into c from public.credit_notes where id=p_id;
 if found then
  if c.invoice_id<>p_invoice or c.amount is distinct from p_amount or c.reason is distinct from trim(p_reason) then raise exception 'Request ID already used';end if;return c.id;
 end if;
 available:=v.total-public.invoice_credit(v.id)-coalesce((select sum(amount) from public.payment_claims where invoice_id=v.id and status in ('Pending','Verified')),0);
 if p_amount is null or p_amount::text in ('NaN','Infinity','-Infinity') or p_amount<=0 or p_amount<>round(p_amount,2) or p_amount>available then raise exception 'Credit exceeds balance after existing credits and pending/verified payments';end if;
 insert into public.credit_notes(id,invoice_id,amount,reason) values(p_id,v.id,p_amount,trim(p_reason));
 insert into public.billing_events(invoice_id,action,detail) values(v.id,'Credit issued',p_id::text||' '||trim(p_reason));return p_id;
end $$;
create function public.reverse_credit(p_id uuid,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare c public.credit_notes;
begin
 if not public.is_admin() then raise exception 'Administrator access required';end if;
 if length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Enter reversal reason';end if;
 select * into c from public.credit_notes where id=p_id;if not found then raise exception 'Credit unavailable';end if;
 perform 1 from public.invoices where id=c.invoice_id for update;
 select * into c from public.credit_notes where id=p_id for update;
 if c.status='Reversed' then return;end if;
 update public.credit_notes set status='Reversed',reversed_at=now() where id=c.id;
 insert into public.billing_events(invoice_id,action,detail) values(c.invoice_id,'Credit reversed',c.id::text||' '||trim(p_reason));
end $$;
create table public.invoice_schedules(id uuid primary key default gen_random_uuid(),source_invoice uuid not null references public.invoices,company_id uuid not null references public.companies,title text not null check(length(trim(title)) between 1 and 200),currency text not null,items jsonb not null,notes text not null,bank_instructions text not null,next_on date not null,anchor_day integer not null check(anchor_day between 1 and 31),due_days integer not null check(due_days between 0 and 365),active boolean not null default true,version integer not null default 1,author_id uuid not null default auth.uid() references public.profiles,created_at timestamptz not null default now());
create table public.invoice_schedule_runs(id uuid primary key default gen_random_uuid(),schedule_id uuid not null references public.invoice_schedules,period_on date not null,invoice_id uuid not null unique references public.invoices,created_at timestamptz not null default now(),unique(schedule_id,period_on));
alter table public.invoice_schedules enable row level security;
alter table public.invoice_schedule_runs enable row level security;
create policy schedule_read on public.invoice_schedules for select to authenticated using(public.is_admin());
create policy schedule_run_read on public.invoice_schedule_runs for select to authenticated using(public.is_admin());
create function public.save_invoice_schedule(p_source uuid,p_title text,p_start date,p_due integer) returns uuid language plpgsql security definer set search_path='' as $$
declare v public.invoices;r uuid;lines jsonb;
begin
 if not public.is_admin() then raise exception 'Administrator access required';end if;
 select * into v from public.invoices where id=p_source for share;
 if not found or v.status='Void' or v.total<=0 then raise exception 'Positive non-void invoice required';end if;
 if p_start is null or not isfinite(p_start) or p_start<(now() at time zone 'UTC')::date then raise exception 'First billing date must be today or later';end if;
 select jsonb_agg(jsonb_build_object('description',description,'quantity',quantity,'unit_price',unit_price,'tax_percent',tax_percent) order by position) into lines from public.invoice_items where invoice_id=v.id;
 insert into public.invoice_schedules(source_invoice,company_id,title,currency,items,notes,bank_instructions,next_on,anchor_day,due_days) values(v.id,v.company_id,trim(p_title),v.currency,lines,v.notes,v.bank_instructions,p_start,extract(day from p_start)::integer,p_due) returning id into r;return r;
end $$;
create function public.toggle_invoice_schedule(p_id uuid,p_version integer,p_active boolean) returns void language plpgsql security definer set search_path='' as $$
begin
 if not public.is_admin() then raise exception 'Administrator access required';end if;
 update public.invoice_schedules set active=p_active,version=version+1 where id=p_id and version=p_version;
 if not found then raise exception 'Schedule changed. Refresh first.';end if;
end $$;
create function public.generate_invoice_drafts() returns integer language plpgsql security definer set search_path='' as $$
declare s public.invoice_schedules;v uuid;n integer:=0;next_month date;period date;
begin
 if not public.is_admin() then raise exception 'Administrator access required';end if;
 for s in select * from public.invoice_schedules where active and next_on<=(now() at time zone 'UTC')::date order by next_on limit 100 for update skip locked loop
  period:=s.next_on;
  if not exists(select 1 from public.invoice_schedule_runs where schedule_id=s.id and period_on=period) then
   v:=public.save_invoice(null,s.company_id,s.currency,period,period+s.due_days,s.notes||E'\nRecurring: '||s.title,s.bank_instructions,s.items);
   insert into public.invoice_schedule_runs(schedule_id,period_on,invoice_id) values(s.id,period,v);n:=n+1;
  end if;
  next_month:=(date_trunc('month',period)+interval '1 month')::date;
  update public.invoice_schedules set next_on=next_month+least(s.anchor_day,extract(day from (next_month+interval '1 month - 1 day'))::integer)-1,version=version+1 where id=s.id;
 end loop;return n;
end $$;
-- Credits must participate in existing payment and void checks, including concurrent actions.
create or replace function public.submit_payment(p_invoice uuid,p_amount numeric,p_reference text,p_date date,p_notes text) returns uuid language plpgsql security definer set search_path='' as $$
declare v public.invoices; pid uuid; outstanding numeric;
begin
 if not public.can_invoice(p_invoice) then raise exception 'Invoice unavailable'; end if;
 select * into v from public.invoices where id=p_invoice for update;
 if v.status<>'Issued' then raise exception 'Invoice is not payable'; end if;
 outstanding:=v.total-public.invoice_credit(v.id)-coalesce((select sum(amount) from public.payment_claims where invoice_id=v.id and status in ('Pending','Verified')),0);
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) or p_amount>outstanding then raise exception 'Amount exceeds balance after pending payments or has invalid precision'; end if;
 if p_date is null or p_date>(now() at time zone 'UTC')::date then raise exception 'Payment date cannot be in the future'; end if;
 if exists(select 1 from public.payment_claims where invoice_id=v.id and lower(trim(reference))=lower(trim(p_reference)) and status in ('Pending','Verified')) then raise exception 'This payment reference has already been submitted'; end if;
 insert into public.payment_claims(invoice_id,amount,reference,paid_on,notes) values(v.id,p_amount,trim(p_reference),p_date,p_notes) returning id into pid;
 insert into public.billing_events(invoice_id,action,detail) values(v.id,'Payment submitted',pid::text);
 return pid;
end $$;
create or replace function public.review_payment(p_payment uuid,p_action text,p_note text) returns void language plpgsql security definer set search_path='' as $$
declare c public.payment_claims; v public.invoices;
begin
 if not public.is_admin() then raise exception 'Administrator access required'; end if;
 select * into c from public.payment_claims where id=p_payment;
 if not found then raise exception 'Payment unavailable'; end if;
 select * into v from public.invoices where id=c.invoice_id for update;
 select * into c from public.payment_claims where id=p_payment for update;
 if p_action='verify' and c.status='Pending' and v.status='Issued' then
  if c.amount>v.total-public.invoice_credit(v.id)-coalesce((select sum(amount) from public.payment_claims where invoice_id=v.id and status='Verified'),0) then raise exception 'Payment exceeds outstanding balance'; end if;
  update public.payment_claims set status='Verified',reviewed_by=auth.uid(),reviewed_at=now(),review_note=p_note where id=c.id;
 elsif (p_action='reject' and c.status='Pending') or (p_action='reverse' and c.status='Verified') then
  if length(trim(coalesce(p_note,'')))<3 then raise exception 'Enter a reason'; end if;
  update public.payment_claims set status=case when p_action='reject' then 'Rejected' else 'Reversed' end,reviewed_by=auth.uid(),reviewed_at=now(),review_note=p_note where id=c.id;
 else raise exception 'Payment already reviewed or action invalid'; end if;
 insert into public.billing_events(invoice_id,action,detail) values(v.id,'Payment '||p_action,c.id::text||' '||coalesce(p_note,''));
end $$;

alter function public.invoice_action(uuid,text) rename to invoice_action_before_credits;
revoke all on function public.invoice_action_before_credits(uuid,text) from public,anon,authenticated;
create function public.invoice_action(p_invoice uuid,p_action text) returns void language plpgsql security definer set search_path='' as $$
begin
 if not public.is_admin() then raise exception 'Administrator access required';end if;
 perform 1 from public.invoices where id=p_invoice for update;
 if p_action='void' and exists(select 1 from public.credit_notes where invoice_id=p_invoice and status='Issued') then raise exception 'Reverse issued credits before voiding';end if;
 perform public.invoice_action_before_credits(p_invoice,p_action);
end $$;
revoke all on public.credit_notes,public.invoice_schedules,public.invoice_schedule_runs from anon,authenticated;
grant select on public.credit_notes,public.invoice_schedules,public.invoice_schedule_runs to authenticated;
revoke all on function public.invoice_credit(uuid),public.record_credit(uuid,uuid,numeric,text),public.reverse_credit(uuid,text),public.save_invoice_schedule(uuid,text,date,integer),public.toggle_invoice_schedule(uuid,integer,boolean),public.generate_invoice_drafts(),public.invoice_action(uuid,text) from public,anon;
grant execute on function public.invoice_credit(uuid),public.record_credit(uuid,uuid,numeric,text),public.reverse_credit(uuid,text),public.save_invoice_schedule(uuid,text,date,integer),public.toggle_invoice_schedule(uuid,integer,boolean),public.generate_invoice_drafts(),public.invoice_action(uuid,text) to authenticated;
commit;
