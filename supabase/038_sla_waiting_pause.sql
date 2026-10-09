-- Snapshot pause rules for new tickets only; existing contractual evidence stays fixed.
begin;
alter table public.tickets add column sla_pause_enabled boolean not null default false,
 add column sla_paused_at timestamptz,
 add column sla_paused_seconds numeric not null default 0 check(sla_paused_seconds>=0);
alter table public.tickets alter column sla_pause_enabled set default true;
create or replace function public.ticket_sla_stamp() returns trigger language plpgsql security definer set search_path='' as $$
declare c public.contracts%rowtype; cid uuid; ecid uuid; ec uuid; equipment_status text; contract_ref uuid; stamp timestamptz:=statement_timestamp(); paused interval;
begin
 if tg_op='INSERT' then
  select company_id,contract_id into cid,contract_ref from public.projects where id=new.project_id;
  if new.equipment_id is not null then
   select company_id,contract_id,status into ecid,ec,equipment_status from public.equipment where id=new.equipment_id;
   if ecid is distinct from cid then raise exception 'Equipment must belong to the project company'; end if;
  end if;
  new.created_at:=stamp; new.status:='Open';
  new.sla_pause_enabled:=true;new.sla_paused_at:=null;new.sla_paused_seconds:=0;
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
     new.sla_note:='24/7 — waiting on client pauses unfinished SLA clocks';
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
  new.sla_pause_enabled:=old.sla_pause_enabled;new.sla_paused_at:=old.sla_paused_at;new.sla_paused_seconds:=old.sla_paused_seconds;
  if old.sla_pause_enabled and old.sla_paused_at is not null then
   paused:=greatest(stamp-old.sla_paused_at,interval '0 seconds');
   -- A first shared reply completes its own clock while resolution stays paused.
   if old.first_response_at is null and (new.first_response_at is not null or new.status<>'Waiting on client') then
    new.response_due_at:=old.response_due_at+paused;
   end if;
   if new.status<>'Waiting on client' then
    new.resolution_due_at:=old.resolution_due_at+paused;
    new.sla_paused_seconds:=old.sla_paused_seconds+extract(epoch from paused);
    new.sla_paused_at:=null;
   end if;
  elsif old.sla_pause_enabled and new.status='Waiting on client' and old.status<>'Waiting on client' and old.resolution_due_at is not null then
   new.sla_paused_at:=stamp;
  end if;
  new.resolved_at:=old.resolved_at;
  if new.status='Resolved' and old.status<>'Resolved' then new.resolved_at:=stamp;
  elsif new.status<>'Resolved' and old.status='Resolved' then new.resolved_at:=null;
  end if;
 end if;
 return new;
end $$;

-- Freeze overdue comparisons at pause entry: existing breaches remain visible,
-- future deadlines do not breach during a wait. Preserve each scanner's authorization.
do $$declare target text;definition text;updated text;begin
 foreach target in array array['public.scan_sla_escalations()','public.queue_business_due_alerts()','portal_private.queue_reminders_before_schedules()'] loop
  definition:=pg_get_functiondef(target::regprocedure);
  updated:=replace(definition,'v.response_due_at<now()','v.response_due_at<coalesce(v.sla_paused_at,now())');
  updated:=replace(updated,'v.resolution_due_at<now()','v.resolution_due_at<coalesce(v.sla_paused_at,now())');
  updated:=replace(updated,' response_due_at<now()',' response_due_at<coalesce(sla_paused_at,now())');
  updated:=replace(updated,' resolution_due_at<now()',' resolution_due_at<coalesce(sla_paused_at,now())');
  -- The escalation loop uses a record named breach, so carry its frozen clock too.
  updated:=replace(updated,'v.first_response_at,v.status,','v.first_response_at,v.status,v.sla_paused_at,');
  updated:=replace(updated,'breach.response_due_at<now()','breach.response_due_at<coalesce(breach.sla_paused_at,now())');
  updated:=replace(updated,'breach.resolution_due_at<now()','breach.resolution_due_at<coalesce(breach.sla_paused_at,now())');
  if updated=definition then raise exception 'SLA scanner definition changed: %',target;end if;
  execute updated;
 end loop;
 definition:=pg_get_functiondef('portal_private.hr_month(uuid,date)'::regprocedure);
 updated:=replace(definition,'Existing contract clocks are 24/7; waiting-on-client pause rules remain pending.','SLA clock rules are captured per ticket: new tickets pause unfinished clocks while waiting on client; legacy tickets retain their recorded 24/7 deadlines.');
 if updated=definition then raise exception 'Service scorecard definition changed';end if;execute updated;
end$$;
revoke all on function public.ticket_sla_stamp() from public,anon,authenticated;
commit;
