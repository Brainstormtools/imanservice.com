begin;
-- Department roles supplement the existing authentication audience. They never
-- turn a technician into a legacy administrator or bypass assignment policies.
create table public.crm_roles(id text primary key check(id ~ '^[a-z][a-z0-9_]{1,49}$'),name text not null check(length(trim(name)) between 1 and 100),permissions text[] not null default '{}',active boolean not null default true,version integer not null default 1);
create table public.crm_teams(id uuid primary key default gen_random_uuid(),name text not null unique check(length(trim(name)) between 1 and 100),active boolean not null default true,version integer not null default 1);
create table public.crm_memberships(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles,role_id text not null references public.crm_roles,team_id uuid not null references public.crm_teams,unique(user_id,role_id,team_id));
create table public.crm_settings(id text primary key check(id ~ '^[a-z][a-z0-9_]{1,49}$'),label text not null,value jsonb not null,version integer not null default 1,updated_by uuid references public.profiles,updated_at timestamptz not null default now());
create table public.crm_config_history(id uuid primary key default gen_random_uuid(),entity text not null,record_id text not null,actor_id uuid references public.profiles,action text not null,before_value jsonb,after_value jsonb,created_at timestamptz not null default now());
insert into public.crm_roles(id,name,permissions) values
('sales_manager','Sales Manager',array['customer.read','sales.manage']),('sales_agent','Sales Agent',array['customer.read','sales.own']),('product_specialist','Product Specialist',array['customer.read','product.own']),('project_manager','Project Manager',array['customer.read','project.own']),('team_lead','Team Lead',array['customer.read','team.own']),('technician','Technician',array['work.own']),('accounts','Accounts',array['customer.read','finance.manage']),('hr','HR',array['hr.manage']),('support_agent','Support Agent',array['customer.read','support.own']),('store_keeper','Store Keeper',array['stock.manage']),('purchase_officer','Procurement / Purchase Officer',array['purchase.manage']),('logistics','Logistics',array['logistics.manage']);
insert into public.crm_settings(id,label,value) values
('delay_reasons','Delay reasons','["Material not available","Tool or equipment missing","Site not ready","Client access / permission","Design or scope change","Rework","Travel & logistics","Other"]'),
('expense_categories','Expense categories','["Materials","Labor/Salaries","Subcontractor","Equipment","TADA","Software & Licenses","Insurance","Admin & Overhead","Rent & Utilities","Marketing & Bidding","Taxes & Fees","Other"]'),
('complaint_categories','Complaint categories','["Delay","Quality","Billing","Staff behaviour","Technical"]');
create function portal_private.crm_permission(p_permission text) returns boolean language sql stable security definer set search_path='' as $$
select public.is_admin() or exists(select 1 from public.crm_memberships m join public.crm_roles r on r.id=m.role_id join public.crm_teams t on t.id=m.team_id join public.profiles u on u.id=m.user_id where u.id=auth.uid() and u.active and u.role='team' and r.active and t.active and p_permission=any(r.permissions));$$;
revoke all on function portal_private.crm_permission(text) from public,anon;
grant execute on function portal_private.crm_permission(text) to authenticated;
do $$declare tab text;begin
foreach tab in array array['crm_roles','crm_teams','crm_settings','crm_memberships','crm_config_history'] loop
 execute format('alter table public.%I enable row level security',tab);
 execute format('revoke all on public.%I from public,anon,authenticated',tab);
 execute format('grant select on public.%I to authenticated',tab);
 execute format('create policy config_admin_read on public.%I for select to authenticated using(public.is_admin())',tab);
end loop;end$$;
create policy memberships_self on public.crm_memberships for select to authenticated using(user_id=auth.uid() and public.is_staff());
create policy roles_staff on public.crm_roles for select to authenticated using(public.is_staff());
create policy teams_staff on public.crm_teams for select to authenticated using(public.is_staff());
create function portal_private.crm_config_audit() returns trigger language plpgsql security definer set search_path='' as $$begin
insert into public.crm_config_history(entity,record_id,actor_id,action,before_value,after_value) values(tg_table_name,coalesce(to_jsonb(new)->>'id',to_jsonb(old)->>'id'),auth.uid(),tg_op,case when tg_op<>'INSERT' then to_jsonb(old) end,case when tg_op<>'DELETE' then to_jsonb(new) end);return coalesce(new,old);end$$;
do $$declare tab text;begin foreach tab in array array['crm_roles','crm_teams','crm_settings','crm_memberships'] loop execute format('create trigger config_audit after insert or update or delete on public.%I for each row execute function portal_private.crm_config_audit()',tab);end loop;end$$;
revoke all on function portal_private.crm_config_audit() from public,anon,authenticated;
create function public.save_crm_configuration(p_kind text,p_id text,p_version integer,p_name text,p_value jsonb default null,p_active boolean default true) returns text language plpgsql security definer set search_path='' as $$declare result_id text;begin
if not public.is_admin() then raise exception 'Administrator required';end if;
if p_kind='team' then
 if p_id is null then insert into public.crm_teams(name) values(trim(p_name)) returning id::text into result_id;
 else update public.crm_teams set name=trim(p_name),active=p_active,version=version+1 where id=p_id::uuid and version=p_version returning id::text into result_id;end if;
