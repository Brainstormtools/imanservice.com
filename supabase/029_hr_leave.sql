begin;
create table public.hr_leave_allowances(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles,
 year integer not null check(year between 2000 and 2200),kind text not null check(kind in ('Annual','Sick','Casual','Unpaid')),
 units numeric(5,1) not null check(units between 0 and 366 and units*2=trunc(units*2)),
 version integer not null default 1,reason text not null,created_by uuid not null references public.profiles,
 unique(user_id,year,kind)
);
create table public.hr_leave_requests(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles,
 kind text not null check(kind in ('Annual','Sick','Casual','Unpaid')),starts_on date not null,ends_on date not null,
 half_day boolean not null default false,half_part text check(half_part in ('Morning','Afternoon')),days jsonb not null,units numeric(5,1) not null check(units>0),
 reason text not null,review_note text not null default '',status text not null default 'Submitted' check(status in ('Submitted','Approved','Rejected','Cancellation requested','Cancelled')),
 version integer not null default 1,reviewed_by uuid references public.profiles,created_at timestamptz not null default now(),
 check(isfinite(starts_on) and isfinite(ends_on) and starts_on<=ends_on and extract(year from starts_on)=extract(year from ends_on)),
 check((not half_day and half_part is null) or (half_day and starts_on=ends_on and half_part is not null))
);
create table public.hr_leave_history(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles,request_id uuid references public.hr_leave_requests,allowance_id uuid references public.hr_leave_allowances,actor_id uuid not null references public.profiles,action text not null,note text not null,snapshot jsonb not null,created_at timestamptz not null default now());
create index hr_leave_dates on public.hr_leave_requests(user_id,starts_on,ends_on,status);
create index hr_leave_history_user on public.hr_leave_history(user_id,created_at);
create function portal_private.hr_leave_read(p_user uuid) returns boolean language sql stable security definer set search_path='' as $$select public.is_staff() and (p_user=auth.uid() or portal_private.hr_access() or portal_private.hr_supervisor(p_user,current_date,'Manager'));$$;
create function portal_private.hr_leave_balance(p_user uuid,p_year integer,p_kind text) returns jsonb language sql stable security definer set search_path='' as $$
 with a as(select * from public.hr_leave_allowances where user_id=p_user and year=p_year and kind=p_kind),r as(select coalesce(sum(units) filter(where status in ('Approved','Cancellation requested')),0) used,coalesce(sum(units) filter(where status='Submitted'),0) pending from public.hr_leave_requests where user_id=p_user and extract(year from starts_on)=p_year and kind=p_kind)
 select jsonb_build_object('kind',p_kind,'year',p_year,'allowance',a.units,'used',r.used,'pending',r.pending,'available',a.units-r.used-r.pending) from a cross join r;$$;
create function public.hr_leave_balances(p_user uuid,p_year integer) returns jsonb language plpgsql stable security definer set search_path='' as $$begin
 if not portal_private.hr_leave_read(p_user) or p_year is null or p_year not between 2000 and 2200 then raise exception 'Own or authorized leave scope required';end if;
 return coalesce((select jsonb_agg(portal_private.hr_leave_balance(p_user,p_year,kind) order by kind) from public.hr_leave_allowances where user_id=p_user and year=p_year),'[]');
