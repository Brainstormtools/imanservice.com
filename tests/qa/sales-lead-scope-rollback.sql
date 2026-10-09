begin;
select set_config('request.jwt.claim.sub',(select id::text from public.profiles where role='admin' and active limit 1),true);
insert into public.crm_leads(name,email,source,owner_id) values
 ('QA scope rollback','scope-team@example.test','QA',(select id from public.profiles where name='Acceptance Sales Agent')),
 ('QA scope rollback','scope-outside@example.test','QA',(select id from public.profiles where role='admin' and active limit 1)),
 ('QA scope rollback','scope-unowned@example.test','QA',null);
select set_config('request.jwt.claim.sub',(select id::text from public.profiles where name='Acceptance Sales Manager'),true);
set local role authenticated;
do $$begin
 if (select count(*) from public.crm_leads where name='QA scope rollback')<>1 then raise exception 'Scope isolation failed';end if;
 if not exists(select 1 from public.crm_leads where email='scope-team@example.test') then raise exception 'Team owner invisible';end if;
 if exists(select 1 from public.crm_leads where email='scope-outside@example.test') then raise exception 'Outside owner visible';end if;
 if exists(select 1 from public.crm_leads where email='scope-unowned@example.test') then raise exception 'Unowned lead visible';end if;
 begin perform public.set_sales_manager_lead_scope(auth.uid(),null);raise exception 'Scope mutation unexpectedly allowed';exception when others then if sqlerrm='Scope mutation unexpectedly allowed' then raise;end if;end;
 if has_function_privilege('anon','public.set_sales_manager_lead_scope(uuid,uuid)','EXECUTE') then raise exception 'Anonymous scope mutation permitted';end if;
end$$;
reset role;
rollback;
select 'Six authenticated scope assertions passed; fixtures rolled back' result;
