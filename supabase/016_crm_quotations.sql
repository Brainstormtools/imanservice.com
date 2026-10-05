begin;
-- Internal costs and client publications are physically separate API resources.
create table public.crm_catalog(
 id uuid primary key default gen_random_uuid(),name text not null check(length(trim(name)) between 1 and 160),category text not null default '' check(length(category)<=100),brand text not null default '' check(length(brand)<=100),model text not null default '' check(length(model)<=100),unit text not null default 'each' check(length(unit) between 1 and 30),last_rate numeric(14,2) not null default 0 check(last_rate>=0 and last_rate<100000000),margin integer not null default 20 check(margin between 5 and 85 and margin%5=0),active boolean not null default true,version integer not null default 1
);
create sequence public.crm_quote_numbers;
insert into public.crm_settings(id,label,value) select 'margin_slabs','Quotation margin slabs',jsonb_agg(n::text order by n) from generate_series(5,85,5) n;
create policy quotation_margin_read on public.crm_settings for select to authenticated using(id='margin_slabs' and (portal_private.sales_user() or portal_private.crm_permission('product.own')));
create table public.crm_quotes(
 id uuid primary key default gen_random_uuid(),deal_id uuid not null references public.crm_deals,number text not null unique default ('Q-'||lpad(nextval('public.crm_quote_numbers')::text,6,'0')),option_name text not null default 'Solution A' check(length(trim(option_name)) between 1 and 100),title text not null check(length(trim(title)) between 1 and 200),currency text not null default 'PKR' check(currency ~ '^[A-Z]{3}$'),valid_until date not null,terms text not null default '' check(length(terms)<=10000),default_margin integer not null default 20 check(default_margin between 5 and 85 and default_margin%5=0),pra_percent numeric(5,2) not null default 0 check(pra_percent between 0 and 100),service_tax_base numeric(14,2) not null default 0 check(service_tax_base>=0),wht_percent numeric(5,2) not null default 0 check(wht_percent between 0 and 100),bank_charges numeric(14,2) not null default 0 check(bank_charges>=0),contingency_percent numeric(5,2) not null default 0 check(contingency_percent between 0 and 100),override_total numeric(14,2) check(override_total>=0),version integer not null default 1,created_at timestamptz not null default now(),unique(deal_id,option_name)
);
create table public.crm_quote_lines(
 id uuid primary key default gen_random_uuid(),quote_id uuid not null references public.crm_quotes,product_line_id uuid not null references public.crm_product_lines,block text not null check(block in ('Material','Labour','Inventory','TADA')),catalog_id uuid references public.crm_catalog,description text not null check(length(trim(description)) between 1 and 500),unit text not null check(length(unit) between 1 and 30),quantity numeric(12,3) not null check(quantity>0 and quantity<=100000),unit_cost numeric(14,2) not null check(unit_cost>=0 and unit_cost<100000000),margin integer check(margin between 5 and 85 and margin%5=0),vendor text not null default '' check(length(vendor)<=160),labour_required boolean not null default false,material_line_id uuid references public.crm_quote_lines,version integer not null default 1
);
create table public.crm_quote_publications(
 id uuid primary key default gen_random_uuid(),quote_id uuid not null references public.crm_quotes,deal_id uuid not null references public.crm_deals,company_id uuid not null references public.companies,number text not null,revision integer not null,title text not null,option_name text not null,currency text not null,valid_until date not null,terms text not null,company_name text not null,items jsonb not null,subtotal numeric(14,2) not null,tax_total numeric(14,2) not null,total numeric(14,2) not null,wht_total numeric(14,2) not null,receivable numeric(14,2) not null,status text not null default 'Published' check(status in ('Published','Accepted','Declined','Withdrawn','Superseded')),version integer not null default 1,published_at timestamptz not null default now(),decided_at timestamptz,decided_by uuid references public.profiles,decision_note text not null default '' check(length(decision_note)<=2000),unique(quote_id,revision)
);
create unique index crm_one_accepted_quote on public.crm_quote_publications(deal_id) where status='Accepted';
create table public.crm_quote_budgets(publication_id uuid primary key references public.crm_quote_publications,snapshot jsonb not null,cost numeric(14,2) not null,profit numeric(14,2) not null,created_at timestamptz not null default now());
create table public.crm_quote_history(id uuid primary key default gen_random_uuid(),deal_id uuid not null references public.crm_deals,quote_id uuid not null references public.crm_quotes,action text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now());
create index crm_quote_deal on public.crm_quotes(deal_id);
create index crm_quote_line_quote on public.crm_quote_lines(quote_id);
create index crm_quote_publication_company on public.crm_quote_publications(company_id);
alter table public.crm_quotes add constraint quote_finite_amounts check(bank_charges<10000000000 and service_tax_base<10000000000 and (override_total is null or override_total<10000000000));
alter table public.crm_quote_lines add column inventory_kind text not null default 'Consumable' check(inventory_kind in ('Consumable','Returnable tool')),add column planner jsonb not null default '{}';

