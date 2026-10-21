begin;
-- Read-only composition: existing original-quote and four-family cost eligibility
-- remains authoritative. EXISTS prevents repeated quote items multiplying a split.
create function public.finance_product_reference_coverage(p_project uuid)
returns jsonb language plpgsql stable security invoker set search_path='' as $$
declare revenue jsonb;register jsonb;s jsonb;l jsonb;frozen jsonb;source_rows jsonb:='[]';segments jsonb:='[]';office jsonb:='[]';
 scoped numeric;position integer;matched boolean;coverage text;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Active Accounts permission required';end if;
 revenue:=public.finance_original_product_revenue_reference(p_project);
 register:=public.finance_classified_cost_register();
 for s in select value from jsonb_array_elements(register->'sources') loop
  if s->>'source_kind'='Office' then
   select coalesce(sum((v->>'amount')::numeric),0) into scoped from jsonb_array_elements(s->'lines') v where v->'workstream_snapshot'->>'project_id'=p_project::text;
   if not exists(select 1 from jsonb_array_elements(s->'lines') v where v->'workstream_snapshot'->>'project_id'=p_project::text) then continue;end if;
   office:=office||jsonb_build_array(jsonb_build_object('source_id',s->'source_id','source_number',s->'source_number','selected_project_slices',scoped,'other_target_slices',(s->>'allocated_amount')::numeric-scoped,'general_office_remainder',s->'unallocated_amount','source_amount_context_only',s->'source_amount','application_id',s->'application_id'));
  elsif s->>'source_project_id'=p_project::text then scoped:=(s->>'source_amount')::numeric;
  else continue;end if;
  source_rows:=source_rows||jsonb_build_array(jsonb_build_object('source_kind',s->'source_kind','source_id',s->'source_id','source_number',s->'source_number','source_project_id',s->'source_project_id','source_project',s->'source_project','category',s->'category','scoped_amount',scoped,'application_id',s->'application_id','classification_state',s->'classification_state'));
  position:=0;
  for l in select value from jsonb_array_elements(s->'lines') loop
   position:=position+1;frozen:=l->'workstream_snapshot';
   if s->>'source_kind'='Office' and frozen->>'project_id' is distinct from p_project::text then continue;end if;
   matched:=frozen->>'project_id'=p_project::text and exists(select 1 from jsonb_array_elements(revenue->'items') r where r->>'workstream_id'=l->>'workstream_id' and r->>'product_line_id'=frozen->>'product_line_id');
   coverage:=case when coalesce(matched,false) then 'Original revenue and cost identity matched' else 'No matching original revenue identity' end;
   segments:=segments||jsonb_build_array(jsonb_build_object('source_kind',s->'source_kind','source_id',s->'source_id','source_number',s->'source_number','source_project_id',s->'source_project_id','category',s->'category','application_id',s->'application_id','classification_state',s->'classification_state','position',position,'amount',l->'amount','workstream_id',l->'workstream_id','product_line_id',frozen->'product_line_id','target_project_id',frozen->'project_id','frozen_product',frozen->'product_name','coverage_state',coverage));
  end loop;
  -- Project-source remainders belong to the source project, never a product.
  -- General-office remainders remain context only, never assigned to this project.
  if s->>'source_kind'<>'Office' and (s->>'unallocated_amount')::numeric<>0 then
   segments:=segments||jsonb_build_array(jsonb_build_object('source_kind',s->'source_kind','source_id',s->'source_id','source_number',s->'source_number','source_project_id',s->'source_project_id','category',s->'category','application_id',s->'application_id','classification_state',s->'classification_state','position',0,'amount',s->'unallocated_amount','workstream_id',null,'product_line_id',null,'target_project_id',p_project,'frozen_product',null,'coverage_state','Unallocated source cost'));
  end if;
 end loop;
 return jsonb_build_object('project_id',p_project,'project',revenue->'project','currency','PKR','as_of',statement_timestamp(),'business_date',(statement_timestamp() at time zone 'Asia/Karachi')::date,'timezone','Asia/Karachi','original_reference',revenue,'cost_sources',source_rows,'cost_segments',segments,'office_context',office,'basis','Read-only evidence coverage, not revenue recognition, cost completeness or profit. Original accepted quotation references and existing Expense/Labour/Stock/Office cost families remain separate. Match by exact workstream/product/target-project identities, never labels; repeated quote items do not multiply cost splits. Project-source remainders stay unallocated. Office includes only current eligible slices targeting this project; General office remainders and other targets are context only. Stale Office splits with no eligible current target remain in the General office register, not project evidence. Additional BOQ/contract references, tax/WHT, invoices, cash, vendor liabilities and project recorded totals are not added. No automatic distribution or business record changes.');
end$$;
revoke all on function public.finance_product_reference_coverage(uuid) from public,anon;
grant execute on function public.finance_product_reference_coverage(uuid) to authenticated;
notify pgrst,'reload schema';
commit;
