begin;
create table public.crm_boards(id uuid primary key default gen_random_uuid(),code text not null unique check(code ~ '^[a-z][a-z0-9_]{1,49}$'),name text not null check(length(trim(name)) between 1 and 100),color text not null check(color ~ '^#[0-9A-Fa-f]{6}$'),outcome text not null check(outcome in ('Project','Contract','Project or direct sale')),active boolean not null default true,rotting_days integer not null default 7 check(rotting_days between 1 and 365),version integer not null default 1);
create table public.crm_board_memberships(id uuid primary key default gen_random_uuid(),board_id uuid not null references public.crm_boards,user_id uuid not null references public.profiles,unique(board_id,user_id));
create table public.crm_board_stages(id uuid primary key default gen_random_uuid(),board_id uuid not null references public.crm_boards,code text not null check(code ~ '^[a-z][a-z0-9_]{1,49}$'),name text not null check(length(trim(name)) between 1 and 100),position integer not null check(position between 0 and 100),probability integer not null default 0 check(probability between 0 and 100),active boolean not null default true,version integer not null default 1,unique(board_id,code));
create table public.crm_leads(id uuid primary key default gen_random_uuid(),name text not null check(length(trim(name)) between 1 and 160),email text not null default '',phone text not null default '',company_name text not null default '' check(length(company_name)<=160),city text not null default '' check(length(city)<=100),country text not null default '' check(length(country)<=100),source text not null, campaign text not null default '',form_name text not null default '',utm jsonb not null default '{}',message text not null default '' check(length(message)<=10000),owner_id uuid references public.profiles,status text not null default 'New' check(status in ('New','Contacted','Ready to assign','Junk/Spam','Duplicate','Assigned')),tags text[] not null default '{}',company_id uuid references public.companies,version integer not null default 1,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),check(email<>'' or phone<>''),check(public.valid_labels(tags)));
create unique index crm_lead_email on public.crm_leads(email) where email<>'';
create unique index crm_lead_phone on public.crm_leads(phone) where phone<>'';
create table public.crm_deals(id uuid primary key default gen_random_uuid(),lead_id uuid not null unique references public.crm_leads,company_id uuid references public.companies,title text not null check(length(trim(title)) between 1 and 200),owner_id uuid not null references public.profiles,stage text not null default 'new',estimated_value numeric(14,2) not null default 0 check(estimated_value>=0 and estimated_value::text<>'NaN'),currency text not null default 'PKR' check(currency ~ '^[A-Z]{3}$'),next_followup date,meeting_at timestamptz,loss_reason text not null default '',loss_note text not null default '',reengage_on date,version integer not null default 1,stage_changed_at timestamptz not null default now(),last_activity_at timestamptz not null default now(),created_at timestamptz not null default now());
create table public.crm_product_lines(id uuid primary key default gen_random_uuid(),deal_id uuid not null references public.crm_deals,board_id uuid not null references public.crm_boards,owner_id uuid references public.profiles,estimated_value numeric(14,2) not null default 0 check(estimated_value>=0 and estimated_value::text<>'NaN'),survey_done boolean not null default false,design_done boolean not null default false,boq_ready boolean not null default false,status text not null default 'Active' check(status in ('Active','Dropped')),drop_reason text not null default '',version integer not null default 1,unique(deal_id,board_id),check(status<>'Dropped' or length(trim(drop_reason))>=3));
create table public.crm_sales_activity(id uuid primary key default gen_random_uuid(),lead_id uuid references public.crm_leads,deal_id uuid references public.crm_deals,kind text not null check(kind in ('Enquiry','Call','Meeting','Note','Stage','Assignment','Product line','Follow-up')),body text not null check(length(trim(body)) between 1 and 10000),actor_id uuid references public.profiles,created_at timestamptz not null default now(),check(lead_id is not null or deal_id is not null));
create table public.crm_saved_views(id uuid primary key default gen_random_uuid(),user_id uuid not null default auth.uid() references public.profiles,name text not null check(length(trim(name)) between 1 and 100),filters jsonb not null,unique(user_id,name),check(jsonb_typeof(filters)='object' and octet_length(filters::text)<=4000));
insert into public.crm_boards(code,name,color,outcome) values ('surveillance','Smart Surveillance','#1F5FA8','Project'),('networking','Smart Networking','#7A2E87','Project'),('wlan','Smart WLAN','#0E7470','Project'),('unified_communication','Smart Unified Communication','#A3401A','Project'),('it_infra','Smart IT-Infra','#6B5A1E','Project or direct sale'),('support_sla','IT-Support SLA','#3F4A5A','Contract');
insert into public.crm_board_stages(board_id,code,name,position,probability) select b.id,s.code,case when b.code='support_sla' and s.code='qualified' then 'Site assessment' else s.name end,s.position,s.probability from public.crm_boards b cross join(values('new','New',0,5),('contacted','Contacted',1,15),('qualified','Qualified',2,30),('meeting','Meeting / Demo',3,45),('proposal','Proposal / Quotation sent',4,60),('negotiation','Negotiation',5,80),('won','Won',6,100),('lost','Lost',7,0)) s(code,name,position,probability);
insert into public.crm_settings(id,label,value) values('lost_reasons','Lost reasons','["Price","Competitor","Budget unavailable","Scope cancelled","No response","Other"]');
create function portal_private.crm_user_permission(p_user uuid,p_permission text) returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.profiles where id=p_user and active and role='admin') or exists(select 1 from public.crm_memberships m join public.crm_roles r on r.id=m.role_id join public.crm_teams t on t.id=m.team_id join public.profiles u on u.id=m.user_id where u.id=p_user and u.active and u.role='team' and r.active and t.active and p_permission=any(r.permissions));$$;
create function portal_private.sales_user() returns boolean language sql stable security definer set search_path='' as $$select portal_private.crm_permission('sales.manage') or portal_private.crm_permission('sales.own');$$;
create function portal_private.board_access(p_board uuid) returns boolean language sql stable security definer set search_path='' as $$select public.is_admin() or (public.is_staff() and (portal_private.sales_user() or portal_private.crm_permission('product.own')) and exists(select 1 from public.crm_board_memberships where board_id=p_board and user_id=auth.uid()));$$;
create function portal_private.lead_access(p_lead uuid) returns boolean language sql stable security definer set search_path='' as $$select public.is_admin() or (portal_private.sales_user() and exists(select 1 from public.crm_leads where id=p_lead and (portal_private.crm_permission('sales.manage') or owner_id=auth.uid())));$$;
create function portal_private.deal_access(p_deal uuid) returns boolean language sql stable security definer set search_path='' as $$select public.is_admin() or exists(select 1 from public.crm_deals d join public.crm_product_lines l on l.deal_id=d.id where d.id=p_deal and portal_private.board_access(l.board_id) and (portal_private.crm_permission('sales.manage') or (portal_private.crm_permission('sales.own') and d.owner_id=auth.uid()) or portal_private.crm_permission('product.own')));$$;
create function portal_private.deal_edit(p_deal uuid) returns boolean language sql stable security definer set search_path='' as $$select public.is_admin() or (portal_private.deal_access(p_deal) and (portal_private.crm_permission('sales.manage') or (portal_private.crm_permission('sales.own') and exists(select 1 from public.crm_deals where id=p_deal and owner_id=auth.uid()))));$$;
create or replace function portal_private.lead_access(p_lead uuid) returns boolean language sql stable security definer set search_path='' as $$select public.is_admin() or (portal_private.sales_user() and exists(select 1 from public.crm_leads l where l.id=p_lead and ((l.status<>'Assigned' and (portal_private.crm_permission('sales.manage') or l.owner_id=auth.uid())) or (l.status='Assigned' and exists(select 1 from public.crm_deals d where d.lead_id=l.id and portal_private.deal_access(d.id))))));$$;
revoke all on function portal_private.crm_user_permission(uuid,text),portal_private.sales_user(),portal_private.board_access(uuid),portal_private.lead_access(uuid),portal_private.deal_access(uuid),portal_private.deal_edit(uuid) from public,anon;
grant execute on function portal_private.crm_user_permission(uuid,text),portal_private.sales_user(),portal_private.board_access(uuid),portal_private.lead_access(uuid),portal_private.deal_access(uuid),portal_private.deal_edit(uuid) to authenticated;
do $$declare tab text;begin foreach tab in array array['crm_boards','crm_board_memberships','crm_board_stages','crm_leads','crm_deals','crm_product_lines','crm_sales_activity','crm_saved_views'] loop
execute format('alter table public.%I enable row level security',tab);execute format('revoke all on public.%I from public,anon,authenticated',tab);execute format('grant select on public.%I to authenticated',tab);end loop;end$$;
create policy boards_read on public.crm_boards for select to authenticated using(portal_private.board_access(id));
create policy board_members_read on public.crm_board_memberships for select to authenticated using(public.is_admin() or user_id=auth.uid());
create policy stages_read on public.crm_board_stages for select to authenticated using(portal_private.board_access(board_id));
create policy leads_read on public.crm_leads for select to authenticated using(portal_private.lead_access(id) or exists(select 1 from public.crm_deals d where d.lead_id=crm_leads.id and portal_private.deal_access(d.id)));
create policy deals_read on public.crm_deals for select to authenticated using(portal_private.deal_access(id));
create policy lines_read on public.crm_product_lines for select to authenticated using(portal_private.deal_access(deal_id));
create policy sales_history_read on public.crm_sales_activity for select to authenticated using((deal_id is not null and portal_private.deal_access(deal_id)) or (deal_id is null and lead_id is not null and portal_private.lead_access(lead_id)));
create policy saved_views_own on public.crm_saved_views for select to authenticated using(user_id=auth.uid() and portal_private.sales_user());
create policy sales_categories_read on public.crm_settings for select to authenticated using(id='lost_reasons' and portal_private.sales_user());
create function public.configure_sales_board(p_id uuid,p_version integer,p_name text,p_color text,p_rotting integer,p_active boolean) returns void language plpgsql security definer set search_path='' as $$begin
if not public.is_admin() then raise exception 'Administrator required';end if;
update public.crm_boards set name=trim(p_name),color=p_color,rotting_days=p_rotting,active=p_active,version=version+1 where id=p_id and version=p_version;if not found then raise exception 'Board changed. Refresh first.';end if;end$$;
create function public.set_sales_board_member(p_board uuid,p_user uuid,p_enabled boolean) returns void language plpgsql security definer set search_path='' as $$begin
if not public.is_admin() then raise exception 'Administrator required';end if;
if p_enabled is null then raise exception 'Membership action required';end if;
if p_enabled then if not exists(select 1 from public.profiles where id=p_user and role='team' and active) then raise exception 'Active staff required';end if;insert into public.crm_board_memberships(board_id,user_id) values(p_board,p_user) on conflict do nothing;
else delete from public.crm_board_memberships where board_id=p_board and user_id=p_user;end if;end$$;
create function public.configure_sales_stage(p_board uuid,p_code text,p_version integer,p_name text,p_position integer,p_probability integer,p_active boolean) returns void language plpgsql security definer set search_path='' as $$begin
if not public.is_admin() then raise exception 'Administrator required';end if;
if p_code in ('won','lost','new') and not p_active then raise exception 'System stages cannot be disabled';end if;
if p_version is null then insert into public.crm_board_stages(board_id,code,name,position,probability,active) values(p_board,p_code,trim(p_name),p_position,p_probability,p_active);
else update public.crm_board_stages set name=trim(p_name),position=p_position,probability=case when p_code='won' then 100 when p_code='lost' then 0 else p_probability end,active=p_active,version=version+1 where board_id=p_board and code=p_code and version=p_version;if not found then raise exception 'Stage changed. Refresh first.';end if;end if;end$$;
-- A single transaction serializes intake and prevents concurrent duplicate leads.
create function public.capture_crm_lead(p_name text,p_email text,p_phone text,p_company text,p_city text,p_country text,p_message text,p_source text default 'Manual',p_campaign text default '',p_tags text[] default '{}') returns uuid language plpgsql security definer set search_path='' as $$declare mail text:=lower(trim(coalesce(p_email,'')));norm_phone text:=regexp_replace(coalesce(p_phone,''),'[[:space:]().-]','','g');existing_email uuid;existing_phone uuid;lid uuid;cid uuid;begin
if not portal_private.sales_user() then raise exception 'Sales access required';end if;
if length(trim(coalesce(p_name,''))) not between 1 and 160 or length(coalesce(p_message,''))>9900 or length(coalesce(p_campaign,''))>300 then raise exception 'Valid name and bounded enquiry required';end if;
if mail<>'' and (length(mail)>254 or mail !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$') then raise exception 'Valid email required';end if;
if norm_phone<>'' and norm_phone !~ '^\+[1-9][0-9]{7,14}$' then raise exception 'Use an international phone number beginning with +';end if;
if mail='' and norm_phone='' then raise exception 'Phone or email required';end if;
if p_source not in ('Manual','CSV import') then raise exception 'This endpoint accepts manual or CSV intake';end if;
if not public.valid_labels(p_tags) then raise exception 'Invalid tags';end if;
perform pg_advisory_xact_lock(hashtext('crm-lead-intake'));
select id into existing_email from public.crm_leads where email=mail and mail<>'';select id into existing_phone from public.crm_leads where crm_leads.phone=norm_phone and norm_phone<>'';
if existing_email is not null and existing_phone is not null and existing_email<>existing_phone then raise exception 'Email and phone match different enquiries; administrator review required';end if;
lid:=coalesce(existing_email,existing_phone);
if lid is null then
select id into cid from public.companies where (mail<>'' and lower(trim(email))=mail) or (norm_phone<>'' and regexp_replace(companies.phone,'[[:space:]().-]','','g')=norm_phone) order by id limit 1;
insert into public.crm_leads(name,email,phone,company_name,city,country,source,campaign,message,owner_id,tags,company_id) values(trim(p_name),mail,norm_phone,trim(coalesce(p_company,'')),trim(coalesce(p_city,'')),trim(coalesce(p_country,'')),p_source,coalesce(p_campaign,''),coalesce(p_message,''),auth.uid(),p_tags,cid) returning id into lid;
else update public.crm_leads set updated_at=now() where id=lid;end if;
insert into public.crm_sales_activity(lead_id,kind,body,actor_id) values(lid,'Enquiry',p_source||': '||coalesce(nullif(trim(p_message),''),'Enquiry received'),auth.uid());
-- Dedupe never discloses another salesperson's lead/contact record.
if not portal_private.lead_access(lid) then return null;end if;return lid;
end$$;
create function public.log_crm_activity(p_lead uuid,p_deal uuid,p_kind text,p_body text,p_followup date default null) returns void language plpgsql security definer set search_path='' as $$begin
if p_deal is not null then if not portal_private.deal_edit(p_deal) then raise exception 'Deal access required';end if;
if p_lead is not null and not exists(select 1 from public.crm_deals where id=p_deal and lead_id=p_lead) then raise exception 'Lead does not match deal';end if;
elsif p_lead is null or not portal_private.lead_access(p_lead) then raise exception 'Lead access required';end if;
if p_kind not in ('Call','Meeting','Note','Follow-up') then raise exception 'Choose an activity type';end if;
insert into public.crm_sales_activity(lead_id,deal_id,kind,body,actor_id) values(p_lead,p_deal,p_kind,trim(p_body),auth.uid());
if p_deal is not null then update public.crm_deals set last_activity_at=now(),next_followup=coalesce(p_followup,next_followup),version=version+1 where id=p_deal;end if;
end$$;
create function public.triage_crm_lead(p_id uuid,p_version integer,p_status text,p_owner uuid) returns void language plpgsql security definer set search_path='' as $$declare old public.crm_leads;begin
if not portal_private.lead_access(p_id) then raise exception 'Lead access required';end if;
select * into old from public.crm_leads where id=p_id for update;
if old.version is distinct from p_version or old.status='Assigned' then raise exception 'Lead changed or already assigned';end if;
if p_status not in ('New','Contacted','Ready to assign','Junk/Spam','Duplicate') then raise exception 'Invalid triage status';end if;
if p_owner is distinct from old.owner_id and not (public.is_admin() or portal_private.crm_permission('sales.manage')) then raise exception 'Manager required to reassign';end if;
if not portal_private.crm_user_permission(p_owner,'sales.own') and not portal_private.crm_user_permission(p_owner,'sales.manage') then raise exception 'Active salesperson required';end if;
update public.crm_leads set status=p_status,owner_id=p_owner,version=version+1,updated_at=now() where id=p_id;
insert into public.crm_sales_activity(lead_id,kind,body,actor_id) values(p_id,'Stage',old.status||' → '||p_status,auth.uid());end$$;
create function public.assign_crm_products(p_lead uuid,p_version integer,p_boards uuid[],p_owner uuid,p_followup date) returns uuid language plpgsql security definer set search_path='' as $$declare l public.crm_leads;did uuid;bid uuid;begin
if not portal_private.lead_access(p_lead) then raise exception 'Lead access required';end if;
select * into l from public.crm_leads where id=p_lead for update;
if l.version is distinct from p_version or l.status in ('Assigned','Junk/Spam','Duplicate') then raise exception 'Lead changed or not assignable';end if;
if p_boards is null or cardinality(p_boards) not between 1 and 6 or cardinality(p_boards)<>(select count(distinct x) from unnest(p_boards) x) then raise exception 'Choose distinct products';end if;
if p_followup is null or p_followup<current_date then raise exception 'Next follow-up date required';end if;
if not (portal_private.crm_user_permission(p_owner,'sales.own') or portal_private.crm_user_permission(p_owner,'sales.manage')) then raise exception 'Active sales owner required';end if;
foreach bid in array p_boards loop
if not portal_private.board_access(bid) or not exists(select 1 from public.crm_boards where id=bid and active) then raise exception 'Product board unavailable';end if;
if not exists(select 1 from public.profiles where id=p_owner and active and role='admin') and not exists(select 1 from public.crm_board_memberships where board_id=bid and user_id=p_owner) then raise exception 'Owner must belong to each selected board';end if;
end loop;
insert into public.crm_deals(lead_id,company_id,title,owner_id,next_followup) values(l.id,l.company_id,l.name||case when l.company_name<>'' then ' · '||l.company_name else '' end,p_owner,p_followup) returning id into did;
foreach bid in array p_boards loop insert into public.crm_product_lines(deal_id,board_id,owner_id) values(did,bid,p_owner);end loop;
update public.crm_leads set status='Assigned',owner_id=p_owner,version=version+1,updated_at=now() where id=l.id;
insert into public.crm_sales_activity(lead_id,deal_id,kind,body,actor_id) values(l.id,did,'Assignment','Assigned products: '||array_to_string(array(select name from public.crm_boards where id=any(p_boards)),', '),auth.uid());return did;end$$;
create function public.save_crm_deal(p_id uuid,p_version integer,p_stage text,p_value numeric,p_followup date,p_meeting timestamptz,p_loss_reason text,p_loss_note text,p_reengage date) returns void language plpgsql security definer set search_path='' as $$declare old public.crm_deals;begin
if not portal_private.deal_edit(p_id) then raise exception 'Deal edit access required';end if;
select * into old from public.crm_deals where id=p_id for update;
if old.version is distinct from p_version then raise exception 'Deal changed. Refresh first.';end if;
if old.stage in ('won','lost') and not (public.is_admin() or portal_private.crm_permission('sales.manage')) then raise exception 'Manager required to reopen terminal deal';end if;
if p_stage='won' then raise exception 'Won requires the accepted quotation and conversion workflow';end if;
if p_stage in ('proposal','negotiation') then raise exception 'Proposal stages require the quotation workflow';end if;
if not exists(select 1 from public.crm_product_lines where deal_id=p_id and status='Active') or exists(select 1 from public.crm_product_lines l where l.deal_id=p_id and l.status='Active' and not exists(select 1 from public.crm_board_stages s where s.board_id=l.board_id and s.code=p_stage and s.active)) then raise exception 'Stage must be available on every active product board';end if;
if p_stage not in ('lost','won') and (p_followup is null or p_followup<current_date) then raise exception 'Next follow-up date required';end if;
if p_stage='contacted' and not exists(select 1 from public.crm_sales_activity where (deal_id=p_id or lead_id=old.lead_id) and kind in ('Call','Meeting','Note')) then raise exception 'Log a contact activity first';end if;
if p_stage in ('qualified','meeting') and (p_value is null or p_value<=0) then raise exception 'Estimated value required';end if;
if p_stage='meeting' and p_meeting is null then raise exception 'Meeting date required';end if;
if p_stage='lost' and (length(trim(coalesce(p_loss_note,'')))<3 or not exists(select 1 from public.crm_settings s where s.id='lost_reasons' and s.value ? p_loss_reason)) then raise exception 'Lost reason and explanation required';end if;
if p_reengage is not null and p_reengage<current_date then raise exception 'Re-engagement cannot be in the past';end if;
update public.crm_deals set stage=p_stage,estimated_value=p_value,next_followup=p_followup,meeting_at=p_meeting,loss_reason=case when p_stage='lost' then p_loss_reason else '' end,loss_note=case when p_stage='lost' then p_loss_note else '' end,reengage_on=case when p_stage='lost' then p_reengage else null end,version=version+1,stage_changed_at=case when stage<>p_stage then now() else stage_changed_at end where id=p_id;
insert into public.crm_sales_activity(lead_id,deal_id,kind,body,actor_id) values(old.lead_id,p_id,'Stage',old.stage||' → '||p_stage,auth.uid());end$$;
create function public.save_crm_product_line(p_id uuid,p_version integer,p_owner uuid,p_value numeric,p_survey boolean,p_design boolean,p_boq boolean,p_status text,p_reason text) returns void language plpgsql security definer set search_path='' as $$declare l public.crm_product_lines;d public.crm_deals;begin
select * into l from public.crm_product_lines where id=p_id for update;select * into d from public.crm_deals where id=l.deal_id for update;
if l.id is null or not portal_private.deal_access(l.deal_id) or not (portal_private.deal_edit(l.deal_id) or (portal_private.crm_permission('product.own') and portal_private.board_access(l.board_id))) then raise exception 'Product section access required';end if;
if l.version is distinct from p_version or d.stage in ('won','lost') then raise exception 'Product line changed or deal locked';end if;
if not portal_private.deal_edit(l.deal_id) and (p_owner is distinct from l.owner_id or p_status is distinct from l.status) then raise exception 'Sales owner controls ownership and dropped products';end if;
if p_owner is not null and not exists(select 1 from public.profiles where id=p_owner and active and role in ('admin','team')) then raise exception 'Active product owner required';end if;
if p_status='Dropped' and (select count(*) from public.crm_product_lines where deal_id=l.deal_id and status='Active')<=1 and l.status='Active' then raise exception 'Keep an active product or mark the deal Lost';end if;
update public.crm_product_lines set owner_id=p_owner,estimated_value=p_value,survey_done=p_survey,design_done=p_design,boq_ready=p_boq,status=p_status,drop_reason=case when p_status='Dropped' then trim(p_reason) else '' end,version=version+1 where id=p_id;
update public.crm_deals set version=version+1,last_activity_at=now() where id=l.deal_id;
insert into public.crm_sales_activity(deal_id,kind,body,actor_id) values(l.deal_id,'Product line','Updated '||(select name from public.crm_boards where id=l.board_id)||': '||p_status,auth.uid());end$$;
create function public.save_crm_sales_view(p_name text,p_filters jsonb) returns void language plpgsql security invoker set search_path='' as $$begin
insert into public.crm_saved_views(user_id,name,filters) values(auth.uid(),trim(p_name),p_filters) on conflict(user_id,name) do update set filters=excluded.filters;end$$;
grant insert,update on public.crm_saved_views to authenticated;
create policy saved_views_write on public.crm_saved_views for all to authenticated using(user_id=auth.uid() and portal_private.sales_user()) with check(user_id=auth.uid() and portal_private.sales_user());
-- All writes are checked RPCs; direct browser updates remain unavailable.
do $$declare f regprocedure;begin for f in select oid::regprocedure from pg_proc where pronamespace='public'::regnamespace and proname in ('configure_sales_board','set_sales_board_member','configure_sales_stage','capture_crm_lead','log_crm_activity','triage_crm_lead','assign_crm_products','save_crm_deal','save_crm_product_line','save_crm_sales_view') loop execute format('revoke all on function %s from public,anon',f);execute format('grant execute on function %s to authenticated',f);end loop;end$$;
create index crm_line_board on public.crm_product_lines(board_id,deal_id);
create index crm_deal_owner on public.crm_deals(owner_id);
create index crm_activity_deal on public.crm_sales_activity(deal_id,created_at desc);
create index crm_activity_lead on public.crm_sales_activity(lead_id,created_at desc);

create table public.crm_lead_imports(id uuid primary key,actor_id uuid not null references public.profiles,payload jsonb not null,row_count integer not null,created_at timestamptz not null default now());
alter table public.crm_lead_imports enable row level security;
revoke all on public.crm_lead_imports from public,anon,authenticated;
create function public.import_crm_leads(p_batch uuid,p_rows jsonb) returns integer language plpgsql security definer set search_path='' as $$declare old public.crm_lead_imports;r jsonb;n integer:=0;begin
if not portal_private.sales_user() or p_batch is null or jsonb_typeof(p_rows) is distinct from 'array' or jsonb_array_length(p_rows) not between 1 and 500 then raise exception 'Sales access and 1–500 enquiry rows required';end if;
perform pg_advisory_xact_lock(hashtext(p_batch::text));select * into old from public.crm_lead_imports where id=p_batch;
if found then if old.actor_id=auth.uid() and old.payload=p_rows then return old.row_count;else raise exception 'Import identifier already used';end if;end if;
for r in select value from jsonb_array_elements(p_rows) loop
perform public.capture_crm_lead(r->>'name',r->>'email',r->>'phone',r->>'company',r->>'city',r->>'country',r->>'message','CSV import',coalesce(r->>'campaign',''),'{}');n:=n+1;
end loop;insert into public.crm_lead_imports(id,actor_id,payload,row_count) values(p_batch,auth.uid(),p_rows,n);return n;end$$;
create function public.bulk_assign_crm_products(p_leads jsonb,p_boards uuid[],p_owner uuid,p_followup date) returns integer language plpgsql security definer set search_path='' as $$declare r jsonb;n integer:=0;begin
if not portal_private.sales_user() or jsonb_typeof(p_leads) is distinct from 'array' or jsonb_array_length(p_leads) not between 1 and 100 then raise exception 'Select 1–100 leads';end if;
for r in select value from jsonb_array_elements(p_leads) order by value->>'id' loop perform public.assign_crm_products((r->>'id')::uuid,(r->>'version')::integer,p_boards,p_owner,p_followup);n:=n+1;end loop;return n;end$$;
revoke all on function public.import_crm_leads(uuid,jsonb),public.bulk_assign_crm_products(jsonb,uuid[],uuid,date) from public,anon;
grant execute on function public.import_crm_leads(uuid,jsonb),public.bulk_assign_crm_products(jsonb,uuid[],uuid,date) to authenticated;
do $$declare tab text;begin foreach tab in array array['crm_boards','crm_board_stages','crm_board_memberships'] loop execute format('create trigger config_audit after insert or update or delete on public.%I for each row execute function portal_private.crm_config_audit()',tab);end loop;end$$;


alter table public.portal_reminders add column deal_id uuid references public.crm_deals;
create policy sales_reminder_scope on public.portal_reminders as restrictive for select to authenticated using(deal_id is null or portal_private.deal_access(deal_id));
create table public.crm_sales_tasks(id uuid primary key default gen_random_uuid(),deal_id uuid not null references public.crm_deals,title text not null,due_on date not null,event_key text not null unique,status text not null default 'Open' check(status in ('Open','Done')),note text not null default '',version integer not null default 1);
alter table public.crm_sales_tasks enable row level security;
revoke all on public.crm_sales_tasks from public,anon,authenticated;
grant select on public.crm_sales_tasks to authenticated;
create policy sales_task_read on public.crm_sales_tasks for select to authenticated using(portal_private.deal_access(deal_id));
create function public.complete_crm_sales_task(p_id uuid,p_version integer,p_note text) returns void language plpgsql security definer set search_path='' as $$declare task public.crm_sales_tasks;begin
select * into task from public.crm_sales_tasks where id=p_id for update;
if not found or not portal_private.deal_edit(task.deal_id) then raise exception 'Sales task unavailable';end if;
if task.version is distinct from p_version or task.status<>'Open' then raise exception 'Task changed or already completed';end if;
if length(trim(coalesce(p_note,''))) not between 3 and 2000 then raise exception 'Completion note required';end if;
update public.crm_sales_tasks set status='Done',note=trim(p_note),version=version+1 where id=p_id;
insert into public.crm_sales_activity(deal_id,kind,body,actor_id) values(task.deal_id,'Follow-up','Completed re-engagement: '||trim(p_note),auth.uid());end$$;
create function public.queue_crm_sales_reminders() returns integer language plpgsql security definer set search_path='' as $$declare opportunity public.crm_deals;recipient public.profiles;event text;heading text;n integer:=0;affected integer;begin
if not public.is_admin() and coalesce(auth.role(),'')<>'service_role' and not(auth.uid() is null and session_user='postgres') then raise exception 'Administrator or scheduler required';end if;
if not pg_try_advisory_xact_lock(hashtext('crm-sales-reminders')) then return 0;end if;
for opportunity in select * from public.crm_deals where (stage='lost' and reengage_on<=current_date) or (stage not in ('won','lost') and next_followup<=current_date) loop
if opportunity.stage='lost' then
 event:='sales-reengage:'||opportunity.id||':'||opportunity.reengage_on;heading:='Lost deal ready for re-engagement';
 insert into public.crm_sales_tasks(deal_id,title,due_on,event_key) values(opportunity.id,'Re-engage: '||opportunity.title,opportunity.reengage_on,event) on conflict do nothing;
else event:='sales-followup:'||opportunity.id||':'||opportunity.next_followup;heading:='Deal follow-up due';end if;
for recipient in select u.* from public.profiles u where u.active and (u.role='admin' or (u.id=opportunity.owner_id and (portal_private.crm_user_permission(u.id,'sales.own') or portal_private.crm_user_permission(u.id,'sales.manage')) and exists(select 1 from public.crm_product_lines pl join public.crm_board_memberships bm on bm.board_id=pl.board_id where pl.deal_id=opportunity.id and bm.user_id=u.id))) loop
insert into public.portal_reminders(user_id,event_key,title,view,deal_id) select recipient.id,event,heading||': '||opportunity.title,'sales_boards',opportunity.id where coalesce((select enabled from public.portal_reminder_preferences where user_id=recipient.id),true) on conflict do nothing;get diagnostics affected=row_count;n:=n+affected;
end loop;end loop;return n;end$$;
revoke all on function public.complete_crm_sales_task(uuid,integer,text),public.queue_crm_sales_reminders() from public,anon;
grant execute on function public.complete_crm_sales_task(uuid,integer,text),public.queue_crm_sales_reminders() to authenticated;
grant execute on function public.queue_crm_sales_reminders() to service_role;
-- The existing inbox's manual scan includes sales; its scheduler gate is preserved.
do $$declare definition text;begin
select pg_get_functiondef('public.queue_portal_reminders()'::regprocedure) into definition;
if position(' return n;' in definition)=0 then raise exception 'Unexpected reminder scanner definition';end if;
definition:=replace(definition,' return n;',' n:=n+public.queue_crm_sales_reminders(); return n;');execute definition;
end$$;

notify pgrst,'reload schema';commit;
