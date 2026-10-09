begin;
-- Employment and payout rules are explicit configuration, never inferred from account creation.
create table public.hr_employment(
 user_id uuid primary key references public.profiles,starts_on date not null,ends_on date,
 version integer not null default 1,reason text not null,created_by uuid not null references public.profiles,
 check(isfinite(starts_on) and (ends_on is null or (isfinite(ends_on) and ends_on>=starts_on)))
);
create table public.hr_payout_policies(
 id uuid primary key default gen_random_uuid(),role_id text not null,effective_on date not null,
 proration text not null check(proration in ('Calendar days','Working days')),
 absence_fraction numeric(5,4) not null check(absence_fraction between 0 and 1),
 late_free integer not null check(late_free between 0 and 31),
 late_mode text not null check(late_mode in ('None','Fixed amount','Day fraction')),
 late_rate numeric(14,4) not null check(late_rate between 0 and 1000000),
 reason text not null,created_by uuid not null references public.profiles,
 check(isfinite(effective_on) and extract(day from effective_on)=1),
 check((late_mode='None' and late_rate=0) or late_mode='Fixed amount' or (late_mode='Day fraction' and late_rate<=1)),
 unique(role_id,effective_on)
);
alter table public.hr_employment enable row level security;
alter table public.hr_payout_policies enable row level security;
revoke all on public.hr_employment,public.hr_payout_policies from anon,authenticated;
grant select on public.hr_employment,public.hr_payout_policies to authenticated;
create policy hr_employment_read on public.hr_employment for select to authenticated using(portal_private.hr_read(user_id,current_date));
create policy hr_payout_rules_read on public.hr_payout_policies for select to authenticated using(public.is_staff());

create function public.save_hr_employment(p_user uuid,p_start date,p_end date,p_version integer,p_reason text) returns void
language plpgsql security definer set search_path='' as $$declare old public.hr_employment;begin
 if not portal_private.hr_access() or p_start is null or not isfinite(p_start) or (p_end is not null and (not isfinite(p_end) or p_end<p_start)) or length(trim(coalesce(p_reason,''))) not between 3 and 2000 or not exists(select 1 from public.profiles where id=p_user and active and role in ('team','admin')) then raise exception 'HR, active employee, valid dates and reason required';end if;
 perform pg_advisory_xact_lock(hashtextextended('hr:'||p_user::text,25));
 select * into old from public.hr_employment where user_id=p_user for update;
 if (old.user_id is null and p_version is not null) or (old.user_id is not null and old.version is distinct from p_version) then raise exception 'Current employment version required';end if;
 if exists(select 1 from public.hr_monthly m cross join lateral generate_series(m.month::timestamp,(m.month+interval '1 month'-interval '1 day')::timestamp,interval '1 day') x where m.user_id=p_user and m.status='Locked' and (old.user_id is null or ((x::date>=old.starts_on and (old.ends_on is null or x::date<=old.ends_on)) is distinct from (x::date>=p_start and (p_end is null or x::date<=p_end))))) then raise exception 'Employment changes cannot change a locked month';end if;
 if exists(select 1 from public.attendance_entries where user_id=p_user and not voided and ((checked_in at time zone 'Asia/Karachi')::date<p_start or (checked_in at time zone 'Asia/Karachi')::date>p_end)) or exists(select 1 from public.work_activities where user_id=p_user and status not in ('Cancelled','Voided') and ((actual_start at time zone 'Asia/Karachi')::date<p_start or (actual_start at time zone 'Asia/Karachi')::date>p_end)) or exists(select 1 from public.hr_leave_requests where user_id=p_user and status in ('Submitted','Approved','Cancellation requested') and (starts_on<p_start or ends_on>p_end)) then raise exception 'Resolve work and leave outside proposed employment dates';end if;
 insert into public.hr_employment(user_id,starts_on,ends_on,reason,created_by) values(p_user,p_start,p_end,trim(p_reason),auth.uid()) on conflict(user_id) do update set starts_on=excluded.starts_on,ends_on=excluded.ends_on,reason=excluded.reason,version=hr_employment.version+1;
 insert into public.hr_history(user_id,actor_id,action,note,snapshot) select p_user,auth.uid(),'Employment dates saved',trim(p_reason),to_jsonb(e) from public.hr_employment e where e.user_id=p_user;
end$$;

