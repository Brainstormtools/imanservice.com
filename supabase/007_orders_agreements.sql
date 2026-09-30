-- Apply once after 006_calendar_estimates.sql. Additive; existing SLA rules are unchanged.
begin;
create table public.catalogue_items(
 id uuid primary key default gen_random_uuid(),sku text not null unique check(length(trim(sku)) between 1 and 60),
 name text not null check(length(trim(name)) between 1 and 200),description text not null default '' check(length(description)<=4000),
 kind text not null check(kind in ('Service','Product')),currency text not null check(currency ~ '^[A-Z]{3}$'),
 unit_price numeric(12,2) not null check(unit_price>=0 and unit_price::text<>'NaN'),tax_percent numeric(5,2) not null check(tax_percent between 0 and 100),
 active boolean not null default true,version integer not null default 1,created_at timestamptz not null default now()
);
create sequence public.order_numbers;
create table public.client_orders(
 id uuid primary key,number text not null unique default ('ORD-'||lpad(nextval('public.order_numbers')::text,6,'0')),
 company_id uuid not null references public.companies,company_name text not null,author_id uuid not null default auth.uid() references public.profiles,
 request_payload jsonb not null,items jsonb not null,currency text not null,subtotal numeric(14,2) not null,tax_total numeric(14,2) not null,total numeric(14,2) not null,
 notes text not null default '' check(length(notes)<=4000),status text not null default 'Submitted' check(status in ('Submitted','Confirmed','In progress','Fulfilled','Cancelled','Rejected')),
 version integer not null default 1,project_id uuid references public.projects,invoice_id uuid references public.invoices,created_at timestamptz not null default now()
);
create table public.order_history(id uuid primary key default gen_random_uuid(),order_id uuid not null references public.client_orders,action text not null,note text not null default '' check(length(note)<=2000),actor_id uuid not null default auth.uid() references public.profiles,created_at timestamptz not null default now());
create function public.commercial_company(p_company uuid) returns boolean language sql stable security definer set search_path='' as $$
 select public.is_admin() or exists(select 1 from public.profiles where id=auth.uid() and active and role='client' and company_id=p_company);
$$;
alter table public.catalogue_items enable row level security;
alter table public.client_orders enable row level security;
alter table public.order_history enable row level security;
create policy catalogue_read on public.catalogue_items for select to authenticated using(public.is_admin() or (active and exists(select 1 from public.profiles where id=auth.uid() and active and role='client')));
create policy order_read on public.client_orders for select to authenticated using(public.commercial_company(company_id));
create policy order_history_read on public.order_history for select to authenticated using(exists(select 1 from public.client_orders o where o.id=order_id and public.commercial_company(o.company_id)));
create function public.save_catalogue_item(p_id uuid,p_version integer,p_sku text,p_name text,p_description text,p_kind text,p_currency text,p_price numeric,p_tax numeric,p_active boolean) returns uuid language plpgsql security definer set search_path='' as $$
declare c public.catalogue_items;
begin
 if not public.is_admin() then raise exception 'Administrator access required';end if;
 if p_id is null then
  insert into public.catalogue_items(sku,name,description,kind,currency,unit_price,tax_percent,active) values(upper(trim(p_sku)),trim(p_name),p_description,p_kind,upper(p_currency),p_price,p_tax,p_active) returning * into c;
 else
  select * into c from public.catalogue_items where id=p_id for update;
  if not found or c.version is distinct from p_version then raise exception 'Item changed or unavailable. Refresh before saving.';end if;
  update public.catalogue_items set sku=upper(trim(p_sku)),name=trim(p_name),description=p_description,kind=p_kind,currency=upper(p_currency),unit_price=p_price,tax_percent=p_tax,active=p_active,version=version+1 where id=c.id;
 end if;return c.id;
