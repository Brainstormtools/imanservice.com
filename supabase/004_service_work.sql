-- Apply once after 003_business.sql. Service evidence and escalation workflow.
begin;
create table public.work_logs (
 id uuid primary key, project_id uuid not null references public.projects, ticket_id uuid references public.tickets,
 task_id uuid references public.tasks, technician_id uuid not null references public.profiles,
 worked_on date not null, minutes integer not null check(minutes between 1 and 1440),
 work_type text not null check(work_type in ('Remote','On site','Other')), summary text not null check(length(trim(summary)) between 3 and 5000),
 parts text not null default '' check(length(parts)<=2000), internal boolean not null default false,
 created_at timestamptz not null default now(), voided_at timestamptz, voided_by uuid references public.profiles, void_reason text,
 check(ticket_id is not null or task_id is not null)
);
create table public.service_signoffs (
 id uuid primary key default gen_random_uuid(),ticket_id uuid not null references public.tickets,project_id uuid not null references public.projects,
 revision integer not null, summary text not null check(length(trim(summary)) between 3 and 5000), work_snapshot jsonb not null,
 status text not null default 'Pending' check(status in ('Pending','Accepted','Changes requested','Superseded')),
 requested_by uuid not null references public.profiles, requested_at timestamptz not null default now(),
 decided_by uuid references public.profiles, decided_at timestamptz, feedback text not null default '' check(length(feedback)<=5000),
 unique(ticket_id,revision)
);
create unique index one_pending_signoff on public.service_signoffs(ticket_id) where status='Pending';
create table public.escalation_routes(project_id uuid primary key references public.projects,supervisor_id uuid not null references public.profiles,updated_by uuid not null references public.profiles,updated_at timestamptz not null default now());
create table public.sla_escalations (
 id uuid primary key default gen_random_uuid(),ticket_id uuid not null references public.tickets,project_id uuid not null references public.projects,
 metric text not null check(metric in ('Response','Resolution')),due_at timestamptz not null,
 supervisor_id uuid references public.profiles,created_at timestamptz not null default now(),
 acknowledged_by uuid references public.profiles,acknowledged_at timestamptz,acknowledgement text,
 cleared_at timestamptz,unique(ticket_id,metric,due_at)
);
alter table public.work_logs enable row level security;
alter table public.service_signoffs enable row level security;
alter table public.escalation_routes enable row level security;
alter table public.sla_escalations enable row level security;
create policy log_read on public.work_logs for select to authenticated using(public.can_project(project_id) and (public.is_staff() or (not internal and (task_id is null or exists(select 1 from public.tasks t where t.id=task_id and not t.internal)))));
create policy signoff_read on public.service_signoffs for select to authenticated using(public.can_project(project_id));
create policy route_read on public.escalation_routes for select to authenticated using(public.is_staff());
create policy escalation_read on public.sla_escalations for select to authenticated using(public.is_staff());
revoke all on public.work_logs,public.service_signoffs,public.escalation_routes,public.sla_escalations from public,anon,authenticated;
grant select on public.work_logs,public.service_signoffs,public.escalation_routes,public.sla_escalations to authenticated;

create function public.record_work(p_id uuid,p_project uuid,p_ticket uuid,p_task uuid,p_date date,p_minutes integer,p_type text,p_summary text,p_parts text,p_internal boolean) returns uuid language plpgsql security definer set search_path='' as $$
declare old_log public.work_logs;
begin
 if not public.is_staff() then raise exception 'Staff access required'; end if;
 if p_id is null or p_date is null or p_date>(now() at time zone 'UTC')::date then raise exception 'Use a valid work date no later than today UTC'; end if;
 perform pg_advisory_xact_lock(hashtext(p_id::text));
 select * into old_log from public.work_logs where id=p_id;
 if found then
  if old_log.technician_id=auth.uid() and old_log.project_id=p_project and old_log.ticket_id is not distinct from p_ticket and old_log.task_id is not distinct from p_task and old_log.worked_on=p_date and old_log.minutes=p_minutes and old_log.work_type=p_type and old_log.summary=trim(p_summary) and old_log.parts=p_parts and old_log.internal=p_internal then return p_id; end if;
  raise exception 'Work entry ID already used';
 end if;
 if p_ticket is not null and not exists(select 1 from public.tickets where id=p_ticket and project_id=p_project) then raise exception 'Ticket must belong to this project'; end if;
 if p_task is not null and not exists(select 1 from public.tasks where id=p_task and project_id=p_project and (p_ticket is null or ticket_id is null or ticket_id=p_ticket) and (p_internal or not internal)) then raise exception 'Task must match this project and ticket; internal tasks require internal logs'; end if;
 insert into public.work_logs(id,project_id,ticket_id,task_id,technician_id,worked_on,minutes,work_type,summary,parts,internal) values(p_id,p_project,p_ticket,p_task,auth.uid(),p_date,p_minutes,p_type,trim(p_summary),p_parts,p_internal);
 return p_id;
