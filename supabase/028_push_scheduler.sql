-- Secrets are provisioned separately into Vault; no secret values in source control.
begin;
create extension if not exists pg_net with schema extensions;
create function public.portal_push_worker_config(p_secret text) returns jsonb language plpgsql security definer set search_path='' as $$declare secret text;pub text;priv text;begin
 if coalesce(auth.role(),'')<>'service_role' then raise exception 'Scheduler required';end if;
 select decrypted_secret into secret from vault.decrypted_secrets where name='portal_push_worker_secret';
 if secret is null or p_secret is null or p_secret<>secret then return null;end if;
 select decrypted_secret into pub from vault.decrypted_secrets where name='portal_push_public_key';
 select decrypted_secret into priv from vault.decrypted_secrets where name='portal_push_private_key';
 if pub is null or priv is null then raise exception 'Push keys not configured';end if;
 return jsonb_build_object('publicKey',pub,'privateKey',priv);
end$$;
revoke all on function public.portal_push_worker_config(text) from public,anon,authenticated;
grant execute on function public.portal_push_worker_config(text) to service_role;
create function portal_private.schedule_portal_push() returns bigint language plpgsql security definer set search_path='' as $$declare secret text;url text;begin
 select decrypted_secret into secret from vault.decrypted_secrets where name='portal_push_worker_secret';
 select decrypted_secret into url from vault.decrypted_secrets where name='portal_push_worker_url';
 if secret is null or url is null then return null;end if;
 if url !~ '^https://[a-z0-9]+[.]supabase[.]co/functions/v1/portal-push-worker$' then raise exception 'Invalid push worker URL';end if;
 return net.http_post(url:=url,headers:=jsonb_build_object('Content-Type','application/json','Authorization','Bearer '||secret),body:='{}'::jsonb,timeout_milliseconds:=55000);
end$$;
revoke all on function portal_private.schedule_portal_push() from public,anon,authenticated,service_role;
select cron.schedule('iman-portal-web-push','1-59/15 * * * *','select portal_private.schedule_portal_push()');
commit;
