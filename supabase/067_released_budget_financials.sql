begin;
-- Private aggregation exposes no cost lines, archived source, actor or review identity.
create function portal_private.released_budget_costs(p_project uuid,p_sale uuid,p_currency text)
returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('count',count(*),'cost',coalesce(sum((snapshot->>'total_cost')::numeric),0),
  'Material',coalesce(sum((snapshot->'block_totals'->>'Material')::numeric),0),
  'Labour',coalesce(sum((snapshot->'block_totals'->>'Labour')::numeric),0),
  'Inventory',coalesce(sum((snapshot->'block_totals'->>'Inventory')::numeric),0),
  'TADA',coalesce(sum((snapshot->'block_totals'->>'TADA')::numeric),0))
 from (
  select distinct on(r.draft_id) r.snapshot
  from public.crm_project_budget_reviews r
  join public.crm_project_budget_drafts d on d.id=r.draft_id
  join public.crm_project_budget_reviews reviewed on reviewed.id=r.review_id
  where r.action='Released' and r.project_id=p_project and d.project_id=p_project and d.sale_id=p_sale and d.currency=p_currency
   and reviewed.action='Reviewed' and reviewed.draft_id=r.draft_id and reviewed.project_id=r.project_id
   and reviewed.draft_version=r.draft_version and reviewed.sequence<r.sequence and reviewed.snapshot=r.snapshot
   and r.snapshot->>'id'=d.id::text and r.snapshot->>'offer_id'=d.offer_id::text
   and r.snapshot->>'project_id'=p_project::text and r.snapshot->>'sale_id'=p_sale::text
   and r.snapshot->>'currency'=p_currency and (r.snapshot->>'version')::integer=r.draft_version
  order by r.draft_id,r.sequence desc
 ) latest;
$$;
revoke all on function portal_private.released_budget_costs(uuid,uuid,text) from public,anon,authenticated;

-- Keep the existing report's independent authority, PKR and recorded-cost checks.
alter function public.project_financials(uuid) set schema portal_private;
alter function portal_private.project_financials(uuid) rename to project_financials_before_released_budget;
revoke all on function portal_private.project_financials_before_released_budget(uuid) from public,anon,authenticated;
create function public.project_financials(p_project uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare base jsonb;added jsonb;s public.crm_sales;planned numeric;material numeric;labour numeric;recorded numeric;net numeric;
begin
 base:=portal_private.project_financials_before_released_budget(p_project);
 select * into s from public.crm_sales where project_id=p_project;
 added:=portal_private.released_budget_costs(p_project,s.id,base->>'currency');
 planned:=(base->>'planned_cost')::numeric+(added->>'cost')::numeric;
 material:=(base->>'planned_material')::numeric+(added->>'Material')::numeric;
 labour:=(base->>'planned_labour')::numeric+(added->>'Labour')::numeric;
 recorded:=(base->>'recorded_cost')::numeric;net:=(base->>'contract_net')::numeric;
 return base||jsonb_build_object(
  'baseline_planned_cost',base->'planned_cost','baseline_planned_material',base->'planned_material','baseline_planned_labour',base->'planned_labour',
  'released_budget_count',added->'count','released_additional_cost',added->'cost',
  'released_additional_material',added->'Material','released_additional_labour',added->'Labour',
  'released_additional_inventory',added->'Inventory','released_additional_tada',added->'TADA',
  'planned_cost',planned,'planned_material',material,'planned_labour',labour,
  'remaining_against_recorded',planned-recorded,
  'recorded_utilisation_percent',case when planned>0 then round(recorded/planned*100,2) end,
  'planned_profit',net-planned,'budget_basis','Original conversion budget plus the latest released additional-scope cost version per accepted offer.',
  'contract_revision_pending',true,'procurement_budget_integration_pending',true,
  'note',replace(base->>'note','budget revisions remain pending','other budget revisions remain pending')||' Financial planned costs include only the latest frozen Released cost snapshot per additional offer; later draft/review/return actions do not replace a release. Missing original budget values remain unknown. Contract/revenue metrics retain the original sale basis; additional selling values and contract revisions are not included. Procurement limits/material-request generation, product cost allocation and tax/charge integration remain pending.');
end$$;
revoke all on function public.project_financials(uuid) from public,anon;
grant execute on function public.project_financials(uuid) to authenticated;
commit;
