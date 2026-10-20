begin;
-- Append-only retirement and correction links; accepted offers, finance and execution remain unchanged.
create table public.crm_boq_line_retirements (
 id uuid primary key default gen_random_uuid(),project_id uuid not null references public.projects,
 proposal_id uuid not null unique references public.crm_boq_line_proposals,review_id uuid not null references public.crm_boq_line_reviews,
 publication_id uuid references public.crm_boq_revision_publications,
 reason text not null check(length(trim(reason)) between 3 and 2000),actor_id uuid not null references public.profiles,
 retired_at timestamptz not null default now(),snapshot jsonb not null
);
create index boq_line_retirement_project on public.crm_boq_line_retirements(project_id);
create table public.crm_boq_line_corrections (
 id uuid primary key default gen_random_uuid(),project_id uuid not null references public.projects,
 previous_id uuid not null unique references public.crm_boq_line_proposals,proposal_id uuid not null unique references public.crm_boq_line_proposals,
 reason text not null check(length(trim(reason)) between 3 and 2000),actor_id uuid not null references public.profiles,
 created_at timestamptz not null default now(),snapshot jsonb not null,check(previous_id<>proposal_id)
);
create index boq_line_correction_project on public.crm_boq_line_corrections(project_id);
alter table public.crm_boq_line_retirements enable row level security;
alter table public.crm_boq_line_corrections enable row level security;
revoke all on public.crm_boq_line_retirements,public.crm_boq_line_corrections from anon,authenticated;
grant select on public.crm_boq_line_retirements,public.crm_boq_line_corrections to authenticated;
create policy boq_line_retirement_read on public.crm_boq_line_retirements for select to authenticated using(portal_private.execution_manager(project_id));
create policy boq_line_correction_read on public.crm_boq_line_corrections for select to authenticated using(portal_private.execution_manager(project_id));
create trigger boq_line_retirement_immutable before update or delete on public.crm_boq_line_retirements for each row execute function portal_private.boq_line_evidence_immutable();
create trigger boq_line_correction_immutable before update or delete on public.crm_boq_line_corrections for each row execute function portal_private.boq_line_evidence_immutable();
create function public.retire_boq_line_proposal(p_proposal uuid,p_review uuid,p_publication uuid,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare p public.projects;q public.crm_boq_line_proposals;v public.crm_boq_line_reviews;latest public.crm_boq_revision_publications;t public.crm_boq_line_retirements;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Current administrator retirement required';end if;
 if length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Explicit retirement reason required';end if;
 select * into p from public.projects where id=(select project_id from public.crm_boq_line_proposals where id=p_proposal) for update;
 select * into q from public.crm_boq_line_proposals where id=p_proposal;
 select * into v from public.crm_boq_line_reviews where proposal_id=q.id;
 if q.id is null or v.id is distinct from p_review or v.outcome is distinct from 'Reviewed' or v.snapshot is distinct from to_jsonb(q) then raise exception 'Exact immutable Reviewed proposal required';end if;
 select * into latest from public.crm_boq_revision_publications where proposal_id=q.id order by revision desc limit 1;
 if latest.id is distinct from p_publication then raise exception 'Exact latest publication history required';end if;
 if exists(select 1 from public.crm_boq_revision_publications f left join public.crm_boq_revision_decisions d on d.publication_id=f.id where f.proposal_id=q.id and coalesce(d.outcome,'Published') not in ('Declined','Withdrawn')) then raise exception 'Open or Accepted client offer prevents retirement';end if;
 select * into t from public.crm_boq_line_retirements where proposal_id=q.id;
 if t.id is not null then
  if t.review_id=p_review and t.publication_id is not distinct from p_publication and t.reason=trim(p_reason) and t.actor_id=auth.uid() then return;end if;
  raise exception 'Retirement already has different immutable evidence';
 end if;
 insert into public.crm_boq_line_retirements(project_id,proposal_id,review_id,publication_id,reason,actor_id,snapshot)
 values(q.project_id,q.id,v.id,latest.id,trim(p_reason),auth.uid(),jsonb_build_object('proposal',to_jsonb(q),'review',to_jsonb(v),'publications',coalesce((select jsonb_agg(to_jsonb(f) order by f.revision) from public.crm_boq_revision_publications f where f.proposal_id=q.id),'[]'::jsonb),'decisions',coalesce((select jsonb_agg(to_jsonb(d) order by f.revision) from public.crm_boq_revision_publications f join public.crm_boq_revision_decisions d on d.publication_id=f.id where f.proposal_id=q.id),'[]'::jsonb)));
end$$;
create or replace function portal_private.boq_revision_current(p_proposal uuid) returns void language plpgsql set search_path='' as $$
declare q public.crm_boq_line_proposals;p public.projects;c public.crm_project_changes;s public.crm_sales;b public.crm_quote_publications;v public.crm_boq_line_reviews;
begin
 select * into p from public.projects where id=(select project_id from public.crm_boq_line_proposals where id=p_proposal) for update;
 select * into q from public.crm_boq_line_proposals where id=p_proposal;
 select * into c from public.crm_project_changes where id=q.change_id for update;
 select * into s from public.crm_sales where id=q.sale_id for update;
 select * into b from public.crm_quote_publications where id=q.baseline_id for update;
 select * into v from public.crm_boq_line_reviews where proposal_id=q.id;
 if exists(select 1 from public.crm_boq_line_retirements where proposal_id=p_proposal) or q.id is null or v.outcome is distinct from 'Reviewed' or v.snapshot is distinct from to_jsonb(q)
  or p.id is null or p.status in ('Completed','Cancelled') or exists(select 1 from public.crm_handovers where project_id=p.id and status in ('Awaiting signatures','Signed','Closed'))
  or c.version is distinct from q.change_version or c.details->>'status' is distinct from 'Approved'
  or b.version is distinct from q.baseline_version or b.status is distinct from 'Accepted' or b.items->(q.line_position-1) is distinct from q.source
  or s.id is null or s.project_id is distinct from p.id or s.publication_id is distinct from b.id or s.company_id is distinct from b.company_id or p.company_id is distinct from b.company_id or s.currency is distinct from b.currency
 then raise exception 'Exact current reviewed proposal, Approved change and accepted source on active project required';end if;
end$$;
create function portal_private.submit_boq_line_scope(p_id uuid,p_project uuid,p_change uuid,p_change_version integer,p_baseline uuid,p_baseline_version integer,p_position integer,p_source jsonb,p_action text,p_replacement jsonb,p_reason text,p_previous uuid) returns uuid language plpgsql set search_path='' as $$
declare p public.projects;c public.crm_project_changes;s public.crm_sales;b public.crm_quote_publications;old public.crm_boq_line_proposals;prior public.crm_boq_line_proposals;r jsonb;
begin
 if auth.uid() is null or not portal_private.execution_manager(p_project) then raise exception 'Current assigned project manager access required';end if;
 select * into p from public.projects where id=p_project for update;
 if p.id is null or p.status in ('Completed','Cancelled') or exists(select 1 from public.crm_handovers where project_id=p.id and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Active project without released handover required';end if;
 select * into c from public.crm_project_changes where id=p_change and project_id=p.id for update;
 if c.id is null or c.version is distinct from p_change_version or c.details->>'status' is distinct from 'Approved' then raise exception 'Exact current Approved internal change required';end if;
 select * into s from public.crm_sales where project_id=p.id for update;
 select * into b from public.crm_quote_publications where id=s.publication_id for update;
 if b.id is null or b.id is distinct from p_baseline or b.version is distinct from p_baseline_version or b.status<>'Accepted' or b.company_id<>s.company_id or p.company_id<>s.company_id or b.currency<>s.currency then raise exception 'Exact current accepted baseline required';end if;
 if p_position is null or p_position<1 or p_position>jsonb_array_length(b.items) or p_source is distinct from b.items->(p_position-1) then raise exception 'Exact original accepted line required';end if;
 if p_id is null or p_action is null or p_action not in ('Replace','Remove') or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Explicit proposal action and reason required';end if;
 if p_action='Remove' then
  if p_replacement is not null then raise exception 'Removal must not invent a replacement or zero price';end if;
 else
  if jsonb_typeof(p_replacement) is distinct from 'object' or (select count(*) from jsonb_object_keys(p_replacement))<>4 or not(p_replacement ?& array['description','unit','quantity','unit_price'])
   or jsonb_typeof(p_replacement->'description') is distinct from 'string' or length(trim(p_replacement->>'description')) not between 3 and 500
   or jsonb_typeof(p_replacement->'unit') is distinct from 'string' or length(trim(p_replacement->>'unit')) not between 1 and 30
   or coalesce(p_replacement->>'quantity','') !~ '^\d{1,9}(\.\d{1,6})?$' or coalesce(p_replacement->>'unit_price','') !~ '^\d{1,10}(\.\d{1,2})?$' then raise exception 'Explicit bounded replacement description, unit, quantity and price required';end if;
  if (p_replacement->>'quantity')::numeric<=0 or (p_replacement->>'unit_price')::numeric<=0 then raise exception 'Positive replacement quantity and price required';end if;
  r:=jsonb_build_object('description',trim(p_replacement->>'description'),'unit',trim(p_replacement->>'unit'),'quantity',(p_replacement->>'quantity')::numeric,'unit_price',(p_replacement->>'unit_price')::numeric);
 end if;
 select * into old from public.crm_boq_line_proposals where id=p_id;
 if old.id is not null then
  if old.project_id=p_project and old.change_id=p_change and old.change_version=p_change_version and old.baseline_id=p_baseline and old.baseline_version=p_baseline_version and old.line_position=p_position and old.source=p_source and old.action=p_action and old.replacement is not distinct from r and old.reason=trim(p_reason) and old.submitted_by=auth.uid() and (select previous_id from public.crm_boq_line_corrections where proposal_id=old.id) is not distinct from p_previous then return old.id;end if;
  raise exception 'Proposal ID already has different immutable evidence';
 end if;
 if exists(select 1 from public.crm_boq_line_proposals q left join public.crm_boq_line_reviews v on v.proposal_id=q.id where q.project_id=p_project and q.baseline_id=p_baseline and q.line_position=p_position and coalesce(v.outcome,'Pending')<>'Returned' and not exists(select 1 from public.crm_boq_line_retirements t where t.proposal_id=q.id)) then raise exception 'Existing pending or reviewed line proposal must be resolved before another proposal';end if;
 if p_previous is null then
  if exists(select 1 from public.crm_boq_line_retirements t join public.crm_boq_line_proposals q on q.id=t.proposal_id where q.project_id=p_project and q.baseline_id=p_baseline and q.line_position=p_position) then raise exception 'Explicit correction predecessor required for retired scope';end if;
 else
  select * into prior from public.crm_boq_line_proposals where id=p_previous;
  if prior.id is null or prior.project_id<>p_project or prior.baseline_id<>p_baseline or prior.baseline_version<>p_baseline_version or prior.line_position<>p_position or prior.source is distinct from p_source
   or exists(select 1 from public.crm_boq_line_corrections where previous_id=prior.id)
   or not(exists(select 1 from public.crm_boq_line_retirements where proposal_id=prior.id) or (exists(select 1 from public.crm_boq_line_reviews where proposal_id=prior.id and outcome='Returned') and exists(select 1 from public.crm_boq_line_corrections where proposal_id=prior.id)))
  then raise exception 'Exact unconsumed retired or returned correction predecessor required';end if;
 end if;
 insert into public.crm_boq_line_proposals(id,project_id,change_id,change_version,sale_id,baseline_id,baseline_version,line_position,source,change_snapshot,action,replacement,reason,submitted_by)
 values(p_id,p.id,c.id,c.version,s.id,b.id,b.version,p_position,p_source,to_jsonb(c),p_action,r,trim(p_reason),auth.uid());
 if p_previous is not null then
  insert into public.crm_boq_line_corrections(project_id,previous_id,proposal_id,reason,actor_id,snapshot)
  select p.id,prior.id,p_id,trim(p_reason),auth.uid(),jsonb_build_object('previous',to_jsonb(prior),'previous_review',(select to_jsonb(v) from public.crm_boq_line_reviews v where v.proposal_id=prior.id),'retirement',(select to_jsonb(t) from public.crm_boq_line_retirements t where t.proposal_id=prior.id),'proposal',to_jsonb(n)) from public.crm_boq_line_proposals n where n.id=p_id;
 end if;return p_id;
end$$;
revoke all on function portal_private.submit_boq_line_scope(uuid,uuid,uuid,integer,uuid,integer,integer,jsonb,text,jsonb,text,uuid) from public,anon,authenticated;
create or replace function public.submit_boq_line_proposal(p_id uuid,p_project uuid,p_change uuid,p_change_version integer,p_baseline uuid,p_baseline_version integer,p_position integer,p_source jsonb,p_action text,p_replacement jsonb,p_reason text) returns uuid language sql security definer set search_path='' as $$
 select portal_private.submit_boq_line_scope(p_id,p_project,p_change,p_change_version,p_baseline,p_baseline_version,p_position,p_source,p_action,p_replacement,p_reason,null);
$$;
create function public.submit_boq_line_correction(p_id uuid,p_previous uuid,p_change uuid,p_change_version integer,p_action text,p_replacement jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare q public.crm_boq_line_proposals;
begin
 select * into q from public.crm_boq_line_proposals where id=p_previous;
 if auth.uid() is null or q.id is null or not portal_private.execution_manager(q.project_id) then raise exception 'Current assigned project manager correction access required';end if;
 return portal_private.submit_boq_line_scope(p_id,q.project_id,p_change,p_change_version,q.baseline_id,q.baseline_version,q.line_position,q.source,p_action,p_replacement,p_reason,p_previous);
end$$;
revoke all on function public.retire_boq_line_proposal(uuid,uuid,uuid,text),public.submit_boq_line_correction(uuid,uuid,uuid,integer,text,jsonb,text) from public,anon,authenticated;
grant execute on function public.retire_boq_line_proposal(uuid,uuid,uuid,text),public.submit_boq_line_correction(uuid,uuid,uuid,integer,text,jsonb,text) to authenticated;
commit;