create function portal_private.quote_access(p_quote uuid) returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.crm_quotes q where q.id=p_quote and portal_private.deal_access(q.deal_id));$$;
create function portal_private.quote_edit(p_quote uuid) returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.crm_quotes q join public.crm_deals d on d.id=q.deal_id where q.id=p_quote and portal_private.deal_edit(d.id) and d.stage not in ('won','lost') and not exists(select 1 from public.crm_quote_publications p where p.deal_id=d.id and p.status='Accepted'));$$;
create function portal_private.quote_section_edit(p_quote uuid,p_line uuid) returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.crm_quotes q join public.crm_product_lines l on l.deal_id=q.deal_id join public.crm_deals d on d.id=q.deal_id where q.id=p_quote and l.id=p_line and l.status='Active' and d.stage not in ('won','lost') and not exists(select 1 from public.crm_quote_publications p where p.deal_id=d.id and p.status='Accepted') and portal_private.deal_access(d.id) and (portal_private.deal_edit(d.id) or (portal_private.crm_permission('product.own') and portal_private.board_access(l.board_id))));$$;
do $$declare t text;begin foreach t in array array['crm_catalog','crm_quotes','crm_quote_lines','crm_quote_publications','crm_quote_budgets','crm_quote_history'] loop execute format('alter table public.%I enable row level security',t);execute format('revoke all on public.%I from public,anon,authenticated',t);execute format('grant select on public.%I to authenticated',t);end loop;end$$;
create policy quote_catalog_read on public.crm_catalog for select to authenticated using(public.is_admin() or portal_private.sales_user() or portal_private.crm_permission('product.own'));
create policy quote_internal_read on public.crm_quotes for select to authenticated using(portal_private.deal_access(deal_id));
create policy quote_line_read on public.crm_quote_lines for select to authenticated using(portal_private.quote_access(quote_id));
create policy quote_public_read on public.crm_quote_publications for select to authenticated using(portal_private.deal_access(deal_id) or exists(select 1 from public.profiles u where u.id=auth.uid() and u.active and u.role='client' and u.company_id=crm_quote_publications.company_id));
create policy quote_budget_read on public.crm_quote_budgets for select to authenticated using(exists(select 1 from public.crm_quote_publications p where p.id=publication_id and portal_private.deal_access(p.deal_id)));
create policy quote_history_read on public.crm_quote_history for select to authenticated using(portal_private.deal_access(deal_id));
grant execute on function portal_private.quote_access(uuid),portal_private.quote_edit(uuid),portal_private.quote_section_edit(uuid,uuid) to authenticated;
revoke all on function portal_private.quote_access(uuid),portal_private.quote_edit(uuid),portal_private.quote_section_edit(uuid,uuid) from public,anon;
create trigger config_audit after insert or update or delete on public.crm_catalog for each row execute function portal_private.crm_config_audit();
create function portal_private.quote_margin_allowed(p_margin integer) returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.crm_settings where id='margin_slabs' and value ? p_margin::text);$$;
revoke all on function portal_private.quote_margin_allowed(integer) from public,anon,authenticated;

