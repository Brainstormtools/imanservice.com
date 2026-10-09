begin;
-- Capture the planned end before review; subsequent deadline edits cannot rewrite it.
create function portal_private.task_performance_snapshot() returns trigger language plpgsql security definer set search_path='' as $$declare submitted public.task_completion_history;begin
 if new.action='Submit' then
 new.snapshot:=new.snapshot||jsonb_build_object('performance_submission',jsonb_build_object('deadline',(select deadline from public.tasks where id=new.task_id),'submitted_at',new.created_at));
 elsif new.action in ('Publish','Approve') then
 select * into submitted from public.task_completion_history where task_id=new.task_id and action='Submit' and (snapshot->>'version')::integer=(new.snapshot->>'version')::integer-1 order by created_at desc,id desc limit 1;
 new.snapshot:=new.snapshot||jsonb_build_object('performance_basis',submitted.snapshot->'performance_submission');
 end if;return new;
end$$;
create trigger task_performance_snapshot before insert on public.task_completion_history for each row execute function portal_private.task_performance_snapshot();
create index task_kpi_history on public.task_completion_history(created_at,task_id) where action in ('Publish','Approve');
do $$declare definition text;begin
 select pg_get_functiondef('public.save_hr_policy(jsonb)'::regprocedure) into definition;
 if position('''report_discipline'')' in definition)=0 then raise exception 'Policy KPI validator changed';end if;
 definition:=replace(definition,'''report_discipline'')','''report_discipline'',''on_time_task'')');execute definition;
end$$;
alter function portal_private.hr_month(uuid,date) rename to hr_month_before_task_history;
create function portal_private.hr_month(p_user uuid,p_month date) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare data jsonb;sources jsonb;metrics jsonb;total integer;missing integer;on_time integer;score numeric:=0;coverage numeric:=0;w record;band jsonb;bonus numeric;basic numeric;begin
 data:=portal_private.hr_month_before_task_history(p_user,p_month);
 select coalesce(jsonb_agg(jsonb_build_object('task_id',task_id,'history_id',id,'reviewed_at',created_at,'basis',snapshot->'performance_basis') order by task_id),'[]') into sources from
 (select distinct on(task_id) * from public.task_completion_history where action in ('Publish','Approve') and snapshot->>'technician_id'=p_user::text and (created_at at time zone 'Asia/Karachi')::date>=p_month and (created_at at time zone 'Asia/Karachi')::date<p_month+interval '1 month' order by task_id,created_at desc,id desc) h;
 select count(*),count(*) filter(where x->'basis'->>'deadline' is null or x->'basis'->>'submitted_at' is null),count(*) filter(where ((x->'basis'->>'submitted_at')::timestamptz at time zone 'Asia/Karachi')::date<=(x->'basis'->>'deadline')::date) into total,missing,on_time from jsonb_array_elements(sources) x;
 metrics:=(data->'metrics')||jsonb_build_object('on_time_task',case when total>0 and missing=0 then round(on_time::numeric/total*100,2) end);
 for w in select key,(value#>>'{}')::numeric weight from jsonb_each(data->'policy'->'weights') loop
 if metrics->>w.key is not null then score:=score+w.weight*(metrics->>w.key)::numeric/100;coverage:=coverage+w.weight;end if;end loop;
 if coverage<>100 then score:=null;end if;
 select x into band from jsonb_array_elements(data->'policy'->'bonus_slabs') x where (x->>'score')::numeric<=score order by (x->>'score')::numeric desc limit 1;
 basic:=(data->>'salary')::numeric;
 bonus:=case when score is null then null when band is null then 0 when band->>'mode'='Salary percent' then round(basic*(band->>'amount')::numeric/100,2) else (band->>'amount')::numeric end;
 return data||jsonb_build_object('metrics',metrics,'score',round(score,2),'coverage',coverage,'bonus',bonus,'bonus_basis',jsonb_build_object('band',band,'salary_base',basic,'base_description','Prorated basic salary before deductions; excludes overtime and TADA'),'gross_salary_summary',basic+(data->>'overtime_pay')::numeric+bonus,'projected_net_before_manual_deductions',basic+(data->>'overtime_pay')::numeric+bonus-coalesce((data->>'automatic_deductions')::numeric,0),'historical_task_sources',sources,'historical_task_completed',total,'historical_task_missing',missing,'historical_task_note','Latest approved/published completion per task in this review month. On-time means submission by the deadline captured at submission, using Pakistan calendar dates. Reassignment, later deadline edits and reopening do not rewrite prior review evidence. Legacy reviews or missing deadlines leave this metric unknown. Direct Done edits without reviewed completion are excluded.');
end$$;
revoke all on function portal_private.task_performance_snapshot(),portal_private.hr_month(uuid,date),portal_private.hr_month_before_task_history(uuid,date) from public,anon,authenticated;
commit;
