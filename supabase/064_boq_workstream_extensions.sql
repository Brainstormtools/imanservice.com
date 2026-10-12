begin;
create function public.boq_workstream_extension_context() returns table(id uuid,project_id uuid,board_id uuid,product_name text)
language sql stable security definer set search_path='' as $$
 select w.id,w.project_id,l.board_id,b.name from public.crm_project_workstreams w join public.crm_product_lines l on l.id=w.product_line_id join public.crm_boards b on b.id=l.board_id
 where auth.uid() is not null and portal_private.execution_manager(w.project_id)
$$;
revoke all on function public.boq_workstream_extension_context() from public,anon;
grant execute on function public.boq_workstream_extension_context() to authenticated;
create table public.crm_boq_workstream_extensions(
 id uuid primary key,offer_id uuid not null references public.crm_boq_offer_publications,board_id uuid not null references public.crm_boards,
 project_id uuid not null references public.projects,workstream_id uuid not null references public.crm_project_workstreams,
 baseline_snapshot jsonb not null,request jsonb not null,source_snapshot jsonb not null,plan_snapshot jsonb not null,task_ids jsonb not null,milestone_ids jsonb not null,
 reason text not null,created_by uuid not null references public.profiles,created_at timestamptz not null default now(),unique(offer_id,workstream_id)
);
create index boq_workstream_extension_stream on public.crm_boq_workstream_extensions(workstream_id);
create index boq_workstream_extension_project on public.crm_boq_workstream_extensions(project_id);
create index boq_workstream_extension_board on public.crm_boq_workstream_extensions(board_id);
create index boq_workstream_extension_actor on public.crm_boq_workstream_extensions(created_by);
alter table public.crm_boq_workstream_extensions enable row level security;
revoke all on public.crm_boq_workstream_extensions from public,anon,authenticated;
grant select on public.crm_boq_workstream_extensions to authenticated;
create policy boq_workstream_extension_read on public.crm_boq_workstream_extensions for select to authenticated using(portal_private.execution_manager(project_id));

