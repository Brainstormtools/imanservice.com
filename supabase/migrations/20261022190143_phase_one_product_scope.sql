-- Explicit pre-Won product additions/moves retain the original product and BOQ history.
create table portal_private.crm_product_scope_history(request_id uuid primary key,deal_id uuid not null references public.crm_deals,actor_id uuid not null references public.profiles,payload jsonb not null,before_value jsonb not null,after_value jsonb not null,new_line_id uuid not null references public.crm_product_lines,reason text not null,created_at timestamptz not null default now());
create index crm_product_scope_deal on portal_private.crm_product_scope_history(deal_id);
create index crm_product_scope_actor on portal_private.crm_product_scope_history(actor_id);
create index crm_product_scope_line on portal_private.crm_product_scope_history(new_line_id);
alter table portal_private.crm_product_scope_history enable row level security;
revoke all on portal_private.crm_product_scope_history from public,anon,authenticated,service_role;
create trigger crm_product_scope_immutable before update or delete on portal_private.crm_product_scope_history for each row execute function portal_private.lead_api_evidence_immutable();
create function public.change_crm_product_scope(p_request uuid,p_deal uuid,p_version integer,p_data jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare d public.crm_deals;source public.crm_product_lines;target uuid;owner uuid;mode text;new_id uuid;old portal_private.crm_product_scope_history;payload jsonb;before_value jsonb;after_value jsonb;
begin
 perform 1 from public.profiles where id=auth.uid() and active and role in ('admin','team') for share;if not found or not portal_private.sales_user() then raise exception 'Active sales account required';end if;
 if p_request is null or length(trim(coalesce(p_reason,''))) not between 3 and 1000 or p_data is null or jsonb_typeof(p_data)<>'object' or (select count(*) from jsonb_object_keys(p_data))<>6 or not(p_data ?& array['mode','target_board','target_owner','target_value','source_line','source_version']) then raise exception 'Explicit actual product scope, snapshot and reason required';end if;
 mode:=p_data->>'mode';if mode is null or mode not in ('Add','Move') or coalesce(p_data->>'target_value','')!~'^[0-9]{1,12}(\.[0-9]{1,2})?$' then raise exception 'Choose Add/Move and enter an actual non-negative product estimate';end if;
 target:=(p_data->>'target_board')::uuid;owner:=nullif(p_data->>'target_owner','')::uuid;
 payload:=jsonb_build_object('deal',p_deal,'version',p_version,'data',p_data,'reason',p_reason);
 perform pg_advisory_xact_lock(hashtextextended('product-scope:'||p_request::text,0));
 select * into old from portal_private.crm_product_scope_history where request_id=p_request;
 if found then if old.actor_id<>auth.uid() or old.payload<>payload or not portal_private.deal_edit(old.deal_id) then raise exception 'Request reused or current scope authority unavailable';end if;return old.new_line_id;end if;
 select * into d from public.crm_deals where id=p_deal for update;
 if not found or not portal_private.deal_edit(d.id) then raise exception 'Current commercial Deal authority required';end if;
 if d.version is distinct from p_version then raise exception 'Deal changed. Refresh first';end if;
 if d.stage in ('won','lost') or exists(select 1 from public.crm_sales where deal_id=d.id) or exists(select 1 from public.crm_quote_publications where deal_id=d.id and status='Accepted') then raise exception 'Closed/accepted scope requires its separate change workflow';end if;
 if exists(select 1 from public.crm_quote_publications where deal_id=d.id and status='Published') then raise exception 'Withdraw the current published quotation before changing product scope';end if;
 perform 1 from public.crm_boards where id=target and active for share;if not found or not portal_private.board_access(target) then raise exception 'Actual active target board membership required';end if;
 perform 1 from public.crm_board_stages where board_id=target and code=d.stage and active for share;if not found then raise exception 'Target board must support the current shared stage';end if;
 if exists(select 1 from public.crm_product_lines where deal_id=d.id and board_id=target) then raise exception 'Target product already exists; use its existing reasoned product section controls';end if;
 if owner is not null then
  perform 1 from public.profiles where id=owner and active and role in ('admin','team') for share;if not found or not exists(select 1 from public.profiles where id=owner and role='admin') and not exists(select 1 from public.crm_board_memberships where board_id=target and user_id=owner) or not(portal_private.crm_user_permission(owner,'sales.own') or portal_private.crm_user_permission(owner,'sales.manage') or portal_private.crm_user_permission(owner,'product.own')) then raise exception 'Actual active target-board product owner required';end if;
 end if;
 if mode='Move' then
  select * into source from public.crm_product_lines where id=(p_data->>'source_line')::uuid and deal_id=d.id for update;
  if not found or source.status<>'Active' or source.version is distinct from (p_data->>'source_version')::integer or not portal_private.board_access(source.board_id) then raise exception 'Current active source product snapshot and board authority required';end if;
 elsif p_data->>'source_line' is not null or p_data->>'source_version' is not null then raise exception 'Add must not silently change another product';end if;
 perform 1 from public.crm_board_memberships where user_id=auth.uid() or user_id=owner order by board_id,user_id for share;
 perform 1 from public.crm_memberships where user_id=auth.uid() or user_id=owner order by user_id,role_id,team_id for share;
 perform 1 from public.crm_roles order by id for share;
 perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id=auth.uid() or user_id=owner) order by id for share;
 if not portal_private.deal_edit(d.id) or not portal_private.board_access(target) or (mode='Move' and not portal_private.board_access(source.board_id)) then raise exception 'Current Deal and product-board authority required after waiting';end if;
 if owner is not null and not exists(select 1 from public.profiles where id=owner and role='admin') and (not exists(select 1 from public.crm_board_memberships where board_id=target and user_id=owner) or not(portal_private.crm_user_permission(owner,'sales.own') or portal_private.crm_user_permission(owner,'sales.manage') or portal_private.crm_user_permission(owner,'product.own'))) then raise exception 'Current eligible product owner required';end if;
 before_value:=jsonb_build_object('deal',to_jsonb(d),'source',case when source.id is null then null else to_jsonb(source) end,'quotes',coalesce((select jsonb_agg(jsonb_build_object('id',id,'version',version)) from public.crm_quotes where deal_id=d.id),'[]'));
 insert into public.crm_product_lines(deal_id,board_id,owner_id,estimated_value) values(d.id,target,owner,(p_data->>'target_value')::numeric) returning id into new_id;
 if mode='Move' then update public.crm_product_lines set status='Dropped',drop_reason='Board move: '||trim(p_reason),version=version+1 where id=source.id;end if;
 update public.crm_deals set version=version+1,last_activity_at=now() where id=d.id;
 update public.crm_quotes set version=version+1 where deal_id=d.id;
 insert into public.crm_quote_history(deal_id,quote_id,action,actor_id) select d.id,id,'Product scope changed; review actual draft BOQ',auth.uid() from public.crm_quotes where deal_id=d.id;
 insert into public.crm_sales_activity(lead_id,deal_id,kind,body,actor_id) values(d.lead_id,d.id,'Product line',mode||' product board: '||(select name from public.crm_boards where id=target)||'. Reason: '||trim(p_reason),auth.uid());
 after_value:=jsonb_build_object('deal_version',d.version+1,'new_product',(select to_jsonb(l) from public.crm_product_lines l where id=new_id),'source_product',(select to_jsonb(l) from public.crm_product_lines l where id=source.id),'quotes',coalesce((select jsonb_agg(jsonb_build_object('id',id,'version',version)) from public.crm_quotes where deal_id=d.id),'[]'));
 insert into portal_private.crm_product_scope_history values(p_request,d.id,auth.uid(),payload,before_value,after_value,new_id,trim(p_reason),now());return new_id;
end$$;
create function public.crm_product_scope_history(p_deal uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$begin
 if not portal_private.deal_edit(p_deal) then raise exception 'Current commercial Deal authority required';end if;
 return coalesce((select jsonb_agg(to_jsonb(h) order by h.created_at,h.request_id) from portal_private.crm_product_scope_history h where h.deal_id=p_deal),'[]'::jsonb);
end$$;
revoke all on function public.change_crm_product_scope(uuid,uuid,integer,jsonb,text),public.crm_product_scope_history(uuid) from public,anon,service_role;
grant execute on function public.change_crm_product_scope(uuid,uuid,integer,jsonb,text),public.crm_product_scope_history(uuid) to authenticated;
