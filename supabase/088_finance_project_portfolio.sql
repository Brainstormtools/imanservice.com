begin;
create function public.finance_project_portfolio()
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare reports jsonb;excluded integer;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Active Accounts permission required';end if;
 select coalesce(jsonb_agg(public.project_financials(p.id) order by p.title,p.id),'[]'::jsonb) into reports from public.projects p where portal_private.finance_project_currency(p.id)='PKR';
 select count(*) into excluded from public.projects p where portal_private.finance_project_currency(p.id) is distinct from 'PKR';
 return jsonb_build_object('projects',reports,'currency','PKR','as_of',now(),'business_date',(now() at time zone 'Asia/Karachi')::date,'timezone','Asia/Karachi','excluded_currency_count',excluded,'basis','Current PKR project financial records, one row per eligible project. Missing source values remain unknown. Accepted additional quoted amounts are reference only. Profitability is provisional; unrecorded costs, operative office distribution, full tax treatment, historical actual-date variance and final financial settlement remain pending.');
end$$;
revoke all on function public.finance_project_portfolio() from public,anon;
grant execute on function public.finance_project_portfolio() to authenticated;
notify pgrst,'reload schema';
commit;
