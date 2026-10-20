begin;
-- Read-only composition of the four existing guarded reports. STABLE keeps all
-- nested reads in one statement snapshot; Office/project expense scopes cannot race.
-- No cross-family total, new cost recognition, distribution or profit policy.
create function public.finance_classified_cost_register()
returns jsonb language plpgsql stable security invoker set search_path='' as $$
declare sources jsonb;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Active Accounts permission required';end if;
 with costs as (
  select 'Expense'::text source_kind,e.expense_id source_id,e.expense_number source_number,e.project_id source_project_id,e.project source_project,e.category,e.expense_amount source_amount,e.allocated_amount,e.unallocated_amount,e.application_id,e.classification_state,e.lines from public.finance_expense_product_report() e
  union all
  select 'Labour',l.cost_id,l.cost_number,l.project_id,l.project,l.category,l.cost_amount,l.allocated_amount,l.unallocated_amount,l.application_id,l.classification_state,l.lines from public.finance_labour_product_report() l
  union all
  select 'Stock',s.project_id,s.project,s.project_id,s.project,s.category,s.stock_amount,s.allocated_amount,s.unallocated_amount,s.application_id,s.classification_state,s.lines from public.finance_stock_product_report() s
  union all
  select 'Office',o.expense_id,o.expense_number,null::uuid,'General office',o.category,o.expense_amount,o.allocated_amount,o.unallocated_amount,o.application_id,o.classification_state,o.lines from public.finance_office_product_report() o
 )
 select coalesce(jsonb_agg(to_jsonb(c) order by c.source_kind,c.source_project,c.source_number,c.source_id),'[]'::jsonb) into sources from costs c;
 return jsonb_build_object('sources',sources,'currency','PKR','as_of',statement_timestamp(),'business_date',(statement_timestamp() at time zone 'Asia/Karachi')::date,'timezone','Asia/Karachi','basis','Current existing Expense, Labour, Stock and Office classified-cost reports in one read snapshot. Each source appears once in its family. Applied splits and unallocated remainders retain existing eligibility and frozen evidence. Family subtotals are separate; no combined cost, revenue, profit, cash, commitment, vendor-liability or project-total calculation. Office sources remain General office even when manual splits target projects.');
end$$;
revoke all on function public.finance_classified_cost_register() from public,anon;
grant execute on function public.finance_classified_cost_register() to authenticated;
notify pgrst,'reload schema';
commit;
