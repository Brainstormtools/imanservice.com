begin;
create table public.billing_job_runs(id uuid primary key default gen_random_uuid(),started_at timestamptz not null default clock_timestamp(),finished_at timestamptz,generated integer not null default 0,failed integer not null default 0,status text not null default 'Running' check(status in ('Running','Succeeded','Partial','Failed')));
create table public.billing_job_errors(id uuid primary key default gen_random_uuid(),run_id uuid not null references public.billing_job_runs,schedule_id uuid not null references public.invoice_schedules,period_on date not null,error_code text not null,created_at timestamptz not null default now());
alter table public.billing_job_runs enable row level security;
alter table public.billing_job_errors enable row level security;
create policy billing_job_read on public.billing_job_runs for select to authenticated using(public.is_admin());
create policy billing_job_error_read on public.billing_job_errors for select to authenticated using(public.is_admin());
create function public.run_billing_automation() returns uuid language plpgsql security definer set search_path='' as $$
declare s public.invoice_schedules;r uuid;v uuid;line jsonb;q numeric(10,3);price numeric(12,2);rate numeric(5,2);net_amount numeric(14,2);idx integer;next_month date;cname text;n integer:=0;errors integer:=0;created boolean;
begin
 -- Only the database owner may execute this function. No user JWT or credentials are impersonated.
 if not pg_try_advisory_xact_lock(hashtextextended('iman-billing-automation',0)) then return null;end if;
 insert into public.billing_job_runs default values returning id into r;
 for s in select * from public.invoice_schedules where active and next_on<=(now() at time zone 'UTC')::date order by next_on,id limit 100 for update skip locked loop
  begin
   created:=false;
   if not exists(select 1 from public.profiles where id=s.author_id and role='admin' and active) then raise exception using errcode='P0001',message='Schedule owner needs active administrator access';end if;
   if not exists(select 1 from public.invoice_schedule_runs where schedule_id=s.id and period_on=s.next_on) then
    if jsonb_typeof(s.items) is distinct from 'array' or jsonb_array_length(s.items) not between 1 and 100 then raise exception 'Invalid saved lines';end if;
    select name into cname from public.companies where id=s.company_id;
    insert into public.invoices(company_id,company_name,currency,issued_on,due_on,notes,bank_instructions,author_id) values(s.company_id,cname,s.currency,s.next_on,s.next_on+s.due_days,s.notes,s.bank_instructions,s.author_id) returning id into v;
    idx:=0;
    for line in select value from jsonb_array_elements(s.items) loop
     q:=(line->>'quantity')::numeric;price:=(line->>'unit_price')::numeric;rate:=(line->>'tax_percent')::numeric;
     if q::text='NaN' or price::text='NaN' or rate::text='NaN' then raise exception 'Invalid saved amount';end if;
     net_amount:=round(q*price,2);idx:=idx+1;
     insert into public.invoice_items(invoice_id,description,quantity,unit_price,tax_percent,net,tax,position) values(v,trim(line->>'description'),q,price,rate,net_amount,round(net_amount*rate/100,2),idx);
    end loop;
    update public.invoices set subtotal=(select sum(net) from public.invoice_items where invoice_id=v),tax_total=(select sum(tax) from public.invoice_items where invoice_id=v),total=(select sum(net+tax) from public.invoice_items where invoice_id=v) where id=v;
    insert into public.billing_events(invoice_id,action,actor_id,detail) values(v,'Recurring draft generated',s.author_id,'Background run '||r::text);
    insert into public.invoice_schedule_runs(schedule_id,period_on,invoice_id) values(s.id,s.next_on,v);created:=true;
   end if;
   next_month:=(date_trunc('month',s.next_on)+interval '1 month')::date;
   update public.invoice_schedules set next_on=next_month+least(s.anchor_day,extract(day from (next_month+interval '1 month - 1 day'))::integer)-1,version=version+1 where id=s.id;
   if created then n:=n+1;end if;
  exception when others then
   errors:=errors+1;
   insert into public.billing_job_errors(run_id,schedule_id,period_on,error_code) values(r,s.id,s.next_on,sqlstate);
   -- Pause only the failing schedule; its period remains unchanged and partial invoices roll back.
   update public.invoice_schedules set active=false,version=version+1 where id=s.id;
  end;
 end loop;
 update public.billing_job_runs set finished_at=clock_timestamp(),generated=n,failed=errors,status=case when errors=0 then 'Succeeded' when n>0 then 'Partial' else 'Failed' end where id=r;
 return r;
end $$;
revoke all on public.billing_job_runs,public.billing_job_errors from anon,authenticated;
grant select on public.billing_job_runs,public.billing_job_errors to authenticated;
revoke all on function public.run_billing_automation() from public,anon,authenticated,service_role;
commit;
