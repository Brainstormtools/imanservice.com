begin;
create table public.crm_mapping_material_requests(
 id uuid primary key,offer_id uuid not null unique references public.crm_boq_offer_publications,
 mapping_id uuid not null references public.crm_budget_material_mappings,approval_id uuid not null references public.crm_budget_material_mapping_reviews,
 project_id uuid not null references public.projects,request_id uuid not null unique references public.sc_requests,
 snapshot jsonb not null,request jsonb not null,request_snapshot jsonb not null,line_snapshot jsonb not null,
 reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now()
);
create index mapping_request_mapping on public.crm_mapping_material_requests(mapping_id);
create index mapping_request_approval on public.crm_mapping_material_requests(approval_id);
create index mapping_request_project on public.crm_mapping_material_requests(project_id);
create index mapping_request_actor on public.crm_mapping_material_requests(actor_id);
alter table public.crm_mapping_material_requests enable row level security;
revoke all on public.crm_mapping_material_requests from public,anon,authenticated;
grant select on public.crm_mapping_material_requests to authenticated;
create policy mapping_request_read on public.crm_mapping_material_requests for select to authenticated using(public.is_admin());
create function public.request_mapping_materials(p_id uuid,p_mapping uuid,p_version integer,p_approval uuid,p_purpose text,p_site text,p_required_by date,p_reason text,p_unrequested boolean)
returns uuid language plpgsql security definer set search_path='' as $$
declare m public.crm_budget_material_mappings;r public.crm_project_budget_reviews;a public.crm_budget_material_mapping_reviews;
 prior public.crm_mapping_material_requests;c public.crm_catalog;l jsonb;rows jsonb;request_data jsonb;doc uuid;offer uuid;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator generates reviewed material requests';end if;
 select * into m from public.crm_budget_material_mappings where id=p_mapping;
 perform 1 from public.projects where id=m.project_id and status not in ('Completed','Cancelled') for update;
 if not found or exists(select 1 from public.crm_handovers where project_id=m.project_id and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Active project without released handover required';end if;
 if p_unrequested is distinct from true or p_id is null or p_version is null or p_approval is null or length(trim(coalesce(p_purpose,''))) not between 3 and 2000 or length(trim(coalesce(p_site,''))) not between 1 and 300
  or p_required_by is null or not isfinite(p_required_by) or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Exact identity/version/approval and explicit purpose/site/finite need date/reason required';end if;
 request_data:=jsonb_build_object('mapping_id',p_mapping,'version',p_version,'approval_id',p_approval,'purpose',trim(p_purpose),'site',trim(p_site),'required_by',p_required_by,'reason',trim(p_reason),'unrequested_confirmation',p_unrequested);
 select * into prior from public.crm_mapping_material_requests where id=p_id;
 if prior.id is not null then
  if prior.actor_id=auth.uid() and prior.request=request_data then return prior.request_id;end if;
  raise exception 'Generation identity already records a different request';
 end if;
 select * into m from public.crm_budget_material_mappings where id=p_mapping for update;
 select * into r from public.crm_project_budget_reviews where id=m.release_id and action='Released';
 if r.id is null or r.project_id is distinct from m.project_id or m.source_snapshot is distinct from to_jsonb(r)
  or exists(select 1 from public.crm_project_budget_reviews where draft_id=r.draft_id and action='Released' and sequence>r.sequence) then raise exception 'Exact latest released cost source required';end if;
 select * into a from public.crm_budget_material_mapping_reviews where mapping_id=m.id and mapping_version=m.version order by sequence desc limit 1;
 if m.version is distinct from p_version or a.id is distinct from p_approval or a.action is distinct from 'Approved' or a.snapshot is distinct from to_jsonb(m) then raise exception 'Exact current approved mapping snapshot required';end if;
 offer:=(r.snapshot->>'offer_id')::uuid;
if not exists(select 1 from public.crm_sales s join public.projects p on p.id=s.project_id join public.crm_boq_offer_publications b on b.id=offer
  where s.id=(r.snapshot->>'sale_id')::uuid and p.id=m.project_id and p.company_id=s.company_id and b.company_id=s.company_id
   and b.project_id=p.id and b.status='Accepted' and b.consent and b.currency=s.currency and s.currency='PKR'
   and b.version=(r.snapshot->'source_snapshot'->>'version')::integer) then raise exception 'Original PKR project sale/customer/accepted source context required';end if;
 if exists(select 1 from public.crm_mapping_material_requests where offer_id=offer) then raise exception 'This accepted offer already generated a request; quantity adjustments/cancellation/replacement require a separate documented workflow';end if;
 for l in select value from jsonb_array_elements(m.lines) order by value->>'catalog_id' loop
  select * into c from public.crm_catalog where id=(l->>'catalog_id')::uuid for share;
  if c.id is null or not c.active or c.tracking not in ('Quantity','Serial')
   or l->'catalog_snapshot' is distinct from jsonb_build_object('id',c.id,'name',c.name,'unit',c.unit,'tracking',c.tracking,'version',c.version)
  then raise exception 'Catalogue changed or inactive; revise/reapprove mapping before request generation';end if;
 end loop;
 select jsonb_agg(jsonb_build_object('item_id',item,'quantity',qty) order by item) into rows
 from (select value->>'catalog_id' item,sum((value->>'quantity')::numeric) qty from jsonb_array_elements(m.lines) group by value->>'catalog_id') grouped;
 doc:=public.create_supply_request(m.project_id,null,p_purpose,p_site,p_required_by,rows);
 update public.sc_requests set source='Reviewed additional Material' where id=doc;
 insert into public.crm_mapping_material_requests(id,offer_id,mapping_id,approval_id,project_id,request_id,snapshot,request,request_snapshot,line_snapshot,reason,actor_id)
 values(p_id,offer,m.id,a.id,m.project_id,doc,to_jsonb(a),request_data,(select to_jsonb(q) from public.sc_requests q where id=doc),
  (select jsonb_agg(to_jsonb(q) order by item_id) from public.sc_request_lines q where request_id=doc),trim(p_reason),auth.uid());
 return doc;
end$$;
revoke all on function public.request_mapping_materials(uuid,uuid,integer,uuid,text,text,date,text,boolean) from public,anon;
grant execute on function public.request_mapping_materials(uuid,uuid,integer,uuid,text,text,date,text,boolean) to authenticated;
commit;
