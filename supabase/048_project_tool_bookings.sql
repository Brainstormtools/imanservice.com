begin;
create table public.crm_tool_bookings(id uuid primary key default gen_random_uuid(),project_id uuid not null references public.projects,task_id uuid not null references public.tasks,issue_id uuid not null references public.sc_issues,starts_at timestamptz not null,ends_at timestamptz not null,quantity integer not null check(quantity between 1 and 100000),status text not null check(status in ('Reserved','Cancelled')),version integer not null default 1,reason text not null check(length(trim(reason)) between 3 and 2000),created_by uuid not null references public.profiles,created_at timestamptz not null default now(),check(ends_at>starts_at and ends_at-starts_at<=interval '31 days'));
create index crm_tool_booking_project on public.crm_tool_bookings(project_id);
create index crm_tool_booking_task on public.crm_tool_bookings(task_id);
create index crm_tool_booking_issue on public.crm_tool_bookings(issue_id);
create index crm_tool_booking_author on public.crm_tool_bookings(created_by);
create table public.crm_tool_booking_history(id uuid primary key default gen_random_uuid(),booking_id uuid not null references public.crm_tool_bookings,project_id uuid not null references public.projects,revision integer not null,before_booking jsonb,after_booking jsonb not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(booking_id,revision));
create index crm_tool_booking_history_project on public.crm_tool_booking_history(project_id);
create index crm_tool_booking_history_actor on public.crm_tool_booking_history(actor_id);
alter table public.crm_tool_bookings enable row level security;
alter table public.crm_tool_booking_history enable row level security;
revoke all on public.crm_tool_bookings,public.crm_tool_booking_history from public,anon,authenticated;
grant select on public.crm_tool_bookings,public.crm_tool_booking_history to authenticated;
create policy tool_booking_read on public.crm_tool_bookings for select to authenticated using(portal_private.execution_manager(project_id));
create policy tool_booking_history_read on public.crm_tool_booking_history for select to authenticated using(portal_private.execution_manager(project_id));
create function portal_private.tool_booking_peak(p_issue uuid,p_exclude uuid,p_start timestamptz,p_end timestamptz,p_quantity integer) returns numeric language sql stable security definer set search_path='' as $$
with spans as (select greatest(starts_at,now()) s,ends_at e,quantity q from public.crm_tool_bookings where issue_id=p_issue and id is distinct from p_exclude and status='Reserved' and ends_at>now() union all select p_start,p_end,p_quantity where p_start is not null),events as(select s t,q delta from spans union all select e,-q from spans),grouped as(select t,sum(delta) delta from events group by t),running as(select sum(delta) over(order by t) n from grouped) select coalesce(max(n),0) from running;
$$;
revoke all on function portal_private.tool_booking_peak(uuid,uuid,timestamptz,timestamptz,integer) from public,anon,authenticated;
create function public.save_project_tool_booking(p_id uuid,p_version integer,p_project uuid,p_task uuid,p_issue uuid,p_start timestamptz,p_end timestamptz,p_quantity integer,p_status text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$declare old public.crm_tool_bookings;newrow public.crm_tool_bookings;capacity numeric;begin
if not portal_private.execution_manager(p_project) then raise exception 'Assigned project manager access required';end if;
perform 1 from public.projects where id=p_project for update;if not found then raise exception 'Project required';end if;
perform 1 from public.sc_issues where id=p_issue for update;
if p_id is null then raise exception 'Client booking ID required';end if;
select * into old from public.crm_tool_bookings where id=p_id for update;
if old.id is not null and p_version is null then
if old.created_by=auth.uid() and old.version=1 and old.project_id=p_project and old.task_id=p_task and old.issue_id=p_issue and old.starts_at=p_start and old.ends_at=p_end and old.quantity=p_quantity and old.status=p_status and old.reason=trim(p_reason) then return old.id;end if;raise exception 'Booking ID already used for different data';
elsif old.id is not null then
if old.version is distinct from p_version or old.project_id is distinct from p_project or old.task_id is distinct from p_task or old.issue_id is distinct from p_issue then raise exception 'Current booking with fixed work and issue required';end if;
else if p_version is not null or p_status is distinct from 'Reserved' then raise exception 'New booking must be Reserved without prior version';end if;end if;
if length(trim(coalesce(p_reason,''))) not between 3 and 2000 or p_status not in ('Reserved','Cancelled') or p_status is null or old.status='Cancelled' then raise exception 'Booking reason and active revision required';end if;
if p_status='Cancelled' then
update public.crm_tool_bookings set status='Cancelled',reason=trim(p_reason),version=version+1 where id=p_id returning * into newrow;
else
perform 1 from public.tasks t join public.crm_task_plans p on p.task_id=t.id join public.crm_project_workstreams s on s.id=p.workstream_id where t.id=p_task and t.project_id=p_project and s.project_id=p_project and t.status<>'Done' for update of t;
if not found or exists(select 1 from public.projects where id=p_project and status='Completed') or exists(select 1 from public.crm_handovers where project_id=p_project and status in ('Awaiting signatures','Signed','Closed')) or exists(select 1 from public.crm_phases f join public.crm_task_plans p on p.phase=f.phase where p.task_id=p_task and f.project_id=p_project and f.status<>'Draft') then raise exception 'Unreviewed active generated task required';end if;
select i.quantity-coalesce((select sum(r.quantity) from public.sc_returns r where r.issue_id=i.id),0) into capacity from public.sc_issues i join public.sc_request_lines l on l.id=i.line_id join public.crm_catalog c on c.id=l.item_id join public.sc_requests r on r.id=i.request_id where i.id=p_issue and r.project_id=p_project and i.status='Delivered' and c.tracking='Returnable';
if capacity is null or capacity<=0 then raise exception 'Delivered outstanding returnable issue required';end if;
if p_start is null or p_end is null or not isfinite(p_start) or not isfinite(p_end) or p_start<now() or p_end<=p_start or p_end-p_start>interval '31 days' or p_quantity is null or p_quantity not between 1 and 100000 then raise exception 'Future bounded interval and whole positive quantity required';end if;
if portal_private.tool_booking_peak(p_issue,p_id,p_start,p_end,p_quantity)>capacity then raise exception 'Overlapping bookings exceed outstanding delivered quantity';end if;
if old.id is null then insert into public.crm_tool_bookings(id,project_id,task_id,issue_id,starts_at,ends_at,quantity,status,reason,created_by) values(p_id,p_project,p_task,p_issue,p_start,p_end,p_quantity,p_status,trim(p_reason),auth.uid()) returning * into newrow;
else update public.crm_tool_bookings set starts_at=p_start,ends_at=p_end,quantity=p_quantity,reason=trim(p_reason),version=version+1 where id=p_id returning * into newrow;end if;
end if;
insert into public.crm_tool_booking_history(booking_id,project_id,revision,before_booking,after_booking,actor_id) values(newrow.id,p_project,newrow.version,case when old.id is not null then to_jsonb(old) end,to_jsonb(newrow),auth.uid());return newrow.id;
end$$;
create function portal_private.tool_booking_return_guard() returns trigger language plpgsql security definer set search_path='' as $$declare capacity numeric;begin
if new.issue_id is not null and exists(select 1 from public.sc_issues i join public.sc_request_lines l on l.id=i.line_id join public.crm_catalog c on c.id=l.item_id where i.id=new.issue_id and c.tracking='Returnable') then
perform 1 from public.sc_issues where id=new.issue_id for update;
select quantity-coalesce((select sum(quantity) from public.sc_returns where issue_id=new.issue_id),0)-new.quantity into capacity from public.sc_issues where id=new.issue_id;
if portal_private.tool_booking_peak(new.issue_id,null,null,null,null)>capacity then raise exception 'Cancel or reduce future tool bookings before return';end if;end if;return new;end$$;
revoke all on function portal_private.tool_booking_return_guard() from public,anon,authenticated;
create trigger tool_booking_return_guard before insert on public.sc_returns for each row execute function portal_private.tool_booking_return_guard();
create function public.project_tool_booking_resources(p_project uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$declare result jsonb;begin
if not exists(select 1 from public.projects where id=p_project) or not portal_private.execution_manager(p_project) then raise exception 'Assigned project manager access required';end if;
select coalesce(jsonb_agg(jsonb_build_object('id',i.id,'project_id',r.project_id,'number',i.number,'item_name',l.item_name,'unit',l.unit,'outstanding',i.quantity-coalesce((select sum(x.quantity) from public.sc_returns x where x.issue_id=i.id),0),'recipient_id',i.recipient_id,'return_due',i.return_due) order by i.number),'[]') into result from public.sc_issues i join public.sc_requests r on r.id=i.request_id join public.sc_request_lines l on l.id=i.line_id join public.crm_catalog c on c.id=l.item_id where r.project_id=p_project and i.status='Delivered' and c.tracking='Returnable' and i.quantity>coalesce((select sum(x.quantity) from public.sc_returns x where x.issue_id=i.id),0);return result;end$$;
revoke all on function public.save_project_tool_booking(uuid,integer,uuid,uuid,uuid,timestamptz,timestamptz,integer,text,text),public.project_tool_booking_resources(uuid) from public,anon;
grant execute on function public.save_project_tool_booking(uuid,integer,uuid,uuid,uuid,timestamptz,timestamptz,integer,text,text),public.project_tool_booking_resources(uuid) to authenticated;
commit;