create function public.save_crm_catalog(p_id uuid,p_version integer,p_data jsonb) returns uuid language plpgsql security definer set search_path='' as $$declare item public.crm_catalog;begin
if not public.is_admin() then raise exception 'Administrator access required';end if;
if not portal_private.quote_margin_allowed((p_data->>'margin')::integer) then raise exception 'Choose an administrator-defined margin slab';end if;
if p_id is null then insert into public.crm_catalog(name,category,brand,model,unit,last_rate,margin,active) values(trim(p_data->>'name'),coalesce(p_data->>'category',''),coalesce(p_data->>'brand',''),coalesce(p_data->>'model',''),p_data->>'unit',(p_data->>'last_rate')::numeric,(p_data->>'margin')::integer,(p_data->>'active')::boolean) returning * into item;
else select * into item from public.crm_catalog where id=p_id for update;if not found or item.version is distinct from p_version then raise exception 'Catalogue item changed. Refresh first.';end if;update public.crm_catalog set name=trim(p_data->>'name'),category=coalesce(p_data->>'category',''),brand=coalesce(p_data->>'brand',''),model=coalesce(p_data->>'model',''),unit=p_data->>'unit',last_rate=(p_data->>'last_rate')::numeric,margin=(p_data->>'margin')::integer,active=(p_data->>'active')::boolean,version=version+1 where id=p_id;end if;return item.id;end$$;

create function public.save_crm_quote(p_id uuid,p_version integer,p_deal uuid,p_data jsonb) returns uuid language plpgsql security definer set search_path='' as $$declare quotation public.crm_quotes;begin
perform 1 from public.crm_deals where id=p_deal for update;
if not portal_private.deal_edit(p_deal) or exists(select 1 from public.crm_deals where id=p_deal and stage in ('won','lost')) or exists(select 1 from public.crm_quote_publications where deal_id=p_deal and status='Accepted') then raise exception 'Editable deal required';end if;
if not portal_private.quote_margin_allowed((p_data->>'default_margin')::integer) then raise exception 'Choose an administrator-defined margin slab';end if;
if p_id is null then insert into public.crm_quotes(deal_id,title,option_name,valid_until) values(p_deal,p_data->>'title',p_data->>'option_name',(p_data->>'valid_until')::date) returning * into quotation;
else select * into quotation from public.crm_quotes where id=p_id for update;if not found or quotation.deal_id<>p_deal or quotation.version is distinct from p_version then raise exception 'Quotation changed. Refresh first.';end if;end if;
update public.crm_quotes set title=trim(p_data->>'title'),option_name=trim(p_data->>'option_name'),valid_until=(p_data->>'valid_until')::date,currency=upper(coalesce(p_data->>'currency','PKR')),terms=coalesce(p_data->>'terms',''),default_margin=(p_data->>'default_margin')::integer,pra_percent=(p_data->>'pra_percent')::numeric,service_tax_base=(p_data->>'service_tax_base')::numeric,wht_percent=(p_data->>'wht_percent')::numeric,bank_charges=(p_data->>'bank_charges')::numeric,contingency_percent=(p_data->>'contingency_percent')::numeric,override_total=nullif(p_data->>'override_total','')::numeric,version=case when p_id is null then version else version+1 end where id=quotation.id;
insert into public.crm_quote_history(deal_id,quote_id,action,actor_id) values(p_deal,quotation.id,'Quotation draft saved',auth.uid());return quotation.id;end$$;

