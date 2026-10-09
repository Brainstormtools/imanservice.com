begin;
create table portal_private.sales_manager_lead_scopes(user_id uuid primary key references public.profiles,team_id uuid not null references public.crm_teams);
create index sales_manager_lead_scope_team on portal_private.sales_manager_lead_scopes(team_id);
alter table portal_private.sales_manager_lead_scopes enable row level security;
revoke all on portal_private.sales_manager_lead_scopes from public,anon,authenticated;
create function public.set_sales_manager_lead_scope(p_user uuid,p_team uuid) returns void language plpgsql security definer set search_path='' as $$begin
 if not public.is_admin() then raise exception 'Administrator sets sales lead scope';end if;
 if p_team is null or not exists(select 1 from public.crm_teams where id=p_team and active) or not exists(select 1 from public.profiles where id=p_user and active and role='team') or not portal_private.crm_user_permission(p_user,'sales.manage') then raise exception 'Active sales manager and team required';end if;
 insert into portal_private.sales_manager_lead_scopes(user_id,team_id) values(p_user,p_team) on conflict(user_id) do update set team_id=excluded.team_id;
end$$;
create or replace function portal_private.lead_access(p_lead uuid) returns boolean language sql stable security definer set search_path='' as $$
select public.is_admin() or (portal_private.sales_user() and exists(select 1 from public.crm_leads l where l.id=p_lead
 and (not exists(select 1 from portal_private.sales_manager_lead_scopes where user_id=auth.uid()) or exists(select 1 from portal_private.sales_manager_lead_scopes s join public.crm_teams t on t.id=s.team_id and t.active join public.crm_memberships m on m.team_id=s.team_id join public.profiles u on u.id=m.user_id and u.active and u.role='team' where s.user_id=auth.uid() and m.user_id=l.owner_id))
 and ((l.status<>'Assigned' and (portal_private.crm_permission('sales.manage') or l.owner_id=auth.uid())) or (l.status='Assigned' and exists(select 1 from public.crm_deals d where d.lead_id=l.id and portal_private.deal_access(d.id))))));$$;
revoke all on function public.set_sales_manager_lead_scope(uuid,uuid) from public,anon;
grant execute on function public.set_sales_manager_lead_scope(uuid,uuid) to authenticated;
commit;
