begin;
create function portal_private.material_approval_budget(p_project uuid)
returns numeric language plpgsql stable security definer set search_path='' as $$
declare s public.crm_sales;baseline numeric;added jsonb;
begin
 select * into s from public.crm_sales where project_id=p_project;
 select coalesce(sum((x->>'quantity')::numeric*(x->>'unit_cost')::numeric),0) into baseline
 from jsonb_array_elements(s.planned_budget->'lines') x where x->>'block'='Material';
 added:=portal_private.released_budget_costs(p_project,s.id,s.currency);
 return baseline+(added->>'Material')::numeric;
end$$;
revoke all on function portal_private.material_approval_budget(uuid) from public,anon,authenticated;
-- Replace only the original material-budget lookup; all approval guards remain intact.
do $$declare signature text;definition text;old_lookup text;begin
 foreach signature in array array['public.approve_supply_request(uuid,integer,text)','public.supply_order_action(uuid,integer,text,text)'] loop
  definition:=pg_get_functiondef(signature::regprocedure);
  old_lookup:=case when signature like '%approve_supply_request%' then
   'select coalesce(sum((x->>''quantity'')::numeric*(x->>''unit_cost'')::numeric),0) into budget from public.crm_sales s cross join lateral jsonb_array_elements(s.planned_budget->''lines'') x where s.project_id=req.project_id and x->>''block''=''Material'';'
  else
   'select coalesce(sum((x->>''quantity'')::numeric*(x->>''unit_cost'')::numeric),0) into budget from public.crm_sales ss cross join lateral jsonb_array_elements(ss.planned_budget->''lines'') x where ss.project_id=req.project_id and x->>''block''=''Material'';'
  end;
  if strpos(definition,old_lookup)=0 then raise exception 'Expected original material budget lookup missing in %',signature;end if;
  execute replace(definition,old_lookup,'budget:=portal_private.material_approval_budget(req.project_id);');
 end loop;
end$$;
do $$declare definition text;begin
 definition:=pg_get_functiondef('public.project_financials(uuid)'::regprocedure);
 if strpos(definition,'''procurement_budget_integration_pending'',true')=0 then raise exception 'Expected financial procurement marker missing';end if;
 definition:=replace(definition,'''procurement_budget_integration_pending'',true','''procurement_budget_integration_pending'',false,''additional_material_request_integration_pending'',true');
 definition:=replace(definition,'Procurement limits/material-request generation,','Additional catalogue-backed material-request generation,');
 execute definition;
end$$;
commit;