elsif p_kind='role' then
 if p_value is null or jsonb_typeof(p_value)<>'array' or jsonb_array_length(p_value)>30 or exists(select 1 from jsonb_array_elements(p_value) x where jsonb_typeof(x)<>'string' or (x#>>'{}') not in ('customer.read','sales.manage','sales.own','product.own','project.own','team.own','work.own','finance.manage','hr.manage','support.own','stock.manage','purchase.manage','logistics.manage')) then raise exception 'Choose supported department permissions';end if;
 if p_version is null then insert into public.crm_roles(id,name,permissions) values(p_id,trim(p_name),array(select x#>>'{}' from jsonb_array_elements(p_value) x)) returning id into result_id;
 else update public.crm_roles set name=trim(p_name),permissions=array(select x#>>'{}' from jsonb_array_elements(p_value) x),active=p_active,version=version+1 where id=p_id and version=p_version returning id into result_id;end if;
elsif p_kind='setting' then
 if p_value is null or jsonb_typeof(p_value)<>'array' or jsonb_array_length(p_value) not between 1 and 100 or exists(select 1 from jsonb_array_elements(p_value) x where jsonb_typeof(x)<>'string' or length(trim(x#>>'{}')) not between 1 and 100) or (select count(distinct lower(trim(x#>>'{}'))) from jsonb_array_elements(p_value) x)<>jsonb_array_length(p_value) then raise exception 'Enter unique nonempty options, one per line';end if;
 update public.crm_settings set value=p_value,version=version+1,updated_by=auth.uid(),updated_at=now() where id=p_id and version=p_version returning id into result_id;
else raise exception 'Unsupported configuration';end if;
if result_id is null then raise exception 'Record changed or unavailable. Refresh first.';end if;return result_id;
end$$;
create function public.set_crm_membership(p_user uuid,p_role text,p_team uuid,p_enabled boolean) returns void language plpgsql security definer set search_path='' as $$begin
if not public.is_admin() then raise exception 'Administrator required';end if;
if p_enabled is null then raise exception 'Membership action required';end if;
if p_enabled then
 if not exists(select 1 from public.profiles where id=p_user and active and role='team') or not exists(select 1 from public.crm_roles where id=p_role and active) or not exists(select 1 from public.crm_teams where id=p_team and active) then raise exception 'Choose active staff, role and team';end if;
 insert into public.crm_memberships(user_id,role_id,team_id) values(p_user,p_role,p_team) on conflict do nothing;
else delete from public.crm_memberships where user_id=p_user and role_id=p_role and team_id=p_team;end if;
end$$;
create function public.my_crm_permissions() returns text[] language sql stable security definer set search_path='' as $$
select coalesce(array_agg(distinct permission),'{}'::text[]) from public.crm_memberships m join public.crm_roles r on r.id=m.role_id join public.crm_teams t on t.id=m.team_id join public.profiles u on u.id=m.user_id cross join lateral unnest(r.permissions) permission where u.id=auth.uid() and u.active and u.role='team' and r.active and t.active;$$;
revoke all on function public.my_crm_permissions() from public,anon;
grant execute on function public.my_crm_permissions() to authenticated;
-- Security invoker: every source still uses its existing row permissions.
create function public.customer_history(p_company uuid) returns table(id text,kind text,title text,state text,happened_at timestamptz,project_id uuid) language plpgsql security invoker set search_path='' as $$begin
if not portal_private.crm_permission('customer.read') or not exists(select 1 from public.companies where companies.id=p_company) then raise exception 'Customer history unavailable';end if;
return query
 select p.id::text,'Project'::text,p.title,p.status,p.created_at,p.id from public.projects p where p.company_id=p_company
 union all select a.id::text,'Activity',a.title,a.action,a.created_at,a.project_id from public.workspace_activity a join public.projects p on p.id=a.project_id where p.company_id=p_company
 union all select t.id::text,'Task',t.title,t.status,t.created_at,t.project_id from public.tasks t join public.projects p on p.id=t.project_id where p.company_id=p_company
 union all select t.id::text,'Support ticket',t.title,t.status,t.created_at,t.project_id from public.tickets t join public.projects p on p.id=t.project_id where p.company_id=p_company
 union all select e.id::text,'Estimate',e.title,e.status,e.created_at,null::uuid from public.estimates e where e.company_id=p_company
 union all select i.id::text,'Invoice',i.number,i.status,i.created_at,null::uuid from public.invoices i where i.company_id=p_company
 union all select c.id::text,'Contract',c.title,c.status,c.created_at,null::uuid from public.contracts c where c.company_id=p_company
 order by 5 desc,1 limit 500;
end$$;
revoke all on function public.save_crm_configuration(text,text,integer,text,jsonb,boolean),public.set_crm_membership(uuid,text,uuid,boolean),public.customer_history(uuid) from public,anon;
grant execute on function public.save_crm_configuration(text,text,integer,text,jsonb,boolean),public.set_crm_membership(uuid,text,uuid,boolean),public.customer_history(uuid) to authenticated;
notify pgrst,'reload schema';
commit;
