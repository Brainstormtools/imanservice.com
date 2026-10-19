begin;
-- Independent review never changes the outcome or issues a certificate.
create table public.competence_assessment_reviews(
 id uuid primary key,assessment_id uuid not null references public.competence_assessments,
 receipt_id uuid not null references public.competence_assessment_events,sequence integer not null,
 action text not null check(action in ('Assigned','Approved','Returned','Withdrawn')),
 reviewer_id uuid not null references public.profiles,request jsonb not null,snapshot jsonb not null,
 reason text not null check(length(reason) between 3 and 2000),actor_id uuid not null references public.profiles,
 created_at timestamptz not null default now(),unique(assessment_id,sequence)
);
create index competence_review_receipt on public.competence_assessment_reviews(receipt_id);
create index competence_review_reviewer on public.competence_assessment_reviews(reviewer_id);
create index competence_review_actor on public.competence_assessment_reviews(actor_id);
create function portal_private.competence_reviewer_current(p_user uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles p join public.crm_memberships m on m.user_id=p.id join public.crm_roles r on r.id=m.role_id join public.crm_teams t on t.id=m.team_id where p.id=p_user and p.active and p.role in ('admin','team') and r.active and t.active and ((r.id='team_lead' and 'team.own'=any(r.permissions)) or (r.id='project_manager' and 'project.own'=any(r.permissions))));
$$;
create function portal_private.competence_review_read(p_assessment uuid) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and public.is_staff() and portal_private.competence_reviewer_current(auth.uid()) and exists(select 1 from public.competence_assessments a join lateral(select * from public.competence_assessment_reviews v where v.assessment_id=a.id order by v.sequence desc limit 1)v on true join public.profiles p on p.id=a.employee_id where a.id=p_assessment and a.status='Recorded' and p.active and p.role in ('admin','team') and v.action<>'Withdrawn' and v.reviewer_id=auth.uid() and a.assessor_id<>auth.uid());
$$;
create or replace function portal_private.competence_assessment_read(p_assessment uuid) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and public.is_staff() and exists(select 1 from public.competence_assessments a where a.id=p_assessment and (portal_private.hr_access() or a.employee_id=auth.uid() or (a.assessor_id=auth.uid() and portal_private.competence_assessor_current(auth.uid()) and exists(select 1 from public.profiles p where p.id=a.employee_id and p.active and p.role in ('admin','team'))) or portal_private.competence_review_read(a.id)));
$$;
create function portal_private.competence_review_live(a public.competence_assessments,p_receipt uuid) returns boolean language sql stable security definer set search_path='' as $$
 select a.status='Recorded' and portal_private.competence_basis_current(a.definition_revision_id) and portal_private.competence_assessor_current(a.assessor_id) and exists(select 1 from public.profiles p where p.id=a.employee_id and p.active and p.role in ('admin','team')) and exists(select 1 from public.competence_assessment_events e where e.id=p_receipt and e.assessment_id=a.id and e.version=a.version and e.action='Recorded');