end $$;
create function public.submit_order(p_id uuid,p_company uuid,p_lines jsonb,p_notes text) returns uuid language plpgsql security definer set search_path='' as $$
declare c public.catalogue_items;o public.client_orders;r jsonb;q numeric(10,3);n numeric(14,2);t numeric(14,2);net_sum numeric(14,2):=0;tax_sum numeric(14,2):=0;lines jsonb:='[]';cur text;cname text;payload jsonb;
begin
 if not public.commercial_company(p_company) then raise exception 'Client or administrator access required';end if;
 if p_id is null then raise exception 'Request ID required';end if;
 if jsonb_typeof(p_lines) is distinct from 'array' or jsonb_array_length(p_lines) not between 1 and 100 then raise exception 'Use 1 to 100 order lines';end if;
 payload:=jsonb_build_object('company',p_company,'lines',p_lines,'notes',p_notes);
 perform pg_advisory_xact_lock(hashtextextended(p_id::text,0));
 select * into o from public.client_orders where id=p_id;
 if found then
  if o.author_id<>auth.uid() or o.request_payload is distinct from payload then raise exception 'Request ID already used';end if;
  return o.id;
 end if;
 if (select count(distinct value->>'id') from jsonb_array_elements(p_lines))<>jsonb_array_length(p_lines) then raise exception 'Use one line per catalogue item';end if;
 select name into cname from public.companies where id=p_company;if cname is null then raise exception 'Company unavailable';end if;
 -- Lock in a deterministic order and verify the displayed version before accepting a price.
 for r in select value from jsonb_array_elements(p_lines) order by value->>'id' loop
  select * into c from public.catalogue_items where id=(r->>'id')::uuid for share;
  if not found or not c.active or c.version is distinct from (r->>'version')::integer then raise exception 'Catalogue changed. Refresh and review your order.';end if;
  q:=(r->>'quantity')::numeric;
  if q is null or q<=0 or q>100000 or q::text='NaN' then raise exception 'Invalid quantity';end if;
  if cur is not null and cur<>c.currency then raise exception 'Use one currency per order';end if;cur:=c.currency;
  n:=round(q*c.unit_price,2);t:=round(n*c.tax_percent/100,2);net_sum:=net_sum+n;tax_sum:=tax_sum+t;
  lines:=lines||jsonb_build_array(jsonb_build_object('catalogue_id',c.id,'sku',c.sku,'description',c.name,'quantity',q,'unit_price',c.unit_price,'tax_percent',c.tax_percent,'net',n,'tax',t));
 end loop;
 insert into public.client_orders(id,company_id,company_name,request_payload,items,currency,subtotal,tax_total,total,notes) values(p_id,p_company,cname,payload,lines,cur,net_sum,tax_sum,net_sum+tax_sum,p_notes);
 insert into public.order_history(order_id,action) values(p_id,'Submitted');return p_id;
end $$;
create function public.order_action(p_id uuid,p_version integer,p_status text,p_note text) returns void language plpgsql security definer set search_path='' as $$
declare o public.client_orders;
begin
 select * into o from public.client_orders where id=p_id for update;
 if not found or not public.commercial_company(o.company_id) then raise exception 'Order unavailable';end if;
 if o.version is distinct from p_version then raise exception 'Order changed. Refresh before continuing.';end if;
 if not public.is_admin() then
  if o.status<>'Submitted' or p_status is distinct from 'Cancelled' then raise exception 'Clients can cancel submitted orders only';end if;
 elsif not ((o.status='Submitted' and p_status in ('Confirmed','Rejected','Cancelled')) or (o.status='Confirmed' and p_status in ('In progress','Cancelled')) or (o.status='In progress' and p_status in ('Fulfilled','Cancelled'))) then raise exception 'Invalid order transition';
 end if;
 if p_status in ('Cancelled','Rejected') then
  if length(trim(coalesce(p_note,'')))<3 then raise exception 'Enter a reason';end if;
  if o.invoice_id is not null or o.project_id is not null then raise exception 'Converted orders cannot be cancelled here. Review their project and invoice separately.';end if;
 end if;
 update public.client_orders set status=p_status,version=version+1 where id=o.id;
 insert into public.order_history(order_id,action,note) values(o.id,p_status,p_note);
