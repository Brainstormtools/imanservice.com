begin;
-- Reject numeric values which cannot survive the portal JSON-number round trip unchanged. No rounding.
create or replace function public.save_crm_product_fields(p_line uuid,p_version integer,p_schema integer,p_values jsonb,p_reason text) returns void language plpgsql security definer set search_path='' set extra_float_digits=3 as $$
declare actor public.profiles;l public.crm_product_lines;d public.crm_deals;r portal_private.crm_product_field_registers;h portal_private.crm_product_field_history;f portal_private.crm_board_fields;e record;v_schema integer;merged jsonb;defs jsonb;
begin
 select * into actor from public.profiles where id=auth.uid() for share;
 select * into l from public.crm_product_lines where id=p_line;
 if actor.id is null or not actor.active or l.id is null or not portal_private.board_access(l.board_id) or not portal_private.deal_access(l.deal_id) then raise exception 'Current product board and Deal access required';end if;
 perform pg_advisory_xact_lock(hashtext('crm-board-fields:'||l.board_id));
 perform 1 from public.crm_boards where id=l.board_id and active for share;if not found then raise exception 'Current active board required';end if;
 select * into l from public.crm_product_lines where id=p_line for update;select * into d from public.crm_deals where id=l.deal_id for share;
 -- Recheck actual board/Deal authority after waiting for configuration/row locks.
 if not portal_private.board_access(l.board_id) or not portal_private.deal_access(l.deal_id) or l.status<>'Active' or d.stage in ('won','lost') or not exists(select 1 from public.crm_boards where id=l.board_id and active) or not (portal_private.deal_edit(l.deal_id) or portal_private.crm_permission('product.own')) then raise exception 'Current editable active product and open Deal required';end if;
 if p_version is null or p_schema is null or length(coalesce(trim(p_reason),'')) not between 3 and 1000 or jsonb_typeof(p_values) is distinct from 'object' or octet_length(p_values::text)>120000 then raise exception 'Exact current receipt/schema, bounded values and actual reason required';end if;
 select * into r from portal_private.crm_product_field_registers where product_line_id=p_line;
 select * into h from portal_private.crm_product_field_history where product_line_id=p_line order by version desc limit 1;
 if r.version=p_version+1 and h.schema_version=p_schema and h.submitted=p_values and h.actor_id=actor.id and h.reason=trim(p_reason) then return;end if;
 v_schema:=coalesce((select version from portal_private.crm_board_field_schemas where board_id=l.board_id),0);
 if coalesce(r.version,0)<>p_version or v_schema<>p_schema then raise exception 'Fields or values changed; reload the current exact schema and receipt';end if;
 for e in select * from jsonb_each(p_values) loop
  select * into f from portal_private.crm_board_fields where id::text=e.key and board_id=l.board_id and active;
  if f.id is null then raise exception 'Unknown, archived or other-board field submitted';end if;
  if f.kind='Text' and (jsonb_typeof(e.value)<>'string' or length(e.value#>>'{}')>2000) or f.kind='Number' and (jsonb_typeof(e.value)<>'number' or length(e.value::text)>50) or f.kind='Yes/No' and jsonb_typeof(e.value)<>'boolean' or f.kind in ('Date','Single choice') and jsonb_typeof(e.value)<>'string' then raise exception 'Field value must match its actual configured type';end if;
  if f.kind='Number' and (e.value::text)::numeric<>(((e.value::text)::double precision)::text)::numeric then raise exception 'Number would lose precision; use Text to preserve exact digits';end if;
  if f.kind='Date' and (e.value#>>'{}' !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or to_char((e.value#>>'{}')::date,'YYYY-MM-DD')<>e.value#>>'{}') then raise exception 'Actual ISO calendar date required';end if;
  if f.kind='Single choice' and not (f.options @> jsonb_build_array(e.value)) then raise exception 'Choose an actual configured option';end if;
 end loop;
 -- Replace only active values; retain archived current values and all immutable receipts.
 select coalesce(jsonb_object_agg(k,v),'{}'::jsonb) into merged from jsonb_each(coalesce(r.field_values,'{}')) old(k,v) where not exists(select 1 from portal_private.crm_board_fields where board_id=l.board_id and active and id::text=k);
 merged:=merged||p_values;select coalesce(jsonb_agg(to_jsonb(x) order by x.key),'[]'::jsonb) into defs from portal_private.crm_board_fields x where board_id=l.board_id;
 insert into portal_private.crm_product_field_registers(product_line_id,version,field_values) values(p_line,1,merged) on conflict(product_line_id) do update set version=crm_product_field_registers.version+1,field_values=excluded.field_values returning * into r;
 insert into portal_private.crm_product_field_history(product_line_id,version,schema_version,submitted,snapshot,actor_id,reason) values(p_line,r.version,v_schema,p_values,jsonb_build_object('fields',defs,'values',merged),actor.id,trim(p_reason));
end$$;
revoke all on function public.save_crm_product_fields(uuid,integer,integer,jsonb,text) from public,anon,authenticated,service_role;
grant execute on function public.save_crm_product_fields(uuid,integer,integer,jsonb,text) to authenticated;
commit;