$$;
create function portal_private.competence_review_immutable() returns trigger language plpgsql set search_path='' as $$begin raise exception 'Competence review history is immutable';end$$;
create trigger competence_review_history before update or delete on public.competence_assessment_reviews for each row execute function portal_private.competence_review_immutable();
alter table public.competence_assessment_reviews enable row level security;
revoke all on public.competence_assessment_reviews from public,anon,authenticated;
grant select on public.competence_assessment_reviews to authenticated;
create policy competence_review_scope on public.competence_assessment_reviews for select to authenticated using(portal_private.competence_assessment_read(assessment_id));
revoke all on function portal_private.competence_reviewer_current(uuid),portal_private.competence_review_read(uuid),portal_private.competence_review_live(public.competence_assessments,uuid),portal_private.competence_review_immutable() from public,anon,authenticated;
create function public.competence_assessment_review_context(p_assessment uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare a public.competence_assessments;v public.competence_assessment_reviews;e public.competence_assessment_events;live boolean;eligible boolean;coordinator boolean;
begin
 if not coalesce(portal_private.competence_assessment_read(p_assessment),false) then raise exception 'Current scoped competence assessment access required';end if;
 select * into a from public.competence_assessments where id=p_assessment;
 select * into v from public.competence_assessment_reviews where assessment_id=a.id order by sequence desc limit 1;
 select * into e from public.competence_assessment_events where assessment_id=a.id and action='Recorded' order by version desc limit 1;
 live:=coalesce(portal_private.competence_review_live(a,e.id),false);coordinator:=portal_private.hr_access();
 eligible:=coalesce(v.reviewer_id=auth.uid() and a.assessor_id<>auth.uid() and portal_private.competence_reviewer_current(auth.uid()),false);
 return jsonb_build_object('assessment_id',a.id,'assessment_version',a.version,'receipt',to_jsonb(e),'previous_sequence',coalesce(v.sequence,0),'latest_review',to_jsonb(v),
 'approved_current',live and coalesce(v.action='Approved' and v.receipt_id=e.id and v.reviewer_id<>a.assessor_id and portal_private.competence_reviewer_current(v.reviewer_id),false),
 'can_assign',coordinator and live and (v.id is null or v.action='Withdrawn'),
 'can_review',live and eligible and v.action='Assigned' and v.receipt_id=e.id,
 'can_withdraw',(coordinator or eligible) and coalesce(v.action in ('Assigned','Approved','Returned'),false),
 'candidates',case when coordinator then coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'name',p.name) order by p.name,p.id) from public.profiles p where p.id<>a.assessor_id and portal_private.competence_reviewer_current(p.id)),'[]'::jsonb) else '[]'::jsonb end,
 'history',coalesce((select jsonb_agg(to_jsonb(h) order by h.sequence) from public.competence_assessment_reviews h where h.assessment_id=a.id),'[]'::jsonb));
