begin;
-- Original accepted quoted amounts only. No operative BOQ adoption or profit.
create function public.finance_original_product_revenue_reference(p_project uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare p public.projects;s public.crm_sales;b public.crm_quote_publications;budget public.crm_quote_budgets;
 result jsonb;rows jsonb:='[]';materials jsonb:='[]';expected jsonb:='[]';item jsonb;line jsonb;quote jsonb;
 n integer:=0;material_count integer;source_total numeric:=0;material_total numeric:=0;mapped numeric:=0;unattributed numeric:=0;
 unit_price numeric;amount numeric;mapping_ok boolean:=false;valid_items boolean:=true;
 stream uuid;product uuid;line_id uuid;state text;mapping_issue text:='Frozen publication/budget mapping unavailable';
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Active Accounts permission required';end if;
 select * into p from public.projects where id=p_project;
 if p.id is null or portal_private.finance_project_currency(p.id) is distinct from 'PKR' then raise exception 'Existing PKR project required';end if;
 result:=jsonb_build_object('project_id',p.id,'project',p.title,'currency','PKR','as_of',statement_timestamp(),'business_date',(statement_timestamp() at time zone 'Asia/Karachi')::date,'timezone','Asia/Karachi','source_state','Original accepted quotation unavailable','mapping_basis','No product attribution established','sale_id',null,'publication_id',null,'publication_number',null,'publication_revision',null,'publication_version',null,'original_subtotal',null,'item_subtotal',null,'mapped_subtotal',null,'unattributed_subtotal',null,'items','[]'::jsonb,'basis','Reference only: original accepted quotation before quoted tax. Product mapping requires exact frozen publication/budget calculation and current original-sale workstream identities. Commercial adjustment and unresolved mapping remain unattributed. Additional BOQ/contract references, invoices, receipts, tax/WHT accounting, costs and profit are excluded. No source or project financial total is changed.');
 select * into s from public.crm_sales where project_id=p.id;
 select * into b from public.crm_quote_publications where id=s.publication_id and status='Accepted' and company_id=s.company_id and company_id=p.company_id and deal_id=s.deal_id and currency='PKR' and currency=s.currency and total=s.total;
 if b.id is null then return result;end if;
 result:=result||jsonb_build_object('sale_id',s.id,'publication_id',b.id,'publication_number',b.number,'publication_revision',b.revision,'publication_version',b.version,'original_subtotal',b.subtotal);
 -- An unavailable or malformed item source is not a zero-price quotation.
 if jsonb_typeof(b.items) is distinct from 'array' or jsonb_array_length(b.items)=0 then
  return result||jsonb_build_object('source_state','Original quoted items require reconciliation');
 end if;
 for item in select value from jsonb_array_elements(b.items) loop
  if jsonb_typeof(item) is distinct from 'object' or jsonb_typeof(item->'product') is distinct from 'string' or jsonb_typeof(item->'description') is distinct from 'string' or jsonb_typeof(item->'unit') is distinct from 'string'
   or coalesce(item->>'quantity','')!~'^[0-9]+([.][0-9]{1,3})?$' or coalesce(item->>'unit_price','')!~'^-?[0-9]+([.][0-9]{1,2})?$' or coalesce(item->>'total','')!~'^-?[0-9]+([.][0-9]{1,2})?$' then valid_items:=false;exit;end if;
  begin
   if (item->>'quantity')::numeric<=0 or (item->>'quantity')::numeric>100000 or round((item->>'quantity')::numeric*(item->>'unit_price')::numeric,2) is distinct from (item->>'total')::numeric then valid_items:=false;exit;end if;
   source_total:=source_total+(item->>'total')::numeric;
  exception when invalid_text_representation or numeric_value_out_of_range then valid_items:=false;exit;end;
 end loop;
 if not valid_items or source_total is distinct from b.subtotal then
  return result||jsonb_build_object('source_state','Original quoted items require reconciliation');
 end if;
 -- Reproduce the existing migration-016 publication algorithm, using frozen data
 -- only. Neither current product labels nor mutable quote lines establish mapping.
 select * into budget from public.crm_quote_budgets where publication_id=b.id;
 if budget.publication_id is not null and budget.snapshot=s.planned_budget
  and budget.snapshot->'calculation'->'client_items'=b.items
  and jsonb_typeof(budget.snapshot->'lines')='array'
  and budget.snapshot->'lines'=budget.snapshot->'calculation'->'internal_items'
  and budget.snapshot->'quote'->>'id'=b.quote_id::text
  and budget.snapshot->'quote'->>'deal_id'=s.deal_id::text
  and budget.snapshot->'quote'->>'currency'='PKR' then
  begin
   quote:=budget.snapshot->'quote';
   select coalesce(jsonb_agg(value order by ord),'[]'::jsonb) into materials from jsonb_array_elements(budget.snapshot->'lines') with ordinality as v(value,ord) where value->>'block'='Material';
   material_count:=jsonb_array_length(materials);
   if material_count=0 or exists(select 1 from jsonb_array_elements(materials) m group by m->>'id' having count(*)>1) then raise invalid_parameter_value;end if;
   for line in select value from jsonb_array_elements(materials) loop
    if line->>'quote_id' is distinct from b.quote_id::text or jsonb_typeof(line->'product_name') is distinct from 'string'
     or coalesce(line->>'id','')!~*'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     or coalesce(line->>'product_line_id','')!~*'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     or (line->>'quantity')::numeric<=0 or (line->>'unit_cost')::numeric<0
     or coalesce((line->>'margin')::integer,(quote->>'default_margin')::integer) not between 5 and 85
     or coalesce((line->>'margin')::integer,(quote->>'default_margin')::integer)%5<>0 then raise invalid_parameter_value;end if;
    if line->>'quantity' is null or line->>'unit_cost' is null or coalesce(line->>'margin',quote->>'default_margin') is null then raise invalid_parameter_value;end if;
    unit_price:=round((line->>'unit_cost')::numeric/(1-coalesce((line->>'margin')::integer,(quote->>'default_margin')::integer)::numeric/100),2);
    amount:=round((line->>'quantity')::numeric*unit_price,2);material_total:=material_total+amount;
    expected:=expected||jsonb_build_array(jsonb_build_object('product',line->>'product_name','description',line->>'description','unit',line->>'unit','quantity',(line->>'quantity')::numeric,'unit_price',unit_price,'total',amount));
   end loop;
   if quote->>'override_total' is not null then
    if (quote->>'override_total')::numeric is distinct from b.total then raise invalid_parameter_value;end if;
    expected:=expected||jsonb_build_array(jsonb_build_object('product','Commercial adjustment','description','Agreed price adjustment','unit','job','quantity',1,'unit_price',b.subtotal-material_total,'total',b.subtotal-material_total));
   end if;
   if expected is distinct from b.items then raise invalid_parameter_value;end if;
   mapping_ok:=true;mapping_issue:='Exact frozen migration-016 publication calculation reproduced';
  exception when invalid_text_representation or numeric_value_out_of_range or division_by_zero or invalid_parameter_value then
   mapping_ok:=false;materials:='[]';mapping_issue:='Frozen publication/budget calculation does not establish product mapping';
  end;
 end if;
 for item in select value from jsonb_array_elements(b.items) loop
  n:=n+1;stream:=null;product:=null;line_id:=null;state:=mapping_issue;
  if mapping_ok and n<=jsonb_array_length(materials) then
   line:=materials->(n-1);product:=(line->>'product_line_id')::uuid;line_id:=(line->>'id')::uuid;
   select w.id into stream from public.crm_project_workstreams w join public.crm_product_lines pl on pl.id=w.product_line_id
    where w.sale_id=s.id and w.project_id=p.id and w.product_line_id=product and pl.deal_id=s.deal_id;
   state:=case when stream is not null then 'Mapped from exact frozen source' else 'Original-sale workstream unavailable; unattributed' end;
  elsif mapping_ok then state:='Commercial adjustment; unattributed';end if;
  amount:=(item->>'total')::numeric;
  if stream is null then unattributed:=unattributed+amount;else mapped:=mapped+amount;end if;
  rows:=rows||jsonb_build_array(jsonb_build_object('position',n,'product',item->>'product','description',item->>'description','unit',item->>'unit','quantity',item->'quantity','unit_price',item->'unit_price','amount',amount,'source_line_id',line_id,'product_line_id',product,'workstream_id',stream,'mapping_state',state));
 end loop;
 return result||jsonb_build_object('source_state','Original accepted quoted items available','mapping_basis',mapping_issue,'item_subtotal',source_total,'mapped_subtotal',mapped,'unattributed_subtotal',unattributed,'items',rows);
end$$;
revoke all on function public.finance_original_product_revenue_reference(uuid) from public,anon;
grant execute on function public.finance_original_product_revenue_reference(uuid) to authenticated;
notify pgrst,'reload schema';
commit;
