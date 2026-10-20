begin;
-- Internal proposals only: no commercial publication, credit, invoice or execution adoption.
create table public.crm_boq_line_proposals (
 id uuid primary key, project_id uuid not null references public.projects,
 change_id uuid not null references public.crm_project_changes, change_version integer not null,
 sale_id uuid not null references public.crm_sales, baseline_id uuid not null references public.crm_quote_publications,
 baseline_version integer not null, line_position integer not null check(line_position>0),
 source jsonb not null, change_snapshot jsonb not null,
 action text not null check(action in ('Replace','Remove')), replacement jsonb,
 reason text not null check(length(trim(reason)) between 3 and 2000),
 submitted_by uuid not null references public.profiles, submitted_at timestamptz not null default now()
);
create index boq_line_proposal_scope on public.crm_boq_line_proposals(project_id,baseline_id,line_position);
create index boq_line_proposal_change on public.crm_boq_line_proposals(change_id);
create table public.crm_boq_line_reviews (
 id uuid primary key default gen_random_uuid(), proposal_id uuid not null unique references public.crm_boq_line_proposals,
 outcome text not null check(outcome in ('Reviewed','Returned')),
 reason text not null check(length(trim(reason)) between 3 and 2000),
 reviewed_by uuid not null references public.profiles, reviewed_at timestamptz not null default now(),
 snapshot jsonb not null
);
alter table public.crm_boq_line_proposals enable row level security;
alter table public.crm_boq_line_reviews enable row level security;
revoke all on public.crm_boq_line_proposals,public.crm_boq_line_reviews from anon,authenticated;
grant select on public.crm_boq_line_proposals,public.crm_boq_line_reviews to authenticated;
create policy boq_line_proposal_read on public.crm_boq_line_proposals for select to authenticated using(portal_private.execution_manager(project_id));
create policy boq_line_review_read on public.crm_boq_line_reviews for select to authenticated using(exists(select 1 from public.crm_boq_line_proposals p where p.id=proposal_id and portal_private.execution_manager(p.project_id)));
create function portal_private.boq_line_evidence_immutable() returns trigger language plpgsql set search_path='' as $$begin raise exception 'BOQ proposal and review evidence is immutable';end$$;
revoke all on function portal_private.boq_line_evidence_immutable() from public,anon,authenticated;
create trigger boq_line_proposal_immutable before update or delete on public.crm_boq_line_proposals for each row execute function portal_private.boq_line_evidence_immutable();
create trigger boq_line_review_immutable before update or delete on public.crm_boq_line_reviews for each row execute function portal_private.boq_line_evidence_immutable();
create function public.boq_line_proposal_context(p_project uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare s public.crm_sales;b public.crm_quote_publications;
begin
 if auth.uid() is null or not portal_private.execution_manager(p_project) then raise exception 'Current assigned project manager access required';end if;
 select * into s from public.crm_sales where project_id=p_project;
 select * into b from public.crm_quote_publications where id=s.publication_id and status='Accepted' and company_id=s.company_id and currency=s.currency;
 if b.id is null or not exists(select 1 from public.projects where id=p_project and company_id=s.company_id) then raise exception 'Matching original accepted quotation required';end if;
 return jsonb_build_object('baseline_id',b.id,'baseline_version',b.version,'number',b.number,'revision',b.revision,'currency',b.currency,'items',b.items,'server_time',now());
end$$;
create function public.submit_boq_line_proposal(p_id uuid,p_project uuid,p_change uuid,p_change_version integer,p_baseline uuid,p_baseline_version integer,p_position integer,p_source jsonb,p_action text,p_replacement jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare p public.projects;c public.crm_project_changes;s public.crm_sales;b public.crm_quote_publications;old public.crm_boq_line_proposals;r jsonb;
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
  if old.project_id=p_project and old.change_id=p_change and old.change_version=p_change_version and old.baseline_id=p_baseline and old.baseline_version=p_baseline_version and old.line_position=p_position and old.source=p_source and old.action=p_action and old.replacement is not distinct from r and old.reason=trim(p_reason) and old.submitted_by=auth.uid() then return old.id;end if;
  raise exception 'Proposal ID already has different immutable evidence';
 end if;
 if exists(select 1 from public.crm_boq_line_proposals q left join public.crm_boq_line_reviews v on v.proposal_id=q.id where q.project_id=p_project and q.baseline_id=p_baseline and q.line_position=p_position and coalesce(v.outcome,'Pending')<>'Returned') then raise exception 'Existing pending or reviewed line proposal must be resolved before another proposal';end if;
 insert into public.crm_boq_line_proposals(id,project_id,change_id,change_version,sale_id,baseline_id,baseline_version,line_position,source,change_snapshot,action,replacement,reason,submitted_by)
 values(p_id,p.id,c.id,c.version,s.id,b.id,b.version,p_position,p_source,to_jsonb(c),p_action,r,trim(p_reason),auth.uid());return p_id;
end$$;
create function public.review_boq_line_proposal(p_proposal uuid,p_outcome text,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare q public.crm_boq_line_proposals;v public.crm_boq_line_reviews;p public.projects;c public.crm_project_changes;b public.crm_quote_publications;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Current administrator review required';end if;
 if p_outcome is null or p_outcome not in ('Reviewed','Returned') or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Explicit review outcome and reason required';end if;
 select * into p from public.projects where id=(select project_id from public.crm_boq_line_proposals where id=p_proposal) for update;
 select * into q from public.crm_boq_line_proposals where id=p_proposal;
 if q.id is null then raise exception 'Actual proposal required';end if;
 select * into c from public.crm_project_changes where id=q.change_id for update;
 perform 1 from public.crm_sales where id=q.sale_id for update;
 select * into b from public.crm_quote_publications where id=q.baseline_id for update;
 -- A return can retire obsolete evidence; a positive review requires all current authority/source gates.
 if p_outcome='Reviewed' and (p.status in ('Completed','Cancelled') or exists(select 1 from public.crm_handovers where project_id=p.id and status in ('Awaiting signatures','Signed','Closed')) or c.version<>q.change_version or c.details->>'status' is distinct from 'Approved' or b.version<>q.baseline_version or b.status<>'Accepted' or b.items->(q.line_position-1) is distinct from q.source or not exists(select 1 from public.crm_sales s where s.id=q.sale_id and s.project_id=p.id and s.publication_id=b.id and s.company_id=b.company_id and p.company_id=b.company_id and s.currency=b.currency)) then raise exception 'Proposal source or approved change is stale or project is closed';end if;
 select * into v from public.crm_boq_line_reviews where proposal_id=q.id;
 if v.proposal_id is not null then
  if v.outcome=p_outcome and v.reason=trim(p_reason) and v.reviewed_by=auth.uid() then return;end if;
  raise exception 'Review already has an immutable outcome';
 end if;
 insert into public.crm_boq_line_reviews(proposal_id,outcome,reason,reviewed_by,snapshot) values(q.id,p_outcome,trim(p_reason),auth.uid(),to_jsonb(q));
end$$;
revoke all on function public.boq_line_proposal_context(uuid),public.submit_boq_line_proposal(uuid,uuid,uuid,integer,uuid,integer,integer,jsonb,text,jsonb,text),public.review_boq_line_proposal(uuid,text,text) from public,anon,authenticated;
grant execute on function public.boq_line_proposal_context(uuid),public.submit_boq_line_proposal(uuid,uuid,uuid,integer,uuid,integer,integer,jsonb,text,jsonb,text),public.review_boq_line_proposal(uuid,text,text) to authenticated;
commit;