create function public.save_hr_payout_policy(p_data jsonb) returns uuid language plpgsql security definer set search_path='' as $$declare result uuid;begin
 if not public.is_admin() or length(trim(coalesce(p_data->>'reason',''))) not between 3 and 2000 or (coalesce(p_data->>'role_id','')<>'default' and not exists(select 1 from public.crm_roles where id=p_data->>'role_id' and active)) or (p_data->>'absence_fraction')::numeric::text in ('NaN','Infinity','-Infinity') or (p_data->>'late_rate')::numeric::text in ('NaN','Infinity','-Infinity') or (p_data->>'absence_fraction')::numeric not between 0 and 1 or round((p_data->>'absence_fraction')::numeric,4)<>(p_data->>'absence_fraction')::numeric or (p_data->>'late_rate')::numeric not between 0 and 1000000 or round((p_data->>'late_rate')::numeric,4)<>(p_data->>'late_rate')::numeric then raise exception 'Administrator and explicit finite payout rules required';end if;
 insert into public.hr_payout_policies(role_id,effective_on,proration,absence_fraction,late_free,late_mode,late_rate,reason,created_by) values(p_data->>'role_id',(p_data->>'effective_on')::date,p_data->>'proration',(p_data->>'absence_fraction')::numeric,(p_data->>'late_free')::integer,p_data->>'late_mode',(p_data->>'late_rate')::numeric,trim(p_data->>'reason'),auth.uid()) returning id into result;
 return result;
end$$;

create function portal_private.hr_salary_anchor(p_user uuid,p_month date) returns date language sql stable security definer set search_path='' as $$select greatest(p_month,coalesce((select starts_on from public.hr_employment where user_id=p_user),p_month));$$;
create function portal_private.hr_payout_policy(p_user uuid,p_day date) returns public.hr_payout_policies language sql stable security definer set search_path='' as $$select p from public.hr_payout_policies p where p.effective_on<=p_day and p.role_id in ('default',(portal_private.hr_term(p_user,p_day)).role_id) order by (p.role_id='default'),p.effective_on desc limit 1;$$;

-- The existing KPI and leave calculations retain their checked sources and review gates.
-- A mid-month joiner uses terms at the first employed day rather than needing fictitious earlier terms.
do $$declare definition text;begin
 select pg_get_functiondef('portal_private.hr_month_recorded(uuid,date)'::regprocedure) into definition;
 if position('t:=portal_private.hr_term(p_user,p_month);p:=portal_private.hr_policy(p_user,p_month);' in definition)=0 then raise exception 'Monthly anchor source changed';end if;
 definition:=replace(definition,'t:=portal_private.hr_term(p_user,p_month);p:=portal_private.hr_policy(p_user,p_month);','t:=portal_private.hr_term(p_user,portal_private.hr_salary_anchor(p_user,p_month));p:=portal_private.hr_policy(p_user,portal_private.hr_salary_anchor(p_user,p_month));');execute definition;
end$$;

alter function portal_private.hr_day(uuid,date) rename to hr_day_leave;
create function portal_private.hr_day(p_user uuid,p_day date) returns jsonb language plpgsql stable security definer set search_path='' as $$declare e public.hr_employment;begin
 select * into e from public.hr_employment where user_id=p_user;
 if e.user_id is not null and (p_day<e.starts_on or p_day>e.ends_on) then return jsonb_build_object('working_date',p_day,'kind','Outside employment','attendance_status','Outside employment','minutes',0,'overtime_hours',0,'overtime_amount',0,'source','[]'::jsonb,'late',false);end if;
 return portal_private.hr_day_leave(p_user,p_day);
end$$;