end $$;
create function public.void_work(p_id uuid,p_reason text) returns void language plpgsql security definer set search_path='' as $$
begin
 if not public.is_staff() or length(trim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'Staff access and a reason of 3 to 1000 characters required'; end if;
 update public.work_logs set voided_at=now(),voided_by=auth.uid(),void_reason=trim(p_reason) where id=p_id and voided_at is null and (technician_id=auth.uid() or public.is_admin());
 if not found then raise exception 'Only the author or administrator can void an active entry'; end if;
end $$;
create function public.request_service_signoff(p_ticket uuid,p_summary text) returns uuid language plpgsql security definer set search_path='' as $$
declare t public.tickets; sid uuid; evidence jsonb;
begin
 if not public.is_staff() then raise exception 'Staff access required'; end if;
 select * into t from public.tickets where id=p_ticket for update;
 if not found or t.status<>'Resolved' then raise exception 'Resolve the ticket before requesting sign-off'; end if;
 if exists(select 1 from public.service_signoffs where ticket_id=t.id and status='Pending') then raise exception 'A decision is already pending'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('date',l.worked_on,'minutes',l.minutes,'type',l.work_type,'summary',l.summary,'parts',l.parts,'technician',p.name) order by l.created_at),'[]'::jsonb) into evidence from public.work_logs l join public.profiles p on p.id=l.technician_id where l.ticket_id=t.id and not l.internal and l.voided_at is null and (l.task_id is null or exists(select 1 from public.tasks k where k.id=l.task_id and not k.internal));
 insert into public.service_signoffs(ticket_id,project_id,revision,summary,work_snapshot,requested_by) values(t.id,t.project_id,coalesce((select max(revision) from public.service_signoffs where ticket_id=t.id),0)+1,trim(p_summary),evidence,auth.uid()) returning id into sid;
 perform public.queue_alert('signoff:'||sid,'Service review requested',(select company_id from public.projects where id=t.project_id),false);
 return sid;
end $$;
create function public.decide_service_signoff(p_id uuid,p_decision text,p_feedback text) returns void language plpgsql security definer set search_path='' as $$
declare s public.service_signoffs;t public.tickets;
begin
 select * into s from public.service_signoffs where id=p_id;
 if not found or not exists(select 1 from public.profiles u join public.projects p on p.company_id=u.company_id where u.id=auth.uid() and u.active and u.role='client' and p.id=s.project_id) then raise exception 'Only a client of this company can decide'; end if;
 select * into t from public.tickets where id=s.ticket_id for update;
 select * into s from public.service_signoffs where id=p_id for update;
 if s.status<>'Pending' or t.status<>'Resolved' then raise exception 'This request is no longer awaiting a decision'; end if;
 if p_decision not in ('Accepted','Changes requested') or p_decision is null then raise exception 'Choose an acceptance or corrections decision'; end if;
 if p_decision='Changes requested' and length(trim(coalesce(p_feedback,'')))<3 then raise exception 'Describe the changes required'; end if;
 update public.service_signoffs set status=p_decision,feedback=coalesce(p_feedback,''),decided_by=auth.uid(),decided_at=now() where id=s.id;
 if p_decision='Changes requested' then update public.tickets set status='In progress' where id=t.id; end if;
 perform public.queue_alert('signoff-decision:'||s.id,'Service review received',(select company_id from public.projects where id=s.project_id),true);
end $$;
create function public.supersede_signoff() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if old.status='Resolved' and new.status<>'Resolved' then update public.service_signoffs set status='Superseded',decided_at=now(),feedback='Ticket reopened before client decision' where ticket_id=new.id and status='Pending'; end if;
 return new;
end $$;
create trigger service_reopened after update on public.tickets for each row execute function public.supersede_signoff();
create function public.set_escalation_route(p_project uuid,p_supervisor uuid) returns void language plpgsql security definer set search_path='' as $$
begin
 if not public.is_admin() then raise exception 'Administrator access required'; end if;
 if p_supervisor is null then delete from public.escalation_routes where project_id=p_project; return; end if;
 if not exists(select 1 from public.profiles where id=p_supervisor and active and role in ('admin','team')) then raise exception 'Choose active staff'; end if;
 insert into public.escalation_routes(project_id,supervisor_id,updated_by) values(p_project,p_supervisor,auth.uid()) on conflict(project_id) do update set supervisor_id=excluded.supervisor_id,updated_by=excluded.updated_by,updated_at=now();
