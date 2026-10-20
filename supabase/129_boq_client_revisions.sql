begin;
-- Frozen client offers and terminal decisions; never alter accepted scope or accounting.
create table public.crm_boq_revision_publications (
 id uuid primary key, proposal_id uuid not null references public.crm_boq_line_proposals,
 review_id uuid not null references public.crm_boq_line_reviews,
 project_id uuid not null references public.projects, company_id uuid not null references public.companies,
 revision integer not null check(revision>0),previous_id uuid references public.crm_boq_revision_publications,
 client_data jsonb not null, internal_snapshot jsonb not null,
 reason text not null check(length(trim(reason)) between 3 and 2000),
 published_by uuid not null references public.profiles,published_at timestamptz not null default now(),
 unique(proposal_id,revision)
);
create index boq_revision_project on public.crm_boq_revision_publications(project_id);
create index boq_revision_company on public.crm_boq_revision_publications(company_id);
create table public.crm_boq_revision_decisions (
 id uuid primary key default gen_random_uuid(),publication_id uuid not null unique references public.crm_boq_revision_publications,
 outcome text not null check(outcome in ('Accepted','Declined','Withdrawn')),
 note text not null check(length(note)<=2000),consent boolean not null,
 actor_id uuid not null references public.profiles,decided_at timestamptz not null default now(),
 receipt jsonb not null
);
alter table public.crm_boq_revision_publications enable row level security;
alter table public.crm_boq_revision_decisions enable row level security;
revoke all on public.crm_boq_revision_publications,public.crm_boq_revision_decisions from anon,authenticated;
grant select on public.crm_boq_revision_publications,public.crm_boq_revision_decisions to authenticated;
-- Clients use the explicit safe projection RPC, never the internal snapshot table.
create policy boq_revision_internal_read on public.crm_boq_revision_publications for select to authenticated using(portal_private.execution_manager(project_id));
create policy boq_revision_decision_internal_read on public.crm_boq_revision_decisions for select to authenticated using(exists(select 1 from public.crm_boq_revision_publications p where p.id=publication_id and portal_private.execution_manager(p.project_id)));
create function portal_private.boq_revision_immutable() returns trigger language plpgsql set search_path='' as $$begin raise exception 'BOQ revision publication and decision evidence is immutable';end$$;
create trigger boq_revision_publication_immutable before update or delete on public.crm_boq_revision_publications for each row execute function portal_private.boq_revision_immutable();
create trigger boq_revision_decision_immutable before update or delete on public.crm_boq_revision_decisions for each row execute function portal_private.boq_revision_immutable();
create function portal_private.boq_revision_current(p_proposal uuid) returns void language plpgsql set search_path='' as $$
declare q public.crm_boq_line_proposals;p public.projects;c public.crm_project_changes;s public.crm_sales;b public.crm_quote_publications;v public.crm_boq_line_reviews;
begin
 select * into p from public.projects where id=(select project_id from public.crm_boq_line_proposals where id=p_proposal) for update;
 select * into q from public.crm_boq_line_proposals where id=p_proposal;
 select * into c from public.crm_project_changes where id=q.change_id for update;
 select * into s from public.crm_sales where id=q.sale_id for update;
 select * into b from public.crm_quote_publications where id=q.baseline_id for update;
 select * into v from public.crm_boq_line_reviews where proposal_id=q.id;
 if q.id is null or v.outcome is distinct from 'Reviewed' or v.snapshot is distinct from to_jsonb(q)
  or p.id is null or p.status in ('Completed','Cancelled') or exists(select 1 from public.crm_handovers where project_id=p.id and status in ('Awaiting signatures','Signed','Closed'))
  or c.version is distinct from q.change_version or c.details->>'status' is distinct from 'Approved'
  or b.version is distinct from q.baseline_version or b.status is distinct from 'Accepted' or b.items->(q.line_position-1) is distinct from q.source
  or s.id is null or s.project_id is distinct from p.id or s.publication_id is distinct from b.id or s.company_id is distinct from b.company_id or p.company_id is distinct from b.company_id or s.currency is distinct from b.currency
 then raise exception 'Exact current reviewed proposal, Approved change and accepted source on active project required';end if;
