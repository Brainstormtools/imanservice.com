-- Release with matching UI. Unapplied while deployment is pending.
create table portal_private.crm_conversion_accounts(
 sale_id uuid primary key references public.crm_sales, deal_id uuid not null unique references public.crm_deals,
 invoice_id uuid not null unique references public.invoices, recipient_id uuid not null references public.profiles,
 actor_id uuid not null references public.profiles, created_at timestamptz not null default now()
);
create index crm_conversion_accounts_recipient on portal_private.crm_conversion_accounts(recipient_id);
create index crm_conversion_accounts_actor on portal_private.crm_conversion_accounts(actor_id);
alter table portal_private.crm_conversion_accounts enable row level security;
revoke all on portal_private.crm_conversion_accounts from public,anon,authenticated;
create trigger crm_conversion_accounts_immutable before update or delete on portal_private.crm_conversion_accounts for each row execute function portal_private.lead_api_evidence_immutable();
create function public.crm_conversion_accounts_people(p_deal uuid) returns table(id uuid,name text)
language plpgsql stable security definer set search_path='' as $$begin
 if auth.uid() is null or not exists(select 1 from public.profiles u where u.id=auth.uid() and u.active and u.role in ('admin','team')) or not portal_private.deal_edit(p_deal) then raise exception 'Current sales conversion authority required';end if;
 return query select p.id,p.name from public.profiles p where p.active and p.role in ('admin','team') and portal_private.crm_user_permission(p.id,'finance.manage') order by p.name,p.id;
end$$;
revoke all on function public.crm_conversion_accounts_people(uuid) from public,anon;
grant execute on function public.crm_conversion_accounts_people(uuid) to authenticated;
-- Patch only the audited definition, retaining accepted-publication, budget, atomicity and template checks.
do $$declare definition text;hook text:='select * into deal from public.crm_deals where id=p_deal for update;';begin
 definition:=pg_get_functiondef('public.convert_crm_won(uuid,integer,uuid,uuid,date,jsonb,jsonb,jsonb)'::regprocedure);
 if position('crm_conversion_accounts' in definition)>0 or position(hook in definition)=0 or position('return sale.id;end' in definition)=0 or position('then return sale.id;else' in definition)=0 then raise exception 'Unexpected conversion source; inspect before applying';end if;
 definition:=replace(definition,hook,hook||$guard$
 perform 1 from public.profiles where id in(auth.uid(),nullif(p_payment->>'accounts_id','')::uuid) order by id for share;
 perform 1 from public.crm_board_memberships where user_id=auth.uid() order by board_id for share;
 perform 1 from public.crm_boards where id in(select board_id from public.crm_product_lines where deal_id=p_deal) order by id for share;
 perform 1 from public.crm_memberships where user_id in(auth.uid(),nullif(p_payment->>'accounts_id','')::uuid) order by user_id,role_id,team_id for share;
 perform 1 from public.crm_roles order by id for share;
 perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id in(auth.uid(),nullif(p_payment->>'accounts_id','')::uuid)) order by id for share;
 if auth.uid() is null or not exists(select 1 from public.profiles u where u.id=auth.uid() and u.active and u.role in ('admin','team')) or not portal_private.deal_edit(p_deal) then raise exception 'Current conversion authority required after waiting';end if;
$guard$);
 definition:=replace(definition,'then return sale.id;else',$retry$then
 if exists(select 1 from portal_private.crm_conversion_accounts r where r.sale_id=sale.id and r.recipient_id is distinct from nullif(p_payment->>'accounts_id','')::uuid) then raise exception 'Conversion retry must retain original Accounts recipient';end if;
 return sale.id;else$retry$);
 hook:='if deal.version is distinct from p_version';
 if position(hook in definition)=0 then raise exception 'Conversion version guard unavailable';end if;
 definition:=replace(definition,hook,$eligible$
 if not exists(select 1 from public.profiles where id=nullif(p_payment->>'accounts_id','')::uuid and active and role in ('admin','team') and portal_private.crm_user_permission(id,'finance.manage')) then raise exception 'Choose an actual active Accounts recipient';end if;
 if deal.version is distinct from p_version$eligible$);
 definition:=replace(definition,'return sale.id;end',$route$
 insert into portal_private.crm_conversion_accounts(sale_id,deal_id,invoice_id,recipient_id,actor_id) values(sale.id,deal.id,invoice,nullif(p_payment->>'accounts_id','')::uuid,auth.uid());
 insert into public.portal_reminders(user_id,event_key,title,view)
 select nullif(p_payment->>'accounts_id','')::uuid,'crm-sale-accounts:'||sale.id,'A converted sale invoice draft requires Accounts review','finance_workspace'
 where coalesce((select enabled from public.portal_reminder_preferences where user_id=nullif(p_payment->>'accounts_id','')::uuid),true) on conflict do nothing;
 return sale.id;end$route$);
 execute definition;
end$$;
