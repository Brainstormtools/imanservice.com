begin;
create table public.crm_budget_material_mapping_reviews(
 id uuid primary key,mapping_id uuid not null references public.crm_budget_material_mappings,
 project_id uuid not null references public.projects,mapping_version integer not null,sequence integer not null,
 action text not null check(action in ('Approved','Returned')),snapshot jsonb not null,request jsonb not null,
 reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(mapping_id,sequence)
);
create index mapping_review_project on public.crm_budget_material_mapping_reviews(project_id);
create index mapping_review_actor on public.crm_budget_material_mapping_reviews(actor_id);
alter table public.crm_budget_material_mapping_reviews enable row level security;
revoke all on public.crm_budget_material_mapping_reviews from public,anon,authenticated;
grant select on public.crm_budget_material_mapping_reviews to authenticated;
create policy mapping_review_read on public.crm_budget_material_mapping_reviews for select to authenticated using(public.is_admin());
create function public.review_budget_material_mapping(p_id uuid,p_mapping uuid,p_version integer,p_action text,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare m public.crm_budget_material_mappings;r public.crm_project_budget_reviews;prior public.crm_budget_material_mapping_reviews;
 retry public.crm_budget_material_mapping_reviews;c public.crm_catalog;l jsonb;request_data jsonb;next_sequence integer;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator reviews material mappings';end if;
 select * into m from public.crm_budget_material_mappings where id=p_mapping;
 perform 1 from public.projects where id=m.project_id and status not in ('Completed','Cancelled') for update;
 if not found or exists(select 1 from public.crm_handovers where project_id=m.project_id and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Active project without released handover required';end if;
 select * into m from public.crm_budget_material_mappings where id=p_mapping for update;
 select * into r from public.crm_project_budget_reviews where id=m.release_id and action='Released';
 if r.id is null or r.project_id is distinct from m.project_id or m.source_snapshot is distinct from to_jsonb(r)
  or exists(select 1 from public.crm_project_budget_reviews where draft_id=r.draft_id and action='Released' and sequence>r.sequence) then raise exception 'Exact latest released cost source required';end if;
 if p_id is null or p_version is null or p_action is null or p_action not in ('Approved','Returned') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit action identity, mapping version and reason required';end if;
 request_data:=jsonb_build_object('mapping_id',p_mapping,'version',p_version,'action',p_action,'reason',trim(p_reason));
 select * into retry from public.crm_budget_material_mapping_reviews where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=request_data then return retry.id;end if;
  raise exception 'Review identity already records a different request';
 end if;
 if m.version is distinct from p_version then raise exception 'Mapping changed; review current version';end if;
 select * into prior from public.crm_budget_material_mapping_reviews where mapping_id=m.id and mapping_version=m.version order by sequence desc limit 1;
 if prior.action=p_action then raise exception 'Mapping version already records this review state';end if;
 if p_action='Approved' then
  for l in select value from jsonb_array_elements(m.lines) loop
   select * into c from public.crm_catalog where id=(l->>'catalog_id')::uuid for share;
   if c.id is null or not c.active or c.tracking not in ('Quantity','Serial')
    or l->'catalog_snapshot' is distinct from jsonb_build_object('id',c.id,'name',c.name,'unit',c.unit,'tracking',c.tracking,'version',c.version)
   then raise exception 'Catalogue changed or inactive; revise mapping before approval';end if;
  end loop;
 end if;
 select coalesce(max(sequence),0)+1 into next_sequence from public.crm_budget_material_mapping_reviews where mapping_id=m.id;
 insert into public.crm_budget_material_mapping_reviews(id,mapping_id,project_id,mapping_version,sequence,action,snapshot,request,reason,actor_id)
 values(p_id,m.id,m.project_id,m.version,next_sequence,p_action,to_jsonb(m),request_data,trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.review_budget_material_mapping(uuid,uuid,integer,text,text) from public,anon;
grant execute on function public.review_budget_material_mapping(uuid,uuid,integer,text,text) to authenticated;
commit;