end $$;
create function public.scan_sla_escalations() returns integer language plpgsql security definer set search_path='' as $$
declare breach record; eid uuid; n integer:=0;
begin
 if not public.is_admin() and coalesce(auth.role(),'')<>'service_role' and not(auth.uid() is null and session_user='postgres') then raise exception 'Administrator or scheduler access required'; end if;
 -- Ticket locks serialize scan and resolution/reopening without locking unrelated projects.
 for breach in select v.id,v.project_id,p.company_id,v.response_due_at,v.resolution_due_at,v.first_response_at,v.status,case when u.active and u.role in ('admin','team') then u.id end supervisor from public.tickets v join public.projects p on p.id=v.project_id left join public.escalation_routes r on r.project_id=v.project_id left join public.profiles u on u.id=r.supervisor_id where v.status<>'Resolved' and ((v.first_response_at is null and v.response_due_at<now()) or v.resolution_due_at<now()) order by v.created_at for update of v skip locked loop
  if breach.first_response_at is null and breach.response_due_at<now() then
   insert into public.sla_escalations(ticket_id,project_id,metric,due_at,supervisor_id) values(breach.id,breach.project_id,'Response',breach.response_due_at,breach.supervisor) on conflict do nothing returning id into eid;
   if eid is not null then n:=n+1;perform public.queue_alert('escalation:'||eid,'SLA response escalated',breach.company_id,true,breach.supervisor,breach.supervisor is null); end if;
  end if;
  if breach.resolution_due_at<now() then
   insert into public.sla_escalations(ticket_id,project_id,metric,due_at,supervisor_id) values(breach.id,breach.project_id,'Resolution',breach.resolution_due_at,breach.supervisor) on conflict do nothing returning id into eid;
   if eid is not null then n:=n+1;perform public.queue_alert('escalation:'||eid,'SLA resolution escalated',breach.company_id,true,breach.supervisor,breach.supervisor is null); end if;
  end if;
 end loop;
 update public.sla_escalations e set cleared_at=case when t.status='Resolved' or (e.metric='Response' and t.first_response_at is not null) then coalesce(e.cleared_at,now()) else null end from public.tickets t where t.id=e.ticket_id;
 return n;
end $$;
create function public.acknowledge_escalation(p_id uuid,p_note text) returns void language plpgsql security definer set search_path='' as $$
begin
 if not public.is_staff() or length(trim(coalesce(p_note,''))) not between 3 and 2000 then raise exception 'Staff access and an action note required'; end if;
 update public.sla_escalations set acknowledged_by=auth.uid(),acknowledged_at=now(),acknowledgement=trim(p_note) where id=p_id and acknowledged_at is null and cleared_at is null and (public.is_admin() or supervisor_id=auth.uid());
 if not found then raise exception 'Only the assigned supervisor or administrator can acknowledge an open escalation'; end if;
end $$;
-- Existing once-per-minute job and Vercel worker now include escalation scanning.
alter function public.queue_due_alerts() rename to queue_business_due_alerts;
create function public.queue_due_alerts() returns integer language plpgsql security definer set search_path='' as $$
declare n integer;
begin
 n:=public.queue_business_due_alerts();return n+public.scan_sla_escalations();
end $$;
revoke all on function public.record_work(uuid,uuid,uuid,uuid,date,integer,text,text,text,boolean),public.void_work(uuid,text),public.request_service_signoff(uuid,text),public.decide_service_signoff(uuid,text,text),public.supersede_signoff(),public.set_escalation_route(uuid,uuid),public.scan_sla_escalations(),public.acknowledge_escalation(uuid,text),public.queue_due_alerts(),public.queue_business_due_alerts() from public,anon,authenticated;
grant execute on function public.record_work(uuid,uuid,uuid,uuid,date,integer,text,text,text,boolean),public.void_work(uuid,text),public.request_service_signoff(uuid,text),public.decide_service_signoff(uuid,text,text),public.set_escalation_route(uuid,uuid),public.scan_sla_escalations(),public.acknowledge_escalation(uuid,text),public.queue_due_alerts() to authenticated;
grant execute on function public.queue_due_alerts(),public.scan_sla_escalations() to service_role;
create index work_logs_project on public.work_logs(project_id,created_at);
create index service_signoffs_project on public.service_signoffs(project_id,requested_at);
create index sla_escalations_project on public.sla_escalations(project_id,created_at);
notify pgrst,'reload schema';
commit;
