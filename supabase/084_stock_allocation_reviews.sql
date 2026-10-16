begin;
create table public.fin_stock_product_allocation_reviews (
 id uuid primary key,
 allocation_id uuid not null references public.fin_stock_product_allocations,
 project_id uuid not null references public.projects,
 allocation_version integer not null,
 sequence integer not null,
 action text not null check(action in ('Reviewed','Returned')),
 snapshot jsonb not null,
 source_snapshot jsonb not null,
 request jsonb not null,
 reason text not null,
 actor_id uuid not null references public.profiles,
 created_at timestamptz not null default now(),
 unique(allocation_id,sequence)
);
create index stock_allocation_review_project on public.fin_stock_product_allocation_reviews(project_id);
create index stock_allocation_review_actor on public.fin_stock_product_allocation_reviews(actor_id);
alter table public.fin_stock_product_allocation_reviews enable row level security;
revoke all on public.fin_stock_product_allocation_reviews from public,anon,authenticated;
grant select on public.fin_stock_product_allocation_reviews to authenticated;
create policy stock_allocation_review_read on public.fin_stock_product_allocation_reviews for select to authenticated using(portal_private.payables_access());
create function public.review_stock_product_allocation(p_id uuid,p_allocation uuid,p_version integer,p_action text,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare d public.fin_stock_product_allocations;source_data jsonb;w public.crm_project_workstreams;
 retry public.fin_stock_product_allocation_reviews;prior public.fin_stock_product_allocation_reviews;
 request_data jsonb;next_sequence integer;l jsonb;product_name text;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Active Accounts permission required';end if;
 select * into d from public.fin_stock_product_allocations where id=p_allocation;
 if d.id is null then raise exception 'Allocation required';end if;
 -- Match the private draft project/allocation lock order; do not lock stock requests/items.
 perform 1 from public.projects where id=d.project_id for share;
 if not found or portal_private.finance_project_currency(d.project_id) is distinct from 'PKR' then raise exception 'Existing PKR project required';end if;
 select * into d from public.fin_stock_product_allocations where id=p_allocation for update;
 source_data:=portal_private.stock_allocation_snapshot(d.project_id);
 if p_id is null or p_version is null or p_action is null or p_action not in ('Reviewed','Returned') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit identity/version/action/reason required';end if;
 request_data:=jsonb_build_object('allocation_id',p_allocation,'version',p_version,'action',p_action,'reason',trim(p_reason));
 select * into retry from public.fin_stock_product_allocation_reviews where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=request_data then return retry.id;end if;
  raise exception 'Action identity records a different request';
 end if;
 if d.version is distinct from p_version then raise exception 'Allocation changed; refresh current version';end if;
 -- A return can document corrections to a stale source; a review requires freshly frozen evidence.
 if p_action='Reviewed' then
  if (source_data->>'amount')::numeric<=0 or d.source_snapshot is distinct from source_data
   then raise exception 'Refresh allocation from the exact current positive net-stock source before review';end if;
  for l in select value from jsonb_array_elements(d.lines) order by value->>'workstream_id' loop
   select * into w from public.crm_project_workstreams where id=(l->>'workstream_id')::uuid for share;
   select b.name into product_name from public.crm_product_lines pl join public.crm_boards b on b.id=pl.board_id where pl.id=w.product_line_id;
   if w.id is null or w.project_id is distinct from d.project_id
    or l->'workstream_snapshot' is distinct from jsonb_build_object('id',w.id,'project_id',w.project_id,'sale_id',w.sale_id,'product_line_id',w.product_line_id,'product_name',product_name)
    then raise exception 'Refresh allocation from current product workstream identities before review';end if;
  end loop;
 end if;
 select * into prior from public.fin_stock_product_allocation_reviews where allocation_id=d.id and allocation_version=d.version order by sequence desc limit 1;
 if prior.action=p_action then raise exception 'This allocation version already has that review state';end if;
 select coalesce(max(sequence),0)+1 into next_sequence from public.fin_stock_product_allocation_reviews where allocation_id=d.id;
 insert into public.fin_stock_product_allocation_reviews(id,allocation_id,project_id,allocation_version,sequence,action,snapshot,source_snapshot,request,reason,actor_id)
 values(p_id,d.id,d.project_id,d.version,next_sequence,p_action,to_jsonb(d),source_data,request_data,trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.review_stock_product_allocation(uuid,uuid,integer,text,text) from public,anon;
grant execute on function public.review_stock_product_allocation(uuid,uuid,integer,text,text) to authenticated;
notify pgrst,'reload schema';
commit;
