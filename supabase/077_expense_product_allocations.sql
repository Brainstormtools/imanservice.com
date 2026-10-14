begin;
create table public.fin_expense_product_allocations(
 id uuid primary key,expense_id uuid not null unique references public.fin_expenses,project_id uuid not null references public.projects,
 currency text not null check(currency='PKR'),source_snapshot jsonb not null,lines jsonb not null,
 allocated_total numeric(14,2) not null,unallocated_amount numeric(14,2) not null,version integer not null default 1,
 reason text not null,created_by uuid not null references public.profiles,created_at timestamptz not null default now()
);
create table public.fin_expense_product_allocation_history(
 id uuid primary key default gen_random_uuid(),allocation_id uuid not null references public.fin_expense_product_allocations,
 project_id uuid not null references public.projects,revision integer not null,before_record jsonb,after_record jsonb not null,
 request jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(allocation_id,revision)
);
create index expense_allocation_project on public.fin_expense_product_allocations(project_id);
create index expense_allocation_author on public.fin_expense_product_allocations(created_by);
create index expense_allocation_history_project on public.fin_expense_product_allocation_history(project_id);
create index expense_allocation_history_actor on public.fin_expense_product_allocation_history(actor_id);
do $$declare t text;begin foreach t in array array['fin_expense_product_allocations','fin_expense_product_allocation_history'] loop execute format('alter table public.%I enable row level security',t);execute format('revoke all on public.%I from public,anon,authenticated',t);execute format('grant select on public.%I to authenticated',t);execute format('create policy expense_allocation_read on public.%I for select to authenticated using(portal_private.payables_access())',t);end loop;end$$;

create function public.finance_product_allocation_workstreams()
returns table(id uuid,project_id uuid,product_line_id uuid,product_name text) language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Accounts access required';end if;
 return query select w.id,w.project_id,w.product_line_id,b.name from public.crm_project_workstreams w join public.crm_product_lines l on l.id=w.product_line_id join public.crm_boards b on b.id=l.board_id where portal_private.finance_project_currency(w.project_id)='PKR' order by w.project_id,b.name,w.id;
end$$;

create function public.save_expense_product_allocation(p_id uuid,p_version integer,p_expense uuid,p_expense_version integer,p_lines jsonb,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare e public.fin_expenses;old public.fin_expense_product_allocations;saved public.fin_expense_product_allocations;
 w public.crm_project_workstreams;item jsonb;v_lines jsonb:='[]';v_input jsonb:='[]';request_data jsonb;amount numeric;total numeric:=0;seen uuid[]:='{}';name text;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Accounts prepares private product allocation drafts';end if;
 select * into e from public.fin_expenses where id=p_expense for update;
 perform 1 from public.projects where id=e.project_id for share;
 if not found or portal_private.finance_project_currency(e.project_id)<>'PKR' then raise exception 'Existing PKR project expense required';end if;
 if e.status is distinct from 'Approved' or e.approved_by is null or e.version is distinct from p_expense_version then raise exception 'Exact current Approved expense required';end if;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 or jsonb_typeof(p_lines) is distinct from 'array' or jsonb_array_length(p_lines) not between 1 and 100 then raise exception 'Explicit allocation identity/reason and 1–100 manual product splits required';end if;
 for item in select value from jsonb_array_elements(p_lines) order by value->>'workstream_id' loop
  if jsonb_typeof(item) is distinct from 'object' or (select count(*) from jsonb_object_keys(item))<>2 or (item-array['workstream_id','amount'])<>'{}'::jsonb or coalesce(item->>'amount','') !~ '^\d{1,8}(\.\d{1,2})?$' then raise exception 'Exact workstream and explicit bounded two-decimal amount required';end if;
  amount:=(item->>'amount')::numeric;if amount<=0 then raise exception 'Positive manual split amount required';end if;
  select * into w from public.crm_project_workstreams where id=(item->>'workstream_id')::uuid for share;
  if w.id is null or w.project_id is distinct from e.project_id then raise exception 'Product workstream must belong to the exact expense project';end if;
  if w.id=any(seen) then raise exception 'Use one split per workstream';end if;seen:=seen||w.id;
  select b.name into name from public.crm_product_lines l join public.crm_boards b on b.id=l.board_id where l.id=w.product_line_id;
  if name is null then raise exception 'Product identity unavailable';end if;
  total:=total+amount;if total>e.amount then raise exception 'Allocated amounts cannot exceed recorded approved expense';end if;
  v_input:=v_input||jsonb_build_array(jsonb_build_object('workstream_id',w.id,'amount',amount));
  v_lines:=v_lines||jsonb_build_array(jsonb_build_object('workstream_id',w.id,'amount',amount,'workstream_snapshot',jsonb_build_object('id',w.id,'project_id',w.project_id,'sale_id',w.sale_id,'product_line_id',w.product_line_id,'product_name',name)));
 end loop;
 request_data:=jsonb_build_object('expense_id',p_expense,'expense_version',p_expense_version,'version',p_version,'lines',v_input,'reason',trim(p_reason));
 select * into old from public.fin_expense_product_allocations where id=p_id for update;
 if old.id is not null then
  if old.expense_id is distinct from e.id or old.project_id is distinct from e.project_id then raise exception 'Allocation expense/project source cannot change';end if;
  if exists(select 1 from public.fin_expense_product_allocation_history h where h.allocation_id=old.id and h.actor_id=auth.uid() and h.request=request_data and h.revision=coalesce(p_version,0)+1) then return old.id;end if;
  if p_version is null or old.version is distinct from p_version then raise exception 'Allocation draft changed; refresh current version';end if;
  if (old.source_snapshot->>'amount')::numeric is distinct from e.amount or old.source_snapshot->>'category' is distinct from e.category then raise exception 'Original approved expense amount/category changed; allocation requires separate reconciliation';end if;
  update public.fin_expense_product_allocations set source_snapshot=to_jsonb(e),lines=v_lines,allocated_total=total,unallocated_amount=e.amount-total,version=version+1,reason=trim(p_reason) where id=old.id returning * into saved;
 else
  if p_version is not null then raise exception 'Unknown allocation cannot be revised';end if;
  insert into public.fin_expense_product_allocations(id,expense_id,project_id,currency,source_snapshot,lines,allocated_total,unallocated_amount,reason,created_by)
  values(p_id,e.id,e.project_id,'PKR',to_jsonb(e),v_lines,total,e.amount-total,trim(p_reason),auth.uid()) returning * into saved;
 end if;
 insert into public.fin_expense_product_allocation_history(allocation_id,project_id,revision,before_record,after_record,request,reason,actor_id)
 values(saved.id,saved.project_id,saved.version,case when old.id is null then null else to_jsonb(old) end,to_jsonb(saved),request_data,trim(p_reason),auth.uid());
 return saved.id;
end$$;
revoke all on function public.finance_product_allocation_workstreams(),public.save_expense_product_allocation(uuid,integer,uuid,integer,jsonb,text) from public,anon;
grant execute on function public.finance_product_allocation_workstreams(),public.save_expense_product_allocation(uuid,integer,uuid,integer,jsonb,text) to authenticated;
notify pgrst,'reload schema';
commit;
