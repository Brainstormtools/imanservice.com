-- Synthetic configuration only. Call inside a local test database or an explicit rollback transaction.
create temporary table qa_boq_context as select gen_random_uuid() a,gen_random_uuid() m,gen_random_uuid() client,gen_random_uuid() outsider,gen_random_uuid() worker,gen_random_uuid() company,gen_random_uuid() other_company,gen_random_uuid() project,gen_random_uuid() lead,gen_random_uuid() deal,gen_random_uuid() board,gen_random_uuid() product,gen_random_uuid() quote,gen_random_uuid() baseline,gen_random_uuid() invoice,gen_random_uuid() sale,gen_random_uuid() template,gen_random_uuid() template_version,gen_random_uuid() stream,gen_random_uuid() team,gen_random_uuid() change;
grant select on qa_boq_context to authenticated;
insert into auth.users(id) select a from qa_boq_context union all select m from qa_boq_context union all select client from qa_boq_context union all select outsider from qa_boq_context union all select worker from qa_boq_context;
insert into public.companies(id,name) select company,'QA BOQ offer rollback company' from qa_boq_context union all select other_company,'QA BOQ offer outside company' from qa_boq_context;
insert into public.profiles(id,name,role,company_id) select a,'QA BOQ offer administrator','admin',null::uuid from qa_boq_context union all select m,'QA BOQ offer manager','team',null::uuid from qa_boq_context union all select client,'QA BOQ offer client','client',company from qa_boq_context union all select outsider,'QA BOQ offer outside client','client',other_company from qa_boq_context union all select worker,'QA BOQ offer unassigned worker','team',null::uuid from qa_boq_context;
select set_config('request.jwt.claim.sub',(select a::text from qa_boq_context),true);
insert into public.projects(id,company_id,title) select project,company,'QA BOQ offer rollback project' from qa_boq_context;
insert into public.crm_teams(id,name) select team,'QA BOQ offer rollback team' from qa_boq_context;
insert into public.crm_memberships(user_id,role_id,team_id) select m,'project_manager',team from qa_boq_context;
insert into public.project_assignments(project_id,technician_id) select project,m from qa_boq_context;
insert into public.crm_boards(id,code,name,color,outcome,active) select board,'qa_boq_'||substr(board::text,1,8),'QA BOQ product','#123456','Project',false from qa_boq_context;
insert into public.crm_leads(id,name,email,source) select lead,'QA BOQ offer lead',lead::text||'@example.test','QA' from qa_boq_context;
insert into public.crm_deals(id,lead_id,company_id,title,owner_id) select deal,lead,company,'QA BOQ offer deal',a from qa_boq_context;
insert into public.crm_product_lines(id,deal_id,board_id) select product,deal,board from qa_boq_context;
insert into public.crm_quotes(id,deal_id,title,valid_until) select quote,deal,'QA original quotation',current_date+10 from qa_boq_context;
insert into public.crm_quote_publications(id,quote_id,deal_id,company_id,number,revision,title,option_name,currency,valid_until,terms,company_name,items,subtotal,tax_total,total,wht_total,receivable,status)
 select baseline,quote,deal,company,'QA-BASE-'||substr(quote::text,1,8),1,'QA original quotation','QA only','PKR',current_date+10,'QA original terms','QA BOQ offer rollback company','[]',1000,0,1000,0,1000,'Accepted' from qa_boq_context;
insert into public.invoices(id,company_id,due_on,company_name,author_id) select invoice,company,current_date+10,'QA BOQ offer rollback company',a from qa_boq_context;
insert into public.crm_sales(id,deal_id,publication_id,company_id,project_id,invoice_id,owner_id,total,currency,payment_terms,planned_budget,created_by)
 select sale,deal,baseline,company,project,invoice,a,1000,'PKR','{"kind":"Full"}','{"private_cost":600}',a from qa_boq_context;
insert into public.crm_project_templates(id,board_id,name,active) select template,board,'QA inactive BOQ fixture',false from qa_boq_context;
insert into public.crm_template_versions(id,template_id,revision,parameters,tasks,author_id) select template_version,template,1,'[]','[]',a from qa_boq_context;
insert into public.crm_project_workstreams(id,sale_id,project_id,product_line_id,template_version_id,parameters,plan) select stream,sale,project,product,template_version,'{}','{}' from qa_boq_context;
insert into public.crm_project_changes(id,project_id,details,version,reason,created_by,submitted_by)
 select change,project,'{"title":"QA approved additional scope","proposed_scope":"QA additional item","justification":"QA need","cost_impact":"QA impact","schedule_impact":"QA time","evidence":"QA PRIVATE internal evidence","status":"Approved","decision_note":"QA internal decision"}',3,'QA approved fixture',m,m from qa_boq_context;
