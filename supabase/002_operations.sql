-- Run once AFTER 001_portal.sql, in the existing project. Preserves existing records.
-- Do not rerun 001_portal.sql. All changes commit together or roll back together.
begin;
create function public.can_company(cid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select public.is_staff() or exists(select 1 from public.profiles where id=auth.uid() and active and role='client' and company_id=cid);
$$;
create function public.valid_sla_targets(v jsonb) returns boolean language plpgsql immutable set search_path='' as $$
declare p text; k text; n numeric;
begin
 if v is null or jsonb_typeof(v)<>'object' then return false; end if;
 foreach p in array array['Low','Normal','High','Urgent'] loop
  if jsonb_typeof(v->p) is distinct from 'object' then return false; end if;
  foreach k in array array['response','resolution'] loop
   if jsonb_typeof(v->p->k) is distinct from 'number' then return false; end if;
   n:=(v->p->>k)::numeric;
   if n<1 or n>525600 or n<>trunc(n) then return false; end if;
  end loop;
  if (v->p->>'resolution')::numeric < (v->p->>'response')::numeric then return false; end if;
 end loop;
 return true;
end $$;
create table public.contracts (
 id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies,
 title text not null check(length(trim(title)) between 1 and 200),
 status text not null default 'Draft' check(status in ('Draft','Active','Cancelled')),
 start_date date not null, end_date date not null, renewal_date date,
 services text not null default '' check(length(services)<=10000),
 targets jsonb not null check(public.valid_sla_targets(targets)),
 created_at timestamptz not null default now(), check(end_date>=start_date)
);
create table public.equipment (
 id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies,
 contract_id uuid references public.contracts,
 name text not null check(length(trim(name)) between 1 and 200),
 category text not null default 'Other' check(category in ('Computer','Server','Router','Switch','Wi-Fi','Printer','Other')),
 serial_number text not null default '' check(length(serial_number)<=200),
 location text not null default '' check(length(location)<=300),
 warranty_end date, status text not null default 'In service' check(status in ('In service','Under repair','Retired')),
 notes text not null default '' check(length(notes)<=10000), created_at timestamptz not null default now()
);
create table public.equipment_service (
 id uuid primary key default gen_random_uuid(), equipment_id uuid not null references public.equipment,
 serviced_on date not null, summary text not null check(length(trim(summary)) between 1 and 10000),
 author_id uuid not null default auth.uid() references public.profiles, created_at timestamptz not null default now()
);
alter table public.projects add column contract_id uuid references public.contracts;
alter table public.tickets
 add column equipment_id uuid references public.equipment,
 add column contract_id uuid references public.contracts,
 add column contract_title text,
 add column response_minutes integer,
 add column resolution_minutes integer,
 add column response_due_at timestamptz,
 add column resolution_due_at timestamptz,
 add column first_response_at timestamptz,
 add column resolved_at timestamptz,
 add column sla_note text not null default 'Legacy ticket — SLA not measured';
alter table public.tasks
 add column priority text not null default 'Normal' check(priority in ('Low','Normal','High','Urgent')),
 add column equipment_id uuid references public.equipment,
 add column ticket_id uuid references public.tickets;
create table public.task_items (
 id uuid primary key default gen_random_uuid(), task_id uuid not null references public.tasks on delete cascade,
 title text not null check(length(trim(title)) between 1 and 300), done boolean not null default false,
 created_at timestamptz not null default now()
);
create table public.ticket_events (
 id uuid primary key default gen_random_uuid(), ticket_id uuid not null references public.tickets on delete cascade,
 status text not null, happened_at timestamptz not null default now(), actor_id uuid references public.profiles
);
-- Cross-company references are checked on the server, even for staff.
create function public.operations_validate_links() returns trigger language plpgsql security definer set search_path='' as $$
declare cid uuid; other_cid uuid; pid uuid;
begin
 if tg_table_name in ('contracts','equipment','projects') then
  if tg_op='UPDATE' and new.company_id is distinct from old.company_id then raise exception 'Company cannot be changed. Create a new record for another company.'; end if;
  if tg_table_name in ('equipment','projects') then
   if new.contract_id is not null then
   select company_id into other_cid from public.contracts where id=new.contract_id;
   if other_cid is distinct from new.company_id then raise exception 'Contract must belong to the same company'; end if;
   end if;
  end if;
 elsif tg_table_name='tasks' then
  select company_id into cid from public.projects where id=new.project_id;
  if tg_op='UPDATE' and new.project_id is distinct from old.project_id then raise exception 'Task project cannot be changed'; end if;
  if new.assignee is not null and (tg_op='INSERT' or new.assignee is distinct from old.assignee) and not exists(select 1 from public.profiles where id=new.assignee and active and role in ('admin','team')) then raise exception 'Choose an active team member'; end if;
  if new.equipment_id is not null then
   select company_id into other_cid from public.equipment where id=new.equipment_id;
   if other_cid is distinct from cid then raise exception 'Equipment must belong to the project company'; end if;
  end if;
  if new.ticket_id is not null then
   select project_id into pid from public.tickets where id=new.ticket_id;
   if pid is distinct from new.project_id then raise exception 'Ticket must belong to the same project'; end if;
  end if;
 end if;
 return new;
end $$;
create trigger contracts_validate before insert or update on public.contracts for each row execute function public.operations_validate_links();
create trigger equipment_validate before insert or update on public.equipment for each row execute function public.operations_validate_links();
create trigger projects_validate before insert or update on public.projects for each row execute function public.operations_validate_links();
create trigger tasks_validate before insert or update on public.tasks for each row execute function public.operations_validate_links();
-- Snapshot SLA terms using the database clock. Contract edits affect new tickets only.
create function public.ticket_sla_stamp() returns trigger language plpgsql security definer set search_path='' as $$
declare c public.contracts%rowtype; cid uuid; ecid uuid; ec uuid; equipment_status text; contract_ref uuid; stamp timestamptz:=statement_timestamp();
begin
 if tg_op='INSERT' then
  select company_id,contract_id into cid,contract_ref from public.projects where id=new.project_id;
  if new.equipment_id is not null then
   select company_id,contract_id,status into ecid,ec,equipment_status from public.equipment where id=new.equipment_id;
   if ecid is distinct from cid then raise exception 'Equipment must belong to the project company'; end if;
  end if;
  new.created_at:=stamp; new.status:='Open';
  new.contract_id:=null;new.contract_title:=null;new.response_minutes:=null;new.resolution_minutes:=null;
  new.response_due_at:=null;new.resolution_due_at:=null;new.first_response_at:=null;new.resolved_at:=null;
  new.sla_note:='No contract linked to project';
  if contract_ref is not null then
   select * into c from public.contracts where id=contract_ref;
   if c.company_id is distinct from cid then raise exception 'Contract company mismatch'; end if;
   new.sla_note:='Project contract is not active for this date';
   if c.status='Active' and (stamp at time zone 'UTC')::date between c.start_date and c.end_date then
    new.sla_note:='Equipment is not covered by the project contract';
    if new.equipment_id is null or (ec=contract_ref and equipment_status<>'Retired') then
     new.contract_id:=c.id;new.contract_title:=c.title;
     new.response_minutes:=(c.targets->new.priority->>'response')::integer;
     new.resolution_minutes:=(c.targets->new.priority->>'resolution')::integer;
     new.response_due_at:=stamp+new.response_minutes*interval '1 minute';
     new.resolution_due_at:=stamp+new.resolution_minutes*interval '1 minute';
     new.sla_note:='24/7 — waiting on client does not pause deadlines';
    end if;
   end if;
  end if;
 else
  -- Identity, priority and SLA evidence cannot be forged by a browser UPDATE.
  if new.project_id is distinct from old.project_id or new.equipment_id is distinct from old.equipment_id or new.author_id is distinct from old.author_id or new.created_at is distinct from old.created_at or new.priority is distinct from old.priority then
   raise exception 'Ticket project, equipment, author, creation time and priority are fixed after creation';
  end if;
  new.contract_id:=old.contract_id;new.contract_title:=old.contract_title;
  new.response_minutes:=old.response_minutes;new.resolution_minutes:=old.resolution_minutes;
  new.response_due_at:=old.response_due_at;new.resolution_due_at:=old.resolution_due_at;new.sla_note:=old.sla_note;
  -- Set only by the nested public staff reply trigger, never a direct API update.
  if pg_trigger_depth()<2 then new.first_response_at:=old.first_response_at; end if;
  new.resolved_at:=old.resolved_at;
  if new.status='Resolved' and old.status<>'Resolved' then new.resolved_at:=stamp;
  elsif new.status<>'Resolved' and old.status='Resolved' then new.resolved_at:=null;
  end if;
 end if;
 return new;
end $$;
create trigger tickets_sla_stamp before insert or update on public.tickets for each row execute function public.ticket_sla_stamp();
create function public.ticket_first_reply() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.ticket_id is not null and not new.internal and exists(select 1 from public.profiles where id=new.author_id and active and role in ('admin','team')) then
  update public.tickets set first_response_at=statement_timestamp() where id=new.ticket_id and project_id=new.project_id and first_response_at is null and status<>'Resolved';
 end if;
 return new;
end $$;
create trigger messages_first_reply after insert on public.messages for each row execute function public.ticket_first_reply();
create function public.ticket_status_event() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if tg_op='INSERT' or new.status is distinct from old.status then insert into public.ticket_events(ticket_id,status,actor_id) values(new.id,new.status,auth.uid()); end if;
 return new;
end $$;
create trigger tickets_status_event after insert or update on public.tickets for each row execute function public.ticket_status_event();
-- Secure company records and task checklists. Service history is append-only and shared with its company.
alter table public.contracts enable row level security;
alter table public.equipment enable row level security;
alter table public.equipment_service enable row level security;
alter table public.task_items enable row level security;
alter table public.ticket_events enable row level security;
create policy contract_read on public.contracts for select to authenticated using(public.can_company(company_id));
create policy contract_insert on public.contracts for insert to authenticated with check(public.is_admin());
create policy contract_update on public.contracts for update to authenticated using(public.is_admin()) with check(public.is_admin());
create policy equipment_read on public.equipment for select to authenticated using(public.can_company(company_id));
create policy equipment_insert on public.equipment for insert to authenticated with check(public.is_staff());
create policy equipment_update on public.equipment for update to authenticated using(public.is_staff()) with check(public.is_staff());
create policy service_read on public.equipment_service for select to authenticated using(exists(select 1 from public.equipment e where e.id=equipment_id and public.can_company(e.company_id)));
create policy service_insert on public.equipment_service for insert to authenticated with check(public.is_staff() and author_id=auth.uid());
create policy checklist_read on public.task_items for select to authenticated using(exists(select 1 from public.tasks t where t.id=task_id and public.can_project(t.project_id) and (not t.internal or public.is_staff())));
create policy checklist_manage on public.task_items for all to authenticated using(public.is_staff()) with check(public.is_staff());
create policy ticket_events_read on public.ticket_events for select to authenticated using(exists(select 1 from public.tickets t where t.id=ticket_id and public.can_project(t.project_id)));
create index contracts_company on public.contracts(company_id);
create index equipment_company on public.equipment(company_id);
create index equipment_contract on public.equipment(contract_id);
create index equipment_service_equipment on public.equipment_service(equipment_id,serviced_on);
create index task_items_task on public.task_items(task_id);
create index tickets_equipment on public.tickets(equipment_id);
create index tasks_ticket on public.tasks(ticket_id);
create index ticket_events_ticket on public.ticket_events(ticket_id,happened_at);
revoke all on public.contracts,public.equipment,public.equipment_service,public.task_items,public.ticket_events from anon;
grant select,insert,update on public.contracts,public.equipment to authenticated;
grant select,insert on public.equipment_service to authenticated;
grant select,insert,update,delete on public.task_items to authenticated;
grant select on public.ticket_events to authenticated;
revoke all on function public.can_company(uuid),public.valid_sla_targets(jsonb),public.operations_validate_links(),public.ticket_sla_stamp(),public.ticket_first_reply(),public.ticket_status_event() from public,anon;
grant execute on function public.can_company(uuid),public.valid_sla_targets(jsonb) to authenticated;
notify pgrst, 'reload schema';
commit;
