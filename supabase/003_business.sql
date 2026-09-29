-- Apply once after 002_operations.sql. Additive business workflows.
begin;
create table public.task_imports(id uuid primary key, project_id uuid not null references public.projects, payload jsonb not null, author_id uuid not null references public.profiles, row_count integer not null, created_at timestamptz not null default now());
alter table public.task_imports enable row level security;
create policy task_import_read on public.task_imports for select to authenticated using(public.is_staff());
grant select on public.task_imports to authenticated;
create function public.import_tasks(p_project uuid,p_batch uuid,p_rows jsonb) returns integer language plpgsql security definer set search_path='' as $$
declare r jsonb; previous public.task_imports; n integer; assignee_id uuid;
begin
 if not public.is_staff() then raise exception 'Staff access required'; end if;
 if jsonb_typeof(p_rows) is distinct from 'array' or jsonb_array_length(p_rows) not between 1 and 500 then raise exception 'Import 1 to 500 rows'; end if;
 perform pg_advisory_xact_lock(hashtext(p_batch::text));
 select * into previous from public.task_imports where id=p_batch;
 if found then
  if previous.project_id<>p_project or previous.payload<>p_rows then raise exception 'Batch already used for different data'; end if;
  return previous.row_count;
 end if;
 if not exists(select 1 from public.projects where id=p_project) then raise exception 'Project unavailable'; end if;
 for r in select value from jsonb_array_elements(p_rows) loop
  if jsonb_typeof(r) is distinct from 'object' or length(trim(coalesce(r->>'title',''))) not between 1 and 300 then raise exception 'Every row needs a task title of 1 to 300 characters'; end if;
  if coalesce(r->>'internal','false') not in ('true','false') then raise exception 'Internal must be true or false'; end if;
  assignee_id:=nullif(r->>'assignee_id','')::uuid;
  insert into public.tasks(project_id,title,priority,status,assignee,deadline,internal)
   values(p_project,trim(r->>'title'),coalesce(nullif(r->>'priority',''),'Normal'),coalesce(nullif(r->>'status',''),'To do'),assignee_id,nullif(r->>'deadline','')::date,coalesce((r->>'internal')::boolean,false));
 end loop;
 n:=jsonb_array_length(p_rows);
 insert into public.task_imports values(p_batch,p_project,p_rows,auth.uid(),n,now());
 return n;
end $$;

create sequence public.invoice_numbers;
create table public.invoices(
 id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies,
 number text not null unique default ('IMS-'||lpad(nextval('public.invoice_numbers')::text,6,'0')),
 status text not null default 'Draft' check(status in ('Draft','Issued','Void')),
 currency text not null default 'PKR' check(currency ~ '^[A-Z]{3}$'),
 issued_on date not null default current_date, due_on date not null, company_name text not null,
 notes text not null default '' check(length(notes)<=4000), bank_instructions text not null default '' check(length(bank_instructions)<=4000),
 subtotal numeric(14,2) not null default 0, tax_total numeric(14,2) not null default 0, total numeric(14,2) not null default 0 check(total>=0),
 author_id uuid not null default auth.uid() references public.profiles, created_at timestamptz not null default now(), check(due_on>=issued_on)
);
create table public.invoice_items(
 id uuid primary key default gen_random_uuid(),invoice_id uuid not null references public.invoices on delete cascade,
 description text not null check(length(trim(description)) between 1 and 500), quantity numeric(10,3) not null check(quantity>0 and quantity<=100000),
 unit_price numeric(12,2) not null check(unit_price>=0), tax_percent numeric(5,2) not null default 0 check(tax_percent between 0 and 100),
 net numeric(14,2) not null, tax numeric(14,2) not null, position integer not null
);
create table public.payment_claims(
 id uuid primary key default gen_random_uuid(), invoice_id uuid not null references public.invoices,
 amount numeric(14,2) not null check(amount>0), reference text not null check(length(trim(reference)) between 1 and 200),
 paid_on date not null, notes text not null default '' check(length(notes)<=2000),
 status text not null default 'Pending' check(status in ('Pending','Verified','Rejected','Reversed')),
 submitted_by uuid not null default auth.uid() references public.profiles, reviewed_by uuid references public.profiles,
 reviewed_at timestamptz, review_note text not null default '', created_at timestamptz not null default now()
);
create unique index verified_bank_reference on public.payment_claims(lower(trim(reference))) where status='Verified';
create table public.billing_events(id uuid primary key default gen_random_uuid(),invoice_id uuid not null references public.invoices,action text not null,actor_id uuid not null default auth.uid() references public.profiles,detail text not null default '',created_at timestamptz not null default now());
alter table public.invoices enable row level security;
alter table public.invoice_items enable row level security;
alter table public.payment_claims enable row level security;
alter table public.billing_events enable row level security;
create function public.can_invoice(i uuid) returns boolean language sql stable security definer set search_path='' as $$
 select public.is_admin() or exists(select 1 from public.invoices v join public.profiles p on p.company_id=v.company_id where v.id=i and v.status<>'Draft' and p.id=auth.uid() and p.active and p.role='client');