create function public.save_crm_quote_line(p_id uuid,p_version integer,p_quote uuid,p_quote_version integer,p_product uuid,p_data jsonb,p_delete boolean default false) returns uuid language plpgsql security definer set search_path='' as $$declare quotation public.crm_quotes;line public.crm_quote_lines;material uuid:=nullif(p_data->>'material_line_id','')::uuid;catalog uuid:=nullif(p_data->>'catalog_id','')::uuid;begin
perform 1 from public.crm_deals where id=(select deal_id from public.crm_quotes where id=p_quote) for update;
select * into quotation from public.crm_quotes where id=p_quote for update;
if not portal_private.quote_section_edit(p_quote,p_product) then raise exception 'Product quotation section access required';end if;
if quotation.version is distinct from p_quote_version then raise exception 'Quotation changed. Refresh first.';end if;
if p_id is not null then select * into line from public.crm_quote_lines where id=p_id for update;if not found or line.quote_id<>p_quote or line.product_line_id<>p_product or line.version is distinct from p_version then raise exception 'BOQ line changed. Refresh first.';end if;end if;
if p_delete then if line.id is null then raise exception 'Existing BOQ line required';end if;delete from public.crm_quote_lines where id=p_id;
else
if nullif(p_data->>'margin','') is not null and not portal_private.quote_margin_allowed((p_data->>'margin')::integer) then raise exception 'Choose an administrator-defined margin slab';end if;
if material is not null and not exists(select 1 from public.crm_quote_lines where id=material and quote_id=p_quote and product_line_id=p_product and block='Material') then raise exception 'Matching material must belong to this section';end if;
if material is not null and p_data->>'block'<>'Labour' then raise exception 'Only labour can reference material';end if;
if catalog is not null and not exists(select 1 from public.crm_catalog where id=catalog and active) then raise exception 'Active catalogue item required';end if;
if p_id is null then insert into public.crm_quote_lines(quote_id,product_line_id,block,description,unit,quantity,unit_cost,margin,vendor,catalog_id,labour_required,material_line_id) values(p_quote,p_product,p_data->>'block',trim(p_data->>'description'),p_data->>'unit',(p_data->>'quantity')::numeric,(p_data->>'unit_cost')::numeric,nullif(p_data->>'margin','')::integer,coalesce(p_data->>'vendor',''),catalog,coalesce((p_data->>'labour_required')::boolean,false),material) returning * into line;
else update public.crm_quote_lines set block=p_data->>'block',description=trim(p_data->>'description'),unit=p_data->>'unit',quantity=(p_data->>'quantity')::numeric,unit_cost=(p_data->>'unit_cost')::numeric,margin=nullif(p_data->>'margin','')::integer,vendor=coalesce(p_data->>'vendor',''),catalog_id=catalog,labour_required=coalesce((p_data->>'labour_required')::boolean,false),material_line_id=material,version=version+1 where id=p_id;end if;end if;
if not p_delete then
update public.crm_quote_lines set inventory_kind=coalesce(p_data->>'inventory_kind','Consumable'),planner='{}' where id=line.id;
if p_data->>'block'='TADA' and p_data->>'plan_enabled'='true' then
if not ((p_data->>'km')::numeric between 0 and 100000 and (p_data->>'trips')::numeric between 0 and 1000 and (p_data->>'fuel_average')::numeric between 0.1 and 1000 and (p_data->>'petrol_price')::numeric between 0 and 100000 and (p_data->>'crew')::numeric between 0 and 1000 and (p_data->>'days')::numeric between 0 and 1000 and (p_data->>'day_rate')::numeric between 0 and 100000) or (p_data->>'km') is null or (p_data->>'trips') is null or (p_data->>'fuel_average') is null or (p_data->>'petrol_price') is null or (p_data->>'crew') is null or (p_data->>'days') is null or (p_data->>'day_rate') is null then raise exception 'Valid fuel and crew parameters required';end if;
update public.crm_quote_lines set quantity=1,unit='job',unit_cost=round((p_data->>'km')::numeric*(p_data->>'trips')::numeric/(p_data->>'fuel_average')::numeric*(p_data->>'petrol_price')::numeric+(p_data->>'crew')::numeric*(p_data->>'days')::numeric*(p_data->>'day_rate')::numeric,2),planner=jsonb_build_object('km',(p_data->>'km')::numeric,'trips',(p_data->>'trips')::numeric,'fuel_average',(p_data->>'fuel_average')::numeric,'petrol_price',(p_data->>'petrol_price')::numeric,'crew',(p_data->>'crew')::numeric,'days',(p_data->>'days')::numeric,'day_rate',(p_data->>'day_rate')::numeric) where id=line.id;
end if;end if;
update public.crm_quotes set version=version+1 where id=p_quote;
insert into public.crm_quote_history(deal_id,quote_id,action,actor_id) values(quotation.deal_id,p_quote,case when p_delete then 'BOQ line removed' else 'BOQ line saved' end,auth.uid());return line.id;end$$;

