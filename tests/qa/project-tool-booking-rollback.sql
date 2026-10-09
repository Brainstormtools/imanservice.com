begin;
do $$
declare qa_admin uuid;qa_company uuid:=gen_random_uuid();qa_project uuid:=gen_random_uuid();qa_lead uuid:=gen_random_uuid();qa_deal uuid:=gen_random_uuid();qa_board uuid:=gen_random_uuid();qa_product uuid:=gen_random_uuid();qa_quote uuid:=gen_random_uuid();qa_publication uuid:=gen_random_uuid();qa_invoice uuid:=gen_random_uuid();qa_sale uuid:=gen_random_uuid();qa_template uuid:=gen_random_uuid();qa_template_version uuid:=gen_random_uuid();qa_stream uuid:=gen_random_uuid();qa_task uuid:=gen_random_uuid();qa_client uuid:=gen_random_uuid();qa_count int:=0;qa_item uuid:=gen_random_uuid();qa_location uuid:=gen_random_uuid();qa_batch uuid:=gen_random_uuid();qa_request uuid:=gen_random_uuid();qa_rows jsonb;qa_report jsonb;qa_issue uuid:=gen_random_uuid();qa_booking uuid:=gen_random_uuid();qa_line uuid;qa_other uuid:=gen_random_uuid();
begin
select id into qa_admin from public.profiles where active and role='admin' order by id limit 1;if qa_admin is null then raise exception 'Administrator required';end if;
perform set_config('request.jwt.claim.sub',qa_admin::text,true);perform set_config('request.jwt.claim.role','authenticated',true);
insert into public.companies(id,name) values(qa_company,'QA timed tool company');
insert into auth.users(id) values(qa_client);insert into public.profiles(id,name,role,company_id) values(qa_client,'QA timed tool client','client',qa_company);
insert into public.projects(id,company_id,title) values(qa_project,qa_company,'QA timed tool project');
insert into public.crm_leads(id,name,email,source) values(qa_lead,'QA timed tool',qa_lead::text||'@example.test','QA');
insert into public.crm_deals(id,lead_id,company_id,title,owner_id) values(qa_deal,qa_lead,qa_company,'QA adjustment deal',qa_admin);
insert into public.crm_boards(id,code,name,color,outcome) values(qa_board,'qa_'||replace(qa_board::text,'-',''),'QA adjustment board','#112233','Project');
insert into public.crm_product_lines(id,deal_id,board_id) values(qa_product,qa_deal,qa_board);
insert into public.crm_quotes(id,deal_id,number,title,valid_until) values(qa_quote,qa_deal,'QA-'||qa_quote::text,'QA adjustment quote',current_date);
insert into public.crm_quote_publications(id,quote_id,deal_id,company_id,number,revision,title,option_name,currency,valid_until,terms,company_name,items,subtotal,tax_total,total,wht_total,receivable) values(qa_publication,qa_quote,qa_deal,qa_company,'QA-'||qa_quote::text,1,'QA adjustment quote','QA option','PKR',current_date,'QA','QA company','[]',1,0,1,0,1);
insert into public.invoices(id,company_id,company_name,number,currency,total,author_id,due_on) values(qa_invoice,qa_company,'QA company','QA-'||qa_invoice::text,'PKR',1,qa_admin,current_date);
insert into public.crm_sales(id,deal_id,publication_id,company_id,project_id,invoice_id,owner_id,total,currency,payment_terms,planned_budget,created_by) values(qa_sale,qa_deal,qa_publication,qa_company,qa_project,qa_invoice,qa_admin,1,'PKR','{}','{}',qa_admin);
insert into public.crm_project_templates(id,board_id,name) values(qa_template,qa_board,'QA adjustment template');
insert into public.crm_template_versions(id,template_id,revision,parameters,tasks,author_id) values(qa_template_version,qa_template,1,'[]','[]',qa_admin);
insert into public.crm_project_workstreams(id,sale_id,project_id,product_line_id,template_version_id,parameters,plan) values(qa_stream,qa_sale,qa_project,qa_product,qa_template_version,'{}','{"qa_fixed_baseline":true}');
insert into public.tasks(id,project_id,title,assignee,internal,deadline) values(qa_task,qa_project,'QA adjustment task',qa_admin,true,current_date);
insert into public.crm_task_plans(task_id,workstream_id,task_key,phase,process,step,unit,quantity,duration_minutes,crew,crew_role,tools,preconditions) values(qa_task,qa_stream,'qa_adjustment',0,'Survey','Inspect','node',2,60,1,'Technician','Tester','Access');

