-- Optional, explicit sales List operations. No business content or assignments seeded.
create table portal_private.crm_sales_list_receipts(
 request_id uuid primary key,actor_id uuid not null references public.profiles,
 payload jsonb not null,evidence jsonb not null,created_at timestamptz not null default now()
);
create index crm_sales_list_receipt_actor on portal_private.crm_sales_list_receipts(actor_id);
alter table portal_private.crm_sales_list_receipts enable row level security;
revoke all on portal_private.crm_sales_list_receipts from public,anon,authenticated,service_role;
create trigger crm_sales_list_receipt_immutable before update or delete on portal_private.crm_sales_list_receipts for each row execute function portal_private.lead_api_evidence_immutable();
create function public.apply_crm_sales_list_action(p_request uuid,p_records jsonb,p_action text,p_value text,p_reason text,p_loss_reason text default '',p_loss_note text default '',p_reengage date default null)
returns integer language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid();item jsonb;d public.crm_deals;l public.crm_leads;target uuid;payload jsonb;receipt portal_private.crm_sales_list_receipts;proof jsonb:='[]';n integer:=0;before_row jsonb;new_tags text[];
begin
 perform 1 from public.profiles where id=actor and active and role in ('admin','team') for share;
 if not found or not portal_private.sales_user() then raise exception 'Active sales account required';end if;
 if p_request is null or p_action is null or p_action not in ('owner','stage','tag') or p_records is null or jsonb_typeof(p_records)<>'array' then raise exception 'Choose a supported List action and actual records';end if;
 if jsonb_array_length(p_records) not between 1 and 100 or length(trim(coalesce(p_reason,''))) not between 3 and 1000 or length(coalesce(p_value,'')) not between 1 and 100 then raise exception 'Select 1–100 records, a value and a reason';end if;
 for item in select value from jsonb_array_elements(p_records) loop
  if jsonb_typeof(item)<>'object' or (select count(*) from jsonb_object_keys(item))<>3 or not(item ?& array['id','version','lead_version']) or coalesce(item->>'version','')!~'^[1-9][0-9]{0,8}$' or coalesce(item->>'lead_version','')!~'^[1-9][0-9]{0,8}$' or jsonb_typeof(item->'id')<>'string' then raise exception 'Actual record IDs and exact current versions required';end if;
 end loop;
 if (select count(distinct (value->>'id')::uuid) from jsonb_array_elements(p_records))<>jsonb_array_length(p_records) then raise exception 'Duplicate selected record';end if;
 payload:=jsonb_build_object('records',p_records,'action',p_action,'value',p_value,'reason',p_reason,'loss_reason',p_loss_reason,'loss_note',p_loss_note,'reengage',p_reengage);
 perform pg_advisory_xact_lock(hashtextextended('sales-list:'||p_request::text,0));
 select * into receipt from portal_private.crm_sales_list_receipts where request_id=p_request;
 if found then
  if receipt.actor_id<>actor or receipt.payload<>payload then raise exception 'Request was already used for another action';end if;
  for item in select value from jsonb_array_elements(p_records) loop if not portal_private.deal_access((item->>'id')::uuid) then raise exception 'Current deal access required';end if;end loop;
  return jsonb_array_length(p_records);
 end if;
 if p_action='owner' then
  if not(public.is_admin() or portal_private.crm_permission('sales.manage')) then raise exception 'Sales Manager required to change sales owner';end if;
  target:=p_value::uuid;
  perform 1 from public.profiles where id=target and active and role in ('admin','team') for share;
  if not found or not(portal_private.crm_user_permission(target,'sales.own') or portal_private.crm_user_permission(target,'sales.manage')) then raise exception 'Actual active eligible sales owner required';end if;
 elsif p_action='tag' and not public.valid_labels(array[trim(p_value)]) then raise exception 'Use one actual tag of 1–40 characters';
 elsif p_action='stage' and p_value='won' then raise exception 'Won requires the accepted quotation and conversion workflow';end if;
 -- Lock all affected records in deterministic order, then recheck authority and snapshots.
 perform 1 from public.crm_deals where id in(select (value->>'id')::uuid from jsonb_array_elements(p_records)) order by id for update;
 perform 1 from public.crm_leads where id in(select lead_id from public.crm_deals where id in(select (value->>'id')::uuid from jsonb_array_elements(p_records))) order by id for update;
 perform 1 from public.crm_board_memberships where user_id=actor or user_id=target order by board_id,user_id for share;
 perform 1 from public.crm_memberships where user_id=actor or user_id=target order by user_id,role_id,team_id for share;
 perform 1 from public.crm_roles order by id for share;
 perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id=actor or user_id=target) order by id for share;
 for item in select value from jsonb_array_elements(p_records) order by value->>'id' loop
  select * into d from public.crm_deals where id=(item->>'id')::uuid;
  if not found or not portal_private.deal_edit(d.id) then raise exception 'Current deal edit access required';end if;
  select * into l from public.crm_leads where id=d.lead_id;
  if d.version<>(item->>'version')::integer or l.version<>(item->>'lead_version')::integer then raise exception 'Selected deal or lead changed. Refresh and select again';end if;
  if d.stage in ('won','lost') or exists(select 1 from public.crm_sales where deal_id=d.id) then raise exception 'Closed or converted deals cannot use bulk List changes';end if;
  if exists(select 1 from public.crm_product_lines p join public.crm_boards b on b.id=p.board_id where p.deal_id=d.id and p.status='Active' and not b.active) then raise exception 'Inactive product boards cannot use bulk List changes';end if;
  before_row:=jsonb_build_object('deal',to_jsonb(d),'lead_owner',l.owner_id,'lead_tags',l.tags,'lead_version',l.version);
  if p_action='owner' then
   if not(public.is_admin() or portal_private.crm_permission('sales.manage')) or not(portal_private.crm_user_permission(target,'sales.own') or portal_private.crm_user_permission(target,'sales.manage')) then raise exception 'Current manager and eligible owner required';end if;
   if not exists(select 1 from public.profiles where id=target and active and role='admin') and exists(select 1 from public.crm_product_lines p where p.deal_id=d.id and p.status='Active' and not exists(select 1 from public.crm_board_memberships m where m.board_id=p.board_id and m.user_id=target)) then raise exception 'Target owner must belong to every active product board';end if;
   update public.crm_deals set owner_id=target,version=version+1 where id=d.id;
   update public.crm_leads set owner_id=target,version=version+1,updated_at=now() where id=l.id;
  elsif p_action='tag' then
   new_tags:=case when exists(select 1 from unnest(l.tags) tag where lower(tag)=lower(trim(p_value))) then l.tags else array_append(l.tags,trim(p_value)) end;
   if not public.valid_labels(new_tags) then raise exception 'Lead tag limit exceeded';end if;
   update public.crm_leads set tags=new_tags,version=version+1,updated_at=now() where id=l.id;
   update public.crm_deals set version=version+1 where id=d.id;
  else
   perform public.save_crm_deal(d.id,d.version,p_value,d.estimated_value,d.next_followup,d.meeting_at,p_loss_reason,p_loss_note,p_reengage);
  end if;
  insert into public.crm_sales_activity(lead_id,deal_id,kind,body,actor_id) values(l.id,d.id,'Note','List '||p_action||': '||p_value||'. Reason: '||trim(p_reason),actor);
  proof:=proof||jsonb_build_array(jsonb_build_object('before',before_row,'after_deal',(select to_jsonb(x) from public.crm_deals x where id=d.id),'after_lead',(select jsonb_build_object('owner',owner_id,'tags',tags,'version',version) from public.crm_leads where id=l.id)));
  n:=n+1;
 end loop;
 insert into portal_private.crm_sales_list_receipts values(p_request,actor,payload,proof,now());return n;
end$$;
revoke all on function public.apply_crm_sales_list_action(uuid,jsonb,text,text,text,text,text,date) from public,anon,service_role;
grant execute on function public.apply_crm_sales_list_action(uuid,jsonb,text,text,text,text,text,date) to authenticated;
