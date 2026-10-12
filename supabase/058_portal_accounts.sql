begin;
create table public.portal_account_requests(id uuid primary key,actor_id uuid not null references public.profiles,target_id uuid not null unique default gen_random_uuid(),details jsonb not null,status text not null default 'Pending' check(status in ('Pending','Completed')),created_at timestamptz not null default now(),completed_at timestamptz);
create index portal_accounts_actor on public.portal_account_requests(actor_id);
create table public.portal_account_history(id uuid primary key default gen_random_uuid(),actor_id uuid not null references public.profiles,target_id uuid not null references public.profiles,action text not null,before_profile jsonb,after_profile jsonb,created_at timestamptz not null default now());
create index portal_account_history_actor on public.portal_account_history(actor_id);
create index portal_account_history_target on public.portal_account_history(target_id);
alter table public.portal_account_requests enable row level security;
alter table public.portal_account_history enable row level security;
revoke all on public.portal_account_requests,public.portal_account_history from public,anon,authenticated;
grant select on public.portal_account_requests,public.portal_account_history to authenticated;
grant all on public.portal_account_requests,public.portal_account_history to service_role;
create policy account_requests_read on public.portal_account_requests for select to authenticated using(public.is_admin());
create policy account_history_read on public.portal_account_history for select to authenticated using(public.is_admin());
create function public.reserve_portal_account(p_actor uuid,p_id uuid,p_details jsonb) returns public.portal_account_requests language plpgsql security definer set search_path='' as $$
declare r public.portal_account_requests;cid uuid;tid uuid;dr text;
begin
 if not exists(select 1 from public.profiles where id=p_actor and active and role='admin') then raise exception 'Active administrator required';end if;
 if p_id is null or p_details is null or jsonb_typeof(p_details)<>'object' or (select count(*) from jsonb_object_keys(p_details))<>6 then raise exception 'Complete account request required';end if;
 if jsonb_typeof(p_details->'name') is distinct from 'string' or length(trim(p_details->>'name')) not between 1 and 160 or jsonb_typeof(p_details->'email') is distinct from 'string' or length(p_details->>'email')>254 or p_details->>'email'!~'^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' or p_details->>'email'<>lower(trim(p_details->>'email')) or p_details->>'role' not in ('client','team','admin') or jsonb_typeof(p_details->'role') is distinct from 'string' then raise exception 'Valid name email and account role required';end if;
 if not(p_details ?& array['company_id','department_role','team_id']) then raise exception 'Explicit access choices required';end if;
 cid:=(p_details->>'company_id')::uuid;tid:=(p_details->>'team_id')::uuid;dr:=p_details->>'department_role';
 if p_details->>'role'='client' then if cid is null or not exists(select 1 from public.companies where id=cid) or tid is not null or dr is not null then raise exception 'Client company and no staff membership required';end if;
 else if cid is not null then raise exception 'Staff accounts cannot inherit a client company';end if;end if;
 if (tid is null)<>(dr is null) or tid is not null and (p_details->>'role'<>'team' or not exists(select 1 from public.crm_teams where id=tid and active) or not exists(select 1 from public.crm_roles where id=dr and active)) then raise exception 'Active explicit staff team and department role required';end if;
 select * into r from public.portal_account_requests where id=p_id for update;
 if r.id is not null then if r.actor_id is distinct from p_actor or r.details is distinct from p_details then raise exception 'Account request ID already used with different data';end if;return r;end if;
 insert into public.portal_account_requests(id,actor_id,details) values(p_id,p_actor,p_details) returning * into r;return r;
end$$;
create function public.complete_portal_account(p_actor uuid,p_id uuid) returns uuid language plpgsql security definer set search_path='' as $$
declare r public.portal_account_requests;u public.profiles;
begin
 if not exists(select 1 from public.profiles where id=p_actor and active and role='admin') then raise exception 'Active administrator required';end if;
 select * into r from public.portal_account_requests where id=p_id for update;
 if r.id is null or r.actor_id is distinct from p_actor then raise exception 'Own reserved account request required';end if;
 if r.status='Completed' then return r.target_id;end if;
 if not exists(select 1 from auth.users where id=r.target_id and lower(email)=r.details->>'email' and raw_app_meta_data->>'portal_request'=r.id::text) then raise exception 'Matching server-created authentication account required';end if;
 if r.details->>'department_role' is not null and (not exists(select 1 from public.crm_roles where id=r.details->>'department_role' and active) or not exists(select 1 from public.crm_teams where id=(r.details->>'team_id')::uuid and active)) then raise exception 'Staff membership is no longer active';end if;
 insert into public.profiles(id,name,role,company_id) values(r.target_id,trim(r.details->>'name'),r.details->>'role',(r.details->>'company_id')::uuid) returning * into u;
 if r.details->>'department_role' is not null then insert into public.crm_memberships(user_id,role_id,team_id) values(r.target_id,r.details->>'department_role',(r.details->>'team_id')::uuid);end if;
 update public.portal_account_requests set status='Completed',completed_at=now() where id=r.id;
 insert into public.portal_account_history(actor_id,target_id,action,after_profile) values(p_actor,u.id,'Account created',to_jsonb(u));return u.id;
end$$;
create function public.manage_portal_account(p_user uuid,p_expected jsonb,p_name text,p_role text,p_company uuid,p_active boolean) returns void language plpgsql security definer set search_path='' as $$
declare old public.profiles;updated public.profiles;
begin
 if not public.is_admin() then raise exception 'Active administrator required';end if;
 if p_user=auth.uid() then raise exception 'Use another administrator to change your own access';end if;
 select * into old from public.profiles where id=p_user for update;
 if old.id is null or jsonb_build_object('name',old.name,'role',old.role,'company_id',old.company_id,'active',old.active) is distinct from p_expected then raise exception 'Current account details required';end if;
 if length(trim(coalesce(p_name,''))) not between 1 and 160 or p_role is null or p_role not in ('client','team','admin') or p_active is null or p_role='client' and (p_company is null or not exists(select 1 from public.companies where id=p_company)) or p_role<>'client' and p_company is not null then raise exception 'Valid name role company and access required';end if;
 if old.role is distinct from p_role then delete from public.crm_memberships where user_id=p_user;end if;
 update public.profiles set name=trim(p_name),role=p_role,company_id=p_company,active=p_active where id=p_user returning * into updated;
 insert into public.portal_account_history(actor_id,target_id,action,before_profile,after_profile) values(auth.uid(),p_user,'Access updated',to_jsonb(old),to_jsonb(updated));
end$$;
create function public.record_portal_password_link(p_actor uuid,p_user uuid) returns void language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.profiles where id=p_actor and active and role='admin') or not exists(select 1 from public.profiles where id=p_user and active) then raise exception 'Active administrator and active target required';end if;
 insert into public.portal_account_history(actor_id,target_id,action) values(p_actor,p_user,'Password setup/recovery link issued');
end$$;
revoke all on function public.reserve_portal_account(uuid,uuid,jsonb),public.complete_portal_account(uuid,uuid),public.record_portal_password_link(uuid,uuid) from public,anon,authenticated;
grant execute on function public.reserve_portal_account(uuid,uuid,jsonb),public.complete_portal_account(uuid,uuid),public.record_portal_password_link(uuid,uuid) to service_role;
revoke all on function public.manage_portal_account(uuid,jsonb,text,text,uuid,boolean) from public,anon;
grant execute on function public.manage_portal_account(uuid,jsonb,text,text,uuid,boolean) to authenticated;
commit;