insert into public.crm_catalog(id,name,unit,tracking) values(qa_item,'QA tool tester','each','Returnable');
insert into public.sc_locations(id,name,kind) values(qa_location,'QA timed tool store','Office');
insert into public.sc_stock_ledger(item_id,location_id,quantity,rate,document_id,kind,actor_id) values(qa_item,qa_location,5,10,gen_random_uuid(),'QA fixture',qa_admin);
qa_rows:=jsonb_build_array(jsonb_build_object('item_id',qa_item,'quantity',2));

-- Trusted synthetic Delivered fixture isolates booking/return guards; issue approvals are tested separately.
insert into public.sc_requests(id,project_id,task_id,purpose,site,required_by,status,created_by) values(qa_request,qa_project,qa_task,'QA timed tool fixture','QA site',current_date,'Closed',qa_admin);
insert into public.sc_request_lines(request_id,item_id,item_name,unit,quantity,issued,delivered) values(qa_request,qa_item,'QA tool tester','each',2,2,2) returning id into qa_line;
insert into public.sc_issues(id,request_id,line_id,location_id,quantity,rate,total,recipient_id,return_due,status,created_by) values(qa_issue,qa_request,qa_line,qa_location,2,10,20,qa_admin,current_date+30,'Delivered',qa_admin);
insert into public.sc_stock_ledger(item_id,location_id,quantity,rate,project_id,request_id,document_id,kind,actor_id) values(qa_item,qa_location,-2,10,qa_project,qa_request,qa_issue,'Issue',qa_admin);
execute 'set local role authenticated';
perform public.save_project_tool_booking(qa_booking,null,qa_project,qa_task,qa_issue,now()+interval '1 day',now()+interval '1 day 1 hour',2,'Reserved','QA reserve delivered tools');
if not exists(select 1 from public.crm_tool_bookings where id=qa_booking and quantity=2 and version=1) then raise exception 'Booking mismatch';end if;qa_count:=qa_count+1;
if public.save_project_tool_booking(qa_booking,null,qa_project,qa_task,qa_issue,now()+interval '1 day',now()+interval '1 day 1 hour',2,'Reserved','QA reserve delivered tools')<>qa_booking then raise exception 'Retry mismatch';end if;qa_count:=qa_count+1;
begin perform public.save_project_tool_booking(qa_other,null,qa_project,qa_task,qa_issue,now()+interval '1 day 30 minutes',now()+interval '1 day 2 hours',1,'Reserved','QA overbooking');raise exception 'Overlap allowed';exception when others then if sqlerrm is distinct from 'Overlapping bookings exceed outstanding delivered quantity' then raise;end if;end;qa_count:=qa_count+1;
begin perform public.return_supply_material(qa_issue,null,qa_location,1,'QA early tool return','{}');raise exception 'Booked capacity return allowed';exception when others then if sqlerrm is distinct from 'Cancel or reduce future tool bookings before return' then raise;end if;end;qa_count:=qa_count+1;
perform public.save_project_tool_booking(qa_booking,1,qa_project,qa_task,qa_issue,now()+interval '1 day',now()+interval '1 day 1 hour',2,'Cancelled','QA release for return');
if not exists(select 1 from public.crm_tool_booking_history where booking_id=qa_booking and revision=1 and after_booking->>'status'='Reserved') or not exists(select 1 from public.crm_tool_bookings where id=qa_booking and version=2 and status='Cancelled') then raise exception 'Cancellation history mismatch';end if;qa_count:=qa_count+1;
perform public.return_supply_material(qa_issue,null,qa_location,2,'QA full tool return','{}');
if jsonb_array_length(public.project_tool_booking_resources(qa_project))<>0 then raise exception 'Returned tool still offered';end if;qa_count:=qa_count+1;
begin update public.crm_tool_bookings set quantity=99 where id=qa_booking;raise exception 'Direct write allowed';exception when insufficient_privilege then null;end;qa_count:=qa_count+1;
perform set_config('request.jwt.claim.sub',qa_client::text,true);
if exists(select 1 from public.crm_tool_bookings) then raise exception 'Client booking visible';end if;qa_count:=qa_count+1;
begin perform public.project_tool_booking_resources(qa_project);raise exception 'Client directory allowed';exception when others then if sqlerrm is distinct from 'Assigned project manager access required' then raise;end if;end;qa_count:=qa_count+1;
execute 'reset role';if has_function_privilege('anon','public.project_tool_booking_resources(uuid)','EXECUTE') or has_function_privilege('authenticated','portal_private.tool_booking_peak(uuid,uuid,timestamptz,timestamptz,integer)','EXECUTE') then raise exception 'Unexpected helper exposure';end if;qa_count:=qa_count+1;
perform set_config('qa.booking_result',jsonb_build_object('passed',true,'assertions',qa_count,'fixtures_rollback',true)::text,true);
end$$;
select current_setting('qa.booking_result')::jsonb as qa_result;
rollback;
