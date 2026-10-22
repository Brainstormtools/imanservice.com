begin;
-- Optional actual administrator configuration only. No rules or business assignments are seeded.
create table portal_private.crm_lead_routes(
 id uuid primary key,version integer not null default 1,definition jsonb not null,last_owner uuid references public.profiles,
 updated_by uuid not null references public.profiles,updated_at timestamptz not null default now()
);
create index lead_route_actor on portal_private.crm_lead_routes(updated_by);
create index lead_route_last_owner on portal_private.crm_lead_routes(last_owner);
create table portal_private.crm_lead_route_history(
 id uuid primary key default gen_random_uuid(),route_id uuid not null references portal_private.crm_lead_routes,version integer not null,
 definition jsonb not null,actor_id uuid not null references public.profiles,reason text not null,created_at timestamptz not null default now(),unique(route_id,version)
);
create index lead_route_history_actor on portal_private.crm_lead_route_history(actor_id);
create table portal_private.crm_lead_route_receipts(
 lead_id uuid primary key references public.crm_leads,route_id uuid not null references portal_private.crm_lead_routes,
 route_version integer not null,definition jsonb not null,outcome text not null check(outcome in ('Routed','Needs review')),
 issue text,owner_id uuid references public.profiles,deal_id uuid references public.crm_deals,created_at timestamptz not null default now()
);
create index lead_route_receipt_rule on portal_private.crm_lead_route_receipts(route_id);
create index lead_route_receipt_owner on portal_private.crm_lead_route_receipts(owner_id);
create index lead_route_receipt_deal on portal_private.crm_lead_route_receipts(deal_id);
create index lead_route_receipt_cursor on portal_private.crm_lead_route_receipts(created_at desc,lead_id desc);
do $$declare t text;begin
 foreach t in array array['crm_lead_routes','crm_lead_route_history','crm_lead_route_receipts'] loop
  execute format('alter table portal_private.%I enable row level security',t);
  execute format('revoke all on portal_private.%I from public,anon,authenticated,service_role',t);
 end loop;
 foreach t in array array['crm_lead_route_history','crm_lead_route_receipts'] loop
  execute format('create trigger routing_evidence_immutable before update or delete on portal_private.%I for each row execute function portal_private.lead_api_evidence_immutable()',t);
 end loop;
end$$;
create function portal_private.route_owner_eligible(p_user uuid,p_boards uuid[]) returns boolean language sql stable set search_path='' as $$
 select (portal_private.crm_user_permission(p_user,'sales.own') or portal_private.crm_user_permission(p_user,'sales.manage'))
 and not exists(select 1 from unnest(p_boards) b where not exists(select 1 from public.profiles where id=p_user and active and role='admin') and not exists(select 1 from public.crm_board_memberships where board_id=b and user_id=p_user));
