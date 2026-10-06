-- Opt-in browser push. Provider endpoints and encryption keys are private account data.
begin;
create table public.portal_push_subscriptions(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles,
 endpoint text not null unique check(length(endpoint) between 20 and 2048),
 p256dh text not null check(p256dh ~ '^[A-Za-z0-9_-]{87}$'),auth text not null check(auth ~ '^[A-Za-z0-9_-]{22}$'),
 created_at timestamptz not null default now(),expires_at timestamptz not null default now()+interval '30 days'
);
create index portal_push_user on public.portal_push_subscriptions(user_id);
alter table public.portal_push_subscriptions enable row level security;
revoke all on public.portal_push_subscriptions from public,anon,authenticated;
grant select on public.portal_push_subscriptions to authenticated;
create policy push_own on public.portal_push_subscriptions for select to authenticated using(user_id=(select auth.uid()) and exists(select 1 from public.profiles where id=auth.uid() and active));
create table portal_private.push_deliveries(
 subscription_id uuid not null references public.portal_push_subscriptions on delete cascade,
 reminder_id uuid not null references public.portal_reminders on delete cascade,
 attempts integer not null default 0,lease uuid,lease_until timestamptz,sent_at timestamptz,
 primary key(subscription_id,reminder_id)
);
alter table portal_private.push_deliveries enable row level security;
revoke all on portal_private.push_deliveries from public,anon,authenticated;

create function public.save_portal_push(p_endpoint text,p_p256dh text,p_auth text) returns uuid language plpgsql security definer set search_path='' as $$declare result uuid;begin
 if not exists(select 1 from public.profiles where id=auth.uid() and active) then raise exception 'Active account required';end if;
 perform pg_advisory_xact_lock(hashtext('portal-push-subscription:'||auth.uid()));
 -- Exact HTTPS provider hosts, no credentials, ports or redirects to arbitrary hosts.
 if p_endpoint is null or length(p_endpoint)>2048 or p_endpoint !~ '^https://(fcm[.]googleapis[.]com|updates[.]push[.]services[.]mozilla[.]com|web[.]push[.]apple[.]com)/[A-Za-z0-9_/?=&%+.-]+$' or p_p256dh is null or p_p256dh !~ '^[A-Za-z0-9_-]{87}$' or p_auth is null or p_auth !~ '^[A-Za-z0-9_-]{22}$' then raise exception 'Supported browser subscription required';end if;
 if exists(select 1 from public.portal_push_subscriptions where endpoint=p_endpoint and user_id<>auth.uid()) then raise exception 'Disable notifications on the previous account first';end if;
 delete from public.portal_push_subscriptions where user_id=auth.uid() and expires_at<=now();
 if not exists(select 1 from public.portal_push_subscriptions where endpoint=p_endpoint) and (select count(*) from public.portal_push_subscriptions where user_id=auth.uid())>=5 then raise exception 'Five devices maximum; disable an old device first';end if;
 insert into public.portal_push_subscriptions(user_id,endpoint,p256dh,auth) values(auth.uid(),p_endpoint,p_p256dh,p_auth)
 on conflict(endpoint) do update set p256dh=excluded.p256dh,auth=excluded.auth,expires_at=now()+interval '30 days' where portal_push_subscriptions.user_id=auth.uid() returning id into result;
 return result;
end$$;
create function public.remove_portal_push(p_endpoint text) returns void language sql security definer set search_path='' as $$delete from public.portal_push_subscriptions where user_id=auth.uid() and endpoint=p_endpoint;$$;