create function portal_private.boq_workstream_extension_plan(p_offer uuid,p_version integer,p_stream uuid,p_template uuid,p_values jsonb,p_start date)
returns jsonb language plpgsql security definer set search_path='' as $$
declare pub public.crm_boq_offer_publications;o public.crm_boq_offers;s public.crm_sales;v public.crm_template_versions;plan jsonb;task jsonb;scheduled jsonb:='[]';cursor_date date;k text;w public.crm_project_workstreams;scope_board uuid;prefix text;
begin
 select * into pub from public.crm_boq_offer_publications where id=p_offer;
 if pub.id is null or not portal_private.execution_manager(pub.project_id) then raise exception 'Assigned project manager access required';end if;
 if pub.status is distinct from 'Accepted' or not pub.consent or pub.version is distinct from p_version then raise exception 'Exact client-approved offer required';end if;
 if not exists(select 1 from public.projects where id=pub.project_id and company_id=pub.company_id and status not in ('Completed','Cancelled')) or exists(select 1 from public.crm_handovers where project_id=pub.project_id and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Active project without released handover required';end if;
 select * into o from public.crm_boq_offers where id=pub.id;select * into s from public.crm_sales where id=o.sale_id;
 if s.project_id is distinct from pub.project_id or s.company_id is distinct from pub.company_id or s.currency is distinct from pub.currency then raise exception 'Original sale customer and currency must match';end if;
 select * into w from public.crm_project_workstreams where id=p_stream;
 if w.id is null or w.project_id is distinct from pub.project_id or w.sale_id is distinct from s.id or not exists(select 1 from jsonb_array_elements(o.data->'lines') l where l->>'workstream_id'=p_stream::text) then raise exception 'Accepted same-project existing workstream scope required';end if;
 select board_id into scope_board from public.crm_product_lines where id=w.product_line_id and deal_id=s.deal_id and status='Active';
 if scope_board is null or not exists(select 1 from public.crm_boards where id=scope_board and active and outcome='Project') then raise exception 'Active existing project product required; adoption is separate';end if;
 select tv.* into v from public.crm_template_versions tv join public.crm_project_templates t on t.id=tv.template_id where tv.id=p_template and t.active and t.board_id=scope_board and t.version=tv.revision;
 if v.id is null then raise exception 'Current active template for the accepted product required';end if;
 if p_start is null or p_start<(now() at time zone 'Asia/Karachi')::date-365 or p_start>(now() at time zone 'Asia/Karachi')::date+730 then raise exception 'Explicit bounded planning start date required';end if;
 if jsonb_typeof(p_values) is distinct from 'object' or (select count(*) from jsonb_object_keys(p_values))<>jsonb_array_length(v.parameters) then raise exception 'Enter every template parameter explicitly';end if;
 for k in select a->>'key' from jsonb_array_elements(v.parameters) a loop
  if coalesce(p_values->>k,'') !~ '^\d{1,6}(\.\d{1,6})?$' then raise exception 'Explicit bounded decimal template parameter required: %',k;end if;
 end loop;
 plan:=portal_private.build_project_plan(v.id,p_values);cursor_date:=p_start;prefix:='co_'||replace(pub.id::text,'-','')||'_';
 for task in select value from jsonb_array_elements(plan->'tasks') loop
  scheduled:=scheduled||jsonb_build_array(task||jsonb_build_object('source_task_key',task->>'key','key',prefix||(task->>'key'),'depends_on',(select coalesce(jsonb_agg(prefix||d),'[]') from jsonb_array_elements_text(task->'depends_on') d),'start_date',cursor_date,'deadline',cursor_date+greatest(0,ceil((task->>'duration_minutes')::numeric/480)::integer-1)));
  cursor_date:=cursor_date+greatest(1,ceil((task->>'duration_minutes')::numeric/480)::integer);
 end loop;
 return plan||jsonb_build_object('tasks',scheduled,'start_date',p_start,'offer_id',pub.id,'offer_version',pub.version,'workstream_id',p_stream,'board_id',scope_board,'project_id',pub.project_id);
end$$;
revoke all on function portal_private.boq_workstream_extension_plan(uuid,integer,uuid,uuid,jsonb,date) from public,anon,authenticated;
create function public.preview_boq_workstream_extension(p_offer uuid,p_version integer,p_stream uuid,p_template uuid,p_values jsonb,p_start date)
returns jsonb language sql security definer set search_path='' as $$select portal_private.boq_workstream_extension_plan(p_offer,p_version,p_stream,p_template,p_values,p_start)$$;

create function public.apply_boq_workstream_extension(p_id uuid,p_offer uuid,p_version integer,p_stream uuid,p_template uuid,p_values jsonb,p_start date,p_expected jsonb,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare pub public.crm_boq_offer_publications;o public.crm_boq_offers;s public.crm_sales;receipt public.crm_boq_workstream_extensions;request jsonb;plan jsonb;stream uuid;task jsonb;task_id uuid;task_ids jsonb:='{}';milestones jsonb:='{}';milestone uuid;phase integer;dependencies uuid[];key text;label text;w public.crm_project_workstreams;scope_board uuid;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator applies reviewed workstreams';end if;
 select * into pub from public.crm_boq_offer_publications where id=p_offer;
 perform 1 from public.projects where id=pub.project_id for update;
 select * into pub from public.crm_boq_offer_publications where id=p_offer for update;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 or jsonb_typeof(p_expected) is distinct from 'object' then raise exception 'Application ID, exact reviewed preview and reason required';end if;
 request:=jsonb_build_object('offer_id',p_offer,'offer_version',p_version,'workstream_id',p_stream,'template_version',p_template,'parameters',p_values,'start_date',p_start,'expected',p_expected,'reason',trim(p_reason));
 select * into receipt from public.crm_boq_workstream_extensions where id=p_id;
 if receipt.id is not null then
  if receipt.created_by=auth.uid() and receipt.request=request then return receipt.workstream_id;end if;raise exception 'Application ID already used with different inputs';
 end if;
 if exists(select 1 from public.crm_boq_workstream_extensions where offer_id=p_offer and workstream_id=p_stream) then raise exception 'Accepted product already applied; open its recorded workstream';end if;
 select * into w from public.crm_project_workstreams where id=p_stream for update;
 select board_id into scope_board from public.crm_product_lines where id=w.product_line_id;
 perform 1 from public.crm_boards where id=scope_board for share;
 perform 1 from public.crm_project_templates t join public.crm_template_versions v on v.template_id=t.id where v.id=p_template for share of t,v;
 plan:=portal_private.boq_workstream_extension_plan(p_offer,p_version,p_stream,p_template,p_values,p_start);
 if plan is distinct from p_expected then raise exception 'Reviewed plan changed; calculate and review it again';end if;
 select * into o from public.crm_boq_offers where id=p_offer;select * into s from public.crm_sales where id=o.sale_id for update;
 select pub.items->((l.n-1)::integer)->>'product' into label from jsonb_array_elements(o.data->'lines') with ordinality l(item,n) where l.item->>'workstream_id'=p_stream::text limit 1;
 stream:=p_stream;
 if exists(select 1 from public.crm_task_plans p where p.workstream_id=stream and p.task_key in(select t->>'key' from jsonb_array_elements(plan->'tasks') t)) then raise exception 'Extension task namespace already used';end if;
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
 insert into public.crm_boq_workstream_extensions(id,offer_id,board_id,project_id,workstream_id,baseline_snapshot,request,source_snapshot,plan_snapshot,task_ids,milestone_ids,reason,created_by)
  values(p_id,pub.id,scope_board,pub.project_id,stream,to_jsonb(w),request,to_jsonb(pub),plan,task_ids,milestones,trim(p_reason),auth.uid());
 insert into public.crm_boq_offer_history(offer_id,project_id,action,after_record,reason,actor_id) values(pub.id,pub.project_id,'Existing workstream additional tasks applied',jsonb_build_object('application_id',p_id,'workstream_id',stream,'board_id',scope_board,'template_version',p_template,'plan',plan,'task_ids',task_ids),trim(p_reason),auth.uid());
 insert into public.crm_sales_activity(deal_id,kind,body,actor_id) values(s.deal_id,'Product line','Extended workstream from accepted change order '||pub.number||' · '||label,auth.uid());
 return stream;
end$$;
revoke all on function public.preview_boq_workstream_extension(uuid,integer,uuid,uuid,jsonb,date),public.apply_boq_workstream_extension(uuid,uuid,integer,uuid,uuid,jsonb,date,jsonb,text) from public,anon;
grant execute on function public.preview_boq_workstream_extension(uuid,integer,uuid,uuid,jsonb,date),public.apply_boq_workstream_extension(uuid,uuid,integer,uuid,uuid,jsonb,date,jsonb,text) to authenticated;
commit;
