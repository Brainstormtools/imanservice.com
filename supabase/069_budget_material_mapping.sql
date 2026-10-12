begin;
create table public.crm_budget_material_mappings(
 id uuid primary key,release_id uuid not null unique references public.crm_project_budget_reviews,
 project_id uuid not null references public.projects,source_snapshot jsonb not null,
 lines jsonb not null,version integer not null default 1,reason text not null,
 created_by uuid not null references public.profiles,created_at timestamptz not null default now()
);
create table public.crm_budget_material_mapping_history(
 id uuid primary key default gen_random_uuid(),mapping_id uuid not null references public.crm_budget_material_mappings,
 project_id uuid not null references public.projects,revision integer not null,before_record jsonb,after_record jsonb not null,
 request jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(mapping_id,revision)
);
create index budget_mapping_project on public.crm_budget_material_mappings(project_id);
create index budget_mapping_author on public.crm_budget_material_mappings(created_by);
create index budget_mapping_history_project on public.crm_budget_material_mapping_history(project_id);
create index budget_mapping_history_actor on public.crm_budget_material_mapping_history(actor_id);
do $$declare t text;begin foreach t in array array['crm_budget_material_mappings','crm_budget_material_mapping_history'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('revoke all on public.%I from public,anon,authenticated',t);
 execute format('grant select on public.%I to authenticated',t);
 execute format('create policy budget_mapping_read on public.%I for select to authenticated using(public.is_admin())',t);
end loop;end$$;
create function public.save_budget_material_mapping(p_id uuid,p_version integer,p_release uuid,p_lines jsonb,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare release public.crm_project_budget_reviews;old public.crm_budget_material_mappings;saved public.crm_budget_material_mappings;
 c public.crm_catalog;l jsonb;normalized jsonb:='[]';request_data jsonb;idx integer;qty numeric;key text;keys text[]:='{}';totals jsonb:='{}';
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator maps private material plans';end if;
 select * into release from public.crm_project_budget_reviews where id=p_release and action='Released';
 perform 1 from public.projects where id=release.project_id and status not in ('Completed','Cancelled') for update;
 if not found or exists(select 1 from public.crm_handovers where project_id=release.project_id and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Active project without released handover required';end if;
 if exists(select 1 from public.crm_project_budget_reviews where draft_id=release.draft_id and action='Released' and sequence>release.sequence) then raise exception 'Latest released cost version required; retain older mapping as history';end if;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 or jsonb_typeof(p_lines) is distinct from 'array' or jsonb_array_length(p_lines) not between 1 and 100 then raise exception 'Identity, explicit reason and 1–100 manual mapping lines required';end if;
 request_data:=jsonb_build_object('version',p_version,'release_id',p_release,'lines',p_lines,'reason',trim(p_reason));
 select * into old from public.crm_budget_material_mappings where id=p_id for update;
 if old.id is not null then
  if old.release_id is distinct from p_release then raise exception 'Mapping release source is fixed';end if;
  if exists(select 1 from public.crm_budget_material_mapping_history h where mapping_id=old.id and actor_id=auth.uid() and request=request_data and revision=coalesce(p_version,0)+1) then return old.id;end if;
  if old.version is distinct from p_version then raise exception 'Mapping changed; refresh before revising';end if;
 elsif p_version is not null then raise exception 'Unknown mapping cannot be revised';end if;
 for l in select value from jsonb_array_elements(p_lines) loop
  if jsonb_typeof(l) is distinct from 'object' or (select count(*) from jsonb_object_keys(l))<>3 or (l-array['cost_line','catalog_id','quantity'])<>'{}'::jsonb
   or jsonb_typeof(l->'cost_line') is distinct from 'number' or coalesce(l->>'cost_line','') !~ '^\d{1,2}$'
   or coalesce(l->>'quantity','') !~ '^\d{1,6}(\.\d{1,3})?$' then raise exception 'Explicit material-line index, catalogue identity and bounded quantity required';end if;
  idx:=(l->>'cost_line')::integer;qty:=(l->>'quantity')::numeric;
  if release.snapshot->'data'->'lines'->idx->>'block' is distinct from 'Material' then raise exception 'Exact released Material cost line required';end if;
  select * into c from public.crm_catalog where id=(l->>'catalog_id')::uuid and active and tracking in ('Quantity','Serial') for share;
  if c.id is null or qty<=0 or qty>100000 or c.tracking='Serial' and qty<>trunc(qty) then raise exception 'Active consumable catalogue item and explicit valid stock quantity required';end if;
  key:=jsonb_build_array(idx,c.id)::text;if key=any(keys) then raise exception 'Duplicate material/catalogue pair; combine quantity';end if;keys:=keys||key;
  totals:=jsonb_set(totals,array[c.id::text],to_jsonb(coalesce((totals->>c.id::text)::numeric,0)+qty));
  if (totals->>c.id::text)::numeric>100000 then raise exception 'Combined catalogue quantity exceeds existing stock-request bound';end if;
  normalized:=normalized||jsonb_build_array(jsonb_build_object('cost_line',idx,'catalog_id',c.id,'quantity',qty,'catalog_snapshot',jsonb_build_object('id',c.id,'name',c.name,'unit',c.unit,'tracking',c.tracking,'version',c.version)));
 end loop;
 if old.id is null then insert into public.crm_budget_material_mappings(id,release_id,project_id,source_snapshot,lines,reason,created_by)
  values(p_id,release.id,release.project_id,to_jsonb(release),normalized,trim(p_reason),auth.uid()) returning * into saved;
 else update public.crm_budget_material_mappings set lines=normalized,reason=trim(p_reason),version=version+1 where id=old.id returning * into saved;end if;
 insert into public.crm_budget_material_mapping_history(mapping_id,project_id,revision,before_record,after_record,request,reason,actor_id)
 values(saved.id,saved.project_id,saved.version,case when old.id is null then null else to_jsonb(old) end,to_jsonb(saved),request_data,trim(p_reason),auth.uid());
 return saved.id;
end$$;
revoke all on function public.save_budget_material_mapping(uuid,integer,uuid,jsonb,text) from public,anon;
grant execute on function public.save_budget_material_mapping(uuid,integer,uuid,jsonb,text) to authenticated;
commit;
