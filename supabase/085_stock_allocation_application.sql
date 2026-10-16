begin;
create table public.fin_stock_product_allocation_applications (
 id uuid primary key,
 allocation_id uuid not null references public.fin_stock_product_allocations,
 project_id uuid not null references public.projects,
 allocation_version integer not null,
 review_id uuid not null references public.fin_stock_product_allocation_reviews,
 sequence integer not null,
 action text not null check(action in ('Applied','Withdrawn')),
 snapshot jsonb not null,
 source_snapshot jsonb not null,
 request jsonb not null,
 reason text not null,
 actor_id uuid not null references public.profiles,
 created_at timestamptz not null default now(),
 unique(allocation_id,sequence)
);
create index stock_allocation_application_project on public.fin_stock_product_allocation_applications(project_id);
create index stock_allocation_application_review on public.fin_stock_product_allocation_applications(review_id);
create index stock_allocation_application_actor on public.fin_stock_product_allocation_applications(actor_id);
alter table public.fin_stock_product_allocation_applications enable row level security;
revoke all on public.fin_stock_product_allocation_applications from public,anon,authenticated;
grant select on public.fin_stock_product_allocation_applications to authenticated;
create policy stock_allocation_application_read on public.fin_stock_product_allocation_applications for select to authenticated using(portal_private.payables_access());
create function public.apply_stock_product_allocation(p_id uuid,p_allocation uuid,p_version integer,p_review uuid,p_previous uuid,p_action text,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare d public.fin_stock_product_allocations;source_data jsonb;w public.crm_project_workstreams;
 r public.fin_stock_product_allocation_reviews;prior public.fin_stock_product_allocation_applications;retry public.fin_stock_product_allocation_applications;
 request_data jsonb;next_sequence integer;l jsonb;product_name text;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Active Accounts permission required';end if;
 select * into d from public.fin_stock_product_allocations where id=p_allocation;
 if d.id is null then raise exception 'Allocation required';end if;
 -- Snapshot decisions follow private proposal lock order without freezing stock workflows.
 perform 1 from public.projects where id=d.project_id for share;
 if not found or portal_private.finance_project_currency(d.project_id) is distinct from 'PKR' then raise exception 'Existing PKR project required';end if;
 select * into d from public.fin_stock_product_allocations where id=p_allocation for update;
 source_data:=portal_private.stock_allocation_snapshot(d.project_id);
 if p_id is null or p_version is null or p_action is null or p_action not in ('Applied','Withdrawn') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit identity/version/action/reason required';end if;
 request_data:=jsonb_build_object('allocation_id',p_allocation,'version',p_version,'review_id',p_review,'previous_id',p_previous,'action',p_action,'reason',trim(p_reason));
 select * into retry from public.fin_stock_product_allocation_applications where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=request_data then return retry.id;end if;
  raise exception 'Application identity records a different request';
 end if;
 if d.version is distinct from p_version then raise exception 'Allocation changed; refresh current version';end if;
 select * into prior from public.fin_stock_product_allocation_applications where allocation_id=d.id order by sequence desc limit 1;
 if prior.id is distinct from p_previous then raise exception 'Application changed; refresh latest event';end if;
 next_sequence:=coalesce(prior.sequence,0)+1;
 if p_action='Applied' then
  select * into r from public.fin_stock_product_allocation_reviews where allocation_id=d.id and allocation_version=d.version order by sequence desc limit 1;
  if r.id is null or r.id is distinct from p_review or r.action is distinct from 'Reviewed' or r.snapshot is distinct from to_jsonb(d) then raise exception 'Exact current Reviewed allocation required';end if;
  if (source_data->>'amount')::numeric<=0 or d.source_snapshot is distinct from source_data
   then raise exception 'Refresh allocation from the exact current positive net-stock source before review';end if;
  for l in select value from jsonb_array_elements(d.lines) order by value->>'workstream_id' loop
   select * into w from public.crm_project_workstreams where id=(l->>'workstream_id')::uuid for share;
   select b.name into product_name from public.crm_product_lines pl join public.crm_boards b on b.id=pl.board_id where pl.id=w.product_line_id;
   if w.id is null or w.project_id is distinct from d.project_id
    or l->'workstream_snapshot' is distinct from jsonb_build_object('id',w.id,'project_id',w.project_id,'sale_id',w.sale_id,'product_line_id',w.product_line_id,'product_name',product_name)
    then raise exception 'Refresh allocation from current product workstream identities before review';end if;
  end loop;

  if prior.action='Applied' and prior.review_id=r.id then raise exception 'This reviewed classification is already applied';end if;
  insert into public.fin_stock_product_allocation_applications(id,allocation_id,project_id,allocation_version,review_id,sequence,action,snapshot,source_snapshot,request,reason,actor_id)
  values(p_id,d.id,d.project_id,d.version,r.id,next_sequence,p_action,to_jsonb(d),source_data,request_data,trim(p_reason),auth.uid());
 else
  if p_review is not null or prior.id is null or prior.action is distinct from 'Applied' then raise exception 'Exact active application required for withdrawal';end if;
  insert into public.fin_stock_product_allocation_applications(id,allocation_id,project_id,allocation_version,review_id,sequence,action,snapshot,source_snapshot,request,reason,actor_id)
  values(p_id,d.id,d.project_id,prior.allocation_version,prior.review_id,next_sequence,p_action,prior.snapshot,source_data,request_data,trim(p_reason),auth.uid());
 end if;
 return p_id;
end$$;
revoke all on function public.apply_stock_product_allocation(uuid,uuid,integer,uuid,uuid,text,text) from public,anon;
grant execute on function public.apply_stock_product_allocation(uuid,uuid,integer,uuid,uuid,text,text) to authenticated;

-- One project-wide rounded net material pool; no independently rounded item totals.
create function public.finance_stock_product_report()
returns table(project_id uuid,project text,category text,stock_amount numeric,allocated_amount numeric,unallocated_amount numeric,application_id uuid,classification_state text,lines jsonb,source_snapshot jsonb)
language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Active Accounts permission required';end if;
 return query
 with pools as (
 select p.id,p.title,b.s,ap.id application,ap.action application_action,ap.snapshot applied_snapshot,
  (ap.action='Applied' and ap.project_id=p.id and ap.snapshot->>'project_id'=p.id::text
   and ap.source_snapshot=b.s and ap.snapshot->'source_snapshot'=b.s) eligible
 from public.projects p cross join lateral (select portal_private.stock_allocation_snapshot(p.id) s) b
 left join public.fin_stock_product_allocations d on d.project_id=p.id
 left join lateral (select z.* from public.fin_stock_product_allocation_applications z where z.allocation_id=d.id order by z.sequence desc limit 1) ap on true
 where portal_private.finance_project_currency(p.id)='PKR' and (jsonb_array_length(b.s->'ledger_snapshot')>0 or ap.id is not null)
 )
 select p.id,p.title,'Materials'::text,(p.s->>'amount')::numeric,
  case when p.eligible then (p.applied_snapshot->>'allocated_total')::numeric else 0::numeric end,
  (p.s->>'amount')::numeric-case when p.eligible then (p.applied_snapshot->>'allocated_total')::numeric else 0::numeric end,
  p.application,case when p.eligible then 'Applied' when p.application_action='Withdrawn' then 'Withdrawn' when p.application is not null then 'Source changed; reconciliation required' else 'Unallocated' end,
  case when p.eligible then p.applied_snapshot->'lines' else '[]'::jsonb end,p.s
 from pools p order by p.title,p.id;
end$$;
revoke all on function public.finance_stock_product_report() from public,anon;
grant execute on function public.finance_stock_product_report() to authenticated;
notify pgrst,'reload schema';
commit;
