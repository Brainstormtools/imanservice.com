-- Fixed first-response evidence and explicitly reviewed repeat complaints.
begin;
create table public.ticket_response_history(id uuid primary key default gen_random_uuid(),ticket_id uuid not null unique references public.tickets,project_id uuid not null references public.projects,user_id uuid references public.profiles,outcome text not null check(outcome in ('First shared reply','Closed without reply')),happened_at timestamptz not null,ticket_created_at timestamptz not null,first_response_at timestamptz,response_due_at timestamptz,response_minutes integer,active_minutes numeric,sla_note text not null);
create index ticket_response_month on public.ticket_response_history(user_id,happened_at);
create table public.ticket_repeat_reviews(id uuid primary key default gen_random_uuid(),ticket_id uuid not null references public.tickets,project_id uuid not null references public.projects,resolution_id uuid not null references public.ticket_resolution_history,original_ticket_id uuid not null references public.tickets,user_id uuid references public.profiles,complaint_at timestamptz not null,revision integer not null,decision text not null check(decision in ('Confirm repeat','Withdraw repeat')),reason text not null check(length(trim(reason)) between 3 and 2000),reviewed_by uuid not null references public.profiles,reviewed_at timestamptz not null default now(),unique(ticket_id,revision));
create index ticket_repeat_month on public.ticket_repeat_reviews(user_id,complaint_at);
create index ticket_repeat_project on public.ticket_repeat_reviews(project_id);
alter table public.ticket_response_history enable row level security;
alter table public.ticket_repeat_reviews enable row level security;
create policy response_history_read on public.ticket_response_history for select to authenticated using(public.is_admin() or (public.is_staff() and portal_private.ticket_visible(ticket_id)));
create policy repeat_history_read on public.ticket_repeat_reviews for select to authenticated using(public.is_admin() or (public.is_staff() and portal_private.ticket_visible(ticket_id) and portal_private.ticket_visible(original_ticket_id)));
revoke all on public.ticket_response_history,public.ticket_repeat_reviews from public,anon,authenticated;
grant select on public.ticket_response_history,public.ticket_repeat_reviews to authenticated;
create function portal_private.capture_ticket_response() returns trigger language plpgsql security definer set search_path='' as $$declare event_time timestamptz;elapsed numeric;kind text;begin
 if old.first_response_at is null and new.first_response_at is not null then
  event_time:=new.first_response_at;kind:='First shared reply';
  elapsed:=greatest(0,extract(epoch from (new.first_response_at-new.created_at))-case when new.response_due_at is not null and new.response_minutes is not null then greatest(0,extract(epoch from (new.response_due_at-new.created_at))-new.response_minutes*60) else 0 end)/60;
 elsif old.status<>'Resolved' and new.status='Resolved' and new.first_response_at is null then event_time:=new.resolved_at;kind:='Closed without reply';
 else return new;end if;
 insert into public.ticket_response_history(ticket_id,project_id,user_id,outcome,happened_at,ticket_created_at,first_response_at,response_due_at,response_minutes,active_minutes,sla_note) values(new.id,new.project_id,(select user_id from public.ticket_performance_owners where ticket_id=new.id),kind,event_time,new.created_at,new.first_response_at,new.response_due_at,new.response_minutes,round(elapsed,4),new.sla_note) on conflict(ticket_id) do nothing;
 return new;