$$;
create policy invoice_read on public.invoices for select to authenticated using(public.can_invoice(id));
create policy invoice_item_read on public.invoice_items for select to authenticated using(public.can_invoice(invoice_id));
create policy payment_read on public.payment_claims for select to authenticated using(public.can_invoice(invoice_id));
create policy billing_event_read on public.billing_events for select to authenticated using(public.can_invoice(invoice_id));
grant select on public.invoices,public.invoice_items,public.payment_claims,public.billing_events to authenticated;
create function public.save_invoice(p_id uuid,p_company uuid,p_currency text,p_issue date,p_due date,p_notes text,p_bank text,p_items jsonb) returns uuid language plpgsql security definer set search_path='' as $$
declare v public.invoices; r jsonb; q numeric(10,3); price numeric(12,2); rate numeric(5,2); net_amount numeric(14,2); idx integer:=0; cname text;
begin
 if not public.is_admin() then raise exception 'Administrator access required'; end if;
 if jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items) not between 1 and 100 then raise exception 'Use 1 to 100 invoice lines'; end if;
 select name into cname from public.companies where id=p_company;
 if cname is null then raise exception 'Company unavailable'; end if;
 if p_id is null then
  insert into public.invoices(company_id,company_name,currency,issued_on,due_on,notes,bank_instructions) values(p_company,cname,upper(p_currency),p_issue,p_due,p_notes,p_bank) returning * into v;
 else
  select * into v from public.invoices where id=p_id for update;
  if not found or v.status<>'Draft' or v.company_id<>p_company then raise exception 'Only drafts can be edited; company cannot change'; end if;
  update public.invoices set currency=upper(p_currency),issued_on=p_issue,due_on=p_due,notes=p_notes,bank_instructions=p_bank,company_name=cname where id=v.id;
  delete from public.invoice_items where invoice_id=v.id;
 end if;
 for r in select value from jsonb_array_elements(p_items) loop
  q:=(r->>'quantity')::numeric; price:=(r->>'unit_price')::numeric; rate:=(r->>'tax_percent')::numeric;
  net_amount:=round(q*price,2); idx:=idx+1;
  insert into public.invoice_items(invoice_id,description,quantity,unit_price,tax_percent,net,tax,position) values(v.id,trim(r->>'description'),q,price,rate,net_amount,round(net_amount*rate/100,2),idx);
 end loop;
 update public.invoices set subtotal=(select sum(net) from public.invoice_items where invoice_id=v.id),tax_total=(select sum(tax) from public.invoice_items where invoice_id=v.id),total=(select sum(net+tax) from public.invoice_items where invoice_id=v.id) where id=v.id;
 insert into public.billing_events(invoice_id,action) values(v.id,'Draft saved');
 return v.id;