alter function portal_private.hr_month(uuid,date) rename to hr_month_leave;
create function portal_private.hr_month(p_user uuid,p_month date) returns jsonb language plpgsql stable security definer set search_path='' as $$declare data jsonb;e public.hr_employment;t public.hr_terms;p public.hr_policies;rules public.hr_payout_policies;day date;x jsonb;denominator integer;rate numeric;basic numeric:=0;absent numeric;worked numeric;leave_units numeric;unpaid numeric;absence_pay numeric:=0;unpaid_pay numeric:=0;late_pay numeric:=0;late_counts jsonb:='{}';late_count integer;missing integer:=0;details jsonb:='[]';policy_sources jsonb:='[]';term_sources jsonb:='[]';automatic numeric;active_days integer:=0;begin
 if p_month is null or not isfinite(p_month) or extract(day from p_month)<>1 then raise exception 'Choose first day of month';end if;
 select * into e from public.hr_employment where user_id=p_user;
 rules:=portal_private.hr_payout_policy(p_user,portal_private.hr_salary_anchor(p_user,p_month));
 if rules.id is null and e.user_id is null then return portal_private.hr_month_leave(p_user,p_month);end if;
 if rules.id is null or e.user_id is null then raise exception 'Configure employment dates and effective payout policy before salary calculation';end if;
 if e.starts_on>=p_month+interval '1 month' or e.ends_on<p_month then raise exception 'No employed days in selected month';end if;
 data:=portal_private.hr_month_leave(p_user,p_month);
 for x in select value from jsonb_array_elements(data->'daily') loop
 day:=(x->>'working_date')::date;if day<e.starts_on or day>e.ends_on then continue;end if;active_days:=active_days+1;
 t:=portal_private.hr_term(p_user,day);p:=portal_private.hr_policy(p_user,day);rules:=portal_private.hr_payout_policy(p_user,day);
 if t.id is null or p.id is null or rules.id is null then raise exception 'Missing effective salary, shift or payout policy';end if;
 if not policy_sources @> jsonb_build_array(to_jsonb(rules)) then policy_sources:=policy_sources||jsonb_build_array(to_jsonb(rules));end if;
 if not term_sources @> jsonb_build_array(to_jsonb(t)) then term_sources:=term_sources||jsonb_build_array(to_jsonb(t));end if;
 if rules.proration='Calendar days' then denominator:=extract(day from p_month+interval '1 month'-interval '1 day');
 else select count(*) into denominator from generate_series(p_month::timestamp,(p_month+interval '1 month'-interval '1 day')::timestamp,interval '1 day') s where not extract(dow from s)::integer=any(p.off_days) and not s::date=any(p.holidays);end if;
 if denominator=0 then raise exception 'Working-day salary basis has no scheduled working days';end if;
 rate:=t.salary/denominator;
 if rules.proration='Calendar days' or x->>'kind'='Working day' then basic:=basic+rate;end if;
 leave_units:=coalesce((x->'leave'->>'units')::numeric,0);unpaid:=case when x->'leave'->>'paid'='false' then leave_units else 0 end;
 worked:=case when x->>'attendance_status' in ('Present','Late') then 1-leave_units when x->>'attendance_status'='Half-day' then 0.5 else 0 end;
 absent:=case when x->>'kind'='Working day' then greatest(0,1-leave_units-worked) else 0 end;
 absence_pay:=absence_pay+rate*absent*rules.absence_fraction;unpaid_pay:=unpaid_pay+rate*unpaid;
 late_count:=coalesce((late_counts->>rules.id::text)::integer,0);
 if x->>'kind'='Working day' and leave_units<1 and (x->>'minutes')::numeric>0 and rules.late_mode<>'None' and x->>'first_checkin' is null then missing:=missing+1;end if;
 if x->>'kind'='Working day' and leave_units<1 and coalesce((x->>'late')::boolean,false) then late_count:=late_count+1;late_counts:=jsonb_set(late_counts,array[rules.id::text],to_jsonb(late_count));if late_count>rules.late_free then late_pay:=late_pay+case rules.late_mode when 'Fixed amount' then rules.late_rate when 'Day fraction' then rate*rules.late_rate else 0 end;end if;end if;
 details:=details||jsonb_build_array(jsonb_build_object('date',day,'terms_id',t.id,'shift_policy_id',p.id,'payout_policy_id',rules.id,'basis',rules.proration,'month_denominator',denominator,'salary_day_rate',round(rate,4),'salary_contribution',case when rules.proration='Calendar days' or x->>'kind'='Working day' then round(rate,4) else 0 end,'absent_units',absent,'unpaid_units',unpaid,'late',coalesce((x->>'late')::boolean,false)));
 end loop;
 basic:=round(basic,2);absence_pay:=round(absence_pay,2);unpaid_pay:=round(unpaid_pay,2);late_pay:=round(late_pay,2);automatic:=absence_pay+unpaid_pay+late_pay;
 return data||jsonb_build_object('salary',basic,'employment',to_jsonb(e),'employed_calendar_days',active_days,'salary_terms_sources',term_sources,'payout_policy_sources',policy_sources,'salary_daily_basis',details,'absence_deduction',absence_pay,'unpaid_leave_deduction',unpaid_pay,'late_deduction',late_pay,'automatic_deductions',automatic,'deduction_evidence_missing',missing,'gross_salary_summary',basic+(data->>'overtime_pay')::numeric+(data->>'bonus')::numeric,'projected_net_before_manual_deductions',basic+(data->>'overtime_pay')::numeric+(data->>'bonus')::numeric-automatic,'note','Salary is prorated from explicit employment dates and effective salary/payout rules. Absence excludes approved leave and credits recorded half-days. Unpaid leave is deducted once. Late penalties require completed check-in evidence and apply after the configured monthly allowance per payout policy. Current-month calculations are provisional. TADA and salary payments remain separate.');