end$$;
create function public.save_hr_leave_allowance(p_user uuid,p_year integer,p_kind text,p_units numeric,p_version integer,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$declare a public.hr_leave_allowances;reserved numeric;begin
 if not portal_private.hr_access() or p_year is null or p_year not between 2000 and 2200 or p_kind is null or p_kind not in ('Annual','Sick','Casual','Unpaid') or p_units is null or p_units::text in ('NaN','Infinity','-Infinity') or p_units not between 0 and 366 or p_units*2<>trunc(p_units*2) or length(trim(coalesce(p_reason,''))) not between 3 and 2000 or not exists(select 1 from public.profiles where id=p_user and active and role in ('admin','team')) then raise exception 'HR, active employee and explicit annual allowance required';end if;
 perform pg_advisory_xact_lock(hashtextextended('hr:'||p_user::text,25));
 select * into a from public.hr_leave_allowances where user_id=p_user and year=p_year and kind=p_kind for update;
 if (a.id is null and p_version is not null) or (a.id is not null and a.version is distinct from p_version) then raise exception 'Current allowance version required';end if;
 select coalesce(sum(units),0) into reserved from public.hr_leave_requests where user_id=p_user and extract(year from starts_on)=p_year and kind=p_kind and status in ('Submitted','Approved','Cancellation requested');
 if p_units<reserved then raise exception 'Allowance cannot be below approved and pending leave';end if;
 if a.id is null then insert into public.hr_leave_allowances(user_id,year,kind,units,reason,created_by) values(p_user,p_year,p_kind,p_units,trim(p_reason),auth.uid()) returning * into a;
 else update public.hr_leave_allowances set units=p_units,reason=trim(p_reason),version=version+1 where id=a.id returning * into a;end if;
 insert into public.hr_leave_history(user_id,allowance_id,actor_id,action,note,snapshot) values(p_user,a.id,auth.uid(),'Allowance saved',trim(p_reason),to_jsonb(a));return a.id;
end$$;
create function public.request_hr_leave(p_id uuid,p_kind text,p_start date,p_end date,p_half boolean,p_reason text,p_half_part text default 'Morning') returns uuid language plpgsql security definer set search_path='' as $$declare r public.hr_leave_requests;day date;p public.hr_policies;days jsonb:='[]';units numeric:=0;amount numeric;begin
 if not public.is_staff() or p_id is null or p_kind is null or p_kind not in ('Annual','Sick','Casual','Unpaid') or p_start is null or p_end is null or not isfinite(p_start) or not isfinite(p_end) or p_start>p_end or extract(year from p_start)<>extract(year from p_end) or p_half is null or (p_half and (p_start<>p_end or p_half_part is null or p_half_part not in ('Morning','Afternoon'))) or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Active staff, same-year dates and leave reason required';end if;
 perform pg_advisory_xact_lock(hashtextextended('hr:'||auth.uid()::text,25));
 select * into r from public.hr_leave_requests where id=p_id;
 if found then if r.user_id=auth.uid() and r.kind=p_kind and r.starts_on=p_start and r.ends_on=p_end and r.half_day=p_half and (not p_half or r.half_part=p_half_part) and r.reason=trim(p_reason) then return r.id;end if;raise exception 'Changed or unavailable leave request retry';end if;
 for day in select x::date from generate_series(p_start::timestamp,p_end::timestamp,interval '1 day') x loop
  if portal_private.hr_locked(auth.uid(),day) then raise exception 'Leave month locked';end if;
  p:=portal_private.hr_policy(auth.uid(),day);if p.id is null or (portal_private.hr_term(auth.uid(),day)).id is null then raise exception 'Effective terms and shift policy required for every requested day';end if;
  if not(day=any(p.holidays)) and not(extract(dow from day)::integer=any(p.off_days)) then
   amount:=case when p_half then 0.5 else 1 end;
   if exists(select 1 from public.hr_leave_requests l cross join lateral jsonb_array_elements(l.days) x where l.user_id=auth.uid() and l.status in ('Submitted','Approved','Cancellation requested') and (x->>'date')::date=day) then raise exception 'Leave overlaps an active request';end if;
   if exists(select 1 from public.attendance_entries where user_id=auth.uid() and not voided and (checked_in at time zone 'Asia/Karachi')::date=day) or exists(select 1 from public.work_activities where user_id=auth.uid() and status not in ('Cancelled','Voided') and (actual_start at time zone 'Asia/Karachi')::date=day) then raise exception 'Resolve recorded attendance/activity before requesting leave';end if;
   days:=days||jsonb_build_array(jsonb_build_object('date',day,'units',amount,'policy_id',p.id));units:=units+amount;
  end if;
 end loop;
 if units=0 then raise exception 'At least one scheduled working day required';end if;
 if not exists(select 1 from public.hr_leave_allowances where user_id=auth.uid() and year=extract(year from p_start) and kind=p_kind) or units>coalesce((portal_private.hr_leave_balance(auth.uid(),extract(year from p_start)::integer,p_kind)->>'available')::numeric,0) then raise exception 'Configured leave balance insufficient';end if;
 insert into public.hr_leave_requests(id,user_id,kind,starts_on,ends_on,half_day,half_part,days,units,reason) values(p_id,auth.uid(),p_kind,p_start,p_end,p_half,case when p_half then p_half_part end,days,units,trim(p_reason)) returning * into r;
 insert into public.hr_leave_history(user_id,request_id,actor_id,action,note,snapshot) values(r.user_id,r.id,auth.uid(),'Requested',r.reason,to_jsonb(r));return r.id;
end$$;
create function public.hr_leave_action(p_id uuid,p_version integer,p_action text,p_note text) returns void language plpgsql security definer set search_path='' as $$declare r public.hr_leave_requests;day date;manager boolean;begin
 select * into r from public.hr_leave_requests where id=p_id;if r.id is null or not portal_private.hr_leave_read(r.user_id) then raise exception 'Leave request unavailable';end if;
 perform pg_advisory_xact_lock(hashtextextended('hr:'||r.user_id::text,25));select * into r from public.hr_leave_requests where id=p_id for update;
 if r.version is distinct from p_version or length(trim(coalesce(p_note,''))) not between 3 and 2000 then raise exception 'Current version and action reason required';end if;
 for day in select x::date from generate_series(r.starts_on::timestamp,r.ends_on::timestamp,interval '1 day') x loop if portal_private.hr_locked(r.user_id,day) then raise exception 'Leave month locked';end if;end loop;
 manager:=r.user_id<>auth.uid() and portal_private.hr_supervisor(r.user_id,r.starts_on,'Manager');
 if p_action='Approve' then
  if r.status<>'Submitted' or not manager or not exists(select 1 from public.profiles where id=r.user_id and active) then raise exception 'Separate designated manager approval for active employee required';end if;
  for day in select (x->>'date')::date from jsonb_array_elements(r.days) x loop
   if (portal_private.hr_policy(r.user_id,day)).id::text is distinct from (select x->>'policy_id' from jsonb_array_elements(r.days) x where (x->>'date')::date=day) then raise exception 'Shift policy changed; reject and request again';end if;
   if exists(select 1 from public.attendance_entries where user_id=r.user_id and not voided and (checked_in at time zone 'Asia/Karachi')::date=day) or exists(select 1 from public.work_activities where user_id=r.user_id and status not in ('Cancelled','Voided') and (actual_start at time zone 'Asia/Karachi')::date=day) then raise exception 'Recorded work conflicts with requested leave';end if;
  end loop;
 elsif p_action='Reject' then if r.status<>'Submitted' or not manager then raise exception 'Designated manager rejection required';end if;
 elsif p_action='Withdraw' then if r.status<>'Submitted' or r.user_id<>auth.uid() then raise exception 'Own pending request required';end if;
 elsif p_action='Request cancellation' then if r.status<>'Approved' or r.user_id<>auth.uid() then raise exception 'Own approved request required';end if;
 elsif p_action in ('Cancel approved','Keep approved') then if r.status<>'Cancellation requested' or not manager then raise exception 'Manager cancellation review required';end if;
 else raise exception 'Unsupported leave action';end if;
 update public.hr_leave_requests set status=case p_action when 'Approve' then 'Approved' when 'Keep approved' then 'Approved' when 'Request cancellation' then 'Cancellation requested' when 'Reject' then 'Rejected' else 'Cancelled' end,review_note=trim(p_note),reviewed_by=case when manager then auth.uid() else reviewed_by end,version=version+1 where id=r.id returning * into r;
 insert into public.hr_leave_history(user_id,request_id,actor_id,action,note,snapshot) values(r.user_id,r.id,auth.uid(),p_action,trim(p_note),to_jsonb(r));
end$$;
create function public.hr_leave_people() returns table(id uuid,name text,can_review boolean) language plpgsql stable security definer set search_path='' as $$begin if not public.is_staff() then raise exception 'Staff required';end if;return query select u.id,u.name,u.id<>auth.uid() and portal_private.hr_supervisor(u.id,current_date,'Manager') from public.profiles u where u.active and u.role in ('admin','team') and portal_private.hr_leave_read(u.id) order by u.name;end$$;
revoke all on function public.hr_leave_people() from public,anon,authenticated;grant execute on function public.hr_leave_people() to authenticated;
-- Approved leave is part of the attendance and monthly source basis. Preserve
-- unchanged day JSON when no leave applies so existing overtime hashes survive.
alter function portal_private.hr_day(uuid,date) rename to hr_day_recorded;
create function portal_private.hr_day(p_user uuid,p_day date) returns jsonb language plpgsql stable security definer set search_path='' as $$declare d jsonb;l public.hr_leave_requests;amount numeric;start_at timestamptz;end_at timestamptz;policy public.hr_policies;begin
 d:=portal_private.hr_day_recorded(p_user,p_day);
 select r.* into l from public.hr_leave_requests r cross join lateral jsonb_array_elements(r.days) x where r.user_id=p_user and r.status in ('Approved','Cancellation requested') and (x->>'date')::date=p_day;
 if l.id is null then return d;end if;
 amount:=(select (x->>'units')::numeric from jsonb_array_elements(l.days) x where (x->>'date')::date=p_day);
 if (portal_private.hr_policy(p_user,p_day)).id::text is distinct from (select x->>'policy_id' from jsonb_array_elements(l.days) x where (x->>'date')::date=p_day) then raise exception 'Approved leave shift policy changed; cancel and request again';end if;
 if amount=0.5 then
 policy:=portal_private.hr_policy(p_user,p_day);start_at:=(p_day+policy.shift_start) at time zone 'Asia/Karachi';end_at:=(p_day+policy.shift_end+case when policy.shift_end<=policy.shift_start then interval '1 day' else interval '0 day' end) at time zone 'Asia/Karachi';
 if l.half_part='Morning' then start_at:=start_at+(end_at-start_at)/2;end if;
 d:=d||jsonb_build_object('late',(d->>'first_checkin')::timestamptz>start_at+make_interval(mins=>policy.grace_minutes));end if;
 return d||jsonb_build_object('leave',jsonb_build_object('id',l.id,'version',l.version,'kind',l.kind,'half_part',l.half_part,'paid',l.kind<>'Unpaid','units',amount),'attendance_status',case when amount=1 then 'Approved leave' when (d->>'minutes')::numeric >= (portal_private.hr_policy(p_user,p_day)).half_day_minutes/2.0 then case when coalesce((d->>'late')::boolean,false) then 'Late' else 'Present' end else 'Approved half-day leave' end,'note','Approved leave is shown separately from recorded work. Paid and unpaid leave require the configured salary deduction basis; this is not a salary payment.');
end$$;
-- Excused leave is removed from attendance/report-discipline denominators.
-- Payroll sees dates/types/units only, never the employee request reason.
alter function portal_private.hr_month(uuid,date) rename to hr_month_recorded;
create function portal_private.hr_month(p_user uuid,p_month date) returns jsonb language plpgsql stable security definer set search_path='' as $$declare d jsonb;days jsonb;working numeric;present numeric;logged numeric;excused numeric;metrics jsonb;score numeric:=0;coverage numeric:=0;w record;bonus numeric;pending integer;begin
 d:=portal_private.hr_month_recorded(p_user,p_month);days:=d->'daily';
 select count(*) into pending from public.hr_leave_requests where user_id=p_user and status in ('Submitted','Cancellation requested') and starts_on<p_month+interval '1 month' and ends_on>=p_month;
 if pending>0 then d:=d||jsonb_build_object('pending_leave_requests',pending);end if;
 select coalesce(sum((x->'leave'->>'units')::numeric),0) into excused from jsonb_array_elements(days) x;
 if excused=0 then return d;end if;
 select count(*) filter(where x->>'kind'='Working day'),coalesce(sum(1-coalesce((x->'leave'->>'units')::numeric,0)) filter(where x->>'kind'='Working day' and x->>'attendance_status' in ('Present','Late')),0) into working,present from jsonb_array_elements(days) x;
 select coalesce(sum(1-coalesce((x->'leave'->>'units')::numeric,0)),0) into logged from jsonb_array_elements(days) x where x->>'kind'='Working day' and exists(select 1 from public.work_activities a where a.user_id=p_user and a.status='Approved' and (a.actual_start at time zone 'Asia/Karachi')::date=(x->>'working_date')::date);
 metrics:=d->'metrics'||jsonb_build_object('attendance',case when working>excused then round(present/(working-excused)*100,2) end,'report_discipline',case when working>excused then round(logged::numeric/(working-excused)*100,2) end);
 for w in select key,(value#>>'{}')::numeric weight from jsonb_each(d->'policy'->'weights') loop if metrics->>w.key is not null then score:=score+w.weight*(metrics->>w.key)::numeric/100;coverage:=coverage+w.weight;end if;end loop;
 if coverage<>100 then score:=null;end if;
 select (x->>'amount')::numeric into bonus from jsonb_array_elements(d->'policy'->'bonus_slabs') x where (x->>'score')::numeric<=score order by (x->>'score')::numeric desc limit 1;
 bonus:=case when score is null then null else coalesce(bonus,0) end;
 return d||jsonb_build_object('metrics',metrics,'score',round(score,2),'coverage',coverage,'bonus',bonus,'gross_salary_summary',(d->>'salary')::numeric+(d->>'overtime_pay')::numeric+bonus,'approved_leave_units',excused,'unpaid_leave_units',(select coalesce(sum((x->'leave'->>'units')::numeric),0) from jsonb_array_elements(days) x where x->'leave'->>'paid'='false'),'note','Approved leave is excused from attendance/report-discipline expectations. Unpaid leave units are explicit for HR deduction review; no salary deduction is silently inferred. Employment-day proration and automatic configured absence/late deductions remain pending. TADA remains separate.');
end$$;
-- Salary review cannot lock while leave or cancellation decisions are unresolved.
do $$declare original text;updated text;begin
 select pg_get_functiondef('public.hr_month_action(uuid,integer,text,text)'::regprocedure) into original;
 updated:=replace(original,'(r.snapshot->>''open_attendance'')::integer>0 then','(r.snapshot->>''open_attendance'')::integer>0 or coalesce((r.snapshot->>''pending_leave_requests'')::integer,0)>0 then');
 if updated=original then raise exception 'Monthly review lock predicate not found';end if;execute updated;
end$$;
create function portal_private.hr_leave_work_guard() returns trigger language plpgsql security definer set search_path='' as $$declare u uuid;day date;l public.hr_leave_requests;p public.hr_policies;slot_start timestamptz;slot_end timestamptz;midpoint timestamptz;record_start timestamptz;record_end timestamptz;begin
 if (tg_table_name='attendance_entries' and (to_jsonb(new)->>'voided')::boolean) or (tg_table_name='work_activities' and to_jsonb(new)->>'status' in ('Cancelled','Voided')) then return new;end if;
 u:=new.user_id;day:=case when tg_table_name='attendance_entries' then (to_jsonb(new)->>'checked_in')::timestamptz at time zone 'Asia/Karachi' else (to_jsonb(new)->>'actual_start')::timestamptz at time zone 'Asia/Karachi' end;
 perform pg_advisory_xact_lock(hashtextextended('hr:'||u::text,25));
 if exists(select 1 from public.hr_leave_requests existing_leave cross join lateral jsonb_array_elements(existing_leave.days) x where existing_leave.user_id=u and existing_leave.status in ('Approved','Cancellation requested') and (x->>'date')::date=day and (x->>'units')::numeric=1) then raise exception 'Cancel approved leave before recording work on that date';end if;
 select r.* into l from public.hr_leave_requests r cross join lateral jsonb_array_elements(r.days) x where r.user_id=u and r.status in ('Approved','Cancellation requested') and (x->>'date')::date=day and (x->>'units')::numeric=0.5;
 if l.id is not null then
 p:=portal_private.hr_policy(u,day);slot_start:=(day+p.shift_start) at time zone 'Asia/Karachi';slot_end:=(day+p.shift_end+case when p.shift_end<=p.shift_start then interval '1 day' else interval '0 day' end) at time zone 'Asia/Karachi';midpoint:=slot_start+(slot_end-slot_start)/2;
 if l.half_part='Morning' then slot_end:=midpoint;else slot_start:=midpoint;end if;
 record_start:=case when tg_table_name='attendance_entries' then (to_jsonb(new)->>'checked_in')::timestamptz else (to_jsonb(new)->>'actual_start')::timestamptz end;
 record_end:=case when tg_table_name='attendance_entries' then (to_jsonb(new)->>'checked_out')::timestamptz else (to_jsonb(new)->>'actual_end')::timestamptz end;
 if (record_start>=slot_start and record_start<slot_end) or (record_end is not null and tstzrange(record_start,record_end,'[)')&&tstzrange(slot_start,slot_end,'[)')) then raise exception 'Recorded work overlaps approved half-day leave';end if;
 end if;return new;
end$$;
create trigger hr_leave_attendance_guard before insert or update on public.attendance_entries for each row execute function portal_private.hr_leave_work_guard();
create trigger hr_leave_activity_guard before insert or update on public.work_activities for each row execute function portal_private.hr_leave_work_guard();
do $$declare tab text;begin foreach tab in array array['hr_leave_allowances','hr_leave_requests','hr_leave_history'] loop execute format('alter table public.%I enable row level security',tab);execute format('revoke all on public.%I from public,anon,authenticated',tab);execute format('grant select on public.%I to authenticated',tab);execute format('create policy leave_read on public.%I for select to authenticated using(portal_private.hr_leave_read(user_id))',tab);end loop;end$$;
revoke all on function portal_private.hr_leave_read(uuid),portal_private.hr_leave_balance(uuid,integer,text),portal_private.hr_day(uuid,date),portal_private.hr_month(uuid,date),portal_private.hr_day_recorded(uuid,date),portal_private.hr_month_recorded(uuid,date),portal_private.hr_leave_work_guard() from public,anon,authenticated;
grant execute on function portal_private.hr_leave_read(uuid) to authenticated;
revoke all on function public.hr_leave_balances(uuid,integer),public.save_hr_leave_allowance(uuid,integer,text,numeric,integer,text),public.request_hr_leave(uuid,text,date,date,boolean,text,text),public.hr_leave_action(uuid,integer,text,text) from public,anon,authenticated;
grant execute on function public.hr_leave_balances(uuid,integer),public.save_hr_leave_allowance(uuid,integer,text,numeric,integer,text),public.request_hr_leave(uuid,text,date,date,boolean,text,text),public.hr_leave_action(uuid,integer,text,text) to authenticated;
commit;