create function portal_private.quote_calculation(p_quote uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$declare quotation public.crm_quotes;line record;cost numeric:=0;subtotal numeric:=0;tax numeric;total numeric;wht numeric;contingency numeric;unit_price numeric;client_items jsonb:='[]';internal_items jsonb:='[]';warnings jsonb:='[]';begin
select * into quotation from public.crm_quotes where id=p_quote;
for line in select l.*,b.name product_name from public.crm_quote_lines l join public.crm_product_lines p on p.id=l.product_line_id join public.crm_boards b on b.id=p.board_id where l.quote_id=p_quote and p.status='Active' order by b.code,l.block,l.id loop
cost:=cost+round(line.quantity*line.unit_cost,2);internal_items:=internal_items||jsonb_build_array(to_jsonb(line));
if line.unit_cost=0 then warnings:=warnings||jsonb_build_array('Missing rate: '||line.description);end if;
if line.block='Material' then
unit_price:=round(line.unit_cost/(1-coalesce(line.margin,quotation.default_margin)::numeric/100),2);subtotal:=subtotal+round(line.quantity*unit_price,2);
client_items:=client_items||jsonb_build_array(jsonb_build_object('product',line.product_name,'description',line.description,'unit',line.unit,'quantity',line.quantity,'unit_price',unit_price,'total',round(line.quantity*unit_price,2)));
if line.labour_required and not exists(select 1 from public.crm_quote_lines where quote_id=p_quote and material_line_id=line.id and block='Labour') then warnings:=warnings||jsonb_build_array('Missing matching labour: '||line.description);end if;
elsif line.block='Labour' and line.material_line_id is null then warnings:=warnings||jsonb_build_array('Labour has no matching material: '||line.description);end if;
end loop;
if exists(select 1 from public.crm_quote_lines where quote_id=p_quote group by product_line_id,block,lower(description),unit having count(*)>1) then warnings:=warnings||jsonb_build_array('Duplicate BOQ descriptions in a product section');end if;
if not exists(select 1 from public.crm_quote_lines l join public.crm_product_lines p on p.id=l.product_line_id where l.quote_id=p_quote and p.status='Active' and l.block='Material') then warnings:=warnings||jsonb_build_array('Add a material BOQ line with a client price');end if;
contingency:=round(cost*quotation.contingency_percent/100,2);cost:=cost+contingency+quotation.bank_charges;
tax:=round(quotation.service_tax_base*quotation.pra_percent/100,2);total:=coalesce(quotation.override_total,subtotal+tax);
if quotation.override_total is not null then client_items:=client_items||jsonb_build_array(jsonb_build_object('product','Commercial adjustment','description','Agreed price adjustment','unit','job','quantity',1,'unit_price',total-tax-subtotal,'total',total-tax-subtotal));subtotal:=total-tax;end if;
if subtotal<0 or quotation.service_tax_base>subtotal then warnings:=warnings||jsonb_build_array('Service tax base exceeds the quoted subtotal');end if;
wht:=round(total*quotation.wht_percent/100,2);
if subtotal<cost then warnings:=warnings||jsonb_build_array('Quotation is below planned cost');end if;
return jsonb_build_object('cost',round(cost,2),'subtotal',round(subtotal,2),'tax_total',tax,'total',total,'wht_total',wht,'receivable',total-wht,'profit',subtotal-cost,'margin_percent',case when subtotal>0 then round((subtotal-cost)/subtotal*100,2) else 0 end,'contingency',contingency,'client_items',client_items,'internal_items',internal_items,'warnings',warnings);
end$$;
revoke all on function portal_private.quote_calculation(uuid) from public,anon,authenticated;
create function public.crm_quote_summary(p_quote uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$begin if not portal_private.quote_access(p_quote) then raise exception 'Quotation access required';end if;return portal_private.quote_calculation(p_quote);end$$;

create function public.publish_crm_quote(p_quote uuid,p_version integer,p_company uuid,p_acknowledge boolean default false) returns uuid language plpgsql security definer set search_path='' as $$declare quotation public.crm_quotes;deal public.crm_deals;calculation jsonb;revision integer;publication uuid;company text;begin
select * into deal from public.crm_deals where id=(select deal_id from public.crm_quotes where id=p_quote) for update;
select * into quotation from public.crm_quotes where id=p_quote for update;
if not portal_private.quote_edit(p_quote) then raise exception 'Sales quotation publishing access required';end if;
if quotation.version is distinct from p_version then raise exception 'Quotation changed. Refresh first.';end if;
if deal.company_id is null then if not public.is_admin() then raise exception 'Administrator must link the customer before publishing';end if;select name into company from public.companies where id=p_company;if company is null then raise exception 'Existing customer required';end if;update public.crm_deals set company_id=p_company,version=version+1 where id=deal.id;
elsif deal.company_id is distinct from p_company then raise exception 'Quotation customer cannot change';end if;
select name into company from public.companies where id=p_company;
if quotation.valid_until<(now() at time zone 'Asia/Karachi')::date then raise exception 'Quotation validity has expired';end if;
calculation:=portal_private.quote_calculation(p_quote);
if not exists(select 1 from public.crm_quote_lines l join public.crm_product_lines p on p.id=l.product_line_id where l.quote_id=p_quote and p.status='Active' and l.block='Material') or (calculation->>'total')::numeric<=0 or (calculation->>'subtotal')::numeric<0 or quotation.service_tax_base>(calculation->>'subtotal')::numeric then raise exception 'Valid client prices and tax base required';end if;
if jsonb_array_length(calculation->'warnings')>0 and not coalesce(p_acknowledge,false) then raise exception 'Review and acknowledge quotation warnings';end if;
select coalesce(max(p.revision),0)+1 into revision from public.crm_quote_publications p where p.quote_id=p_quote;
update public.crm_quote_publications set status='Superseded',version=version+1 where quote_id=p_quote and status='Published';
insert into public.crm_quote_publications(quote_id,deal_id,company_id,number,revision,title,option_name,currency,valid_until,terms,company_name,items,subtotal,tax_total,total,wht_total,receivable) values(p_quote,deal.id,p_company,quotation.number,revision,quotation.title,quotation.option_name,quotation.currency,quotation.valid_until,quotation.terms,company,calculation->'client_items',(calculation->>'subtotal')::numeric,(calculation->>'tax_total')::numeric,(calculation->>'total')::numeric,(calculation->>'wht_total')::numeric,(calculation->>'receivable')::numeric) returning id into publication;
insert into public.crm_quote_budgets(publication_id,snapshot,cost,profit) values(publication,jsonb_build_object('quote',to_jsonb(quotation),'lines',calculation->'internal_items','calculation',calculation),(calculation->>'cost')::numeric,(calculation->>'profit')::numeric);
update public.crm_quotes set version=version+1 where id=p_quote;
insert into public.crm_quote_history(deal_id,quote_id,action,actor_id) values(deal.id,p_quote,'Published '||quotation.number||' v'||revision,auth.uid());return publication;end$$;

create function public.decide_crm_quote(p_publication uuid,p_version integer,p_action text,p_note text default '') returns void language plpgsql security definer set search_path='' as $$declare publication public.crm_quote_publications;begin
perform 1 from public.crm_deals where id=(select deal_id from public.crm_quote_publications where id=p_publication) for update;
select * into publication from public.crm_quote_publications where id=p_publication for update;
if not found or publication.version is distinct from p_version or publication.status<>'Published' then raise exception 'Quotation changed or no longer open';end if;
if p_action in ('accept','decline') then
if not exists(select 1 from public.profiles where id=auth.uid() and active and role='client' and company_id=publication.company_id) then raise exception 'Customer decision required';end if;
if publication.valid_until<(now() at time zone 'Asia/Karachi')::date then raise exception 'Quotation validity has expired';end if;
if exists(select 1 from public.crm_quote_publications where deal_id=publication.deal_id and status='Accepted') then raise exception 'A solution has already been accepted';end if;
update public.crm_quote_publications set status=case when p_action='accept' then 'Accepted' else 'Declined' end,version=version+1,decided_by=auth.uid(),decided_at=now(),decision_note=p_note where id=p_publication;
if p_action='accept' then update public.crm_quote_publications set status='Withdrawn',version=version+1 where deal_id=publication.deal_id and status='Published' and id<>p_publication;end if;
elsif p_action='withdraw' and portal_private.quote_edit(publication.quote_id) then update public.crm_quote_publications set status='Withdrawn',version=version+1 where id=p_publication;
else raise exception 'Quotation decision access required';end if;
insert into public.crm_quote_history(deal_id,quote_id,action,actor_id) values(publication.deal_id,publication.quote_id,publication.number||' v'||publication.revision||': '||p_action,auth.uid());end$$;

-- Preserve earlier stage checks; only release the quotation prerequisite.
do $$declare definition text;begin definition:=pg_get_functiondef('public.save_crm_configuration(text,text,integer,text,jsonb,boolean)'::regprocedure);
definition:=replace(definition,$gate$elsif p_kind='setting' then$gate$,$gate$elsif p_kind='setting' then
if p_id='margin_slabs' and (p_value is null or jsonb_typeof(p_value)<>'array' or exists(select 1 from jsonb_array_elements(p_value) x where (x#>>'{}') !~ '^(5|10|15|20|25|30|35|40|45|50|55|60|65|70|75|80|85)$')) then raise exception 'Use margin slabs from 5 to 85 in steps of 5';end if;$gate$);execute definition;end$$;
do $$declare definition text;begin definition:=pg_get_functiondef('public.save_crm_deal(uuid,integer,text,numeric,date,timestamptz,text,text,date)'::regprocedure);
definition:=replace(definition,$gate$if p_stage in ('proposal','negotiation') then raise exception 'Proposal stages require the quotation workflow';end if;$gate$,$gate$if p_stage in ('proposal','negotiation') and not exists(select 1 from public.crm_quote_publications where deal_id=p_id and status in ('Published','Accepted') and valid_until>=(now() at time zone 'Asia/Karachi')::date) then raise exception 'Publish a current quotation before proposal or negotiation';end if;$gate$);
execute definition;end$$;
do $$declare definition text;begin definition:=pg_get_functiondef('public.save_crm_product_line(uuid,integer,uuid,numeric,boolean,boolean,boolean,text,text)'::regprocedure);
definition:=replace(definition,'select * into l from public.crm_product_lines where id=p_id for update;select * into d from public.crm_deals where id=l.deal_id for update;','perform 1 from public.crm_deals where id=(select deal_id from public.crm_product_lines where id=p_id) for update;select * into l from public.crm_product_lines where id=p_id for update;select * into d from public.crm_deals where id=l.deal_id; if exists(select 1 from public.crm_quote_publications where deal_id=d.id and status=''Accepted'') then raise exception ''Accepted quotation locks product scope'';end if;');execute definition;end$$;
do $$declare f regprocedure;begin for f in select oid::regprocedure from pg_proc where pronamespace='public'::regnamespace and proname in ('save_crm_catalog','save_crm_quote','save_crm_quote_line','crm_quote_summary','publish_crm_quote','decide_crm_quote') loop execute format('revoke all on function %s from public,anon',f);execute format('grant execute on function %s to authenticated',f);end loop;end$$;
-- Existing trigger helpers do not need to be anonymous RPC endpoints.
do $$declare f regprocedure;begin for f in select oid::regprocedure from pg_proc where pronamespace='public'::regnamespace and proname in ('it_job_visible','rls_auto_enable','validate_asset_site') loop execute format('revoke all on function %s from public,anon',f);if f::text like '%it_job_visible%' then execute format('grant execute on function %s to authenticated',f);end if;end loop;end$$;
commit;