end $$;
create function public.invoice_action(p_invoice uuid,p_action text) returns void language plpgsql security definer set search_path='' as $$
declare v public.invoices;
begin
 if not public.is_admin() then raise exception 'Administrator access required'; end if;
 select * into v from public.invoices where id=p_invoice for update;
 if not found then raise exception 'Invoice unavailable'; end if;
 if p_action='issue' and v.status='Draft' and v.total>0 and length(trim(v.bank_instructions))>0 then
  update public.invoices set status='Issued' where id=v.id;
 elsif p_action='void' and v.status<>'Void' and not exists(select 1 from public.payment_claims where invoice_id=v.id and status in ('Pending','Verified')) then
  update public.invoices set status='Void' where id=v.id;
 else raise exception 'Cannot perform this action. Issue requires a positive total and bank instructions; void requires no pending or verified payments.'; end if;
 insert into public.billing_events(invoice_id,action) values(v.id,p_action);
end $$;
create function public.submit_payment(p_invoice uuid,p_amount numeric,p_reference text,p_date date,p_notes text) returns uuid language plpgsql security definer set search_path='' as $$
declare v public.invoices; pid uuid; outstanding numeric;
begin
 if not public.can_invoice(p_invoice) then raise exception 'Invoice unavailable'; end if;
 select * into v from public.invoices where id=p_invoice for update;
 if v.status<>'Issued' then raise exception 'Invoice is not payable'; end if;
 outstanding:=v.total-coalesce((select sum(amount) from public.payment_claims where invoice_id=v.id and status in ('Pending','Verified')),0);
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) or p_amount>outstanding then raise exception 'Amount exceeds balance after pending payments or has invalid precision'; end if;
 if p_date is null or p_date>(now() at time zone 'UTC')::date then raise exception 'Payment date cannot be in the future'; end if;
 if exists(select 1 from public.payment_claims where invoice_id=v.id and lower(trim(reference))=lower(trim(p_reference)) and status in ('Pending','Verified')) then raise exception 'This payment reference has already been submitted'; end if;
 insert into public.payment_claims(invoice_id,amount,reference,paid_on,notes) values(v.id,p_amount,trim(p_reference),p_date,p_notes) returning id into pid;
 insert into public.billing_events(invoice_id,action,detail) values(v.id,'Payment submitted',pid::text);
 return pid;
end $$;
create function public.review_payment(p_payment uuid,p_action text,p_note text) returns void language plpgsql security definer set search_path='' as $$
declare c public.payment_claims; v public.invoices;
begin
 if not public.is_admin() then raise exception 'Administrator access required'; end if;
 select * into c from public.payment_claims where id=p_payment;
 if not found then raise exception 'Payment unavailable'; end if;
 select * into v from public.invoices where id=c.invoice_id for update;
 select * into c from public.payment_claims where id=p_payment for update;
 if p_action='verify' and c.status='Pending' and v.status='Issued' then
  if c.amount>v.total-coalesce((select sum(amount) from public.payment_claims where invoice_id=v.id and status='Verified'),0) then raise exception 'Payment exceeds outstanding balance'; end if;
  update public.payment_claims set status='Verified',reviewed_by=auth.uid(),reviewed_at=now(),review_note=p_note where id=c.id;
 elsif (p_action='reject' and c.status='Pending') or (p_action='reverse' and c.status='Verified') then
  if length(trim(coalesce(p_note,'')))<3 then raise exception 'Enter a reason'; end if;
  update public.payment_claims set status=case when p_action='reject' then 'Rejected' else 'Reversed' end,reviewed_by=auth.uid(),reviewed_at=now(),review_note=p_note where id=c.id;
 else raise exception 'Payment already reviewed or action invalid'; end if;
 insert into public.billing_events(invoice_id,action,detail) values(v.id,'Payment '||p_action,c.id::text||' '||coalesce(p_note,''));
end $$;