end$$;
revoke all on function portal_private.boq_revision_current(uuid),portal_private.boq_revision_immutable() from public,anon,authenticated;
create function public.boq_revision_publications() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not exists(select 1 from public.profiles where id=auth.uid() and active and role in ('admin','team','client')) then raise exception 'Current portal account required';end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'project_id',p.project_id,'revision',p.revision,'previous_id',p.previous_id,'data',p.client_data,'published_at',p.published_at,'status',coalesce(d.outcome,'Published'),'decision',case when d.id is not null then jsonb_build_object('outcome',d.outcome,'note',d.note,'consent',d.consent,'actor_id',d.actor_id,'decided_at',d.decided_at,'receipt',d.receipt) else null end)
 ||case when portal_private.execution_manager(p.project_id) then jsonb_build_object('proposal_id',p.proposal_id,'review_id',p.review_id,'publish_reason',p.reason,'published_by',p.published_by) else '{}'::jsonb end order by p.published_at,p.id)
 from public.crm_boq_revision_publications p left join public.crm_boq_revision_decisions d on d.publication_id=p.id
 where portal_private.execution_manager(p.project_id) or (exists(select 1 from public.profiles a join public.projects j on j.id=p.project_id where a.id=auth.uid() and a.active and a.role='client' and a.company_id=p.company_id and j.company_id=p.company_id) and public.can_project(p.project_id))),'[]'::jsonb);
