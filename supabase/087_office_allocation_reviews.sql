begin;
create table public.fin_office_product_allocation_reviews (
 id uuid primary key,
 allocation_id uuid not null references public.fin_office_product_allocations,
 allocation_version integer not null,
 sequence integer not null,
 action text not null check(action in ('Reviewed','Returned')),
 snapshot jsonb not null,
 expense_snapshot jsonb not null,
 request jsonb not null,
 reason text not null,
 actor_id uuid not null references public.profiles,
 created_at timestamptz not null default now(),
 unique(allocation_id,sequence)
);
create index office_allocation_review_actor on public.fin_office_product_allocation_reviews(actor_id);
alter table public.fin_office_product_allocation_reviews enable row level security;
revoke all on public.fin_office_product_allocation_reviews from public,anon,authenticated;
grant select on public.fin_office_product_allocation_reviews to authenticated;
create policy office_allocation_review_read on public.fin_office_product_allocation_reviews for select to authenticated using(portal_private.payables_access());
create function public.review_office_product_allocation(p_id uuid,p_allocation uuid,p_version integer,p_action text,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare d public.fin_office_product_allocations;e public.fin_expenses;w public.crm_project_workstreams;
 retry public.fin_office_product_allocation_reviews;prior public.fin_office_product_allocation_reviews;
 request_data jsonb;next_sequence integer;l jsonb;product_name text;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Active Accounts permission required';end if;
 select * into d from public.fin_office_product_allocations where id=p_allocation;
 if d.id is null then raise exception 'Allocation required';end if;
 -- Serialize source/draft decisions with the existing office draft save workflow.
 select * into e from public.fin_expenses where id=d.expense_id for update;
 if e.id is null then raise exception 'Existing office expense source required';end if;
 select * into d from public.fin_office_product_allocations where id=p_allocation for update;
 if d.expense_id is distinct from e.id then raise exception 'Exact office source required';end if;
 if p_id is null or p_version is null or p_action is null or p_action not in ('Reviewed','Returned') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit identity/version/action/reason required';end if;
 request_data:=jsonb_build_object('allocation_id',p_allocation,'version',p_version,'action',p_action,'reason',trim(p_reason));
 select * into retry from public.fin_office_product_allocation_reviews where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=request_data then return retry.id;end if;
  raise exception 'Action identity records a different request';
 end if;
 if d.version is distinct from p_version then raise exception 'Allocation changed; refresh current version';end if;
 -- A return can document corrections to a stale source; a review requires freshly frozen evidence.
 if p_action='Reviewed' then
  if e.status is distinct from 'Approved' or e.approved_by is null or e.project_id is not null or e.task_id is not null or d.source_snapshot is distinct from to_jsonb(e) then raise exception 'Refresh allocation from exact current Approved office expense before review';end if;
  for l in select value from jsonb_array_elements(d.lines) order by value->>'workstream_id' loop
   select * into w from public.crm_project_workstreams where id=(l->>'workstream_id')::uuid for share;
   select b.name into product_name from public.crm_product_lines pl join public.crm_boards b on b.id=pl.board_id where pl.id=w.product_line_id;
   perform 1 from public.projects where id=w.project_id for share;
   if not found or portal_private.finance_project_currency(w.project_id) is distinct from 'PKR' or w.id is null
    or l->'workstream_snapshot' is distinct from jsonb_build_object('id',w.id,'project_id',w.project_id,'project_name',(select p.title from public.projects p where p.id=w.project_id),'sale_id',w.sale_id,'product_line_id',w.product_line_id,'product_name',product_name)
    then raise exception 'Refresh allocation from current product workstream identities before review';end if;
  end loop;
 end if;
 select * into prior from public.fin_office_product_allocation_reviews where allocation_id=d.id and allocation_version=d.version order by sequence desc limit 1;
 if prior.action=p_action then raise exception 'This allocation version already has that review state';end if;
 select coalesce(max(sequence),0)+1 into next_sequence from public.fin_office_product_allocation_reviews where allocation_id=d.id;
 insert into public.fin_office_product_allocation_reviews(id,allocation_id,allocation_version,sequence,action,snapshot,expense_snapshot,request,reason,actor_id)
 values(p_id,d.id,d.version,next_sequence,p_action,to_jsonb(d),to_jsonb(e),request_data,trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.review_office_product_allocation(uuid,uuid,integer,text,text) from public,anon;
grant execute on function public.review_office_product_allocation(uuid,uuid,integer,text,text) to authenticated;
notify pgrst,'reload schema';
commit;
