begin;
create table public.crm_project_tool_requests(request_id uuid primary key references public.sc_requests,project_id uuid not null references public.projects,task_id uuid not null references public.tasks,plan_version integer not null,plan_snapshot jsonb not null,author_id uuid not null references public.profiles,batch_id uuid not null,source_hash text not null,created_at timestamptz not null default now(),unique(author_id,batch_id));
create index crm_tool_request_project on public.crm_project_tool_requests(project_id);
create index crm_tool_request_task on public.crm_project_tool_requests(task_id);
alter table public.crm_project_tool_requests enable row level security;
revoke all on public.crm_project_tool_requests from public,anon,authenticated;
grant select on public.crm_project_tool_requests to authenticated;
create policy project_tool_request_read on public.crm_project_tool_requests for select to authenticated using(portal_private.execution_manager(project_id));
create function public.request_project_task_tools(p_task uuid,p_plan_version integer,p_batch uuid,p_site text,p_required_by date,p_reason text,p_lines jsonb) returns uuid language plpgsql security definer set search_path='' as $$declare pid uuid;plan public.crm_task_plans;receipt public.crm_project_tool_requests;hash text;row jsonb;doc uuid;begin
select project_id into pid from public.tasks where id=p_task;
if pid is null or not portal_private.execution_manager(pid) then raise exception 'Assigned project manager access required';end if;
perform 1 from public.projects where id=pid for update;
perform 1 from public.tasks where id=p_task and project_id=pid for update;if not found then raise exception 'Generated project task required';end if;
if p_batch is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 or length(trim(coalesce(p_site,''))) not between 1 and 300 or p_required_by is null or jsonb_typeof(p_lines) is distinct from 'array' then raise exception 'Batch, site, required date, reason and tool lines required';end if;
if jsonb_array_length(p_lines) not between 1 and 50 or length(p_lines::text)>50000 then raise exception 'Use 1–50 bounded tool lines';end if;
perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(auth.uid()::text||p_batch::text,0));
hash:=md5(jsonb_build_array(p_task,p_plan_version,trim(p_site),p_required_by,trim(p_reason),p_lines)::text);
select * into receipt from public.crm_project_tool_requests where author_id=auth.uid() and batch_id=p_batch;
if found then if receipt.source_hash is distinct from hash then raise exception 'Tool request batch already used for different data';end if;return receipt.request_id;end if;
select p.* into plan from public.crm_task_plans p join public.crm_project_workstreams s on s.id=p.workstream_id where p.task_id=p_task and s.project_id=pid for update of p;
if plan.task_id is null or plan.version is distinct from p_plan_version then raise exception 'Current generated task plan required';end if;
if exists(select 1 from public.tasks where id=p_task and status='Done') or exists(select 1 from public.crm_phases where project_id=pid and phase=plan.phase and status<>'Draft') or exists(select 1 from public.crm_handovers where project_id=pid and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Reviewed or handover-locked task cannot request tools';end if;
for row in select value from jsonb_array_elements(p_lines) order by value->>'item_id' loop
if jsonb_typeof(row) is distinct from 'object' or row-'item_id'-'quantity'<>'{}'::jsonb or coalesce(row->>'quantity','') !~ '^[1-9][0-9]{0,5}$' or (row->>'quantity')::numeric>100000 then raise exception 'Select active returnable items and whole quantities 1–100000';end if;
perform 1 from public.crm_catalog where id=(row->>'item_id')::uuid and active and tracking='Returnable' for share;if not found then raise exception 'Active returnable catalogue item required';end if;
end loop;
doc:=public.create_supply_request(pid,p_task,trim(p_reason),trim(p_site),p_required_by,p_lines);
update public.sc_requests set source='Project tool plan' where id=doc;
insert into public.crm_project_tool_requests(request_id,project_id,task_id,plan_version,plan_snapshot,author_id,batch_id,source_hash) values(doc,pid,p_task,plan.version,to_jsonb(plan),auth.uid(),p_batch,hash);
return doc;end$$;
create function public.project_task_tool_requests(p_project uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$declare result jsonb;begin
if not exists(select 1 from public.projects where id=p_project) or not portal_private.execution_manager(p_project) then raise exception 'Assigned project manager access required';end if;
select coalesce(jsonb_agg(jsonb_build_object('request_id',r.id,'task_id',r.task_id,'title',t.title,'number',r.number,'status',r.status,'site',r.site,'required_by',r.required_by,'reason',r.purpose,'author_id',r.created_by,'created_at',r.created_at,'plan_version',b.plan_version,'plan_tools',b.plan_snapshot->>'tools','lines',coalesce((select jsonb_agg(jsonb_build_object('item_id',l.item_id,'item_name',l.item_name,'unit',l.unit,'quantity',l.quantity,'reserved',l.reserved,'issued',l.issued,'returned',l.returned,'outstanding_issued',greatest(l.issued-l.returned,0)) order by l.item_id) from public.sc_request_lines l where l.request_id=r.id),'[]'::jsonb)) order by r.created_at,r.id),'[]') into result from public.crm_project_tool_requests b join public.sc_requests r on r.id=b.request_id join public.tasks t on t.id=b.task_id where b.project_id=p_project and r.project_id=p_project and t.project_id=p_project;
return result;end$$;
revoke all on function public.request_project_task_tools(uuid,integer,uuid,text,date,text,jsonb),public.project_task_tool_requests(uuid) from public,anon;
grant execute on function public.request_project_task_tools(uuid,integer,uuid,text,date,text,jsonb),public.project_task_tool_requests(uuid) to authenticated;
commit;