create table public.maintenance_plans(
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects,
 equipment_id uuid references public.equipment, title text not null check(length(trim(title)) between 1 and 250),
 frequency text not null check(frequency in ('Daily','Weekly','Monthly')), anchor_date date not null,
 next_due date not null, end_date date, lead_days integer not null default 7 check(lead_days between 0 and 90),
 assignee uuid references public.profiles, priority text not null default 'Normal' check(priority in ('Low','Normal','High','Urgent')),
 internal boolean not null default false, active boolean not null default true, checklist jsonb not null default '[]'::jsonb,
 created_at timestamptz not null default now(),check(end_date is null or end_date>=anchor_date),check(jsonb_typeof(checklist)='array' and jsonb_array_length(checklist)<=50)
);
create table public.maintenance_runs(id uuid primary key default gen_random_uuid(),plan_id uuid not null references public.maintenance_plans,task_id uuid not null references public.tasks,due_on date not null,created_at timestamptz not null default now(),unique(plan_id,due_on));
alter table public.maintenance_plans enable row level security;
alter table public.maintenance_runs enable row level security;
create policy maintenance_read on public.maintenance_plans for select to authenticated using(public.can_project(project_id) and (not internal or public.is_staff()));
create policy maintenance_manage on public.maintenance_plans for all to authenticated using(public.is_staff()) with check(public.is_staff());
create policy maintenance_run_read on public.maintenance_runs for select to authenticated using(exists(select 1 from public.tasks t where t.id=task_id and public.can_project(t.project_id) and (not t.internal or public.is_staff())));
grant select,insert,update on public.maintenance_plans to authenticated;
grant select on public.maintenance_runs to authenticated;
create function public.validate_maintenance() returns trigger language plpgsql security definer set search_path='' as $$
declare item jsonb;
begin
 if tg_op='UPDATE' and (new.project_id<>old.project_id or new.anchor_date<>old.anchor_date or new.frequency<>old.frequency) then raise exception 'Create a new plan to change project, start date or frequency'; end if;
 if tg_op='INSERT' then new.next_due:=new.anchor_date; end if;
 if (tg_op='INSERT' or new.equipment_id is distinct from old.equipment_id) and new.equipment_id is not null and not exists(select 1 from public.equipment e join public.projects p on p.company_id=e.company_id where e.id=new.equipment_id and p.id=new.project_id and e.status<>'Retired') then raise exception 'Choose non-retired equipment from the project company'; end if;
 if (tg_op='INSERT' or new.assignee is distinct from old.assignee) and new.assignee is not null and not exists(select 1 from public.profiles where id=new.assignee and active and role in ('admin','team')) then raise exception 'Choose an active team member'; end if;
 for item in select value from jsonb_array_elements(new.checklist) loop
  if jsonb_typeof(item)<>'string' or length(trim(item#>>'{}')) not between 1 and 300 then raise exception 'Checklist items must contain 1 to 300 characters'; end if;
 end loop;
 return new;
end $$;
create trigger maintenance_validate before insert or update on public.maintenance_plans for each row execute function public.validate_maintenance();
-- Explicitly restrict editable columns. next_due is maintained by the scheduler only.
revoke update on public.maintenance_plans from authenticated;
grant update(title,equipment_id,end_date,lead_days,assignee,priority,internal,active,checklist) on public.maintenance_plans to authenticated;
create function public.generate_maintenance() returns integer language plpgsql security definer set search_path='' as $$
declare p public.maintenance_plans; task_uuid uuid; item jsonb; count_all integer:=0; count_plan integer; next_month date; today date:=(now() at time zone 'UTC')::date;
begin
 if not public.is_staff() and coalesce(auth.role(),'')<>'service_role' and not (auth.uid() is null and session_user='postgres') then raise exception 'Staff access required'; end if;
 for p in select * from public.maintenance_plans where active and next_due<=today+lead_days and (end_date is null or next_due<=end_date) and (equipment_id is null or not exists(select 1 from public.equipment e where e.id=equipment_id and e.status='Retired')) order by next_due limit 100 for update skip locked loop
  count_plan:=0;
  while p.next_due<=today+p.lead_days and (p.end_date is null or p.next_due<=p.end_date) and count_plan<50 and count_all<500 loop
   if not exists(select 1 from public.maintenance_runs where plan_id=p.id and due_on=p.next_due) then
    -- Inactive assignees become unassigned; retired equipment does not create new work.
    if p.equipment_id is not null and exists(select 1 from public.equipment where id=p.equipment_id and status='Retired') then exit; end if;
    insert into public.tasks(project_id,title,assignee,deadline,internal,priority,equipment_id)
     values(p.project_id,p.title||' · '||p.next_due::text,case when exists(select 1 from public.profiles where id=p.assignee and active and role in ('admin','team')) then p.assignee else null end,p.next_due,p.internal,p.priority,p.equipment_id) returning id into task_uuid;
    insert into public.maintenance_runs(plan_id,task_id,due_on) values(p.id,task_uuid,p.next_due);
    for item in select value from jsonb_array_elements(p.checklist) loop insert into public.task_items(task_id,title) values(task_uuid,item#>>'{}'); end loop;
    count_all:=count_all+1;
   end if;
   count_plan:=count_plan+1;
   if p.frequency='Daily' then p.next_due:=p.next_due+1;
   elsif p.frequency='Weekly' then p.next_due:=p.next_due+7;
   else
    next_month:=(date_trunc('month',p.next_due)+interval '1 month')::date;
    p.next_due:=next_month+(least(extract(day from p.anchor_date)::integer,extract(day from (next_month+interval '1 month - 1 day'))::integer)-1);
   end if;
  end loop;
  update public.maintenance_plans set next_due=p.next_due where id=p.id;
 end loop;
 return count_all;
end $$;

create table public.notification_preferences(
 id uuid primary key references public.profiles, email_enabled boolean not null default false,
 sms_enabled boolean not null default false, whatsapp_enabled boolean not null default false,
 phone text not null default '' check(phone='' or phone ~ '^\+[1-9][0-9]{7,14}$'),
 consent_at timestamptz, updated_at timestamptz not null default now()
);
create table public.notifications(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles,
 company_id uuid references public.companies, event_key text not null,event_type text not null,
 channel text not null check(channel in ('email','sms','whatsapp')),status text not null default 'Queued' check(status in ('Queued','Processing','Submitted','Failed','Unknown','Unconfigured','Cancelled')),
 provider_id text,last_error text,attempted_at timestamptz,created_at timestamptz not null default now(),unique(user_id,event_key,channel)
);
alter table public.notification_preferences enable row level security;
alter table public.notifications enable row level security;
create policy notification_pref_read on public.notification_preferences for select to authenticated using(id=auth.uid() and exists(select 1 from public.profiles where id=auth.uid() and active));
create policy notification_read on public.notifications for select to authenticated using(public.is_admin() or (user_id=auth.uid() and exists(select 1 from public.profiles p where p.id=auth.uid() and p.active and (p.role in ('admin','team') or p.company_id=notifications.company_id))));
grant select on public.notification_preferences,public.notifications to authenticated;
create function public.save_notification_preferences(p_email boolean,p_sms boolean,p_whatsapp boolean,p_phone text) returns void language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.profiles where id=auth.uid() and active) then raise exception 'Active account required'; end if;
 if (p_sms or p_whatsapp) and coalesce(p_phone,'') !~ '^\+[1-9][0-9]{7,14}$' then raise exception 'Use an international phone number such as +923001234567'; end if;
 insert into public.notification_preferences(id,email_enabled,sms_enabled,whatsapp_enabled,phone,consent_at) values(auth.uid(),p_email,p_sms,p_whatsapp,trim(p_phone),now())
 on conflict(id) do update set email_enabled=excluded.email_enabled,sms_enabled=excluded.sms_enabled,whatsapp_enabled=excluded.whatsapp_enabled,phone=excluded.phone,consent_at=now(),updated_at=now();
end $$;
-- No customer text is put in outbound alerts. Recipients sign in to see protected records.
create function public.queue_alert(p_key text,p_type text,p_company uuid,p_staff_only boolean,p_user uuid default null,p_admin_only boolean default false) returns void language plpgsql security definer set search_path='' as $$
begin
 insert into public.notifications(user_id,company_id,event_key,event_type,channel)
 select u.id,p_company,p_key,p_type,c.channel from public.profiles u join public.notification_preferences f on f.id=u.id
 cross join lateral (values ('email',f.email_enabled),('sms',f.sms_enabled),('whatsapp',f.whatsapp_enabled)) c(channel,enabled)
 where u.active and c.enabled and (p_user is null or u.id=p_user)
 and (case when p_admin_only then u.role='admin' else u.role in ('admin','team') or (not p_staff_only and u.role='client' and u.company_id=p_company) end)
 on conflict(user_id,event_key,channel) do nothing;
end $$;
create function public.business_event_alert() returns trigger language plpgsql security definer set search_path='' as $$
declare cid uuid;
begin
 if tg_table_name='tasks' then
  select company_id into cid from public.projects where id=new.project_id;
  if new.assignee is not null and (tg_op='INSERT' or new.assignee is distinct from old.assignee) then
   perform public.queue_alert('task:'||new.id||':'||new.assignee||':'||extract(epoch from statement_timestamp())::text,'Task assigned',cid,true,new.assignee);
  end if;
 elsif tg_table_name='tickets' then
  select company_id into cid from public.projects where id=new.project_id;
  if tg_op='INSERT' then perform public.queue_alert('ticket:'||new.id,'New support request',cid,true);
  elsif new.status is distinct from old.status then perform public.queue_alert('ticket-status:'||new.id||':'||extract(epoch from statement_timestamp())::text,'Support status updated',cid,false); end if;
 elsif tg_table_name='messages' then
  if not new.internal and new.ticket_id is not null then
   select company_id into cid from public.projects where id=new.project_id;
   perform public.queue_alert('reply:'||new.id,'Support reply added',cid,false);
  end if;
 elsif tg_table_name='payment_claims' then
  select company_id into cid from public.invoices where id=new.invoice_id;
  if tg_op='INSERT' then perform public.queue_alert('payment:'||new.id,'Payment awaiting review',cid,true,null,true);
  elsif new.status is distinct from old.status then
   -- Only the submitter receives the review alert; never include payment details.
   insert into public.notifications(user_id,company_id,event_key,event_type,channel)
    select u.id,cid,'payment-review:'||new.id||':'||new.status,'Payment review updated',c.channel from public.profiles u join public.notification_preferences f on f.id=u.id
    cross join lateral(values('email',f.email_enabled),('sms',f.sms_enabled),('whatsapp',f.whatsapp_enabled)) c(channel,enabled)
    where u.id=new.submitted_by and u.active and c.enabled and (u.role='admin' or (u.role='client' and u.company_id=cid)) on conflict do nothing;
  end if;
 elsif tg_table_name='invoices' then
  if new.status='Issued' and old.status='Draft' then
   -- Client billing alerts, plus admins; team never receives financial notifications.
   perform public.queue_alert('invoice-admin:'||new.id,'Invoice issued',new.company_id,true,null,true);
   insert into public.notifications(user_id,company_id,event_key,event_type,channel)
    select u.id,new.company_id,'invoice:'||new.id,'Invoice issued',c.channel from public.profiles u join public.notification_preferences f on f.id=u.id
    cross join lateral(values('email',f.email_enabled),('sms',f.sms_enabled),('whatsapp',f.whatsapp_enabled)) c(channel,enabled)
    where u.active and u.role='client' and u.company_id=new.company_id and c.enabled on conflict do nothing;
  end if;
 end if;
 return new;
end $$;
create trigger task_alert after insert or update on public.tasks for each row execute function public.business_event_alert();
create trigger ticket_alert after insert or update on public.tickets for each row execute function public.business_event_alert();
create trigger message_alert after insert on public.messages for each row execute function public.business_event_alert();
create trigger payment_alert after insert or update on public.payment_claims for each row execute function public.business_event_alert();
create trigger invoice_alert after update on public.invoices for each row execute function public.business_event_alert();
create function public.queue_due_alerts() returns integer language plpgsql security definer set search_path='' as $$
declare t record; n integer:=0;
begin
 if not public.is_admin() and coalesce(auth.role(),'')<>'service_role' and not (auth.uid() is null and session_user='postgres') then raise exception 'Administrator access required'; end if;
 for t in select v.*,p.company_id from public.tickets v join public.projects p on p.id=v.project_id where v.status<>'Resolved' and ((v.first_response_at is null and v.response_due_at<now()) or v.resolution_due_at<now()) loop
  perform public.queue_alert('sla-overdue:'||t.id,'SLA overdue',t.company_id,true); n:=n+1;
 end loop;
 for t in select * from public.contracts where status<>'Cancelled' and renewal_date<=(now() at time zone 'UTC')::date+30 loop
  perform public.queue_alert('renewal:'||t.id||':'||t.renewal_date,'Contract renewal due',t.company_id,true); n:=n+1;
 end loop;
 return n;
end $$;
create function public.claim_notifications(p_channels text[]) returns setof public.notifications language plpgsql security definer set search_path='' as $$
begin
 if coalesce(auth.role(),'')<>'service_role' and not (auth.uid() is null and session_user='postgres') then raise exception 'Server access required'; end if;
 update public.notifications set status='Unknown',last_error='Worker interrupted; check provider before retrying' where status='Processing' and attempted_at<now()-interval '10 minutes';
 update public.notifications set status='Unconfigured',last_error='Channel not configured' where status='Queued' and not(channel=any(p_channels));
 return query update public.notifications set status='Processing',attempted_at=now(),last_error=null where id in
 (select id from public.notifications where status in ('Queued','Unconfigured') and channel=any(p_channels) order by created_at limit 5 for update skip locked) returning *;
end $$;
create function public.retry_notification(p_id uuid) returns void language plpgsql security definer set search_path='' as $$
begin
 if not public.is_admin() then raise exception 'Administrator access required'; end if;
 update public.notifications set status='Queued',last_error=null where id=p_id and status in ('Failed','Unconfigured');
 if not found then raise exception 'Only failed or unconfigured alerts can be retried. Unknown submissions need provider reconciliation.'; end if;
end $$;
-- Override Supabase default table privileges; all business writes use checked RPCs.
revoke all on public.task_imports,public.invoices,public.invoice_items,public.payment_claims,public.billing_events,public.maintenance_plans,public.maintenance_runs,public.notification_preferences,public.notifications from anon,authenticated;
revoke all on sequence public.invoice_numbers from anon,authenticated;
grant select on public.task_imports,public.invoices,public.invoice_items,public.payment_claims,public.billing_events,public.maintenance_plans,public.maintenance_runs,public.notification_preferences,public.notifications to authenticated;
grant insert on public.maintenance_plans to authenticated;
grant update(title,equipment_id,end_date,lead_days,assignee,priority,internal,active,checklist) on public.maintenance_plans to authenticated;
-- Default execution privileges are removed from every new function.
revoke all on function public.import_tasks(uuid,uuid,jsonb),public.can_invoice(uuid),public.save_invoice(uuid,uuid,text,date,date,text,text,jsonb),public.invoice_action(uuid,text),public.submit_payment(uuid,numeric,text,date,text),public.review_payment(uuid,text,text),public.validate_maintenance(),public.generate_maintenance(),public.save_notification_preferences(boolean,boolean,boolean,text),public.queue_alert(text,text,uuid,boolean,uuid,boolean),public.business_event_alert(),public.queue_due_alerts(),public.claim_notifications(text[]),public.retry_notification(uuid) from public,anon,authenticated;
grant execute on function public.import_tasks(uuid,uuid,jsonb),public.can_invoice(uuid),public.save_invoice(uuid,uuid,text,date,date,text,text,jsonb),public.invoice_action(uuid,text),public.submit_payment(uuid,numeric,text,date,text),public.review_payment(uuid,text,text),public.generate_maintenance(),public.save_notification_preferences(boolean,boolean,boolean,text),public.queue_due_alerts(),public.retry_notification(uuid) to authenticated;
grant execute on function public.generate_maintenance(),public.queue_due_alerts(),public.claim_notifications(text[]) to service_role;
grant select,update on public.notifications to service_role;
grant select on public.notification_preferences,public.profiles to service_role;
create index invoices_company on public.invoices(company_id);
create index invoice_items_invoice on public.invoice_items(invoice_id);
create index payment_claim_invoice on public.payment_claims(invoice_id);
create index billing_events_invoice on public.billing_events(invoice_id);
create index maintenance_due on public.maintenance_plans(next_due) where active;
create index notifications_queue on public.notifications(status,created_at);
notify pgrst,'reload schema';
commit;
