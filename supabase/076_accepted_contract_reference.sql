begin;
-- Numeric reference values only: this helper exposes no wording, private cost, actor or source identity.
create function portal_private.accepted_contract_reference(p_project uuid,p_sale uuid,p_currency text)
returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('count',count(*),'subtotal',coalesce(sum((source->>'subtotal')::numeric),0),
  'quoted_tax',coalesce(sum((source->>'tax_total')::numeric),0),'total',coalesce(sum((source->>'total')::numeric),0),
  'quoted_wht',coalesce(sum((source->>'wht_total')::numeric),0),'receivable',coalesce(sum((source->>'receivable')::numeric),0))
 from (
  select distinct on(d.offer_id) e.snapshot->'commercial_source' source
  from public.crm_project_contract_decisions e
  join public.crm_project_contract_publications p on p.id=e.publication_id
  join public.crm_project_contract_drafts d on d.id=p.draft_id
  join public.crm_boq_offer_publications b on b.id=d.offer_id
  join public.crm_sales s on s.id=d.sale_id
  join public.projects project on project.id=p.project_id
  where e.action='Accepted' and e.consent and p.status='Accepted' and p.version=e.publication_version+1
   and e.project_id=p_project and p.project_id=p_project and d.project_id=p_project and s.project_id=p_project
   and d.sale_id=p_sale and d.currency=p_currency and p.currency=p_currency and s.currency=p_currency and b.currency=p_currency
   and b.status='Accepted' and b.consent and b.version=(d.source_snapshot->>'version')::integer
   and b.project_id=p_project and p.offer_id=b.id
   and e.company_id=p.company_id and p.company_id=b.company_id and b.company_id=s.company_id and project.company_id=s.company_id
   and e.snapshot->>'status'='Published' and (e.snapshot->>'version')::integer=e.publication_version
   and e.snapshot->>'id'=p.id::text and e.snapshot->>'project_id'=p_project::text
   and e.snapshot->>'company_id'=p.company_id::text and e.snapshot->>'offer_id'=b.id::text
   and e.snapshot->>'currency'=p_currency and (e.snapshot->>'draft_version')::integer=p.draft_version
   and e.snapshot->'commercial_source'=p.commercial_source
   and (e.snapshot->'commercial_source'->>'subtotal')::numeric=b.subtotal
   and (e.snapshot->'commercial_source'->>'tax_total')::numeric=b.tax_total
   and (e.snapshot->'commercial_source'->>'total')::numeric=b.total
   and (e.snapshot->'commercial_source'->>'wht_total')::numeric=b.wht_total
   and (e.snapshot->'commercial_source'->>'receivable')::numeric=b.receivable
  order by d.offer_id,p.draft_version desc,e.created_at desc,e.id
 ) latest;
$$;
revoke all on function portal_private.accepted_contract_reference(uuid,uuid,text) from public,anon,authenticated;

-- Preserve the independent existing Accounts/assigned-manager authority, PKR, cost, invoice and original contract basis.
alter function public.project_financials(uuid) set schema portal_private;
alter function portal_private.project_financials(uuid) rename to project_financials_before_contract_reference;
revoke all on function portal_private.project_financials_before_contract_reference(uuid) from public,anon,authenticated;
create function public.project_financials(p_project uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare base jsonb;reference jsonb;s public.crm_sales;
begin
 base:=portal_private.project_financials_before_contract_reference(p_project);
 select * into s from public.crm_sales where project_id=p_project;
 reference:=portal_private.accepted_contract_reference(p_project,s.id,base->>'currency');
 return base||jsonb_build_object(
  'accepted_contract_reference_count',reference->'count','accepted_contract_reference_subtotal',reference->'subtotal',
  'accepted_contract_reference_quoted_tax',reference->'quoted_tax','accepted_contract_reference_total',reference->'total',
  'accepted_contract_reference_quoted_wht',reference->'quoted_wht','accepted_contract_reference_receivable',reference->'receivable',
  'accepted_contract_reference_applied',false,
  'accepted_contract_reference_basis','Reference only: latest client-Accepted fixed contract proposal per accepted additional BOQ offer; no operative revenue or profit application.',
  'note',(base->>'note')||' Accepted additional contract reference values are shown separately, counted once per offer from the latest Accepted fixed publication. Later private drafts or Declined proposals do not replace an earlier acceptance. These quoted subtotal/tax/gross/WHT/receivable references are not operative revenue, tax accounting, amounts due or additional invoice totals; original contract/profit calculations remain unchanged pending an explicit operative contribution model.');
end$$;
revoke all on function public.project_financials(uuid) from public,anon;
grant execute on function public.project_financials(uuid) to authenticated;
notify pgrst,'reload schema';
commit;
