-- Apply once after 011. Additive assigned-work access and reviewed task results.
begin;
create schema if not exists portal_private;
revoke all on schema portal_private from public,anon;
grant usage on schema portal_private to authenticated;
create table public.project_assignments(
 project_id uuid references public.projects on delete cascade, technician_id uuid references public.profiles,
 assigned_by uuid not null default auth.uid() references public.profiles, assigned_at timestamptz not null default now(),
 primary key(project_id,technician_id)
);
alter table public.project_assignments enable row level security;
create function portal_private.team_account() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles where id=auth.uid() and role='team');$$;
create function portal_private.project_assigned(pid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select public.is_staff() and exists(select 1 from public.project_assignments where project_id=pid and technician_id=auth.uid());$$;
create function portal_private.task_assigned(tid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select public.is_staff() and exists(select 1 from public.tasks t where t.id=tid and (t.assignee=auth.uid() or auth.uid()=any(t.collaborators) or portal_private.project_assigned(t.project_id) or exists(select 1 from public.it_jobs j where j.task_id=t.id and j.technician_id=auth.uid() and j.status<>'Cancelled')));$$;
create function portal_private.project_visible(pid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select public.is_staff() and (portal_private.project_assigned(pid) or exists(select 1 from public.tasks t where t.project_id=pid and (t.assignee=auth.uid() or auth.uid()=any(t.collaborators))) or exists(select 1 from public.it_jobs j where j.project_id=pid and j.technician_id=auth.uid() and j.status<>'Cancelled'));$$;
create or replace function public.can_project(pid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select public.is_admin() or portal_private.project_visible(pid) or exists(select 1 from public.projects p join public.profiles u on u.company_id=p.company_id where p.id=pid and u.id=auth.uid() and u.active and u.role='client');$$;
create function portal_private.asset_visible(eid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select public.is_staff() and (exists(select 1 from public.tasks t where t.equipment_id=eid and portal_private.task_assigned(t.id)) or exists(select 1 from public.equipment e join public.it_jobs j on j.site_id=e.site_id where e.id=eid and j.technician_id=auth.uid() and j.status<>'Cancelled'));$$;
create function portal_private.site_visible(sid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select public.is_staff() and (exists(select 1 from public.it_jobs j where j.site_id=sid and j.technician_id=auth.uid() and j.status<>'Cancelled') or exists(select 1 from public.equipment e where e.site_id=sid and portal_private.asset_visible(e.id)));$$;
create function portal_private.company_visible(cid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select public.is_staff() and (exists(select 1 from public.projects p where p.company_id=cid and portal_private.project_visible(p.id)) or exists(select 1 from public.it_jobs j where j.company_id=cid and j.technician_id=auth.uid() and j.status<>'Cancelled'));$$;
create function portal_private.ticket_visible(tid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select public.is_staff() and exists(select 1 from public.tickets t where t.id=tid and (portal_private.project_assigned(t.project_id) or exists(select 1 from public.tasks k where k.ticket_id=t.id and portal_private.task_assigned(k.id))));$$;
create policy assignment_read on public.project_assignments for select to authenticated using(public.is_admin() or (technician_id=auth.uid() and public.is_staff()));
create policy assignment_manage on public.project_assignments for all to authenticated using(public.is_admin()) with check(public.is_admin());
grant select,insert,delete on public.project_assignments to authenticated;
create function portal_private.validate_assignment() returns trigger language plpgsql security definer set search_path='' as $$begin
 if not exists(select 1 from public.profiles where id=new.technician_id and active and role='team') then raise exception 'Choose an active technician';end if;new.assigned_by:=auth.uid();new.assigned_at:=now();return new;end$$;
create trigger assignment_validate before insert on public.project_assignments for each row execute function portal_private.validate_assignment();
-- Restrictive policies intersect every existing permissive policy. Unlisted modules are admin/client only.
do $$declare t text; rule text;begin
 for t in select tablename from pg_tables where schemaname='public' loop
 rule:=case t
 when 'profiles' then 'id=auth.uid()'
 when 'companies' then 'portal_private.company_visible(id)'
 when 'projects' then 'portal_private.project_visible(id)'
 when 'project_assignments' then 'technician_id=auth.uid() and public.is_staff()'
 when 'tasks' then 'portal_private.task_assigned(id)'
 when 'task_items' then 'portal_private.task_assigned(task_id)'
 when 'tickets' then 'portal_private.ticket_visible(id)'
 when 'ticket_events' then 'portal_private.ticket_visible(ticket_id)'
 when 'client_sites' then 'portal_private.site_visible(id)'
 when 'equipment' then 'portal_private.asset_visible(id)'
 when 'equipment_service' then 'portal_private.asset_visible(equipment_id)'
 when 'contracts' then 'exists(select 1 from public.projects p where p.contract_id=contracts.id and portal_private.project_visible(p.id)) or exists(select 1 from public.equipment e where e.contract_id=contracts.id and portal_private.asset_visible(e.id))'
 when 'milestones' then 'portal_private.project_visible(project_id)'
 when 'messages' then 'portal_private.project_visible(project_id) and (ticket_id is null or portal_private.ticket_visible(ticket_id))'
 when 'files' then 'portal_private.project_visible(project_id)'
 when 'approvals' then 'exists(select 1 from public.files f where f.id=file_id and portal_private.project_visible(f.project_id))'
 when 'work_logs' then 'portal_private.project_visible(project_id) and (technician_id=auth.uid() or (task_id is not null and portal_private.task_assigned(task_id)))'
 when 'service_signoffs' then 'portal_private.ticket_visible(ticket_id)'
 when 'maintenance_plans' then 'portal_private.project_assigned(project_id) or assignee=auth.uid()'
 when 'maintenance_runs' then 'portal_private.task_assigned(task_id)'
 when 'calendar_events' then 'portal_private.project_visible(project_id)'
 when 'workspace_activity' then 'portal_private.project_visible(project_id)'
 when 'it_jobs' then 'public.is_staff() and technician_id=auth.uid() and status<>''Cancelled''' 
 when 'it_job_reports' then 'exists(select 1 from public.it_jobs j where j.id=job_id and j.technician_id=auth.uid() and public.is_staff())'
 when 'it_operation_history' then '(record_type=''Site'' and portal_private.site_visible(record_id)) or (record_type=''Job'' and exists(select 1 from public.it_jobs j where j.id=record_id and j.technician_id=auth.uid() and public.is_staff()))'
 when 'attendance_entries' then 'user_id=auth.uid() and public.is_staff()'
 when 'attendance_history' then 'exists(select 1 from public.attendance_entries a where a.id=entry_id and a.user_id=auth.uid() and public.is_staff())'
 when 'notification_preferences' then 'id=auth.uid() and public.is_staff()'
 else 'false' end;
 execute format('create policy technician_scope on public.%I as restrictive for select to authenticated using(not portal_private.team_account() or (%s))',t,rule);
 -- Team writes use checked RPCs, file upload, and scoped conversations only.
 foreach rule in array array['insert','update','delete'] loop
 execute format('create policy technician_no_%s on public.%I as restrictive for %s to authenticated %s',rule,t,rule,
 case when rule='insert' then 'with check (not portal_private.team_account()' || case when t='files' then ' or (portal_private.project_visible(project_id) and author_id=auth.uid())' when t='messages' then ' or (portal_private.project_visible(project_id) and author_id=auth.uid() and internal and (ticket_id is null or portal_private.ticket_visible(ticket_id)))' else '' end || ')'
 else 'using (not portal_private.team_account())' end);
 end loop;
 end loop;
end$$;
alter table public.files add column published boolean not null default true;
create function portal_private.file_visible(fid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.files f where f.id=fid and public.can_project(f.project_id) and (public.is_staff() or f.published));$$;
create policy file_publication on public.files as restrictive for select to authenticated using(portal_private.file_visible(id));
create policy approval_publication on public.approvals as restrictive for all to authenticated using(portal_private.file_visible(file_id)) with check(portal_private.file_visible(file_id));
create function portal_private.stamp_evidence() returns trigger language plpgsql security definer set search_path='' as $$begin
 if portal_private.team_account() then new.published:=false;new.deliverable:=false;end if;return new;end$$;
create trigger evidence_stamp before insert on public.files for each row execute function portal_private.stamp_evidence();
create policy object_publication on storage.objects as restrictive for select to authenticated using(bucket_id<>'project-files' or exists(select 1 from public.files f where f.path=storage.objects.name and portal_private.file_visible(f.id)) or (owner_id=auth.uid()::text and exists(select 1 from public.projects p where p.id::text=split_part(storage.objects.name,'/',1) and public.can_project(p.id))));
create table public.task_completions(
 id uuid not null unique default gen_random_uuid(),task_id uuid primary key references public.tasks,project_id uuid not null references public.projects,
 technician_id uuid not null references public.profiles,summary text not null check(length(trim(summary)) between 3 and 10000),evidence uuid[] not null default '{}',
 status text not null default 'Draft' check(status in ('Draft','Submitted','Published','Confirmed','Changes requested')),
 feedback text not null default '',version integer not null default 1,updated_at timestamptz not null default now()
);
create table public.task_completion_history(id uuid primary key default gen_random_uuid(),task_id uuid not null references public.tasks,actor_id uuid not null default auth.uid() references public.profiles,action text not null,snapshot jsonb not null,created_at timestamptz not null default now());
alter table public.task_completions enable row level security;
alter table public.task_completion_history enable row level security;
create policy completion_read on public.task_completions for select to authenticated using(public.is_admin() or (public.is_staff() and portal_private.task_assigned(task_id)) or (not public.is_staff() and public.can_project(project_id) and status in ('Published','Confirmed','Changes requested') and exists(select 1 from public.tasks t where t.id=task_id and not t.internal)));
create policy completion_history_read on public.task_completion_history for select to authenticated using(exists(select 1 from public.task_completions c where c.task_id=task_completion_history.task_id) and (public.is_staff() or action in ('Publish','Confirm','Request changes')));
grant select on public.task_completions,public.task_completion_history to authenticated;
create function public.save_task_completion(p_task uuid,p_version integer,p_summary text,p_evidence uuid[]) returns void language plpgsql security definer set search_path='' as $$declare t public.tasks;c public.task_completions;begin
 if not public.is_staff() or (not public.is_admin() and not portal_private.task_assigned(p_task)) then raise exception 'Assigned work required';end if;
 select * into t from public.tasks where id=p_task for update;if not found then raise exception 'Task unavailable';end if;
 select * into c from public.task_completions where task_id=p_task for update;
 if found and (c.version is distinct from p_version or c.status not in ('Draft','Changes requested')) then raise exception 'Completion changed or locked';end if;
 if c.task_id is null and p_version is not null then raise exception 'Completion changed';end if;
 if p_evidence is null or cardinality(p_evidence)>100 or exists(select 1 from unnest(p_evidence) e where not exists(select 1 from public.files f where f.id=e and f.project_id=t.project_id)) then raise exception 'Evidence must belong to this project';end if;
 insert into public.task_completions(task_id,project_id,technician_id,summary,evidence) values(t.id,t.project_id,auth.uid(),trim(p_summary),p_evidence)
 on conflict(task_id) do update set summary=excluded.summary,evidence=excluded.evidence,status='Draft',version=task_completions.version+1,updated_at=now();
 update public.tasks set status='In progress' where id=t.id;
 insert into public.task_completion_history(task_id,action,snapshot) select task_id,'Save',to_jsonb(x) from public.task_completions x where task_id=t.id;
end$$;
create function public.task_completion_action(p_task uuid,p_version integer,p_action text,p_note text default '') returns void language plpgsql security definer set search_path='' as $$declare c public.task_completions;t public.tasks;next_status text;begin
 select * into t from public.tasks where id=p_task for update;
 select * into c from public.task_completions where task_id=p_task for update;
 if not found or c.version is distinct from p_version then raise exception 'Completion changed or unavailable';end if;
 if p_note is null or length(p_note)>2000 then raise exception 'Invalid feedback';end if;
 if p_action='Submit' and public.is_staff() and (public.is_admin() or portal_private.task_assigned(p_task)) and c.status in ('Draft','Changes requested') then
 if exists(select 1 from public.task_items where task_id=p_task and not done) then raise exception 'Complete the checklist first';end if;next_status:='Submitted';
 elsif p_action='Publish' and public.is_admin() and c.status='Submitted' then
 if t.internal then raise exception 'Internal tasks cannot be published to clients';end if;
 update public.files set published=true where id=any(c.evidence);update public.tasks set status='Done' where id=p_task;next_status:='Published';
 elsif p_action='Return' and public.is_admin() and c.status='Submitted' and length(trim(p_note))>=3 then next_status:='Changes requested';
 elsif p_action in ('Confirm','Request changes') and exists(select 1 from public.profiles u where u.id=auth.uid() and u.active and u.role='client') and public.can_project(t.project_id) and not t.internal and c.status='Published' then
 if p_action='Request changes' and length(trim(p_note))<3 then raise exception 'Explain required changes';end if;next_status:=case when p_action='Confirm' then 'Confirmed' else 'Changes requested' end;
 else raise exception 'Action not permitted';end if;
 if next_status='Changes requested' then update public.tasks set status='In progress' where id=p_task;end if;
 update public.task_completions set status=next_status,feedback=p_note,version=version+1,updated_at=now() where task_id=p_task;
 insert into public.task_completion_history(task_id,action,snapshot) select task_id,p_action,to_jsonb(x) from public.task_completions x where task_id=p_task;
end$$;
create function public.technician_checklist(p_item uuid,p_done boolean) returns void language plpgsql security definer set search_path='' as $$declare tid uuid;begin
 select task_id into tid from public.task_items where id=p_item;
 perform 1 from public.tasks where id=tid for update;
 if not public.is_staff() or (not public.is_admin() and not portal_private.task_assigned(tid)) then raise exception 'Assigned task required';end if;
 if exists(select 1 from public.task_completions where task_id=tid and status in ('Submitted','Published','Confirmed')) then raise exception 'Submitted work is locked';end if;
 update public.task_items set done=p_done where id=p_item;
end$$;
-- New helper functions are internal, not Data API endpoints.
revoke all on all functions in schema portal_private from public,anon;
grant execute on all functions in schema portal_private to authenticated;
revoke all on function public.save_task_completion(uuid,integer,text,uuid[]),public.task_completion_action(uuid,integer,text,text),public.technician_checklist(uuid,boolean) from public,anon;
grant execute on function public.save_task_completion(uuid,integer,text,uuid[]),public.task_completion_action(uuid,integer,text,text),public.technician_checklist(uuid,boolean) to authenticated;

create or replace function public.import_tasks(p_project uuid,p_batch uuid,p_rows jsonb) returns integer language plpgsql security definer set search_path='' as $$
declare r jsonb; previous public.task_imports; n integer; assignee_id uuid;
begin
 if portal_private.team_account() then raise exception 'Administrator required';end if;
 if not public.is_staff() then raise exception 'Staff access required'; end if;
 if jsonb_typeof(p_rows) is distinct from 'array' or jsonb_array_length(p_rows) not between 1 and 500 then raise exception 'Import 1 to 500 rows'; end if;
 perform pg_advisory_xact_lock(hashtext(p_batch::text));
 select * into previous from public.task_imports where id=p_batch;
 if found then
  if previous.project_id<>p_project or previous.payload<>p_rows then raise exception 'Batch already used for different data'; end if;
  return previous.row_count;
 end if;
 if not exists(select 1 from public.projects where id=p_project) then raise exception 'Project unavailable'; end if;
 for r in select value from jsonb_array_elements(p_rows) loop
  if jsonb_typeof(r) is distinct from 'object' or length(trim(coalesce(r->>'title',''))) not between 1 and 300 then raise exception 'Every row needs a task title of 1 to 300 characters'; end if;
  if coalesce(r->>'internal','false') not in ('true','false') then raise exception 'Internal must be true or false'; end if;
  assignee_id:=nullif(r->>'assignee_id','')::uuid;
  insert into public.tasks(project_id,title,priority,status,assignee,deadline,internal)
   values(p_project,trim(r->>'title'),coalesce(nullif(r->>'priority',''),'Normal'),coalesce(nullif(r->>'status',''),'To do'),assignee_id,nullif(r->>'deadline','')::date,coalesce((r->>'internal')::boolean,false));
 end loop;
 n:=jsonb_array_length(p_rows);
 insert into public.task_imports values(p_batch,p_project,p_rows,auth.uid(),n,now());
 return n;
end $$;

create or replace function public.bulk_update_tasks(p_project uuid,p_ids uuid[],p_patch jsonb) returns integer language plpgsql security definer set search_path='' as $$
declare n integer;
begin
 if portal_private.team_account() then raise exception 'Administrator required';end if;
 if not public.is_staff() then raise exception 'Staff access required'; end if;
 if p_ids is null or cardinality(p_ids) not between 1 and 500 or cardinality(p_ids)<>(select count(distinct x) from unnest(p_ids) x) then raise exception 'Select 1 to 500 unique tasks'; end if;
 if p_patch is null or jsonb_typeof(p_patch)<>'object' or p_patch='{}'::jsonb or exists(select 1 from jsonb_object_keys(p_patch) k where k not in ('status','priority','assignee','deadline','milestone_id')) then raise exception 'Unsupported bulk fields'; end if;
 perform id from public.tasks where id=any(p_ids) order by id for update;
 if (select count(*) from public.tasks where id=any(p_ids) and project_id=p_project)<>cardinality(p_ids) then raise exception 'All tasks must belong to this project'; end if;
 update public.tasks set status=case when p_patch?'status' then p_patch->>'status' else status end,priority=case when p_patch?'priority' then p_patch->>'priority' else priority end,assignee=case when p_patch?'assignee' then nullif(p_patch->>'assignee','')::uuid else assignee end,deadline=case when p_patch?'deadline' then nullif(p_patch->>'deadline','')::date else deadline end,milestone_id=case when p_patch?'milestone_id' then nullif(p_patch->>'milestone_id','')::uuid else milestone_id end where id=any(p_ids);
 get diagnostics n=row_count;return n;
end $$;

create or replace function public.import_workspace(p_batch uuid,p_kind text,p_rows jsonb) returns integer language plpgsql security definer set search_path='' as $$
declare prior public.workspace_imports;r jsonb;n integer:=0;ls text[];
begin
 if portal_private.team_account() then raise exception 'Administrator required';end if;
 if not public.is_staff() or (p_kind='clients' and not public.is_admin()) then raise exception 'Required staff or administrator access missing'; end if;
 if p_batch is null or p_kind not in ('clients','projects') or p_kind is null or p_rows is null or jsonb_typeof(p_rows)<>'array' then raise exception 'Invalid import'; end if;
 if jsonb_array_length(p_rows) not between 1 and 500 then raise exception 'Import 1 to 500 rows'; end if;
 perform pg_advisory_xact_lock(hashtext(p_batch::text));select * into prior from public.workspace_imports where id=p_batch;
 if found then if prior.author_id=auth.uid() and prior.kind=p_kind and prior.payload=p_rows then return prior.row_count; else raise exception 'Import ID already used'; end if; end if;
 for r in select value from jsonb_array_elements(p_rows) loop
  if jsonb_typeof(r)<>'object' then raise exception 'Invalid row'; end if;
  ls:=array(select trim(x) from unnest(string_to_array(coalesce(r->>'labels',''),',')) x where trim(x)<>'');
  if p_kind='clients' then
   insert into public.companies(name,email,phone,address,website,labels) values(trim(r->>'name'),coalesce(r->>'email',''),coalesce(r->>'phone',''),coalesce(r->>'address',''),coalesce(r->>'website',''),ls);
  else
   insert into public.projects(company_id,title,description,status,start_date,deadline,labels) values((r->>'company_id')::uuid,trim(r->>'title'),coalesce(r->>'description',''),coalesce(nullif(r->>'status',''),'Planning'),nullif(r->>'start_date','')::date,nullif(r->>'deadline','')::date,ls);
  end if;n:=n+1;
 end loop;
 insert into public.workspace_imports values(p_batch,p_kind,auth.uid(),p_rows,n,now());return n;
end $$;

create or replace function public.generate_maintenance() returns integer language plpgsql security definer set search_path='' as $$
declare p public.maintenance_plans; task_uuid uuid; item jsonb; count_all integer:=0; count_plan integer; next_month date; today date:=(now() at time zone 'UTC')::date;
begin
 if portal_private.team_account() then raise exception 'Administrator or scheduler required';end if;
 if not public.is_staff() and coalesce(auth.role(),'')<>'service_role' and not (auth.uid() is null and session_user='postgres') then raise exception 'Staff access required'; end if;
 for p in select * from public.maintenance_plans where active and next_due<=today+lead_days and (end_date is null or next_due<=end_date) and (equipment_id is null or not exists(select 1 from public.equipment e where e.id=equipment_id and e.status='Retired')) order by next_due limit 100 for update skip locked loop
  count_plan:=0;
  while p.next_due<=today+p.lead_days and (p.end_date is null or p.next_due<=p.end_date) and count_plan<50 and count_all<500 loop
   if not exists(select 1 from public.maintenance_runs where plan_id=p.id and due_on=p.next_due) then
    -- Inactive assignees become unassigned; retired equipment does not create new work.
    if p.equipment_id is not null and exists(select 1 from public.equipment where id=p.equipment_id and status='Retired') then exit; end if;
    insert into public.tasks(project_id,title,assignee,deadline,internal,priority,equipment_id)
     values(p.project_id,p.title||' · '||p.next_due::text,case when exists(select 1 from public.profiles where id=p.assignee and active and role in ('admin','team')) then p.assignee else null end,p.next_due,p.internal,p.priority,p.equipment_id) returning id into task_uuid;
    insert into public.maintenance_runs(plan_id,task_id,due_on) values(p.id,task_uuid,p.next_due);
    for item in select value from jsonb_array_elements(p.checklist) loop insert into public.task_items(task_id,title) values(task_uuid,item#>>'{}'); end loop;
    count_all:=count_all+1;
   end if;
   count_plan:=count_plan+1;
   if p.frequency='Daily' then p.next_due:=p.next_due+1;
   elsif p.frequency='Weekly' then p.next_due:=p.next_due+7;
   else
    next_month:=(date_trunc('month',p.next_due)+interval '1 month')::date;
    p.next_due:=next_month+(least(extract(day from p.anchor_date)::integer,extract(day from (next_month+interval '1 month - 1 day'))::integer)-1);
   end if;
  end loop;
  update public.maintenance_plans set next_due=p.next_due where id=p.id;
 end loop;
 return count_all;
end $$;

create or replace function public.request_service_signoff(p_ticket uuid,p_summary text) returns uuid language plpgsql security definer set search_path='' as $$
declare t public.tickets; sid uuid; evidence jsonb;
begin
 if portal_private.team_account() then raise exception 'Administrator publishes service results';end if;
 if not public.is_staff() then raise exception 'Staff access required'; end if;
 select * into t from public.tickets where id=p_ticket for update;
 if not found or t.status<>'Resolved' then raise exception 'Resolve the ticket before requesting sign-off'; end if;
 if exists(select 1 from public.service_signoffs where ticket_id=t.id and status='Pending') then raise exception 'A decision is already pending'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('date',l.worked_on,'minutes',l.minutes,'type',l.work_type,'summary',l.summary,'parts',l.parts,'technician',p.name) order by l.created_at),'[]'::jsonb) into evidence from public.work_logs l join public.profiles p on p.id=l.technician_id where l.ticket_id=t.id and not l.internal and l.voided_at is null and (l.task_id is null or exists(select 1 from public.tasks k where k.id=l.task_id and not k.internal));
 insert into public.service_signoffs(ticket_id,project_id,revision,summary,work_snapshot,requested_by) values(t.id,t.project_id,coalesce((select max(revision) from public.service_signoffs where ticket_id=t.id),0)+1,trim(p_summary),evidence,auth.uid()) returning id into sid;
 perform public.queue_alert('signoff:'||sid,'Service review requested',(select company_id from public.projects where id=t.project_id),false);
 return sid;
end $$;

create or replace function public.acknowledge_escalation(p_id uuid,p_note text) returns void language plpgsql security definer set search_path='' as $$
begin
 if portal_private.team_account() then raise exception 'Administrator required';end if;
 if not public.is_staff() or length(trim(coalesce(p_note,''))) not between 3 and 2000 then raise exception 'Staff access and an action note required'; end if;
 update public.sla_escalations set acknowledged_by=auth.uid(),acknowledged_at=now(),acknowledgement=trim(p_note) where id=p_id and acknowledged_at is null and cleared_at is null and (public.is_admin() or supervisor_id=auth.uid());
 if not found then raise exception 'Only the assigned supervisor or administrator can acknowledge an open escalation'; end if;
end $$;

create or replace function public.record_work(p_id uuid,p_project uuid,p_ticket uuid,p_task uuid,p_date date,p_minutes integer,p_type text,p_summary text,p_parts text,p_internal boolean) returns uuid language plpgsql security definer set search_path='' as $$
declare old_log public.work_logs;
begin
 if not public.is_staff() or not public.can_project(p_project) or (not public.is_admin() and ((p_task is not null and not portal_private.task_assigned(p_task)) or (p_ticket is not null and not portal_private.ticket_visible(p_ticket)))) then raise exception 'Staff access required'; end if;
 if p_id is null or p_date is null or p_date>(now() at time zone 'UTC')::date then raise exception 'Use a valid work date no later than today UTC'; end if;
 perform pg_advisory_xact_lock(hashtext(p_id::text));
 select * into old_log from public.work_logs where id=p_id;
 if found then
  if old_log.technician_id=auth.uid() and old_log.project_id=p_project and old_log.ticket_id is not distinct from p_ticket and old_log.task_id is not distinct from p_task and old_log.worked_on=p_date and old_log.minutes=p_minutes and old_log.work_type=p_type and old_log.summary=trim(p_summary) and old_log.parts=p_parts and old_log.internal=p_internal then return p_id; end if;
  raise exception 'Work entry ID already used';
 end if;
 if p_task is not null then perform 1 from public.tasks where id=p_task for update;if not public.is_admin() and exists(select 1 from public.task_completions where task_id=p_task and status in ('Submitted','Published','Confirmed')) then raise exception 'Submitted task work is locked';end if;end if;
 if p_ticket is not null and not exists(select 1 from public.tickets where id=p_ticket and project_id=p_project) then raise exception 'Ticket must belong to this project'; end if;
 if p_task is not null and not exists(select 1 from public.tasks where id=p_task and project_id=p_project and (p_ticket is null or ticket_id is null or ticket_id=p_ticket) and (p_internal or not internal)) then raise exception 'Task must match this project and ticket; internal tasks require internal logs'; end if;
 insert into public.work_logs(id,project_id,ticket_id,task_id,technician_id,worked_on,minutes,work_type,summary,parts,internal) values(p_id,p_project,p_ticket,p_task,auth.uid(),p_date,p_minutes,p_type,trim(p_summary),p_parts,p_internal);
 return p_id;
end $$;

create or replace function public.save_calendar_event(p_id uuid,p_version integer,p_project uuid,p_title text,p_notes text,p_start timestamptz,p_end timestamptz,p_internal boolean,p_reminder integer,p_cancelled boolean) returns uuid language plpgsql security definer set search_path='' as $$
declare e public.calendar_events;
begin
 if not exists(select 1 from public.profiles where id=auth.uid() and active) then raise exception 'Active account required'; end if;
 if p_project is not null and not public.is_admin() then raise exception 'Staff creates project events'; end if;
 if p_project is not null and not public.can_project(p_project) then raise exception 'Project unavailable'; end if;
 if p_id is null then
  insert into public.calendar_events(project_id,title,notes,starts_at,ends_at,internal,reminder_minutes,cancelled) values(p_project,trim(p_title),p_notes,p_start,p_end,case when p_project is null then true else p_internal end,p_reminder,p_cancelled) returning * into e;
 else
  select * into e from public.calendar_events where id=p_id for update;
  if not found or (e.project_id is null and e.owner_id<>auth.uid()) or (e.project_id is not null and not public.is_admin()) then raise exception 'Event unavailable'; end if;
  if e.version is distinct from p_version then raise exception 'Event changed. Refresh before saving.'; end if;
  if e.project_id is distinct from p_project then raise exception 'Event project cannot change'; end if;
  update public.calendar_events set title=trim(p_title),notes=p_notes,starts_at=p_start,ends_at=p_end,internal=case when p_project is null then true else p_internal end,reminder_minutes=p_reminder,cancelled=p_cancelled,version=version+1 where id=e.id;
 end if;
 return e.id;
end $$;

create or replace function public.it_job_action(p_id uuid,p_version integer,p_action text,p_note text default '') returns uuid language plpgsql security definer set search_path='' as $$declare j public.it_jobs;next_status text;begin
 select * into j from public.it_jobs where id=p_id for update;
 if not found or not public.it_job_visible(j) or j.version is distinct from p_version then raise exception 'Job changed or unavailable';end if;
 if p_note is null or length(p_note)>2000 then raise exception 'Note too long';end if;
 if p_action='Submit' and public.is_staff() and (public.is_admin() or j.technician_id=auth.uid()) and j.status in ('Scheduled','Changes requested') then
 if length(trim(j.work))<3 or exists(select 1 from jsonb_array_elements(j.checklist) c where c->>'done'<>'true') then raise exception 'Complete checklist and work record first';end if;next_status:='Submitted';
 elsif p_action='Publish' and public.is_admin() and j.status='Submitted' then
 if exists(select 1 from unnest(j.evidence) e where not exists(select 1 from public.files f where f.id=e and f.project_id=j.project_id)) then raise exception 'Evidence is no longer shared';end if;update public.files set published=true where id=any(j.evidence);insert into public.it_job_reports(job_id,version,snapshot) values(j.id,j.version+1,to_jsonb(j));next_status:='Published';
 elsif p_action='Return' and public.is_admin() and j.status='Submitted' and length(trim(p_note))>=3 then next_status:='Changes requested';
 elsif p_action in ('Confirm','Request changes') and not public.is_staff() and public.can_company(j.company_id) and j.status='Published' then
 if p_action='Request changes' and length(trim(p_note))<3 then raise exception 'Explain required changes';end if;next_status:=case when p_action='Confirm' then 'Confirmed' else 'Changes requested' end;
 elsif p_action='Cancel' and public.is_admin() and j.status in ('Scheduled','Changes requested','Submitted') and length(trim(p_note))>=3 then next_status:='Cancelled';
 else raise exception 'Action not permitted';end if;
 update public.it_jobs set status=next_status,client_note=case when p_action in ('Confirm','Request changes','Return') then p_note else client_note end,version=version+1 where id=p_id;
 insert into public.it_operation_history(record_id,company_id,record_type,action) values(j.id,j.company_id,'Job',p_action||case when p_note<>'' then ': '||p_note else '' end);return j.id;end $$;

alter policy technician_scope on public.calendar_events using(not portal_private.team_account() or (public.is_staff() and ((project_id is null and owner_id=auth.uid()) or portal_private.project_visible(project_id))));
-- Service logs written by technicians are drafts until administrator publication.
alter table public.work_logs add column published boolean not null default true;
create policy work_publication on public.work_logs as restrictive for select to authenticated using(public.is_staff() or published);
create function portal_private.stamp_work_log() returns trigger language plpgsql security definer set search_path='' as $$begin
 if portal_private.team_account() then new.published:=false;end if;return new;end$$;
create trigger work_publication_stamp before insert on public.work_logs for each row execute function portal_private.stamp_work_log();

create or replace function public.request_service_signoff(p_ticket uuid,p_summary text) returns uuid language plpgsql security definer set search_path='' as $$
declare t public.tickets; sid uuid; evidence jsonb;
begin
 if not public.is_admin() then raise exception 'Staff access required'; end if;
 select * into t from public.tickets where id=p_ticket for update;
 if not found or t.status<>'Resolved' then raise exception 'Resolve the ticket before requesting sign-off'; end if;
 if exists(select 1 from public.service_signoffs where ticket_id=t.id and status='Pending') then raise exception 'A decision is already pending'; end if;
 update public.work_logs set published=true where ticket_id=t.id and not internal and voided_at is null;
 select coalesce(jsonb_agg(jsonb_build_object('date',l.worked_on,'minutes',l.minutes,'type',l.work_type,'summary',l.summary,'parts',l.parts,'technician',p.name) order by l.created_at),'[]'::jsonb) into evidence from public.work_logs l join public.profiles p on p.id=l.technician_id where l.ticket_id=t.id and not l.internal and l.voided_at is null and (l.task_id is null or exists(select 1 from public.tasks k where k.id=l.task_id and not k.internal));
 insert into public.service_signoffs(ticket_id,project_id,revision,summary,work_snapshot,requested_by) values(t.id,t.project_id,coalesce((select max(revision) from public.service_signoffs where ticket_id=t.id),0)+1,trim(p_summary),evidence,auth.uid()) returning id into sid;
 perform public.queue_alert('signoff:'||sid,'Service review requested',(select company_id from public.projects where id=t.project_id),false);
 return sid;
end $$;

create function portal_private.publish_task_logs() returns trigger language plpgsql security definer set search_path='' as $$begin
 if new.status in ('Published','Confirmed') then update public.work_logs set published=true where task_id=new.task_id and not internal and voided_at is null;end if;return new;end$$;
create trigger publish_task_logs after update on public.task_completions for each row execute function portal_private.publish_task_logs();
create or replace function public.void_work(p_id uuid,p_reason text) returns void language plpgsql security definer set search_path='' as $$begin
 if not public.is_staff() or length(trim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'Staff access and a reason required';end if;
 update public.work_logs set voided_at=now(),voided_by=auth.uid(),void_reason=trim(p_reason) where id=p_id and voided_at is null and (public.is_admin() or (technician_id=auth.uid() and portal_private.project_visible(project_id) and ((task_id is not null and portal_private.task_assigned(task_id)) or (ticket_id is not null and portal_private.ticket_visible(ticket_id)))));
 if not found then raise exception 'Assigned work or administrator required';end if;
end$$;
create index tasks_assignee_scope on public.tasks(assignee,project_id);
create index tasks_collaborator_scope on public.tasks using gin(collaborators);
create index jobs_technician_scope on public.it_jobs(technician_id,project_id,site_id);
revoke all on function portal_private.stamp_work_log(),portal_private.publish_task_logs() from public,anon,authenticated;
notify pgrst,'reload schema';
commit;
