begin;
create sequence public.crm_boq_offer_number;
create table public.crm_boq_offers (
 id uuid primary key, number text not null unique default ('CO-'||lpad(nextval('public.crm_boq_offer_number')::text,6,'0')),
 project_id uuid not null references public.projects, change_id uuid not null references public.crm_project_changes,
 change_version integer not null, sale_id uuid not null references public.crm_sales, baseline_id uuid not null references public.crm_quote_publications,
 revision integer not null, previous_id uuid references public.crm_boq_offers,
 currency text not null, data jsonb not null, reason text not null, version integer not null default 1,
 status text not null default 'Draft' check(status in ('Draft','Published')),
 created_by uuid not null references public.profiles, created_at timestamptz not null default now(),
 published_by uuid references public.profiles, publish_reason text,
 unique(change_id,revision)
);
create table public.crm_boq_offer_publications (
 id uuid primary key references public.crm_boq_offers, project_id uuid not null references public.projects,
 company_id uuid not null references public.companies, change_id uuid not null references public.crm_project_changes,
 number text not null, revision integer not null, source_version integer not null,
 project_title text not null, company_name text not null, baseline_number text not null, baseline_revision integer not null,
 title text not null, currency text not null, valid_until date not null, terms text not null, items jsonb not null,
 subtotal numeric(16,2) not null, service_tax_base numeric(16,2) not null, pra_percent numeric(5,2) not null,
 tax_total numeric(16,2) not null, total numeric(16,2) not null, wht_percent numeric(5,2) not null,
 wht_total numeric(16,2) not null, receivable numeric(16,2) not null,
 status text not null default 'Published' check(status in ('Published','Accepted','Declined','Withdrawn','Superseded')),
 version integer not null default 1, published_at timestamptz not null default now(),
 decided_by uuid references public.profiles, decided_at timestamptz, decision_note text not null default '', consent boolean not null default false
);
create unique index crm_boq_one_open_offer on public.crm_boq_offer_publications(change_id) where status in ('Published','Accepted');
create table public.crm_boq_offer_history (
 id uuid primary key default gen_random_uuid(),offer_id uuid not null references public.crm_boq_offers,
 project_id uuid not null references public.projects,action text not null,before_record jsonb,after_record jsonb not null,
 reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now()
);
create index crm_boq_offers_project on public.crm_boq_offers(project_id);
create index crm_boq_offers_sale on public.crm_boq_offers(sale_id);
create index crm_boq_offers_baseline on public.crm_boq_offers(baseline_id);
create index crm_boq_offers_previous on public.crm_boq_offers(previous_id);
create index crm_boq_offers_author on public.crm_boq_offers(created_by);
create index crm_boq_offers_publisher on public.crm_boq_offers(published_by);
create index crm_boq_publication_project on public.crm_boq_offer_publications(project_id);
create index crm_boq_publication_company on public.crm_boq_offer_publications(company_id);
create index crm_boq_publication_actor on public.crm_boq_offer_publications(decided_by);
create index crm_boq_history_offer on public.crm_boq_offer_history(offer_id);
create index crm_boq_history_project on public.crm_boq_offer_history(project_id);
create index crm_boq_history_actor on public.crm_boq_offer_history(actor_id);
do $$declare t text;begin foreach t in array array['crm_boq_offers','crm_boq_offer_publications','crm_boq_offer_history'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('revoke all on public.%I from public,anon,authenticated',t);
 execute format('grant select on public.%I to authenticated',t);
end loop;end$$;
revoke all on sequence public.crm_boq_offer_number from public,anon,authenticated;
create policy boq_offer_read on public.crm_boq_offers for select to authenticated using(portal_private.execution_manager(project_id));
create policy boq_offer_history_read on public.crm_boq_offer_history for select to authenticated using(portal_private.execution_manager(project_id));
create policy boq_offer_public_read on public.crm_boq_offer_publications for select to authenticated using(
 portal_private.execution_manager(project_id) or
 (exists(select 1 from public.profiles p where p.id=auth.uid() and p.active and p.role='client' and p.company_id=crm_boq_offer_publications.company_id)
 and public.can_project(project_id)));

create function public.boq_change_offer_context() returns table(id uuid,project_id uuid,product_name text,currency text)
language sql stable security definer set search_path='' as $$
 select w.id,w.project_id,b.name,s.currency from public.crm_project_workstreams w
 join public.crm_sales s on s.id=w.sale_id join public.crm_product_lines l on l.id=w.product_line_id
 join public.crm_boards b on b.id=l.board_id
 where auth.uid() is not null and portal_private.execution_manager(w.project_id)
$$;
revoke all on function public.boq_change_offer_context() from public,anon;
grant execute on function public.boq_change_offer_context() to authenticated;

create function public.save_boq_change_offer(p_id uuid,p_version integer,p_change uuid,p_change_version integer,p_previous uuid,p_data jsonb,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare c public.crm_project_changes; s public.crm_sales; old public.crm_boq_offers; saved public.crm_boq_offers; prior uuid;
 d jsonb; item jsonb; lines jsonb:='[]'; k text; stream uuid; qty numeric; price numeric; rate numeric; base numeric;
 subtotal numeric:=0; total numeric; keys text[]:='{}'; item_key text;
begin
 select * into c from public.crm_project_changes where id=p_change;
 if c.id is null or not portal_private.execution_manager(c.project_id) then raise exception 'Assigned project manager access required';end if;
 perform 1 from public.projects where id=c.project_id and status not in ('Completed','Cancelled') for update;
 if not found or exists(select 1 from public.crm_handovers where project_id=c.project_id and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Active project without released handover required';end if;
 select * into c from public.crm_project_changes where id=p_change for update;
 if c.details->>'status' is distinct from 'Approved' or c.version is distinct from p_change_version then raise exception 'Current Approved change decision required';end if;
 select * into s from public.crm_sales where project_id=c.project_id for update;
 if s.id is null or not exists(select 1 from public.crm_quote_publications b join public.projects p on p.id=s.project_id where b.id=s.publication_id and b.status='Accepted' and b.company_id=s.company_id and p.company_id=s.company_id and b.currency=s.currency) then raise exception 'Converted project with matching accepted quotation required';end if;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Offer ID and reason required';end if;
 if jsonb_typeof(p_data) is distinct from 'object' or (select count(*) from jsonb_object_keys(p_data))<>7 then raise exception 'Complete offer fields required';end if;
 foreach k in array array['title','terms','valid_until'] loop
  if jsonb_typeof(p_data->k) is distinct from 'string' then raise exception 'Offer text fields required';end if;
 end loop;
 if length(trim(p_data->>'title')) not between 3 and 160 or length(trim(p_data->>'terms')) not between 3 and 10000 or (p_data->>'valid_until') !~ '^\d{4}-\d{2}-\d{2}$' then raise exception 'Bounded title, explicit terms and validity required';end if;
 perform (p_data->>'valid_until')::date;
 foreach k in array array['pra_percent','service_tax_base','wht_percent'] loop
  if coalesce(p_data->>k,'') !~ '^\d{1,12}(\.\d{1,2})?$' then raise exception 'Explicit bounded decimal tax fields required';end if;
 end loop;
 if (p_data->>'pra_percent')::numeric>100 or (p_data->>'wht_percent')::numeric>100 then raise exception 'Tax percentages must be 0–100';end if;
 if jsonb_typeof(p_data->'lines') is distinct from 'array' or jsonb_array_length(p_data->'lines') not between 1 and 100 then raise exception 'Use 1–100 additional BOQ items';end if;
 for item in select value from jsonb_array_elements(p_data->'lines') loop
  if jsonb_typeof(item) is distinct from 'object' or (select count(*) from jsonb_object_keys(item))<>5
   or jsonb_typeof(item->'description') is distinct from 'string' or jsonb_typeof(item->'unit') is distinct from 'string'
   or length(trim(item->>'description')) not between 3 and 1000 or length(trim(item->>'unit')) not between 1 and 30
   or coalesce(item->>'quantity','') !~ '^\d{1,9}(\.\d{1,6})?$' or coalesce(item->>'unit_price','') !~ '^\d{1,10}(\.\d{1,2})?$' then raise exception 'Complete bounded BOQ items required';end if;
  stream:=(item->>'workstream_id')::uuid;
  if stream is null or not exists(select 1 from public.crm_project_workstreams where id=stream and project_id=c.project_id and sale_id=s.id) then raise exception 'Existing project workstream required';end if;
  qty:=(item->>'quantity')::numeric;price:=(item->>'unit_price')::numeric;
  if qty<=0 or price<=0 then raise exception 'Positive additional quantities and selling prices required';end if;
  item_key:=stream::text||':'||lower(trim(item->>'description'))||':'||lower(trim(item->>'unit'));
  if item_key=any(keys) then raise exception 'Duplicate BOQ item; combine its quantity';end if;keys:=keys||item_key;
  subtotal:=subtotal+round(qty*price,2);
  lines:=lines||jsonb_build_array(jsonb_build_object('workstream_id',stream,'description',trim(item->>'description'),'unit',trim(item->>'unit'),'quantity',qty,'unit_price',price));
 end loop;
 base:=(p_data->>'service_tax_base')::numeric;rate:=(p_data->>'pra_percent')::numeric;total:=subtotal+round(base*rate/100,2);
 if subtotal<=0 or base>subtotal or total>999999999999.99 then raise exception 'Positive bounded total and taxable base within subtotal required';end if;
 d:=jsonb_build_object('title',trim(p_data->>'title'),'terms',trim(p_data->>'terms'),'valid_until',p_data->>'valid_until','pra_percent',rate,'service_tax_base',base,'wht_percent',(p_data->>'wht_percent')::numeric,'lines',lines);
 select * into old from public.crm_boq_offers where id=p_id for update;
 if old.id is not null then
  if p_version is null then
   if old.created_by=auth.uid() and old.version=1 and old.change_id=p_change and old.change_version=p_change_version and old.previous_id is not distinct from p_previous and old.data=d and old.reason=trim(p_reason) then return old.id;end if;
   raise exception 'Offer ID already used with different data';
  end if;
  if old.change_id<>p_change or old.change_version<>p_change_version or old.version is distinct from p_version or old.previous_id is distinct from p_previous then raise exception 'Current offer version and fixed request required';end if;
  if old.status<>'Draft' then raise exception 'Published BOQ content is immutable';end if;
  if exists(select 1 from public.crm_boq_offers where change_id=p_change and revision>old.revision) then raise exception 'Only the latest draft offer can be revised';end if;
  update public.crm_boq_offers set data=d,reason=trim(p_reason),version=version+1 where id=p_id returning * into saved;
 else
  select id into prior from public.crm_boq_offers where change_id=p_change order by revision desc limit 1;
  if p_version is not null or prior is distinct from p_previous then raise exception 'Current previous offer required';end if;
  if exists(select 1 from public.crm_boq_offer_publications where change_id=p_change and status='Accepted') then raise exception 'Client-approved request requires a new change request for further scope';end if;
  insert into public.crm_boq_offers(id,project_id,change_id,change_version,sale_id,baseline_id,revision,previous_id,currency,data,reason,created_by)
   values(p_id,c.project_id,c.id,c.version,s.id,s.publication_id,coalesce((select max(revision) from public.crm_boq_offers where change_id=c.id),0)+1,p_previous,s.currency,d,trim(p_reason),auth.uid()) returning * into saved;
 end if;
 insert into public.crm_boq_offer_history(offer_id,project_id,action,before_record,after_record,reason,actor_id)
  values(saved.id,saved.project_id,'Draft saved',case when old.id is null then null else to_jsonb(old) end,to_jsonb(saved),trim(p_reason),auth.uid());return saved.id;
end$$;

create function public.publish_boq_change_offer(p_offer uuid,p_version integer,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare o public.crm_boq_offers; b public.crm_quote_publications; p public.projects; item jsonb; items jsonb:='[]'; label text; subtotal numeric:=0; tax numeric; total numeric; wht numeric; prior public.crm_boq_offer_publications;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator publishes BOQ offers';end if;
 select * into o from public.crm_boq_offers where id=p_offer;
 select * into p from public.projects where id=o.project_id for update;
 select * into o from public.crm_boq_offers where id=p_offer for update;
 if o.id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Offer and publication reason required';end if;
 if p.status in ('Completed','Cancelled') or exists(select 1 from public.crm_handovers where project_id=p.id and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Active project without released handover required';end if;
 if o.status='Published' then
  if o.published_by=auth.uid() and o.publish_reason=trim(p_reason) and exists(select 1 from public.crm_boq_offer_publications where id=o.id and source_version=p_version) then return o.id;end if;
  raise exception 'Published BOQ content is immutable';
 end if;
 if o.version is distinct from p_version or not exists(select 1 from public.crm_project_changes where id=o.change_id and project_id=o.project_id and version=o.change_version and details->>'status'='Approved') then raise exception 'Current offer and Approved request required';end if;
 if exists(select 1 from public.crm_boq_offers where change_id=o.change_id and revision>o.revision) then raise exception 'Only the latest draft offer can be published';end if;
 select * into b from public.crm_quote_publications where id=o.baseline_id;
 if b.status is distinct from 'Accepted' or b.company_id is distinct from p.company_id or b.currency is distinct from o.currency then raise exception 'Accepted quotation customer and currency must match';end if;
 if (o.data->>'valid_until')::date<(now() at time zone 'Asia/Karachi')::date then raise exception 'Offer validity has expired';end if;
 if exists(select 1 from public.crm_boq_offer_publications where change_id=o.change_id and status='Accepted') then raise exception 'Client-approved request requires a new change request for further scope';end if;
 for item in select value from jsonb_array_elements(o.data->'lines') loop
  select board.name into label from public.crm_project_workstreams s join public.crm_product_lines l on l.id=s.product_line_id join public.crm_boards board on board.id=l.board_id where s.id=(item->>'workstream_id')::uuid and s.project_id=o.project_id and s.sale_id=o.sale_id;
  if not found then raise exception 'Existing project workstream required';end if;
  subtotal:=subtotal+round((item->>'quantity')::numeric*(item->>'unit_price')::numeric,2);
  items:=items||jsonb_build_array((item-'workstream_id')||jsonb_build_object('product',label,'total',round((item->>'quantity')::numeric*(item->>'unit_price')::numeric,2)));
 end loop;
 tax:=round((o.data->>'service_tax_base')::numeric*(o.data->>'pra_percent')::numeric/100,2);total:=subtotal+tax;wht:=round(total*(o.data->>'wht_percent')::numeric/100,2);
 for prior in select * from public.crm_boq_offer_publications where change_id=o.change_id and status='Published' for update loop
  update public.crm_boq_offer_publications set status='Superseded',version=version+1 where id=prior.id;
  insert into public.crm_boq_offer_history(offer_id,project_id,action,before_record,after_record,reason,actor_id)
   select prior.id,o.project_id,'Superseded',to_jsonb(prior),to_jsonb(pub),trim(p_reason),auth.uid() from public.crm_boq_offer_publications pub where pub.id=prior.id;
 end loop;
 insert into public.crm_boq_offer_publications(id,project_id,company_id,change_id,number,revision,source_version,project_title,company_name,baseline_number,baseline_revision,title,currency,valid_until,terms,items,subtotal,service_tax_base,pra_percent,tax_total,total,wht_percent,wht_total,receivable)
 values(o.id,o.project_id,b.company_id,o.change_id,o.number,o.revision,o.version,p.title,(select name from public.companies where id=b.company_id),b.number,b.revision,o.data->>'title',o.currency,(o.data->>'valid_until')::date,o.data->>'terms',items,subtotal,(o.data->>'service_tax_base')::numeric,(o.data->>'pra_percent')::numeric,tax,total,(o.data->>'wht_percent')::numeric,wht,total-wht);
 update public.crm_boq_offers set status='Published',version=version+1,published_by=auth.uid(),publish_reason=trim(p_reason) where id=o.id;
 insert into public.crm_boq_offer_history(offer_id,project_id,action,before_record,after_record,reason,actor_id)
  select o.id,o.project_id,'Published',to_jsonb(o),to_jsonb(pub),trim(p_reason),auth.uid() from public.crm_boq_offer_publications pub where pub.id=o.id;return o.id;
end$$;

create function public.decide_boq_change_offer(p_offer uuid,p_version integer,p_action text,p_note text,p_consent boolean) returns void language plpgsql security definer set search_path='' as $$
declare pub public.crm_boq_offer_publications; o public.crm_boq_offers; p public.projects; target text;
begin
 select * into pub from public.crm_boq_offer_publications where id=p_offer;
 select * into p from public.projects where id=pub.project_id for update;
 select * into pub from public.crm_boq_offer_publications where id=p_offer for update;
 if pub.id is null or auth.uid() is null or length(coalesce(p_note,''))>2000 or p_action is null or p_action not in ('accept','decline','withdraw') then raise exception 'Offer and valid decision required';end if;
 if p_action='withdraw' then
  if not public.is_admin() or length(trim(coalesce(p_note,'')))<3 then raise exception 'Administrator withdrawal requires a client-visible reason';end if;target:='Withdrawn';
 else
  if not exists(select 1 from public.profiles where id=auth.uid() and active and role='client' and company_id=pub.company_id) or not public.can_project(pub.project_id) or p.company_id is distinct from pub.company_id then raise exception 'Own-company active client required';end if;
  if p_action='accept' and p_consent is distinct from true then raise exception 'Explicit client approval consent required';end if;
  if p_action='decline' and length(trim(coalesce(p_note,'')))<3 then raise exception 'Decline reason required';end if;
  target:=case when p_action='accept' then 'Accepted' else 'Declined' end;
 end if;
 if pub.status=target and pub.version=p_version+1 and pub.decided_by=auth.uid() and pub.decision_note=trim(coalesce(p_note,'')) and pub.consent=(p_action='accept' and coalesce(p_consent,false)) then return;end if;
 if pub.status<>'Published' or pub.version is distinct from p_version then raise exception 'Current open offer required';end if;
 if p_action<>'withdraw' then
  if pub.valid_until<(now() at time zone 'Asia/Karachi')::date then raise exception 'Offer validity has expired';end if;
  if p.status in ('Completed','Cancelled') or exists(select 1 from public.crm_handovers where project_id=p.id and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Active project without released handover required';end if;
 end if;
 update public.crm_boq_offer_publications set status=target,version=version+1,decided_by=auth.uid(),decided_at=now(),decision_note=trim(coalesce(p_note,'')),consent=(p_action='accept' and coalesce(p_consent,false)) where id=pub.id;
 insert into public.crm_boq_offer_history(offer_id,project_id,action,before_record,after_record,reason,actor_id)
  select pub.id,pub.project_id,target,to_jsonb(pub),to_jsonb(newpub),case when trim(coalesce(p_note,''))='' then 'Client approved the published additional BOQ' else trim(p_note) end,auth.uid() from public.crm_boq_offer_publications newpub where newpub.id=pub.id;
end$$;
revoke all on function public.save_boq_change_offer(uuid,integer,uuid,integer,uuid,jsonb,text),public.publish_boq_change_offer(uuid,integer,text),public.decide_boq_change_offer(uuid,integer,text,text,boolean) from public,anon;
grant execute on function public.save_boq_change_offer(uuid,integer,uuid,integer,uuid,jsonb,text),public.publish_boq_change_offer(uuid,integer,text),public.decide_boq_change_offer(uuid,integer,text,text,boolean) to authenticated;
commit;
