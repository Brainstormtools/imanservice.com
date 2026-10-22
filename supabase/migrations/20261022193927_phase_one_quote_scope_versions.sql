-- Preserve existing product-edit authority/accepted locks; invalidate stale draft quotes on scope status changes.
do $$
declare definition text;guard text:=$needle$update public.crm_product_lines set owner_id=p_owner$needle$;after_write text:=$needle$update public.crm_deals set version=version+1,last_activity_at=now() where id=l.deal_id;$needle$;
begin
 definition:=pg_get_functiondef('public.save_crm_product_line(uuid,integer,uuid,numeric,boolean,boolean,boolean,text,text)'::regprocedure);
 if position('Actual product status change reason required' in definition)>0 then raise exception 'Product-scope quote guard is already applied; do not reapply';end if;
 if position(guard in definition)=0 or position(after_write in definition)=0 then raise exception 'Unexpected product-save definition; inspect current source before applying';end if;
 definition:=replace(definition,guard,$body$
perform 1 from public.profiles where id=auth.uid() and active and role in ('admin','team') for share;if not found then raise exception 'Active product-edit account required';end if;
perform 1 from public.crm_board_memberships where user_id=auth.uid() order by board_id for share;
perform 1 from public.crm_memberships where user_id=auth.uid() order by role_id,team_id for share;
perform 1 from public.crm_roles order by id for share;
perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id=auth.uid()) order by id for share;
if not portal_private.deal_access(l.deal_id) or not(portal_private.deal_edit(l.deal_id) or (portal_private.crm_permission('product.own') and portal_private.board_access(l.board_id))) then raise exception 'Current product authority required after waiting';end if;
if p_status='Dropped' and trim(coalesce(p_reason,'')) is distinct from l.drop_reason and not portal_private.deal_edit(l.deal_id) then raise exception 'Commercial owner controls dropped-product reasons';end if;
if p_status is distinct from l.status then
 if length(trim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'Actual product status change reason required';end if;
 if exists(select 1 from public.crm_quote_publications where deal_id=d.id and status='Published') then raise exception 'Withdraw the current published quotation before changing product status';end if;
 if p_status='Active' then
  perform 1 from public.crm_boards b join public.crm_board_stages s on s.board_id=b.id and s.code=d.stage and s.active where b.id=l.board_id and b.active for share of b,s;
  if not found then raise exception 'Restored product board must support the current shared stage';end if;
 end if;
end if;
update public.crm_product_lines set owner_id=p_owner$body$);
 definition:=replace(definition,after_write,after_write||$body$
if p_status is distinct from l.status then
 update public.crm_quotes set version=version+1 where deal_id=d.id;
 insert into public.crm_quote_history(deal_id,quote_id,action,actor_id) select d.id,id,'Product status changed; review actual draft BOQ',auth.uid() from public.crm_quotes where deal_id=d.id;
end if;
if p_status is distinct from l.status or (p_status='Dropped' and trim(coalesce(p_reason,'')) is distinct from l.drop_reason) then
 insert into portal_private.crm_product_scope_history(request_id,deal_id,actor_id,payload,before_value,after_value,new_line_id,reason)
 values(gen_random_uuid(),d.id,auth.uid(),jsonb_build_object('mode','Status','line',l.id,'version',l.version,'status',p_status),jsonb_build_object('deal',to_jsonb(d),'source',to_jsonb(l)),jsonb_build_object('deal_version',d.version+1,'source',(select to_jsonb(x) from public.crm_product_lines x where id=l.id),'quotes',coalesce((select jsonb_agg(jsonb_build_object('id',id,'version',version)) from public.crm_quotes where deal_id=d.id),'[]')),l.id,trim(p_reason));
end if;
$body$);
 execute definition;
 definition:=pg_get_functiondef('portal_private.quote_calculation(uuid)'::regprocedure);
 guard:=$duplicate$if exists(select 1 from public.crm_quote_lines where quote_id=p_quote group by product_line_id,block,lower(description),unit having count(*)>1) then$duplicate$;
 if position(guard in definition)=0 then raise exception 'Unexpected quotation duplicate-warning definition; inspect current source before applying';end if;
 definition:=replace(definition,guard,$duplicate$if exists(select 1 from public.crm_quote_lines l join public.crm_product_lines p on p.id=l.product_line_id where l.quote_id=p_quote and p.status='Active' group by l.product_line_id,l.block,lower(trim(l.description)),l.unit having count(*)>1) or exists(select 1 from public.crm_quote_lines l join public.crm_product_lines p on p.id=l.product_line_id where l.quote_id=p_quote and p.status='Active' and l.catalog_id is not null group by l.product_line_id,l.block,l.catalog_id having count(*)>1) then$duplicate$);
 definition:=replace(definition,'Duplicate BOQ descriptions in a product section','Duplicate BOQ items in an active product section');
 execute definition;
 definition:=pg_get_functiondef('public.save_crm_deal(uuid,integer,text,numeric,date,timestamptz,text,text,date)'::regprocedure);
 guard:=$dealguard$select * into old from public.crm_deals where id=p_id for update;$dealguard$;
 if position(guard in definition)=0 then raise exception 'Unexpected Deal-save definition; inspect current source before applying';end if;
 definition:=replace(definition,guard,guard||$dealguard$
if old.id is null then raise exception 'Deal unavailable';end if;
perform 1 from public.profiles where id=auth.uid() and active and role in ('admin','team') for share;if not found then raise exception 'Active sales account required after waiting';end if;
perform 1 from public.crm_board_memberships where user_id=auth.uid() order by board_id for share;
perform 1 from public.crm_memberships where user_id=auth.uid() order by role_id,team_id for share;
perform 1 from public.crm_roles order by id for share;
perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id=auth.uid()) order by id for share;
if not portal_private.deal_edit(p_id) then raise exception 'Current Deal authority required after waiting';end if;
$dealguard$);
 execute definition;
end$$;
