begin;
create table public.crm_boq_workstream_applications(
 id uuid primary key,offer_id uuid not null references public.crm_boq_offer_publications,board_id uuid not null references public.crm_boards,
 project_id uuid not null references public.projects,workstream_id uuid not null unique references public.crm_project_workstreams,
 request jsonb not null,source_snapshot jsonb not null,plan_snapshot jsonb not null,task_ids jsonb not null,milestone_ids jsonb not null,
 reason text not null,created_by uuid not null references public.profiles,created_at timestamptz not null default now(),unique(offer_id,board_id)
);
create index boq_workstream_application_project on public.crm_boq_workstream_applications(project_id);
create index boq_workstream_application_board on public.crm_boq_workstream_applications(board_id);
create index boq_workstream_application_actor on public.crm_boq_workstream_applications(created_by);
alter table public.crm_boq_workstream_applications enable row level security;
revoke all on public.crm_boq_workstream_applications from public,anon,authenticated;
grant select on public.crm_boq_workstream_applications to authenticated;
create policy boq_workstream_application_read on public.crm_boq_workstream_applications for select to authenticated using(portal_private.execution_manager(project_id));

create function portal_private.boq_workstream_plan(p_offer uuid,p_version integer,p_board uuid,p_template uuid,p_values jsonb,p_start date)
returns jsonb language plpgsql security definer set search_path='' as $$
declare pub public.crm_boq_offer_publications;o public.crm_boq_offers;s public.crm_sales;v public.crm_template_versions;plan jsonb;task jsonb;scheduled jsonb:='[]';cursor_date date;k text;
begin
 select * into pub from public.crm_boq_offer_publications where id=p_offer;
 if pub.id is null or not portal_private.execution_manager(pub.project_id) then raise exception 'Assigned project manager access required';end if;
 if pub.status is distinct from 'Accepted' or not pub.consent or pub.version is distinct from p_version then raise exception 'Exact client-approved offer required';end if;
 if not exists(select 1 from public.projects where id=pub.project_id and company_id=pub.company_id and status not in ('Completed','Cancelled')) or exists(select 1 from public.crm_handovers where project_id=pub.project_id and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Active project without released handover required';end if;
 select * into o from public.crm_boq_offers where id=pub.id;select * into s from public.crm_sales where id=o.sale_id;
 if s.project_id is distinct from pub.project_id or s.company_id is distinct from pub.company_id or s.currency is distinct from pub.currency then raise exception 'Original sale customer and currency must match';end if;
 if not exists(select 1 from jsonb_array_elements(o.data->'lines') l where l->>'board_id'=p_board::text) then raise exception 'Accepted new-product scope required';end if;
 if not exists(select 1 from public.crm_boards where id=p_board and active and outcome='Project') then raise exception 'Active project product required';end if;
 if exists(select 1 from public.crm_project_workstreams w join public.crm_product_lines l on l.id=w.product_line_id where w.project_id=pub.project_id and l.board_id=p_board) or exists(select 1 from public.crm_product_lines where deal_id=s.deal_id and board_id=p_board) then raise exception 'Existing product/workstream adoption requires a separate change';end if;
 select tv.* into v from public.crm_template_versions tv join public.crm_project_templates t on t.id=tv.template_id where tv.id=p_template and t.active and t.board_id=p_board and t.version=tv.revision;
 if v.id is null then raise exception 'Current active template for the accepted product required';end if;
 if p_start is null or p_start<(now() at time zone 'Asia/Karachi')::date-365 or p_start>(now() at time zone 'Asia/Karachi')::date+730 then raise exception 'Explicit bounded planning start date required';end if;
 if jsonb_typeof(p_values) is distinct from 'object' or (select count(*) from jsonb_object_keys(p_values))<>jsonb_array_length(v.parameters) then raise exception 'Enter every template parameter explicitly';end if;
 for k in select a->>'key' from jsonb_array_elements(v.parameters) a loop
  if coalesce(p_values->>k,'') !~ '^\d{1,6}(\.\d{1,6})?$' then raise exception 'Explicit bounded decimal template parameter required: %',k;end if;
 end loop;
 plan:=portal_private.build_project_plan(v.id,p_values);cursor_date:=p_start;
 for task in select value from jsonb_array_elements(plan->'tasks') loop
  scheduled:=scheduled||jsonb_build_array(task||jsonb_build_object('start_date',cursor_date,'deadline',cursor_date+greatest(0,ceil((task->>'duration_minutes')::numeric/480)::integer-1)));
  cursor_date:=cursor_date+greatest(1,ceil((task->>'duration_minutes')::numeric/480)::integer);
 end loop;
 return plan||jsonb_build_object('tasks',scheduled,'start_date',p_start,'offer_id',pub.id,'offer_version',pub.version,'board_id',p_board,'project_id',pub.project_id);
end$$;
revoke all on function portal_private.boq_workstream_plan(uuid,integer,uuid,uuid,jsonb,date) from public,anon,authenticated;
create function public.preview_boq_workstream(p_offer uuid,p_version integer,p_board uuid,p_template uuid,p_values jsonb,p_start date)
returns jsonb language sql security definer set search_path='' as $$select portal_private.boq_workstream_plan(p_offer,p_version,p_board,p_template,p_values,p_start)$$;

create function public.apply_boq_workstream(p_id uuid,p_offer uuid,p_version integer,p_board uuid,p_template uuid,p_values jsonb,p_start date,p_expected jsonb,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare pub public.crm_boq_offer_publications;o public.crm_boq_offers;s public.crm_sales;receipt public.crm_boq_workstream_applications;request jsonb;plan jsonb;line uuid;stream uuid;task jsonb;task_id uuid;task_ids jsonb:='{}';milestones jsonb:='{}';milestone uuid;phase integer;dependencies uuid[];key text;label text;product_value numeric;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator applies reviewed workstreams';end if;
 select * into pub from public.crm_boq_offer_publications where id=p_offer;
 perform 1 from public.projects where id=pub.project_id for update;
 select * into pub from public.crm_boq_offer_publications where id=p_offer for update;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 or jsonb_typeof(p_expected) is distinct from 'object' then raise exception 'Application ID, exact reviewed preview and reason required';end if;
 request:=jsonb_build_object('offer_id',p_offer,'offer_version',p_version,'board_id',p_board,'template_version',p_template,'parameters',p_values,'start_date',p_start,'expected',p_expected,'reason',trim(p_reason));
 select * into receipt from public.crm_boq_workstream_applications where id=p_id;
 if receipt.id is not null then
  if receipt.created_by=auth.uid() and receipt.request=request then return receipt.workstream_id;end if;raise exception 'Application ID already used with different inputs';
 end if;
 if exists(select 1 from public.crm_boq_workstream_applications where offer_id=p_offer and board_id=p_board) then raise exception 'Accepted product already applied; open its recorded workstream';end if;
 perform 1 from public.crm_boards where id=p_board for share;
 perform 1 from public.crm_project_templates t join public.crm_template_versions v on v.template_id=t.id where v.id=p_template for share of t,v;
 plan:=portal_private.boq_workstream_plan(p_offer,p_version,p_board,p_template,p_values,p_start);
 if plan is distinct from p_expected then raise exception 'Reviewed plan changed; calculate and review it again';end if;
 select * into o from public.crm_boq_offers where id=p_offer;select * into s from public.crm_sales where id=o.sale_id for update;
 select pub.items->((l.n-1)::integer)->>'product' into label from jsonb_array_elements(o.data->'lines') with ordinality l(item,n) where l.item->>'board_id'=p_board::text limit 1;
 select sum((pub.items->((l.n-1)::integer)->>'total')::numeric) into product_value from jsonb_array_elements(o.data->'lines') with ordinality l(item,n) where l.item->>'board_id'=p_board::text;
 insert into public.crm_product_lines(deal_id,board_id,estimated_value) values(s.deal_id,p_board,product_value) returning id into line;
 insert into public.crm_project_workstreams(sale_id,project_id,product_line_id,template_version_id,parameters,plan) values(s.id,pub.project_id,line,p_template,plan->'parameters',plan) returning id into stream;
 for phase in select distinct (t->>'phase')::integer from jsonb_array_elements(plan->'tasks') t loop
  insert into public.milestones(project_id,title) values(pub.project_id,pub.number||' · '||label||' · Phase '||phase) returning id into milestone;
  milestones:=milestones||jsonb_build_object(phase::text,milestone);
 end loop;
 for task in select value from jsonb_array_elements(plan->'tasks') loop
  dependencies:='{}';for key in select value from jsonb_array_elements_text(task->'depends_on') loop dependencies:=dependencies||(task_ids->>key)::uuid;end loop;
  insert into public.tasks(project_id,title,internal,start_date,deadline,milestone_id) values(pub.project_id,task->>'title',true,(task->>'start_date')::date,(task->>'deadline')::date,(milestones->>(task->>'phase'))::uuid) returning id into task_id;
  insert into public.crm_task_plans(task_id,workstream_id,task_key,phase,process,step,unit,quantity,duration_minutes,crew,crew_role,tools,preconditions,dependencies)
   values(task_id,stream,task->>'key',(task->>'phase')::integer,coalesce(task->>'process',''),coalesce(task->>'step',''),task->>'unit',(task->>'quantity')::numeric,(task->>'duration_minutes')::numeric,(task->>'crew')::integer,task->>'crew_role',coalesce(task->>'tools',''),coalesce(task->>'preconditions',''),dependencies);
  insert into public.task_items(task_id,title) select task_id,value from jsonb_array_elements_text(task->'checklist');task_ids:=task_ids||jsonb_build_object(task->>'key',task_id);
 end loop;
 update public.milestones m set deadline=(select max(t.deadline) from public.tasks t where t.milestone_id=m.id) where m.id in(select value::uuid from jsonb_each_text(milestones));
 insert into public.crm_boq_workstream_applications(id,offer_id,board_id,project_id,workstream_id,request,source_snapshot,plan_snapshot,task_ids,milestone_ids,reason,created_by)
  values(p_id,pub.id,p_board,pub.project_id,stream,request,to_jsonb(pub),plan,task_ids,milestones,trim(p_reason),auth.uid());
 insert into public.crm_boq_offer_history(offer_id,project_id,action,after_record,reason,actor_id) values(pub.id,pub.project_id,'New product workstream applied',jsonb_build_object('application_id',p_id,'workstream_id',stream,'board_id',p_board,'template_version',p_template,'plan',plan,'task_ids',task_ids),trim(p_reason),auth.uid());
 insert into public.crm_sales_activity(deal_id,kind,body,actor_id) values(s.deal_id,'Product line','Applied accepted change order '||pub.number||' · '||label,auth.uid());
 return stream;
end$$;
revoke all on function public.preview_boq_workstream(uuid,integer,uuid,uuid,jsonb,date),public.apply_boq_workstream(uuid,uuid,integer,uuid,uuid,jsonb,date,jsonb,text) from public,anon;
grant execute on function public.preview_boq_workstream(uuid,integer,uuid,uuid,jsonb,date),public.apply_boq_workstream(uuid,uuid,integer,uuid,uuid,jsonb,date,jsonb,text) to authenticated;
commit;