end$$;
create trigger capture_ticket_response after update on public.tickets for each row execute function portal_private.capture_ticket_response();
create function public.review_ticket_repeat(p_ticket uuid,p_resolution uuid,p_version integer,p_action text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$declare t public.tickets;h public.ticket_resolution_history;o public.ticket_repeat_reviews;r uuid;asset uuid;begin
 if not public.is_admin() or p_action is null or p_action not in ('Confirm repeat','Withdraw repeat') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Administrator, review decision and reason required';end if;
 select * into t from public.tickets where id=p_ticket for update;select * into h from public.ticket_resolution_history where id=p_resolution;
 if t.id is null or h.id is null or h.project_id is distinct from t.project_id or h.ticket_id=t.id or h.resolved_at>t.created_at then raise exception 'Link an earlier recorded resolution of another ticket in this project';end if;
 select equipment_id into asset from public.tickets where id=h.ticket_id;
 if t.equipment_id is not null and asset is not null and t.equipment_id<>asset then raise exception 'Repeat complaints cannot link different assets';end if;
 select * into o from public.ticket_repeat_reviews where ticket_id=t.id order by revision desc limit 1;
 if (o.id is null and p_version is not null) or (o.id is not null and o.revision is distinct from p_version) then raise exception 'Current repeat-review version required';end if;
 if p_action='Withdraw repeat' and (o.id is null or o.decision<>'Confirm repeat' or o.resolution_id is distinct from h.id) then raise exception 'Withdraw the current confirmed link';end if;
 if o.id is not null and o.decision='Confirm repeat' and p_action='Confirm repeat' then raise exception 'Withdraw the existing link before a corrected confirmation';end if;
 insert into public.ticket_repeat_reviews(ticket_id,project_id,resolution_id,original_ticket_id,user_id,complaint_at,revision,decision,reason,reviewed_by) values(t.id,t.project_id,h.id,h.ticket_id,h.user_id,t.created_at,coalesce(o.revision,0)+1,p_action,trim(p_reason),auth.uid()) returning id into r;return r;
end$$;
do $$declare definition text;updated text;begin
 definition:=pg_get_functiondef('public.save_hr_policy(jsonb)'::regprocedure);updated:=replace(definition,'''customer_rating'')','''customer_rating'',''ticket_response'')');if updated=definition then raise exception 'KPI validator changed';end if;execute updated;
end$$;
alter function portal_private.hr_month(uuid,date) rename to hr_month_before_ticket_response;
create function portal_private.hr_month(p_user uuid,p_month date) returns jsonb language plpgsql stable security definer set search_path='' as $$declare data jsonb;sources jsonb;repeats jsonb;total integer;missing integer;met integer;unanswered integer;average_minutes numeric;repeat_count integer;original_count integer;metrics jsonb;score numeric:=0;coverage numeric:=0;w record;band jsonb;bonus numeric;basic numeric;begin
 data:=portal_private.hr_month_before_ticket_response(p_user,p_month);
 select coalesce(jsonb_agg(to_jsonb(h) order by id),'[]'),count(*),count(*) filter(where response_due_at is null),count(*) filter(where first_response_at<=response_due_at),count(*) filter(where outcome='Closed without reply'),avg(active_minutes) into sources,total,missing,met,unanswered,average_minutes from public.ticket_response_history h where user_id=p_user and (happened_at at time zone 'Asia/Karachi')::date>=p_month and (happened_at at time zone 'Asia/Karachi')::date<p_month+interval '1 month';
 -- Latest reviewed disposition for each complaint, independent of current assignment.
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'ticket_id',ticket_id,'resolution_id',resolution_id,'complaint_at',complaint_at,'revision',revision,'decision',decision,'reviewed_at',reviewed_at) order by id),'[]'),count(*) filter(where decision='Confirm repeat'),count(distinct resolution_id) filter(where decision='Confirm repeat') into repeats,repeat_count,original_count from (select distinct on(ticket_id) * from public.ticket_repeat_reviews order by ticket_id,revision desc) r where user_id=p_user and (complaint_at at time zone 'Asia/Karachi')::date>=p_month and (complaint_at at time zone 'Asia/Karachi')::date<p_month+interval '1 month';
 metrics:=(data->'metrics')||jsonb_build_object('ticket_response',case when total>0 and missing=0 then round(met::numeric/total*100,2) end);
 for w in select key,(value#>>'{}')::numeric weight from jsonb_each(data->'policy'->'weights') loop if metrics->>w.key is not null then score:=score+w.weight*(metrics->>w.key)::numeric/100;coverage:=coverage+w.weight;end if;end loop;
 if coverage<>100 then score:=null;end if;select x into band from jsonb_array_elements(data->'policy'->'bonus_slabs') x where (x->>'score')::numeric<=score order by (x->>'score')::numeric desc limit 1;
 basic:=(data->>'salary')::numeric;bonus:=case when score is null then null when band is null then 0 when band->>'mode'='Salary percent' then round(basic*(band->>'amount')::numeric/100,2) else (band->>'amount')::numeric end;
 return data||jsonb_build_object('metrics',metrics,'score',round(score,2),'coverage',coverage,'bonus',bonus,'bonus_basis',jsonb_build_object('band',band,'salary_base',basic,'base_description','Prorated basic salary before deductions; excludes overtime and TADA'),'gross_salary_summary',basic+(data->>'overtime_pay')::numeric+bonus,'projected_net_before_manual_deductions',basic+(data->>'overtime_pay')::numeric+bonus-coalesce((data->>'automatic_deductions')::numeric,0),'response_sources',sources,'response_outcomes',total,'response_sla_missing',missing,'response_closed_without_reply',unanswered,'response_average_active_minutes',round(average_minutes,2),'repeat_sources',repeats,'repeat_complaints',repeat_count,'repeat_original_resolutions',original_count,'response_repeat_note','Response SLA uses the first saved reply or first closure without reply, in its outcome month, with the owner captured at that time. Waiting is excluded from active reply minutes. A closure without reply fails a measured response SLA, even before its deadline. Missing SLA makes the cohort unknown; open unanswered tickets are outside this completed-outcome KPI. Earlier response events are not reconstructed. Repeat counts use explicit administrator confirmations (latest disposition), in the complaint receipt month, attributed to the earlier resolution owner. Zero confirmed repeats does not establish repeat-free quality: recurrence windows/denominators and bonus rules require business configuration. Withdrawals retain audit history.');
end$$;
revoke all on function public.review_ticket_repeat(uuid,uuid,integer,text,text) from public,anon;
grant execute on function public.review_ticket_repeat(uuid,uuid,integer,text,text) to authenticated;
revoke all on function portal_private.capture_ticket_response(),portal_private.hr_month(uuid,date),portal_private.hr_month_before_ticket_response(uuid,date) from public,anon,authenticated;
commit;
