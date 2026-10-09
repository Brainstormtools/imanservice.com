begin;
-- Legacy bands without a mode continue to mean fixed PKR amounts.
create or replace function public.save_hr_policy(p_data jsonb) returns uuid language plpgsql security definer set search_path='' as $$declare result_id uuid;weights jsonb:=p_data->'weights';slabs jsonb:=p_data->'bonus_slabs';r text:=coalesce(p_data->>'role_id','default');begin
 if not public.is_admin() then raise exception 'Administrator policy configuration required';end if;
 if r<>'default' and not exists(select 1 from public.crm_roles where crm_roles.id=r and active) then raise exception 'Choose active role or default';end if;
 if jsonb_typeof(weights) is distinct from 'object' or weights is null or exists(select 1 from jsonb_each(weights) x where x.key not in ('attendance','punctuality','task_completion','billable_utilisation','report_discipline') or jsonb_typeof(x.value)<>'number' or (x.value#>>'{}')::numeric not between 0 and 100) or coalesce((select sum((value#>>'{}')::numeric) from jsonb_each(weights)),0)<>100 then raise exception 'Supported KPI weights must total 100';end if;
 if slabs is null or jsonb_typeof(slabs) is distinct from 'array' or jsonb_array_length(slabs)>20 or exists(select 1 from jsonb_array_elements(slabs) x where jsonb_typeof(x->'score') is distinct from 'number' or jsonb_typeof(x->'amount') is distinct from 'number' or (x->>'score')::numeric not between 0 and 100 or (x->>'amount')::numeric not between 0 and 100000000 or coalesce(x->>'mode','Fixed amount') not in ('Fixed amount','Salary percent') or (x->>'mode'='Salary percent' and (x->>'amount')::numeric>100) or round((x->>'amount')::numeric,2)<>(x->>'amount')::numeric) or (select count(*) from jsonb_array_elements(slabs))<>(select count(distinct (x->>'score')::numeric) from jsonb_array_elements(slabs) x) then raise exception 'Unique bonus thresholds and bounded amounts required (salary percentage 0–100)';end if;
 if exists(select 1 from jsonb_array_elements_text(coalesce(p_data->'holidays','[]')) x where not isfinite(x.value::date)) or round((p_data->>'ot_rate')::numeric,2)<>(p_data->>'ot_rate')::numeric or length(trim(coalesce(p_data->>'reason',''))) not between 3 and 2000 then raise exception 'Policy reason required';end if;
 insert into public.hr_policies(role_id,effective_on,shift_start,shift_end,grace_minutes,half_day_minutes,off_days,holidays,ot_mode,ot_rate,off_multiplier,holiday_multiplier,weights,bonus_slabs,reason,created_by) values(r,(p_data->>'effective_on')::date,(p_data->>'shift_start')::time,(p_data->>'shift_end')::time,(p_data->>'grace_minutes')::integer,(p_data->>'half_day_minutes')::integer,array(select value::integer from jsonb_array_elements_text(p_data->'off_days')),array(select value::date from jsonb_array_elements_text(coalesce(p_data->'holidays','[]'))),p_data->>'ot_mode',(p_data->>'ot_rate')::numeric,(p_data->>'off_multiplier')::numeric,(p_data->>'holiday_multiplier')::numeric,weights,slabs,trim(p_data->>'reason'),auth.uid()) returning hr_policies.id into result_id;return result_id;
end$$;

alter function portal_private.hr_month(uuid,date) rename to hr_month_before_bonus_modes;
create function portal_private.hr_month(p_user uuid,p_month date) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare data jsonb;band jsonb;bonus numeric;basic numeric;begin
 data:=portal_private.hr_month_before_bonus_modes(p_user,p_month);
 basic:=(data->>'salary')::numeric;
 select x into band from jsonb_array_elements(data->'policy'->'bonus_slabs') x
 where (x->>'score')::numeric<=(data->>'score')::numeric order by (x->>'score')::numeric desc limit 1;
 if data->>'score' is null then bonus:=null;
 elsif band is null then bonus:=0;
 elsif band->>'mode'='Salary percent' then bonus:=round(basic*(band->>'amount')::numeric/100,2);
 else bonus:=(band->>'amount')::numeric;end if;
 return data||jsonb_build_object('bonus',bonus,'bonus_basis',jsonb_build_object('band',band,'salary_base',basic,'base_description','Prorated basic salary before deductions; excludes overtime and TADA'),
 'gross_salary_summary',basic+(data->>'overtime_pay')::numeric+bonus,
 'projected_net_before_manual_deductions',basic+(data->>'overtime_pay')::numeric+bonus-coalesce((data->>'automatic_deductions')::numeric,0));
end$$;
revoke all on function portal_private.hr_month(uuid,date),portal_private.hr_month_before_bonus_modes(uuid,date) from public,anon,authenticated;
commit;