end$$;
create function public.publish_boq_line_revision(p_id uuid,p_proposal uuid,p_review uuid,p_previous uuid,p_data jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare q public.crm_boq_line_proposals;v public.crm_boq_line_reviews;b public.crm_quote_publications;p public.projects;old public.crm_boq_revision_publications;latest public.crm_boq_revision_publications;data jsonb;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Current administrator publication required';end if;
 perform portal_private.boq_revision_current(p_proposal);
 select * into q from public.crm_boq_line_proposals where id=p_proposal;
 select * into v from public.crm_boq_line_reviews where proposal_id=q.id;
 if v.id is distinct from p_review then raise exception 'Exact immutable Reviewed receipt required';end if;
 if p_id is null or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Explicit publication ID and internal reason required';end if;
 if jsonb_typeof(p_data) is distinct from 'object' or (select count(*) from jsonb_object_keys(p_data))<>3 or not(p_data ?& array['title','terms','valid_until'])
  or jsonb_typeof(p_data->'title') is distinct from 'string' or length(trim(p_data->>'title')) not between 3 and 160
  or jsonb_typeof(p_data->'terms') is distinct from 'string' or length(trim(p_data->>'terms')) not between 3 and 10000
  or coalesce(p_data->>'valid_until','') !~ '^\d{4}-\d{2}-\d{2}$' or (p_data->>'valid_until')::date<(now() at time zone 'Asia/Karachi')::date then raise exception 'Explicit bounded client title, terms and current validity date required';end if;
 select * into b from public.crm_quote_publications where id=q.baseline_id;
 select * into p from public.projects where id=q.project_id;
 data:=jsonb_build_object('title',trim(p_data->>'title'),'terms',trim(p_data->>'terms'),'valid_until',(p_data->>'valid_until')::date,'project',p.title,'company',(select name from public.companies where id=p.company_id),'baseline_number',b.number,'baseline_revision',b.revision,'baseline_version',b.version,'line_position',q.line_position,'currency',b.currency,'action',q.action,'original',q.source,'replacement',q.replacement);
 select * into old from public.crm_boq_revision_publications where id=p_id;
 if old.id is not null then
  if old.proposal_id=q.id and old.review_id=v.id and old.previous_id is not distinct from p_previous and old.client_data=data and old.reason=trim(p_reason) and old.published_by=auth.uid() then return old.id;end if;
  raise exception 'Publication ID already has different frozen evidence';
 end if;
 select * into latest from public.crm_boq_revision_publications where proposal_id=q.id order by revision desc limit 1;
 if latest.id is distinct from p_previous then raise exception 'Exact latest prior publication required';end if;
 if latest.id is not null and not exists(select 1 from public.crm_boq_revision_decisions where publication_id=latest.id and outcome in ('Declined','Withdrawn')) then raise exception 'Pending or accepted revision cannot be duplicated or superseded';end if;
 insert into public.crm_boq_revision_publications(id,proposal_id,review_id,project_id,company_id,revision,previous_id,client_data,internal_snapshot,reason,published_by)
 values(p_id,q.id,v.id,q.project_id,p.company_id,coalesce(latest.revision,0)+1,latest.id,data,jsonb_build_object('proposal',to_jsonb(q),'review',to_jsonb(v)),trim(p_reason),auth.uid());return p_id;
end$$;
create function public.decide_boq_line_revision(p_publication uuid,p_action text,p_note text,p_consent boolean) returns void language plpgsql security definer set search_path='' as $$
declare pub public.crm_boq_revision_publications;d public.crm_boq_revision_decisions;p public.projects;outcome text;note text:=trim(coalesce(p_note,''));
begin
 if auth.uid() is null or p_action is null or p_action not in ('accept','decline','withdraw') or length(coalesce(p_note,''))>2000 then raise exception 'Current account and valid revision decision required';end if;
 select * into pub from public.crm_boq_revision_publications where id=p_publication;
 if pub.id is null then raise exception 'Actual frozen publication required';end if;
 if p_action='withdraw' then
  if not public.is_admin() or length(note)<3 then raise exception 'Administrator withdrawal needs a client-visible reason';end if;outcome:='Withdrawn';
 else
  if not exists(select 1 from public.profiles a join public.projects j on j.id=pub.project_id where a.id=auth.uid() and a.active and a.role='client' and a.company_id=pub.company_id and j.company_id=pub.company_id) or not public.can_project(pub.project_id) then raise exception 'Current own-company client project access required';end if;
  if p_action='accept' and p_consent is distinct from true then raise exception 'Explicit agreement to this frozen line revision required';end if;
  if p_action='decline' and length(note)<3 then raise exception 'Client decline reason required';end if;
  outcome:=case when p_action='accept' then 'Accepted' else 'Declined' end;
 end if;
 select * into p from public.projects where id=pub.project_id for update;
 if p_action<>'withdraw' then
  perform portal_private.boq_revision_current(pub.proposal_id);
  if (pub.client_data->>'valid_until')::date<(now() at time zone 'Asia/Karachi')::date then raise exception 'Revision validity has expired';end if;
 end if;
 select * into d from public.crm_boq_revision_decisions where publication_id=pub.id;
 if d.id is not null then
  if d.outcome=outcome and d.note=note and d.consent=(p_action='accept') and d.actor_id=auth.uid() then return;end if;
  raise exception 'Revision already has an immutable terminal decision';
 end if;
 if exists(select 1 from public.crm_boq_revision_publications where proposal_id=pub.proposal_id and revision>pub.revision) then raise exception 'Exact latest frozen publication required';end if;
 insert into public.crm_boq_revision_decisions(publication_id,outcome,note,consent,actor_id,receipt)
 values(pub.id,outcome,note,p_action='accept',auth.uid(),jsonb_build_object('publication_id',pub.id,'revision',pub.revision,'published_at',pub.published_at,'data',pub.client_data));
end$$;
revoke all on function public.boq_revision_publications(),public.publish_boq_line_revision(uuid,uuid,uuid,uuid,jsonb,text),public.decide_boq_line_revision(uuid,text,text,boolean) from public,anon,authenticated;
grant execute on function public.boq_revision_publications(),public.publish_boq_line_revision(uuid,uuid,uuid,uuid,jsonb,text),public.decide_boq_line_revision(uuid,text,text,boolean) to authenticated;
commit;
