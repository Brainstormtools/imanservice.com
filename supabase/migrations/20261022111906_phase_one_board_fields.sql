begin;
-- Actual Administrator definitions only; no boards, fields, members or values seeded.
create table portal_private.crm_board_creation_evidence(
 board_id uuid primary key references public.crm_boards,definition jsonb not null,template_id uuid not null references public.crm_boards,
 template_hash text not null,template_snapshot jsonb not null,actor_id uuid not null references public.profiles,reason text not null,created_at timestamptz not null default now()
);
create index board_creation_template on portal_private.crm_board_creation_evidence(template_id);
create index board_creation_actor on portal_private.crm_board_creation_evidence(actor_id);
create table portal_private.crm_board_field_schemas(board_id uuid primary key references public.crm_boards,version integer not null);
create table portal_private.crm_board_fields(
 id uuid primary key,board_id uuid not null references public.crm_boards,key text not null,label text not null,kind text not null,
 options jsonb not null,active boolean not null,version integer not null default 1,unique(board_id,key)
);
create table portal_private.crm_board_field_history(
 field_id uuid not null references portal_private.crm_board_fields,version integer not null,definition jsonb not null,
 actor_id uuid not null references public.profiles,reason text not null,created_at timestamptz not null default now(),primary key(field_id,version)
);
create index board_field_history_actor on portal_private.crm_board_field_history(actor_id);
create table portal_private.crm_product_field_registers(
 product_line_id uuid primary key references public.crm_product_lines,version integer not null,field_values jsonb not null
);
create table portal_private.crm_product_field_history(
 product_line_id uuid not null references public.crm_product_lines,version integer not null,schema_version integer not null,
 submitted jsonb not null,snapshot jsonb not null,actor_id uuid not null references public.profiles,reason text not null,created_at timestamptz not null default now(),primary key(product_line_id,version)
);
create index product_field_history_actor on portal_private.crm_product_field_history(actor_id);
do $$declare t text;begin
 foreach t in array array['crm_board_creation_evidence','crm_board_field_schemas','crm_board_fields','crm_board_field_history','crm_product_field_registers','crm_product_field_history'] loop
  execute format('alter table portal_private.%I enable row level security',t);
  execute format('revoke all on portal_private.%I from public,anon,authenticated,service_role',t);
 end loop;
 foreach t in array array['crm_board_creation_evidence','crm_board_field_history','crm_product_field_history'] loop
  execute format('create trigger board_field_evidence_immutable before update or delete on portal_private.%I for each row execute function portal_private.lead_api_evidence_immutable()',t);
 end loop;
end$$;
create function portal_private.sales_board_stage_snapshot(p_board uuid) returns jsonb language sql stable set search_path='' as $$
 select jsonb_build_object('board',to_jsonb(b),'stages',coalesce((select jsonb_agg(to_jsonb(s) order by s.position,s.code) from public.crm_board_stages s where s.board_id=b.id),'[]'::jsonb)) from public.crm_boards b where b.id=p_board;