end$$;
-- Serialize with cancellation, qualification revocation and criteria revision.
create function portal_private.write_competence_review(p_id uuid,p_assessment uuid,p_receipt uuid,p_version integer,p_previous integer,p_action text,p_reviewer uuid,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare a public.competence_assessments;v public.competence_assessment_reviews;old public.competence_assessment_reviews;d public.competence_definition_revisions;e public.competence_assessment_events;req jsonb;reviewer uuid;coordinator boolean;eligible boolean;snap jsonb;
begin
 if not coalesce(portal_private.competence_assessment_read(p_assessment),false) then raise exception 'Current scoped competence assessment access required';end if;
 if p_id is null or p_receipt is null or p_version is null or p_previous is null or p_action is null or p_action not in ('Assign','Approve','Return','Withdraw') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Exact receipt, version, review sequence, action and reason required';end if;
 select * into a from public.competence_assessments where id=p_assessment;
 select * into v from public.competence_assessment_reviews where assessment_id=a.id order by sequence desc limit 1;
 perform 1 from public.profiles where id in(auth.uid(),a.employee_id,a.assessor_id,p_reviewer,v.reviewer_id) order by id for share;
 perform 1 from public.crm_memberships m join public.crm_roles r on r.id=m.role_id join public.crm_teams t on t.id=m.team_id where m.user_id in(auth.uid(),p_reviewer,v.reviewer_id) order by m.id for share of m,r,t;
 perform pg_advisory_xact_lock(hashtextextended(a.assessor_id::text,123));
 select * into d from public.competence_definition_revisions where id=a.definition_revision_id;
 perform pg_advisory_xact_lock(hashtextextended(d.definition_id::text,122));
 perform pg_advisory_xact_lock(hashtextextended(p_id::text,125));
 select * into a from public.competence_assessments where id=p_assessment for update;
 if not coalesce(portal_private.competence_assessment_read(a.id),false) then raise exception 'Current scoped competence assessment access required';end if;
 coordinator:=portal_private.hr_access();
 req:=jsonb_build_object('assessment_id',a.id,'receipt_id',p_receipt,'version',p_version,'previous_sequence',p_previous,'action',p_action,'reviewer_id',p_reviewer,'reason',trim(p_reason));
 select * into old from public.competence_assessment_reviews where id=p_id;
 if old.id is not null then
  if old.actor_id=auth.uid() and old.request=req and ((p_action='Assign' and coordinator) or (p_action='Withdraw' and coordinator) or (p_action in ('Approve','Return','Withdraw') and old.reviewer_id=auth.uid() and auth.uid()<>a.assessor_id and portal_private.competence_reviewer_current(auth.uid()))) then return old.id;end if;
  raise exception 'Review request records different content, account or current authority';
 end if;
 select * into v from public.competence_assessment_reviews where assessment_id=a.id order by sequence desc limit 1;
 select * into e from public.competence_assessment_events where assessment_id=a.id and action='Recorded' order by version desc limit 1;
 if a.version<>p_version or e.id is distinct from p_receipt or coalesce(v.sequence,0)<>p_previous then raise exception 'Exact current assessment receipt, version and review sequence required';end if;
 if p_action='Assign' then
  reviewer:=p_reviewer;
  if not coordinator or reviewer is null or reviewer=a.assessor_id or not portal_private.competence_reviewer_current(reviewer) or not portal_private.competence_review_live(a,p_receipt) or (v.id is not null and v.action<>'Withdrawn') then raise exception 'HR/Admin must explicitly select an independent current Team Lead or PM for a live recorded receipt; withdraw existing review first';end if;
 else
  reviewer:=v.reviewer_id;eligible:=coalesce(reviewer=auth.uid() and reviewer<>a.assessor_id and portal_private.competence_reviewer_current(reviewer),false);
  if p_reviewer is not null or v.id is null or v.receipt_id<>p_receipt then raise exception 'Current assigned review required';end if;
  if p_action='Withdraw' then
   if not (coordinator or eligible) or v.action not in ('Assigned','Approved','Returned') then raise exception 'Current reviewer or HR/Admin and nonwithdrawn review required';end if;
  elsif not eligible or v.action<>'Assigned' or not portal_private.competence_review_live(a,p_receipt) then raise exception 'Actual independent assigned current reviewer and live exact recorded receipt required';end if;
 end if;
 snap:=jsonb_build_object('assessment',to_jsonb(a),'receipt',to_jsonb(e),'reviewer',(select jsonb_build_object('id',p.id,'name',p.name) from public.profiles p where p.id=reviewer),
 'reviewer_roles',coalesce((select jsonb_agg(jsonb_build_object('role_id',r.id,'team_id',t.id) order by r.id,t.id) from public.crm_memberships m join public.crm_roles r on r.id=m.role_id join public.crm_teams t on t.id=m.team_id where m.user_id=reviewer and r.active and t.active and ((r.id='team_lead' and 'team.own'=any(r.permissions)) or (r.id='project_manager' and 'project.own'=any(r.permissions)))),'[]'::jsonb));
 insert into public.competence_assessment_reviews(id,assessment_id,receipt_id,sequence,action,reviewer_id,request,snapshot,reason,actor_id) values(p_id,a.id,e.id,coalesce(v.sequence,0)+1,case p_action when 'Assign' then 'Assigned' when 'Approve' then 'Approved' when 'Return' then 'Returned' else 'Withdrawn' end,reviewer,req,snap,trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function portal_private.write_competence_review(uuid,uuid,uuid,integer,integer,text,uuid,text) from public,anon,authenticated;
create function public.assign_competence_assessment_reviewer(p_id uuid,p_assessment uuid,p_receipt uuid,p_version integer,p_previous integer,p_reviewer uuid,p_reason text) returns uuid language sql security definer set search_path='' as $$select portal_private.write_competence_review(p_id,p_assessment,p_receipt,p_version,p_previous,'Assign',p_reviewer,p_reason);$$;
create function public.review_competence_assessment(p_id uuid,p_assessment uuid,p_receipt uuid,p_version integer,p_previous integer,p_action text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$begin
 if p_action is null or p_action not in ('Approve','Return','Withdraw') then raise exception 'Explicit review action required';end if;
 return portal_private.write_competence_review(p_id,p_assessment,p_receipt,p_version,p_previous,p_action,null,p_reason);
end$$;
revoke all on function public.competence_assessment_review_context(uuid),public.assign_competence_assessment_reviewer(uuid,uuid,uuid,integer,integer,uuid,text),public.review_competence_assessment(uuid,uuid,uuid,integer,integer,text,text) from public,anon,authenticated;
grant execute on function public.competence_assessment_review_context(uuid),public.assign_competence_assessment_reviewer(uuid,uuid,uuid,integer,integer,uuid,text),public.review_competence_assessment(uuid,uuid,uuid,integer,integer,text,text) to authenticated;
commit;