-- Mirrors reminder_read (013) and sales_reminder_scope (015). Keep this predicate
-- in sync with reminder RLS. Only the service scheduler may select another identity.
create function portal_private.push_visible(p_uid uuid,p_reminder uuid) returns boolean language plpgsql security definer set search_path='' as $$declare previous text:=current_setting('request.jwt.claim.sub',true);visible boolean;begin
 perform set_config('request.jwt.claim.sub',p_uid::text,true);
 select exists(select 1 from public.portal_reminders r where r.id=p_reminder and r.user_id=p_uid and r.read_at is null
 and exists(select 1 from public.profiles where id=p_uid and active)
 and coalesce((select enabled from public.portal_reminder_preferences where user_id=p_uid),true)
 and (r.project_id is null or public.can_project(r.project_id))
 and (r.task_id is null or not portal_private.team_account() or portal_private.task_assigned(r.task_id))
 and (r.ticket_id is null or not portal_private.team_account() or portal_private.ticket_visible(r.ticket_id))
 and (r.contract_id is null or (not portal_private.team_account() and exists(select 1 from public.contracts c where c.id=r.contract_id and public.can_company(c.company_id))))
 and (r.job_id is null or exists(select 1 from public.it_jobs j where j.id=r.job_id and public.it_job_visible(j)))
 and (r.deal_id is null or portal_private.deal_access(r.deal_id))) into visible;
 perform set_config('request.jwt.claim.sub',coalesce(previous,''),true);return visible;
 exception when others then perform set_config('request.jwt.claim.sub',coalesce(previous,''),true);raise;
end$$;
create function public.claim_portal_push() returns jsonb language plpgsql security definer set search_path='' as $$declare result jsonb;begin
 if coalesce(auth.role(),'')<>'service_role' then raise exception 'Scheduler required';end if;
 if not pg_try_advisory_xact_lock(hashtext('portal-push')) then return '[]'::jsonb;end if;
 delete from public.portal_push_subscriptions where expires_at<=now();
 delete from portal_private.push_deliveries d using public.portal_reminders r where d.reminder_id=r.id and r.created_at<=now()-interval '24 hours';
 insert into portal_private.push_deliveries(subscription_id,reminder_id)
 select s.id,r.id from public.portal_push_subscriptions s join public.portal_reminders r on r.user_id=s.user_id
 where s.expires_at>now() and r.created_at>=s.created_at and r.created_at>now()-interval '24 hours' and r.read_at is null
 and portal_private.push_visible(s.user_id,r.id) on conflict do nothing;
 with selected as (
 select d.subscription_id,d.reminder_id from portal_private.push_deliveries d join public.portal_push_subscriptions s on s.id=d.subscription_id join public.portal_reminders r on r.id=d.reminder_id
 where d.sent_at is null and d.attempts<3 and (d.lease_until is null or d.lease_until<now()) and s.expires_at>now() and r.created_at>now()-interval '24 hours' and portal_private.push_visible(s.user_id,r.id)
 order by r.created_at limit 20 for update of d skip locked
 ),claimed as (
 update portal_private.push_deliveries d set attempts=attempts+1,lease=gen_random_uuid(),lease_until=now()+interval '5 minutes' from selected x where d.subscription_id=x.subscription_id and d.reminder_id=x.reminder_id returning d.*
 ) select coalesce(jsonb_agg(jsonb_build_object('subscription_id',s.id,'reminder_id',d.reminder_id,'lease',d.lease,'endpoint',s.endpoint,'p256dh',s.p256dh,'auth',s.auth)),'[]'::jsonb) into result from claimed d join public.portal_push_subscriptions s on s.id=d.subscription_id;
 return result;
end$$;
create function public.finish_portal_push(p_subscription uuid,p_reminder uuid,p_lease uuid,p_outcome text) returns void language plpgsql security definer set search_path='' as $$begin
 if coalesce(auth.role(),'')<>'service_role' then raise exception 'Scheduler required';end if;
 if p_outcome not in ('sent','retry','expired') or p_outcome is null then raise exception 'Invalid outcome';end if;
 if not exists(select 1 from portal_private.push_deliveries where subscription_id=p_subscription and reminder_id=p_reminder and lease=p_lease) then return;end if;
 if p_outcome='expired' then delete from public.portal_push_subscriptions where id=p_subscription;return;end if;
 update portal_private.push_deliveries set sent_at=case when p_outcome='sent' then now() else null end,lease=null,lease_until=case when p_outcome='retry' then now()+interval '15 minutes' else null end where subscription_id=p_subscription and reminder_id=p_reminder and lease=p_lease;
end$$;
revoke all on function public.save_portal_push(text,text,text),public.remove_portal_push(text),portal_private.push_visible(uuid,uuid),public.claim_portal_push(),public.finish_portal_push(uuid,uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.save_portal_push(text,text,text),public.remove_portal_push(text) to authenticated;
grant execute on function public.claim_portal_push(),public.finish_portal_push(uuid,uuid,uuid,text) to service_role;
commit;