end$$;

-- Additional HR deductions are added to the automatic total, never substituted for it.
do $$declare definition text;begin
 select pg_get_functiondef('public.save_hr_month(uuid,date,integer,numeric,text)'::regprocedure) into definition;
 if position('p_deductions>(data->>''gross_salary_summary'')::numeric' in definition)=0 then raise exception 'Monthly deduction source changed';end if;
 definition:=replace(definition,'p_deductions>(data->>''gross_salary_summary'')::numeric','p_deductions+coalesce((data->>''automatic_deductions'')::numeric,0)>(data->>''gross_salary_summary'')::numeric');
 definition:=replace(definition,'''deductions'',p_deductions,','''manual_deductions'',p_deductions,''deductions'',p_deductions+coalesce((data->>''automatic_deductions'')::numeric,0),');
 definition:=replace(definition,'::numeric-p_deductions','::numeric-p_deductions-coalesce((data->>''automatic_deductions'')::numeric,0)');
 definition:=replace(definition,'p_deductions,coalesce(p_note','p_deductions+coalesce((data->>''automatic_deductions'')::numeric,0),coalesce(p_note');
 definition:=replace(definition,'deductions=p_deductions,','deductions=p_deductions+coalesce((data->>''automatic_deductions'')::numeric,0),');execute definition;
 select pg_get_functiondef('public.hr_month_action(uuid,integer,text,text)'::regprocedure) into definition;
 if position('coalesce((r.snapshot->>''pending_leave_requests'')::integer,0)>0' in definition)=0 then raise exception 'Monthly lock source changed';end if;
 definition:=replace(definition,'coalesce((r.snapshot->>''pending_leave_requests'')::integer,0)>0','coalesce((r.snapshot->>''pending_leave_requests'')::integer,0)>0 or coalesce((r.snapshot->>''deduction_evidence_missing'')::integer,0)>0');execute definition;
end$$;

create function portal_private.hr_employment_work_guard() returns trigger language plpgsql security definer set search_path='' as $$declare u uuid;day date;last_day date;e public.hr_employment;begin
 if tg_table_name='attendance_entries' then if new.voided then return new;end if;u:=new.user_id;day:=(new.checked_in at time zone 'Asia/Karachi')::date;
 elsif tg_table_name='work_activities' then if new.status in ('Cancelled','Voided') then return new;end if;u:=new.user_id;day:=(new.actual_start at time zone 'Asia/Karachi')::date;
 else u:=new.user_id;day:=new.starts_on;last_day:=new.ends_on;end if;
 perform pg_advisory_xact_lock(hashtextextended('hr:'||u::text,25));select * into e from public.hr_employment where user_id=u;
 if e.user_id is not null and (day<e.starts_on or day>e.ends_on or last_day>e.ends_on) then raise exception 'Work and leave dates must be within configured employment';end if;return new;
end$$;
create trigger hr_employment_attendance_guard before insert or update on public.attendance_entries for each row execute function portal_private.hr_employment_work_guard();
create trigger hr_employment_activity_guard before insert or update on public.work_activities for each row execute function portal_private.hr_employment_work_guard();
create trigger hr_employment_leave_guard before insert or update on public.hr_leave_requests for each row execute function portal_private.hr_employment_work_guard();
revoke all on function public.save_hr_employment(uuid,date,date,integer,text),public.save_hr_payout_policy(jsonb) from public,anon;
grant execute on function public.save_hr_employment(uuid,date,date,integer,text),public.save_hr_payout_policy(jsonb) to authenticated;
revoke all on function portal_private.hr_salary_anchor(uuid,date),portal_private.hr_payout_policy(uuid,date),portal_private.hr_day(uuid,date),portal_private.hr_day_leave(uuid,date),portal_private.hr_month(uuid,date),portal_private.hr_month_leave(uuid,date),portal_private.hr_employment_work_guard() from public,anon,authenticated;
commit;
