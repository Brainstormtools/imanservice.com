begin;
create table public.crm_project_budget_drafts(
 id uuid primary key,offer_id uuid not null unique references public.crm_boq_offer_publications,project_id uuid not null references public.projects,
 sale_id uuid not null references public.crm_sales,currency text not null,source_snapshot jsonb not null,baseline_snapshot jsonb not null,
 data jsonb not null,total_cost numeric(14,2) not null,block_totals jsonb not null,version integer not null default 1,
 reason text not null,created_by uuid not null references public.profiles,created_at timestamptz not null default now()
);
create table public.crm_project_budget_draft_history(
 id uuid primary key default gen_random_uuid(),draft_id uuid not null references public.crm_project_budget_drafts,project_id uuid not null references public.projects,
 revision integer not null,before_record jsonb,after_record jsonb not null,request jsonb not null,reason text not null,
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(draft_id,revision)
);
create index budget_draft_project on public.crm_project_budget_drafts(project_id);
create index budget_draft_sale on public.crm_project_budget_drafts(sale_id);
create index budget_draft_author on public.crm_project_budget_drafts(created_by);
create index budget_draft_history_project on public.crm_project_budget_draft_history(project_id);
create index budget_draft_history_actor on public.crm_project_budget_draft_history(actor_id);
do $$declare t text;begin foreach t in array array['crm_project_budget_drafts','crm_project_budget_draft_history'] loop execute format('alter table public.%I enable row level security',t);execute format('revoke all on public.%I from public,anon,authenticated',t);execute format('grant select on public.%I to authenticated',t);execute format('create policy budget_draft_read on public.%I for select to authenticated using(public.is_admin())',t);end loop;end$$;

create function public.save_project_budget_draft(p_id uuid,p_version integer,p_offer uuid,p_offer_version integer,p_data jsonb,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare pub public.crm_boq_offer_publications;s public.crm_sales;o public.crm_boq_offers;old public.crm_project_budget_drafts;saved public.crm_project_budget_drafts;
 item jsonb;lines jsonb:='[]';d jsonb;v_request jsonb;qty numeric;rate numeric;cost numeric;total numeric:=0;blocks jsonb:='{"Material":0,"Labour":0,"Inventory":0,"TADA":0}';keys text[]:='{}';key text;block text;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator prepares private budget drafts';end if;
 select * into pub from public.crm_boq_offer_publications where id=p_offer;
 perform 1 from public.projects where id=pub.project_id and status not in ('Completed','Cancelled') for update;
 if not found or exists(select 1 from public.crm_handovers where project_id=pub.project_id and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Active project without released handover required';end if;
 select * into pub from public.crm_boq_offer_publications where id=p_offer for update;
 if pub.status is distinct from 'Accepted' or not pub.consent or pub.version is distinct from p_offer_version then raise exception 'Exact client-approved additional offer required';end if;
 select * into o from public.crm_boq_offers where id=pub.id;select * into s from public.crm_sales where id=o.sale_id for update;
 if s.id is null or s.project_id is distinct from pub.project_id or s.company_id is distinct from pub.company_id or s.currency is distinct from pub.currency or not exists(select 1 from public.projects where id=pub.project_id and company_id=pub.company_id) then raise exception 'Original project sale/customer/currency must match';end if;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Draft ID and explicit revision reason required';end if;
 if jsonb_typeof(p_data) is distinct from 'object' or (p_data-array['title','notes','lines'])<>'{}'::jsonb or jsonb_typeof(p_data->'title') is distinct from 'string' or length(trim(p_data->>'title')) not between 3 and 160 or jsonb_typeof(p_data->'notes') is distinct from 'string' or length(p_data->>'notes')>4000 or jsonb_typeof(p_data->'lines') is distinct from 'array' or jsonb_array_length(p_data->'lines') not between 1 and 100 then raise exception 'Explicit bounded title/notes and 1–100 cost lines required';end if;
 for item in select value from jsonb_array_elements(p_data->'lines') loop
  block:=item->>'block';
  if jsonb_typeof(item) is distinct from 'object' or (select count(*) from jsonb_object_keys(item))<>5 or block is null or block not in ('Material','Labour','Inventory','TADA') or jsonb_typeof(item->'description') is distinct from 'string' or length(trim(item->>'description')) not between 3 and 1000 or jsonb_typeof(item->'unit') is distinct from 'string' or length(trim(item->>'unit')) not between 1 and 30 or coalesce(item->>'quantity','') !~ '^\d{1,9}(\.\d{1,6})?$' or coalesce(item->>'unit_cost','') !~ '^\d{1,10}(\.\d{1,2})?$' then raise exception 'Complete bounded manual cost lines using existing quotation blocks required';end if;
  qty:=(item->>'quantity')::numeric;rate:=(item->>'unit_cost')::numeric;if qty<=0 then raise exception 'Positive explicit cost quantity required';end if;
  cost:=round(qty*rate,2);total:=total+cost;if total>999999999999.99 then raise exception 'Cost proposal exceeds technical bounds';end if;
  key:=jsonb_build_array(block,lower(trim(item->>'description')),lower(trim(item->>'unit')))::text;if key=any(keys) then raise exception 'Duplicate cost line; combine its quantity';end if;keys:=keys||key;
  blocks:=jsonb_set(blocks,array[block],to_jsonb((blocks->>block)::numeric+cost));
  lines:=lines||jsonb_build_array(jsonb_build_object('block',block,'description',trim(item->>'description'),'unit',trim(item->>'unit'),'quantity',qty,'unit_cost',rate,'cost',cost));
 end loop;
 d:=jsonb_build_object('title',trim(p_data->>'title'),'notes',trim(p_data->>'notes'),'lines',lines);
 v_request:=jsonb_build_object('offer_id',p_offer,'offer_version',p_offer_version,'version',p_version,'data',d,'reason',trim(p_reason));
 select * into old from public.crm_project_budget_drafts where id=p_id for update;
 if old.id is not null then
  if old.offer_id is distinct from p_offer then raise exception 'Budget draft source cannot change';end if;
  if exists(select 1 from public.crm_project_budget_draft_history h where h.draft_id=old.id and h.actor_id=auth.uid() and h.request=v_request and h.revision=coalesce(p_version,0)+1) then return old.id;end if;
  if p_version is null or old.version is distinct from p_version then raise exception 'Budget draft changed; refresh before revising';end if;
  update public.crm_project_budget_drafts set data=d,total_cost=total,block_totals=blocks,version=version+1,reason=trim(p_reason) where id=old.id returning * into saved;
 else
  if p_version is not null then raise exception 'Unknown draft cannot be revised';end if;
  insert into public.crm_project_budget_drafts(id,offer_id,project_id,sale_id,currency,source_snapshot,baseline_snapshot,data,total_cost,block_totals,reason,created_by)
   values(p_id,pub.id,pub.project_id,s.id,s.currency,to_jsonb(pub),s.planned_budget,d,total,blocks,trim(p_reason),auth.uid()) returning * into saved;
 end if;
 insert into public.crm_project_budget_draft_history(draft_id,project_id,revision,before_record,after_record,request,reason,actor_id)
  values(saved.id,saved.project_id,saved.version,case when old.id is null then null else to_jsonb(old) end,to_jsonb(saved),v_request,trim(p_reason),auth.uid());
 return saved.id;
end$$;
revoke all on function public.save_project_budget_draft(uuid,integer,uuid,integer,jsonb,text) from public,anon;
grant execute on function public.save_project_budget_draft(uuid,integer,uuid,integer,jsonb,text) to authenticated;
commit;