end $$;
create function public.convert_order(p_id uuid,p_target text,p_due date default null) returns uuid language plpgsql security definer set search_path='' as $$
declare o public.client_orders;result uuid;
begin
 if not public.is_admin() then raise exception 'Administrator access required';end if;
 select * into o from public.client_orders where id=p_id for update;
 if not found or o.status not in ('Confirmed','In progress','Fulfilled') then raise exception 'Confirmed order required';end if;
 if p_target='project' then
  if o.project_id is not null then return o.project_id;end if;
  insert into public.projects(company_id,title,description) values(o.company_id,o.number||' - '||o.company_name,o.notes||E'\n'||(select string_agg((value->>'description')||' x '||(value->>'quantity'),E'\n') from jsonb_array_elements(o.items))) returning id into result;
  update public.client_orders set project_id=result,version=version+1 where id=o.id;
 elsif p_target='invoice' then
  if o.invoice_id is not null then return o.invoice_id;end if;
  result:=public.save_invoice(null,o.company_id,o.currency,(now() at time zone 'UTC')::date,p_due,'From order '||o.number,'',o.items);
  update public.client_orders set invoice_id=result,version=version+1 where id=o.id;
 else raise exception 'Choose project or invoice';end if;
 insert into public.order_history(order_id,action) values(o.id,'Converted to '||p_target);return result;
end $$;

