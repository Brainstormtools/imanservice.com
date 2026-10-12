begin;
create table public.crm_project_budget_reviews (
 id uuid primary key,
 draft_id uuid not null references public.crm_project_budget_drafts,
 project_id uuid not null references public.projects,
 draft_version integer not null,
 sequence integer not null,
 action text not null check(action in ('Reviewed','Returned','Released')),
 review_id uuid references public.crm_project_budget_reviews,
 snapshot jsonb not null,
 request jsonb not null,
 reason text not null,
 actor_id uuid not null references public.profiles,
 created_at timestamptz not null default now(),
 unique(draft_id,sequence)
);
create index budget_review_project on public.crm_project_budget_reviews(project_id);
create index budget_review_actor on public.crm_project_budget_reviews(actor_id);
create index budget_review_parent on public.crm_project_budget_reviews(review_id);
alter table public.crm_project_budget_reviews enable row level security;
revoke all on public.crm_project_budget_reviews from public,anon,authenticated;
grant select on public.crm_project_budget_reviews to authenticated;
create policy budget_review_read on public.crm_project_budget_reviews for select to authenticated using(public.is_admin());

create function public.review_project_budget_draft(p_id uuid,p_draft uuid,p_version integer,p_action text,p_review uuid,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare d public.crm_project_budget_drafts;pub public.crm_boq_offer_publications;s public.crm_sales;
 prior public.crm_project_budget_reviews;retry public.crm_project_budget_reviews;
 request_data jsonb;next_sequence integer;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator reviews private budgets';end if;
 select * into d from public.crm_project_budget_drafts where id=p_draft;
 perform 1 from public.projects where id=d.project_id and status not in ('Completed','Cancelled') for update;
 if not found or exists(select 1 from public.crm_handovers where project_id=d.project_id and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Active project without released handover required';end if;
 select * into pub from public.crm_boq_offer_publications where id=d.offer_id for update;
 select * into s from public.crm_sales where id=d.sale_id for update;
 select * into d from public.crm_project_budget_drafts where id=p_draft for update;
 if pub.status is distinct from 'Accepted' or not pub.consent or pub.version is distinct from (d.source_snapshot->>'version')::integer
  or pub.project_id is distinct from d.project_id or pub.company_id is distinct from s.company_id
  or s.project_id is distinct from d.project_id or s.currency is distinct from d.currency or pub.currency is distinct from d.currency
  or not exists(select 1 from public.projects where id=d.project_id and company_id=pub.company_id)
 then raise exception 'Exact accepted source and original project sale/customer/currency required';end if;
 if p_id is null or p_version is null or p_action is null or p_action not in ('Reviewed','Returned','Released')
  or length(trim(coalesce(p_reason,''))) not between 3 and 2000
  or (p_action<>'Released' and p_review is not null)
 then raise exception 'Explicit supported action, version, identity and reason required';end if;
 request_data:=jsonb_build_object('draft_id',p_draft,'version',p_version,'action',p_action,'review_id',p_review,'reason',trim(p_reason));
 select * into retry from public.crm_project_budget_reviews where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=request_data then return retry.id;end if;
  raise exception 'Action identity already records a different request';
 end if;
 if d.version is distinct from p_version then raise exception 'Budget draft changed; refresh and review current version';end if;
 select * into prior from public.crm_project_budget_reviews where draft_id=d.id and draft_version=d.version order by sequence desc limit 1;
 if prior.action='Released' then raise exception 'Released cost snapshot is immutable; revise the draft for a new review';end if;
 if p_action='Reviewed' and prior.action='Reviewed' then raise exception 'This draft version is already reviewed';end if;
 if p_action='Returned' and prior.action='Returned' then raise exception 'This draft version is already returned';end if;
 if p_action='Released' and (p_review is null or prior.id is distinct from p_review or prior.action is distinct from 'Reviewed' or prior.snapshot is distinct from to_jsonb(d)) then
  raise exception 'Exact current reviewed cost snapshot required for release';
 end if;
 select coalesce(max(sequence),0)+1 into next_sequence from public.crm_project_budget_reviews where draft_id=d.id;
 insert into public.crm_project_budget_reviews(id,draft_id,project_id,draft_version,sequence,action,review_id,snapshot,request,reason,actor_id)
 values(p_id,d.id,d.project_id,d.version,next_sequence,p_action,p_review,to_jsonb(d),request_data,trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.review_project_budget_draft(uuid,uuid,integer,text,uuid,text) from public,anon;
grant execute on function public.review_project_budget_draft(uuid,uuid,integer,text,uuid,text) to authenticated;
commit;
