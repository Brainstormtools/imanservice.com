begin;
do $$
declare admin_id uuid; accounts_id uuid:=gen_random_uuid(); tech_id uuid:=gen_random_uuid(); client_id uuid:=gen_random_uuid(); team_id uuid:=gen_random_uuid(); customer_a uuid:=gen_random_uuid(); customer_b uuid:=gen_random_uuid(); vendor_id uuid:=gen_random_uuid(); invoice_a uuid:=gen_random_uuid(); invoice_b uuid:=gen_random_uuid(); invoice_c uuid:=gen_random_uuid(); expense_linked uuid:=gen_random_uuid(); expense_name uuid:=gen_random_uuid(); report jsonb; item jsonb; count_ok int:=0; before_hash text; after_hash text;
begin
 select id into admin_id from public.profiles where active and role='admin' order by id limit 1;
 if admin_id is null then raise exception 'Active administrator required for rollback QA';end if;
 perform set_config('request.jwt.claim.sub',admin_id::text,true);perform set_config('request.jwt.claim.role','authenticated',true);
 execute 'set local role authenticated'; report:=public.finance_trade_report();
 before_hash:=md5(jsonb_build_array(report->'summary',report->'aging',report->'upcoming')::text);
 if report->>'counterparty_identity_version' is distinct from '1' then raise exception 'Missing identity version';end if;count_ok:=count_ok+1;
 execute 'reset role';
 insert into public.companies(id,name) values(customer_a,'QA identity shared account'),(customer_b,'QA identity shared account');
 insert into auth.users(id) values(accounts_id),(tech_id),(client_id);
 insert into public.profiles(id,name,role,company_id) values(accounts_id,'QA identity Accounts','team',null),(tech_id,'QA identity technician','team',null),(client_id,'QA identity client','client',customer_a);
 insert into public.crm_teams(id,name) values(team_id,'QA identity team '||team_id::text);
 insert into public.crm_memberships(user_id,role_id,team_id) values(accounts_id,'accounts',team_id);
 insert into public.sc_vendors(id,name,status,created_by) values(vendor_id,'QA identity vendor '||vendor_id::text,'Approved',admin_id);
 insert into public.invoices(id,company_id,company_name,number,currency,status,issued_on,due_on,total,author_id) values
 (invoice_a,customer_a,'QA old invoice name','QA-ID-'||invoice_a::text,'PKR','Issued',current_date,current_date,10,admin_id),
 (invoice_b,customer_a,'QA new invoice name','QA-ID-'||invoice_b::text,'PKR','Issued',current_date,current_date,20,admin_id),
 (invoice_c,customer_b,'QA old invoice name','QA-ID-'||invoice_c::text,'PKR','Issued',current_date,current_date,30,admin_id);
 insert into public.fin_expenses(id,payee,vendor_id,voucher,category,description,incurred_on,due_on,amount,evidence,status,created_by,approved_by) values
 (expense_linked,'QA historical vendor payee',vendor_id,'QA-ID-'||expense_linked::text,'Other','QA identity linked expense',current_date,current_date,7,'QA rollback receipt','Approved',accounts_id,admin_id),
 (expense_name,'QA identity vendor '||vendor_id::text,null,'QA-ID-'||expense_name::text,'Other','QA identity unlinked expense',current_date,current_date,3,'QA rollback receipt','Approved',accounts_id,admin_id);
 perform set_config('request.jwt.claim.sub',accounts_id::text,true);execute 'set local role authenticated';report:=public.finance_trade_report();
 select d into item from jsonb_array_elements(report->'documents') d where d->>'id'=invoice_a::text;
 if item->>'counterparty_id' is distinct from customer_a::text or item->>'counterparty_type' is distinct from 'Customer' or item->>'account_name' is distinct from 'QA identity shared account' or item->>'counterparty' is distinct from 'QA old invoice name' then raise exception 'Customer identity/snapshot mismatch';end if;count_ok:=count_ok+1;
 select d into item from jsonb_array_elements(report->'documents') d where d->>'id'=invoice_b::text;
 if item->>'counterparty_id' is distinct from customer_a::text then raise exception 'Renamed invoice split identity';end if;count_ok:=count_ok+1;
 select d into item from jsonb_array_elements(report->'documents') d where d->>'id'=invoice_c::text;
 if item->>'counterparty_id' is distinct from customer_b::text then raise exception 'Shared name merged account identities';end if;count_ok:=count_ok+1;
 if (select sum((d->>'balance')::numeric) from jsonb_array_elements(report->'documents') d where d->>'counterparty_id'=customer_a::text) is distinct from 30 then raise exception 'Customer account amount mismatch';end if;count_ok:=count_ok+1;
 select d into item from jsonb_array_elements(report->'documents') d where d->>'id'=expense_linked::text;
 if item->>'counterparty_id' is distinct from vendor_id::text or item->>'counterparty_type' is distinct from 'Vendor' or item->>'counterparty' is distinct from 'QA historical vendor payee' then raise exception 'Explicit vendor identity missing';end if;count_ok:=count_ok+1;
 select d into item from jsonb_array_elements(report->'documents') d where d->>'id'=expense_name::text;
 if item->>'counterparty_id' is not null or item->>'counterparty_type' is distinct from 'Recorded name' then raise exception 'Unlinked payee identity inferred';end if;count_ok:=count_ok+1;
 if exists(select 1 from jsonb_array_elements(report->'documents') d where d ? 'evidence' or d ? 'contact' or d ? 'loan_id') then raise exception 'Private fields exposed';end if;count_ok:=count_ok+1;
 perform set_config('request.jwt.claim.sub',client_id::text,true);
 begin perform public.finance_trade_report();raise exception 'Client unexpectedly authorized';exception when others then if sqlerrm is distinct from 'Accounts access required' then raise;end if;end;count_ok:=count_ok+1;
 perform set_config('request.jwt.claim.sub',tech_id::text,true);
 begin perform public.finance_trade_report();raise exception 'Technician unexpectedly authorized';exception when others then if sqlerrm is distinct from 'Accounts access required' then raise;end if;end;count_ok:=count_ok+1;
 execute 'reset role';update public.profiles set active=false where id=accounts_id;
 perform set_config('request.jwt.claim.sub',accounts_id::text,true);execute 'set local role authenticated';
 begin perform public.finance_trade_report();raise exception 'Inactive Accounts unexpectedly authorized';exception when others then if sqlerrm is distinct from 'Accounts access required' then raise;end if;end;count_ok:=count_ok+1;
 execute 'reset role';update public.profiles set active=true where id=accounts_id;delete from public.crm_memberships where user_id=accounts_id;execute 'set local role authenticated';
 begin perform public.finance_trade_report();raise exception 'Revoked Accounts unexpectedly authorized';exception when others then if sqlerrm is distinct from 'Accounts access required' then raise;end if;end;count_ok:=count_ok+1;
 execute 'reset role';
 if has_function_privilege('anon','public.finance_trade_report()','EXECUTE') then raise exception 'Anonymous execution allowed';end if;count_ok:=count_ok+1;
 perform set_config('qa.identity_result',jsonb_build_object('passed',true,'assertions',count_ok,'fixtures_rollback',true,'production_amounts_before_fixtures_hash',before_hash)::text,true);
end$$;
select current_setting('qa.identity_result')::jsonb as qa_result;
rollback;