create table public.contract_documents(
 id uuid primary key default gen_random_uuid(),contract_id uuid not null references public.contracts,company_id uuid not null references public.companies,
 revision integer not null,previous_id uuid unique references public.contract_documents,title text not null check(length(trim(title)) between 1 and 200),
 body text not null check(length(trim(body)) between 1 and 20000),snapshot jsonb not null,
 status text not null default 'Draft' check(status in ('Draft','Published','Accepted','Declined','Withdrawn','Superseded')),
 version integer not null default 1,published_at timestamptz,decided_at timestamptz,decided_by uuid references public.profiles,
 decision_note text not null default '' check(length(decision_note)<=2000),author_id uuid not null default auth.uid() references public.profiles,
 created_at timestamptz not null default now(),unique(contract_id,revision)
);
create table public.contract_document_history(id uuid primary key default gen_random_uuid(),document_id uuid not null references public.contract_documents,action text not null,actor_id uuid not null default auth.uid() references public.profiles,created_at timestamptz not null default now());
alter table public.contract_documents enable row level security;
alter table public.contract_document_history enable row level security;
create function public.can_contract_document(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$
 select public.is_admin() or exists(select 1 from public.contract_documents d where d.id=p_id and d.published_at is not null and public.commercial_company(d.company_id));
$$;
create policy document_read on public.contract_documents for select to authenticated using(public.can_contract_document(id));
create policy document_history_read on public.contract_document_history for select to authenticated using(public.can_contract_document(document_id));
create function public.save_contract_document(p_id uuid,p_version integer,p_contract uuid,p_title text,p_body text) returns uuid language plpgsql security definer set search_path='' as $$
declare c public.contracts;d public.contract_documents;rev integer;
begin
 if not public.is_admin() then raise exception 'Administrator access required';end if;
 select * into c from public.contracts where id=p_contract for share;if not found then raise exception 'Contract unavailable';end if;
 if p_id is null then
  perform pg_advisory_xact_lock(hashtextextended(p_contract::text,1));
  if exists(select 1 from public.contract_documents where contract_id=p_contract) then raise exception 'Use Create revision on the latest document';end if;
  insert into public.contract_documents(contract_id,company_id,revision,title,body,snapshot) values(c.id,c.company_id,1,trim(p_title),p_body,to_jsonb(c)) returning * into d;
 else
  select * into d from public.contract_documents where id=p_id for update;
  if not found or d.status<>'Draft' or d.contract_id<>p_contract or d.version is distinct from p_version then raise exception 'Draft changed or unavailable. Refresh before saving.';end if;
  update public.contract_documents set title=trim(p_title),body=p_body,snapshot=to_jsonb(c),version=version+1 where id=d.id;
 end if;
 insert into public.contract_document_history(document_id,action) values(d.id,'Draft saved with current contract snapshot');return d.id;
end $$;
create function public.contract_document_action(p_id uuid,p_version integer,p_action text,p_note text default '') returns uuid language plpgsql security definer set search_path='' as $$
declare d public.contract_documents;c public.contracts;result uuid;
begin
 select * into d from public.contract_documents where id=p_id for update;
 if not found or not public.can_contract_document(p_id) then raise exception 'Document unavailable';end if;
 if d.version is distinct from p_version then raise exception 'Document changed. Refresh before continuing.';end if;result:=d.id;
 if p_action in ('accept','decline') then
  if not exists(select 1 from public.profiles where id=auth.uid() and active and role='client' and company_id=d.company_id) then raise exception 'Client decision required';end if;
  if d.status<>'Published' then raise exception 'Document is not open for a decision';end if;
  update public.contract_documents set status=case p_action when 'accept' then 'Accepted' else 'Declined' end,decided_at=now(),decided_by=auth.uid(),decision_note=p_note,version=version+1 where id=d.id;
 elsif public.is_admin() then
  if p_action='publish' and d.status='Draft' then
   update public.contract_documents set status='Published',published_at=now(),version=version+1 where id=d.id;
  elsif p_action='withdraw' and d.status='Published' then
   update public.contract_documents set status='Withdrawn',version=version+1 where id=d.id;
  elsif p_action='revise' and d.status in ('Published','Accepted','Declined','Withdrawn') then
   perform pg_advisory_xact_lock(hashtextextended(d.contract_id::text,1));
   if exists(select 1 from public.contract_documents where contract_id=d.contract_id and revision>d.revision) then raise exception 'Revise the latest document';end if;
   select * into c from public.contracts where id=d.contract_id for share;
   insert into public.contract_documents(contract_id,company_id,revision,previous_id,title,body,snapshot) values(d.contract_id,d.company_id,d.revision+1,d.id,d.title,d.body,to_jsonb(c)) returning id into result;
   -- Accepted revisions remain an immutable record of what the client accepted.
   update public.contract_documents set status=case when status='Accepted' then 'Accepted' else 'Superseded' end,version=version+1 where id=d.id;
   insert into public.contract_document_history(document_id,action) values(result,'Revision created with current contract snapshot');
  else raise exception 'Action unavailable for this state';end if;
 else raise exception 'Administrator access required';end if;
 insert into public.contract_document_history(document_id,action) values(d.id,p_action);return result;
end $$;
revoke all on public.catalogue_items,public.client_orders,public.order_history,public.contract_documents,public.contract_document_history from anon,authenticated;
grant select on public.catalogue_items,public.client_orders,public.order_history,public.contract_documents,public.contract_document_history to authenticated;
revoke all on sequence public.order_numbers from anon,authenticated;
revoke all on function public.commercial_company(uuid),public.save_catalogue_item(uuid,integer,text,text,text,text,text,numeric,numeric,boolean),public.submit_order(uuid,uuid,jsonb,text),public.order_action(uuid,integer,text,text),public.convert_order(uuid,text,date),public.can_contract_document(uuid),public.save_contract_document(uuid,integer,uuid,text,text),public.contract_document_action(uuid,integer,text,text) from public,anon,authenticated;
grant execute on function public.commercial_company(uuid),public.save_catalogue_item(uuid,integer,text,text,text,text,text,numeric,numeric,boolean),public.submit_order(uuid,uuid,jsonb,text),public.order_action(uuid,integer,text,text),public.convert_order(uuid,text,date),public.can_contract_document(uuid),public.save_contract_document(uuid,integer,uuid,text,text),public.contract_document_action(uuid,integer,text,text) to authenticated;
create index orders_company on public.client_orders(company_id);
create index order_history_parent on public.order_history(order_id);
create index documents_company on public.contract_documents(company_id);
create index document_history_parent on public.contract_document_history(document_id);
notify pgrst,'reload schema';
commit;