$$;
create function public.create_crm_sales_board(p_id uuid,p_data jsonb,p_template uuid,p_hash text,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare actor public.profiles;prior portal_private.crm_board_creation_evidence;snapshot jsonb;current_hash text;s jsonb;
begin
 select * into actor from public.profiles where id=auth.uid() for share;
 if actor.id is null or not actor.active or actor.role<>'admin' then raise exception 'Current Administrator access required';end if;
 if p_id is null or length(coalesce(trim(p_reason),'')) not between 3 and 1000 or jsonb_typeof(p_data) is distinct from 'object' or octet_length(p_data::text)>8000 or (select count(*) from jsonb_object_keys(p_data))<>6 or exists(select 1 from jsonb_object_keys(p_data) k where k not in ('code','name','color','outcome','rotting_days','active')) then raise exception 'Explicit actual board definition and reason required';end if;
 if jsonb_typeof(p_data->'code') is distinct from 'string' or p_data->>'code' !~ '^[a-z][a-z0-9_]{1,49}$' or jsonb_typeof(p_data->'name') is distinct from 'string' or length(trim(p_data->>'name')) not between 1 and 100 or jsonb_typeof(p_data->'color') is distinct from 'string' or p_data->>'color' !~ '^#[0-9A-Fa-f]{6}$' or jsonb_typeof(p_data->'outcome') is distinct from 'string' or p_data->>'outcome' not in ('Project','Contract','Project or direct sale') or jsonb_typeof(p_data->'rotting_days') is distinct from 'number' or p_data->>'rotting_days' !~ '^[0-9]{1,3}$' or (p_data->>'rotting_days')::int not between 1 and 365 or jsonb_typeof(p_data->'active') is distinct from 'boolean' then raise exception 'Valid actual code, name, color, outcome, rotting interval and active action required';end if;
 perform pg_advisory_xact_lock(hashtext('crm-sales-board-creation'));
 select * into prior from portal_private.crm_board_creation_evidence where board_id=p_id;
 if found then
  if prior.actor_id=actor.id and prior.definition=p_data and prior.template_id=p_template and prior.template_hash=p_hash and prior.reason=trim(p_reason) then return;end if;
  raise exception 'Board identity already has different creation evidence';
 end if;
 if p_template is null or p_hash is null or p_hash !~ '^[0-9a-f]{64}$' or not exists(select 1 from public.crm_boards where id=p_template and active) then raise exception 'Actual active source board and exact stage snapshot required';end if;
 perform 1 from public.crm_boards where id=p_template and active for share;if not found then raise exception 'Source board is no longer active';end if;
 perform 1 from public.crm_board_stages where board_id=p_template order by id for share;
 snapshot:=portal_private.sales_board_stage_snapshot(p_template);current_hash:=encode(sha256(convert_to(snapshot::text,'UTF8')),'hex');
 if p_hash<>current_hash then raise exception 'Source board/stages changed; reload the current exact stage snapshot';end if;
 if exists(select 1 from (values('new'),('won'),('lost')) required(code) where not exists(select 1 from public.crm_board_stages where board_id=p_template and code=required.code and active and (code<>'won' or probability=100) and (code<>'lost' or probability=0))) then raise exception 'Source must have active New, Won and Lost system stages';end if;
 insert into public.crm_boards(id,code,name,color,outcome,rotting_days,active) values(p_id,p_data->>'code',trim(p_data->>'name'),p_data->>'color',p_data->>'outcome',(p_data->>'rotting_days')::int,(p_data->>'active')::boolean);
 for s in select value from jsonb_array_elements(snapshot->'stages') loop
  insert into public.crm_board_stages(board_id,code,name,position,probability,active) values(p_id,s->>'code',s->>'name',(s->>'position')::int,(s->>'probability')::int,(s->>'active')::boolean);
 end loop;
 insert into portal_private.crm_board_creation_evidence(board_id,definition,template_id,template_hash,template_snapshot,actor_id,reason) values(p_id,p_data,p_template,p_hash,snapshot,actor.id,trim(p_reason));
end$$;
create function public.save_crm_board_field(p_id uuid,p_board uuid,p_version integer,p_data jsonb,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare actor public.profiles;old portal_private.crm_board_fields;h portal_private.crm_board_field_history;v integer;
begin
 select * into actor from public.profiles where id=auth.uid() for share;
 if actor.id is null or not actor.active or actor.role<>'admin' then raise exception 'Current Administrator access required';end if;
 if p_id is null or p_board is null or length(coalesce(trim(p_reason),'')) not between 3 and 1000 or jsonb_typeof(p_data) is distinct from 'object' or octet_length(p_data::text)>32000 or (select count(*) from jsonb_object_keys(p_data))<>5 or exists(select 1 from jsonb_object_keys(p_data) k where k not in ('key','label','kind','options','active')) then raise exception 'Actual field definition and reason required';end if;
 if jsonb_typeof(p_data->'key') is distinct from 'string' or p_data->>'key' !~ '^[a-z][a-z0-9_]{1,49}$' or jsonb_typeof(p_data->'label') is distinct from 'string' or length(trim(p_data->>'label')) not between 1 and 100 or jsonb_typeof(p_data->'kind') is distinct from 'string' or p_data->>'kind' not in ('Text','Number','Date','Yes/No','Single choice') or jsonb_typeof(p_data->'active') is distinct from 'boolean' or jsonb_typeof(p_data->'options') is distinct from 'array' then raise exception 'Valid actual field key, label, type, options and active action required';end if;
 if exists(select 1 from jsonb_array_elements(p_data->'options') x where jsonb_typeof(x)<>'string' or length(trim(x#>>'{}')) not between 1 and 100 or x#>>'{}'<>trim(x#>>'{}')) or jsonb_array_length(p_data->'options')<>(select count(distinct x) from jsonb_array_elements(p_data->'options') x) or (p_data->>'kind'='Single choice' and jsonb_array_length(p_data->'options') not between 1 and 50) or (p_data->>'kind'<>'Single choice' and p_data->'options'<>'[]'::jsonb) then raise exception 'Enter 1–50 distinct actual options only for a Single choice field';end if;
 perform pg_advisory_xact_lock(hashtext('crm-board-fields:'||p_board));
 perform 1 from public.crm_boards where id=p_board for share;if not found then raise exception 'Actual board required';end if;
 select * into old from portal_private.crm_board_fields where id=p_id for update;
 select * into h from portal_private.crm_board_field_history where field_id=p_id order by version desc limit 1;
 if old.id is not null and old.board_id=p_board and ((p_version is null and old.version=1) or old.version=p_version+1) and h.definition=p_data and h.actor_id=actor.id and h.reason=trim(p_reason) then return;end if;
 if old.id is null then
  if p_version is not null or (select count(*) from portal_private.crm_board_fields where board_id=p_board)>=50 then raise exception 'New field identity/version unavailable or 50-field limit reached';end if;
  insert into portal_private.crm_board_fields(id,board_id,key,label,kind,options,active) values(p_id,p_board,p_data->>'key',trim(p_data->>'label'),p_data->>'kind',p_data->'options',(p_data->>'active')::boolean);v:=1;
 else
  if old.board_id<>p_board or p_version is distinct from old.version then raise exception 'Field changed or belongs to another board; reload current definition';end if;
  if old.key<>p_data->>'key' or old.kind<>p_data->>'kind' or not (p_data->'options' @> old.options) then raise exception 'Existing field key/type/options cannot be replaced; archive and create a new field or append options';end if;
  v:=old.version+1;update portal_private.crm_board_fields set label=trim(p_data->>'label'),options=p_data->'options',active=(p_data->>'active')::boolean,version=v where id=p_id;
 end if;
 insert into portal_private.crm_board_field_history(field_id,version,definition,actor_id,reason) values(p_id,v,p_data,actor.id,trim(p_reason));
 insert into portal_private.crm_board_field_schemas(board_id,version) values(p_board,1) on conflict(board_id) do update set version=crm_board_field_schemas.version+1;
end$$;
create function public.crm_board_definition_register() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Current Administrator access required';end if;
 return jsonb_build_object('boards',coalesce((select jsonb_agg(to_jsonb(b)||jsonb_build_object('stage_hash',encode(sha256(convert_to(portal_private.sales_board_stage_snapshot(b.id)::text,'UTF8')),'hex'),'stages',portal_private.sales_board_stage_snapshot(b.id)->'stages','creation',(select to_jsonb(e) from portal_private.crm_board_creation_evidence e where e.board_id=b.id),'fields',coalesce((select jsonb_agg(to_jsonb(f)||jsonb_build_object('history',(select jsonb_agg(to_jsonb(h) order by h.version) from portal_private.crm_board_field_history h where h.field_id=f.id)) order by f.key) from portal_private.crm_board_fields f where f.board_id=b.id),'[]'::jsonb)) order by b.name,b.id) from public.crm_boards b),'[]'::jsonb));
end$$;
create function public.crm_product_field_context(p_line uuid,p_before integer default null) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare l public.crm_product_lines;d public.crm_deals;r portal_private.crm_product_field_registers;fields jsonb;schema_version integer;editable boolean;
begin
 select * into l from public.crm_product_lines where id=p_line;select * into d from public.crm_deals where id=l.deal_id;
 if l.id is null or not portal_private.board_access(l.board_id) or not portal_private.deal_access(l.deal_id) then raise exception 'Current product board and Deal access required';end if;
 select * into r from portal_private.crm_product_field_registers where product_line_id=p_line;
 select coalesce(jsonb_agg(to_jsonb(f) order by f.key),'[]'::jsonb) into fields from portal_private.crm_board_fields f where board_id=l.board_id;
 select coalesce((select version from portal_private.crm_board_field_schemas where board_id=l.board_id),0) into schema_version;
 editable:=l.status='Active' and d.stage not in ('won','lost') and exists(select 1 from public.crm_boards where id=l.board_id and active) and (portal_private.deal_edit(l.deal_id) or portal_private.crm_permission('product.own'));
 return jsonb_build_object('product_line_id',l.id,'board_id',l.board_id,'deal_id',d.id,'version',coalesce(r.version,0),'schema_version',schema_version,'can_edit',editable,'fields',fields,'values',coalesce(r.field_values,'{}'::jsonb),'history',coalesce((select jsonb_agg(to_jsonb(h) order by h.version desc) from (select * from portal_private.crm_product_field_history where product_line_id=p_line and (p_before is null or version<p_before) order by version desc limit 100) h),'[]'::jsonb));
end$$;
create function public.save_crm_product_fields(p_line uuid,p_version integer,p_schema integer,p_values jsonb,p_reason text) returns void language plpgsql security definer set search_path='' as $$
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
  if f.kind='Date' and (e.value#>>'{}' !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or to_char((e.value#>>'{}')::date,'YYYY-MM-DD')<>e.value#>>'{}') then raise exception 'Actual ISO calendar date required';end if;
  if f.kind='Single choice' and not (f.options @> jsonb_build_array(e.value)) then raise exception 'Choose an actual configured option';end if;
 end loop;
 -- Replace only active values; retain archived current values and all immutable receipts.
 select coalesce(jsonb_object_agg(k,v),'{}'::jsonb) into merged from jsonb_each(coalesce(r.field_values,'{}')) old(k,v) where not exists(select 1 from portal_private.crm_board_fields where board_id=l.board_id and active and id::text=k);
 merged:=merged||p_values;select coalesce(jsonb_agg(to_jsonb(x) order by x.key),'[]'::jsonb) into defs from portal_private.crm_board_fields x where board_id=l.board_id;
 insert into portal_private.crm_product_field_registers(product_line_id,version,field_values) values(p_line,1,merged) on conflict(product_line_id) do update set version=crm_product_field_registers.version+1,field_values=excluded.field_values returning * into r;
 insert into portal_private.crm_product_field_history(product_line_id,version,schema_version,submitted,snapshot,actor_id,reason) values(p_line,r.version,v_schema,p_values,jsonb_build_object('fields',defs,'values',merged),actor.id,trim(p_reason));
end$$;
revoke all on function portal_private.sales_board_stage_snapshot(uuid) from public,anon,authenticated,service_role;
revoke all on function public.create_crm_sales_board(uuid,jsonb,uuid,text,text),public.save_crm_board_field(uuid,uuid,integer,jsonb,text),public.crm_board_definition_register(),public.crm_product_field_context(uuid,integer),public.save_crm_product_fields(uuid,integer,integer,jsonb,text) from public,anon,authenticated,service_role;
grant execute on function public.create_crm_sales_board(uuid,jsonb,uuid,text,text),public.save_crm_board_field(uuid,uuid,integer,jsonb,text),public.crm_board_definition_register(),public.crm_product_field_context(uuid,integer),public.save_crm_product_fields(uuid,integer,integer,jsonb,text) to authenticated;
commit;