$$;
create function public.save_crm_lead_route(p_id uuid,p_version integer,p_data jsonb,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare actor public.profiles;prior portal_private.crm_lead_routes;boards uuid[];owners uuid[];v_user uuid;v integer;history portal_private.crm_lead_route_history;
begin
 select * into actor from public.profiles where id=auth.uid() for share;
 if actor.id is null or not actor.active or actor.role<>'admin' then raise exception 'Current Administrator access required';end if;
 if p_id is null or length(coalesce(trim(p_reason),'')) not between 3 and 1000 or jsonb_typeof(p_data) is distinct from 'object' or octet_length(p_data::text)>8000 then raise exception 'Actual bounded routing definition and reason required';end if;
 if (select count(*) from jsonb_object_keys(p_data))<>8 or exists(select 1 from jsonb_object_keys(p_data) k where k not in ('name','priority','enabled','conditions','boards','owners','mode','followup_days')) then raise exception 'Explicit supported routing fields required';end if;
 if jsonb_typeof(p_data->'name') is distinct from 'string' or length(trim(p_data->>'name')) not between 2 and 100 or jsonb_typeof(p_data->'enabled') is distinct from 'boolean' or jsonb_typeof(p_data->'priority') is distinct from 'number' or jsonb_typeof(p_data->'followup_days') is distinct from 'number' or jsonb_typeof(p_data->'mode') is distinct from 'string' or p_data->>'priority' !~ '^[0-9]{1,4}$' or (p_data->>'priority')::int not between 1 and 9999 or p_data->>'followup_days' !~ '^[0-9]{1,3}$' or (p_data->>'followup_days')::int not between 0 and 365 or p_data->>'mode' not in ('Fixed','Round robin') then raise exception 'Actual name, priority, enabled action, owner method and calendar-day follow-up required';end if;
 if jsonb_typeof(p_data->'conditions') is distinct from 'object' or p_data->'conditions'='{}'::jsonb or exists(select 1 from jsonb_each(p_data->'conditions') e where e.key not in ('source','form','campaign') or jsonb_typeof(e.value)<>'string' or length(trim(e.value#>>'{}')) not between 1 and 300 or e.value#>>'{}'<>trim(e.value#>>'{}')) then raise exception 'At least one actual exact source, form or campaign condition required';end if;
 if jsonb_typeof(p_data->'boards') is distinct from 'array' or jsonb_typeof(p_data->'owners') is distinct from 'array' then raise exception 'Actual selected board and owner lists required';end if;
 select array_agg(value::uuid order by ordinality) into boards from jsonb_array_elements_text(p_data->'boards') with ordinality;
 select array_agg(value::uuid order by ordinality) into owners from jsonb_array_elements_text(p_data->'owners') with ordinality;
 if cardinality(boards) not between 1 and 6 or cardinality(owners) not between 1 and 100 or boards is null or owners is null or cardinality(boards)<>(select count(distinct x) from unnest(boards) x) or cardinality(owners)<>(select count(distinct x) from unnest(owners) x) or (p_data->>'mode'='Fixed' and cardinality(owners)<>1) then raise exception 'Distinct actual boards and eligible owners required; Fixed selects one owner';end if;
 if exists(select 1 from unnest(boards) b where not exists(select 1 from public.crm_boards where id=b)) or exists(select 1 from unnest(owners) u where not exists(select 1 from public.profiles where id=u)) then raise exception 'Select actual existing boards and accounts';end if;
 perform pg_advisory_xact_lock(hashtext('crm-lead-intake'));
 if (p_data->>'enabled')::boolean then
  perform 1 from public.crm_boards where id=any(boards) order by id for share;
  perform 1 from public.profiles where id=any(owners) order by id for share;
  if exists(select 1 from unnest(boards) b where not exists(select 1 from public.crm_boards where id=b and active) or not exists(select 1 from public.crm_board_stages where board_id=b and code='new' and active)) then raise exception 'Every selected board and New stage must be active';end if;
  foreach v_user in array owners loop if not portal_private.route_owner_eligible(v_user,boards) then raise exception 'Every selected owner needs current sales permission and access to all selected boards';end if;end loop;
 end if;
 select * into prior from portal_private.crm_lead_routes where id=p_id for update;
 select * into history from portal_private.crm_lead_route_history where route_id=p_id order by version desc limit 1;
 if prior.id is not null and ((p_version is null and prior.version=1) or prior.version=p_version+1) and prior.definition=p_data and history.actor_id=actor.id and history.reason=trim(p_reason) then return;end if;
 if prior.id is null then
  if p_version is not null or (select count(*) from portal_private.crm_lead_routes)>=200 then raise exception 'New rule identity/version unavailable or 200-rule limit reached';end if;
  insert into portal_private.crm_lead_routes(id,definition,updated_by) values(p_id,p_data,actor.id);v:=1;
 else
  if p_version is distinct from prior.version then raise exception 'Rule changed; reload the exact current version';end if;
  v:=prior.version+1;
  update portal_private.crm_lead_routes set definition=p_data,version=v,updated_by=actor.id,updated_at=now(),last_owner=case when prior.definition->'owners'=p_data->'owners' and prior.definition->>'mode'=p_data->>'mode' then last_owner else null end where id=p_id;
 end if;
 insert into portal_private.crm_lead_route_history(route_id,version,definition,actor_id,reason) values(p_id,v,p_data,actor.id,trim(p_reason));
end$$;
create function portal_private.route_new_crm_lead() returns trigger language plpgsql security definer set search_path='' as $$
declare r portal_private.crm_lead_routes;boards uuid[];owners uuid[];v_user uuid;chosen uuid;did uuid;bid uuid;issue text;start_at integer;i integer;
begin
 if new.status<>'New' then return new;end if;
 perform pg_advisory_xact_lock(hashtext('crm-lead-intake'));
 select * into r from portal_private.crm_lead_routes where definition->>'enabled'='true'
 and not exists(select 1 from jsonb_each_text(definition->'conditions') c where c.value is distinct from case c.key when 'source' then new.source when 'form' then new.form_name when 'campaign' then new.campaign end)
 order by (definition->>'priority')::int,id limit 1 for update;
 if r.id is null then return new;end if;
 select array_agg(value::uuid order by ordinality) into boards from jsonb_array_elements_text(r.definition->'boards') with ordinality;
 select array_agg(value::uuid order by ordinality) into owners from jsonb_array_elements_text(r.definition->'owners') with ordinality;
 perform 1 from public.crm_boards where id=any(boards) order by id for share;
 perform 1 from public.profiles where id=any(owners) order by id for share;
 if exists(select 1 from unnest(boards) b where not exists(select 1 from public.crm_boards where id=b and active) or not exists(select 1 from public.crm_board_stages where board_id=b and code='new' and active)) then issue:='A configured board or New stage is no longer active';
 else
  start_at:=coalesce(array_position(owners,r.last_owner),0);
  for i in 1..cardinality(owners) loop v_user:=owners[((start_at+i-1)%cardinality(owners))+1];if portal_private.route_owner_eligible(v_user,boards) then chosen:=v_user;exit;end if;end loop;
  if chosen is null then issue:='No configured owner currently has eligible sales and board access';end if;
 end if;
 if issue is null then
  insert into public.crm_deals(lead_id,company_id,title,owner_id,next_followup) values(new.id,new.company_id,left(new.name||case when new.company_name<>'' then ' · '||new.company_name else '' end,200),chosen,current_date+(r.definition->>'followup_days')::int) returning id into did;
  foreach bid in array boards loop insert into public.crm_product_lines(deal_id,board_id,owner_id) values(did,bid,chosen);end loop;
  update public.crm_leads set status='Assigned',owner_id=chosen,version=version+1,updated_at=now() where id=new.id;
  update portal_private.crm_lead_routes set last_owner=chosen where id=r.id;
  insert into public.crm_sales_activity(lead_id,deal_id,kind,body,actor_id) values(new.id,did,'Assignment','Administrator-configured routing: '||(r.definition->>'name')||' · rule '||r.id||' version '||r.version,null);
  insert into public.portal_reminders(user_id,event_key,title,view) select chosen,'lead-route:'||new.id,'New lead routed to your product boards','sales_boards' where coalesce((select enabled from public.portal_reminder_preferences where user_id=chosen),true) on conflict(user_id,event_key) do nothing;
 else
  insert into public.portal_reminders(user_id,event_key,title,view) select id,'lead-route-review:'||new.id,'Lead routing needs review; enquiry retained on Raw Lead Board','sales_configuration' from public.profiles p where active and role='admin' and coalesce((select enabled from public.portal_reminder_preferences where user_id=p.id),true) on conflict(user_id,event_key) do nothing;
 end if;
 insert into portal_private.crm_lead_route_receipts(lead_id,route_id,route_version,definition,outcome,issue,owner_id,deal_id) values(new.id,r.id,r.version,r.definition,case when issue is null then 'Routed' else 'Needs review' end,issue,chosen,did);
 return new;
end$$;
create trigger optional_crm_lead_routing after insert on public.crm_leads for each row execute function portal_private.route_new_crm_lead();
create function public.crm_lead_route_register(p_before timestamptz default null,p_lead uuid default null) returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Current Administrator access required';end if;
 return jsonb_build_object('rules',coalesce((select jsonb_agg(to_jsonb(r)||jsonb_build_object('history',(select jsonb_agg(to_jsonb(h) order by h.version) from portal_private.crm_lead_route_history h where h.route_id=r.id)) order by (r.definition->>'priority')::int,r.id) from portal_private.crm_lead_routes r),'[]'::jsonb),
 'boards',coalesce((select jsonb_agg(to_jsonb(b) order by b.name,b.id) from public.crm_boards b where b.active),'[]'::jsonb),
 'owners',coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'name',p.name,'boards',coalesce((select jsonb_agg(board_id order by board_id) from public.crm_board_memberships where user_id=p.id),'[]'::jsonb),'admin',p.role='admin') order by p.name,p.id) from public.profiles p where p.active and (portal_private.crm_user_permission(p.id,'sales.own') or portal_private.crm_user_permission(p.id,'sales.manage'))),'[]'::jsonb),
 'receipts',coalesce((select jsonb_agg(to_jsonb(e) order by e.created_at desc,e.lead_id desc) from (select * from portal_private.crm_lead_route_receipts where p_before is null or (created_at,lead_id)<(p_before,p_lead) order by created_at desc,lead_id desc limit 100) e),'[]'::jsonb));
end$$;
revoke all on function portal_private.route_owner_eligible(uuid,uuid[]),portal_private.route_new_crm_lead() from public,anon,authenticated,service_role;
revoke all on function public.save_crm_lead_route(uuid,integer,jsonb,text),public.crm_lead_route_register(timestamptz,uuid) from public,anon,authenticated,service_role;
grant execute on function public.save_crm_lead_route(uuid,integer,jsonb,text),public.crm_lead_route_register(timestamptz,uuid) to authenticated;
commit;
