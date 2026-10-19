begin;
-- Private issued records; no accreditation wording, public verification service or automatic renewal.
create table public.competence_certificates(
 id uuid primary key,assessment_id uuid not null unique references public.competence_assessments,
 employee_id uuid not null references public.profiles,receipt_id uuid not null references public.competence_assessment_events,
 review_id uuid not null references public.competence_assessment_reviews,snapshot jsonb not null,request jsonb not null,
 reason text not null check(length(reason) between 3 and 2000),issued_by uuid not null references public.profiles,
 issued_at timestamptz not null,expires_at timestamptz not null,warning_at timestamptz,
 check(expires_at>issued_at)
);
create index competence_certificate_employee on public.competence_certificates(employee_id);
create index competence_certificate_receipt on public.competence_certificates(receipt_id);
create index competence_certificate_review on public.competence_certificates(review_id);
create index competence_certificate_issuer on public.competence_certificates(issued_by);
create table public.competence_certificate_revocations(
 id uuid primary key,certificate_id uuid not null unique references public.competence_certificates,
 request jsonb not null,snapshot jsonb not null,reason text not null check(length(reason) between 3 and 2000),
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now()
);
create index competence_certificate_revocation_actor on public.competence_certificate_revocations(actor_id);
create function portal_private.competence_certificate_read(p_assessment uuid) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and public.is_staff() and exists(select 1 from public.competence_assessments a where a.id=p_assessment and (portal_private.hr_access() or a.employee_id=auth.uid()));
$$;
create function portal_private.competence_certificate_basis(a public.competence_assessments,p_review uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.competence_assessment_reviews v join public.competence_assessment_events e on e.id=v.receipt_id where v.id=p_review and v.assessment_id=a.id and v.action='Approved' and v.reviewer_id<>a.assessor_id and portal_private.competence_reviewer_current(v.reviewer_id) and not exists(select 1 from public.competence_assessment_reviews n where n.assessment_id=a.id and n.sequence>v.sequence) and portal_private.competence_review_live(a,e.id) and e.snapshot->'result'->>'outcome'='Pass');
$$;
create function portal_private.competence_certificate_state(c public.competence_certificates,p_time timestamptz) returns text language sql stable security definer set search_path='' as $$
 select case when exists(select 1 from public.competence_certificate_revocations r where r.certificate_id=c.id) then 'Revoked' when p_time>=c.expires_at then 'Expired' when c.warning_at is not null and p_time>=c.warning_at then 'Renewal due' else 'Current' end;
$$;
create function portal_private.competence_certificate_immutable() returns trigger language plpgsql set search_path='' as $$begin raise exception 'Issued certificate and revocation evidence are immutable';end$$;
create trigger competence_certificate_history before update or delete on public.competence_certificates for each row execute function portal_private.competence_certificate_immutable();
create trigger competence_certificate_revocation_history before update or delete on public.competence_certificate_revocations for each row execute function portal_private.competence_certificate_immutable();
alter table public.competence_certificates enable row level security;
alter table public.competence_certificate_revocations enable row level security;
revoke all on public.competence_certificates,public.competence_certificate_revocations from public,anon,authenticated;
grant select on public.competence_certificates,public.competence_certificate_revocations to authenticated;
create policy competence_certificate_scope on public.competence_certificates for select to authenticated using(portal_private.competence_certificate_read(assessment_id));
create policy competence_certificate_revocation_scope on public.competence_certificate_revocations for select to authenticated using(exists(select 1 from public.competence_certificates c where c.id=certificate_id and portal_private.competence_certificate_read(c.assessment_id)));
revoke all on function portal_private.competence_certificate_read(uuid),portal_private.competence_certificate_basis(public.competence_assessments,uuid),portal_private.competence_certificate_state(public.competence_certificates,timestamptz),portal_private.competence_certificate_immutable() from public,anon,authenticated;
grant execute on function portal_private.competence_certificate_read(uuid) to authenticated;
create function public.competence_certificate_register() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.is_staff() then raise exception 'Current internal staff certificate access required';end if;
 return jsonb_build_object('server_time',now(),
 'certificates',coalesce((select jsonb_agg(jsonb_build_object('id',c.id,'assessment_id',c.assessment_id,'employee',c.snapshot->'assignment'->'employee','title',c.snapshot->'assignment'->'criteria'->>'title','skill',c.snapshot->'assignment'->'criteria'->>'skill','issued_at',c.issued_at,'expires_at',c.expires_at,'warning_at',c.warning_at,'state',portal_private.competence_certificate_state(c,now())) order by c.issued_at,c.id) from public.competence_certificates c where portal_private.competence_certificate_read(c.assessment_id)),'[]'::jsonb),
 'candidates',case when portal_private.hr_access() then coalesce((select jsonb_agg(jsonb_build_object('assessment_id',a.id,'employee',a.assignment_snapshot->'employee','title',a.assignment_snapshot->'criteria'->>'title','criteria_revision',a.assignment_snapshot->'criteria'->'revision') order by a.created_at,a.id) from public.competence_assessments a join lateral(select v.id from public.competence_assessment_reviews v where v.assessment_id=a.id order by v.sequence desc limit 1)v on true where portal_private.competence_certificate_basis(a,v.id) and not exists(select 1 from public.competence_certificates c where c.assessment_id=a.id)),'[]'::jsonb) else '[]'::jsonb end);
end$$;
create function public.competence_certificate_context(p_assessment uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare a public.competence_assessments;c public.competence_certificates;v public.competence_assessment_reviews;e public.competence_assessment_events;
begin
 if not coalesce(portal_private.competence_certificate_read(p_assessment),false) then raise exception 'Current own-employee or HR/Admin certificate access required';end if;
 select * into a from public.competence_assessments where id=p_assessment;
 select * into c from public.competence_certificates where assessment_id=a.id;
 select * into v from public.competence_assessment_reviews where assessment_id=a.id order by sequence desc limit 1;
 select * into e from public.competence_assessment_events where id=v.receipt_id;
 return jsonb_build_object('assessment_id',a.id,'assessment_version',a.version,'assignment',a.assignment_snapshot,'receipt',case when e.id is not null then to_jsonb(e) else null end,'review',case when v.id is not null then to_jsonb(v) else null end,'server_time',now(),
 'certificate',case when c.id is not null then to_jsonb(c) else null end,'state',case when c.id is not null then portal_private.competence_certificate_state(c,now()) else null end,
 'revocation',(select to_jsonb(r) from public.competence_certificate_revocations r where r.certificate_id=c.id),
 'can_issue',portal_private.hr_access() and c.id is null and portal_private.competence_certificate_basis(a,v.id),
 'can_revoke',portal_private.hr_access() and c.id is not null and not exists(select 1 from public.competence_certificate_revocations r where r.certificate_id=c.id));
end$$;
create function public.issue_competence_certificate(p_id uuid,p_assessment uuid,p_receipt uuid,p_review uuid,p_version integer,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare a public.competence_assessments;c public.competence_certificates;d public.competence_definition_revisions;v public.competence_assessment_reviews;e public.competence_assessment_events;req jsonb;t timestamptz;expiry timestamptz;warning timestamptz;
begin
 if auth.uid() is null or not public.is_staff() or not portal_private.hr_access() then raise exception 'Current HR or administrator certificate issuer required';end if;
 if p_id is null or p_assessment is null or p_receipt is null or p_review is null or p_version is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Exact reviewed Pass receipt, review, assessment version and issuance reason required';end if;
 select * into a from public.competence_assessments where id=p_assessment;
 select * into v from public.competence_assessment_reviews where id=p_review;
 perform 1 from public.profiles where id in(auth.uid(),a.employee_id,a.assessor_id,v.reviewer_id) order by id for share;
 perform 1 from public.crm_memberships m join public.crm_roles r on r.id=m.role_id join public.crm_teams team on team.id=m.team_id where m.user_id in(auth.uid(),v.reviewer_id) order by m.id for share of m,r,team;
 if not public.is_staff() or not portal_private.hr_access() then raise exception 'Current HR or administrator certificate issuer required';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_id::text,126));
 req:=jsonb_build_object('assessment_id',p_assessment,'receipt_id',p_receipt,'review_id',p_review,'version',p_version,'reason',trim(p_reason));
 select * into c from public.competence_certificates where id=p_id;
 if c.id is not null then
  if c.issued_by=auth.uid() and c.request=req then return c.id;end if;
  raise exception 'Certificate request records different content or account';
 end if;
 if a.id is null then raise exception 'Actual recorded assessment required';end if;
 perform pg_advisory_xact_lock(hashtextextended(a.assessor_id::text,123));
 select * into d from public.competence_definition_revisions where id=a.definition_revision_id;
 perform pg_advisory_xact_lock(hashtextextended(d.definition_id::text,122));
 select * into a from public.competence_assessments where id=p_assessment for update;
 select * into v from public.competence_assessment_reviews where id=p_review;
 if a.version<>p_version or v.receipt_id is distinct from p_receipt or not portal_private.competence_certificate_basis(a,p_review) then raise exception 'Exact current independently Approved Pass assessment receipt required';end if;
 if exists(select 1 from public.competence_certificates where assessment_id=a.id) then raise exception 'One issued certificate per actual assessment; use a separately assessed renewal';end if;
 select * into e from public.competence_assessment_events where id=p_receipt;
 t:=now();expiry:=((t at time zone 'UTC')+make_interval(months=>d.validity_months)) at time zone 'UTC';
 warning:=case when d.warning_days is not null then ((expiry at time zone 'UTC')-make_interval(days=>d.warning_days)) at time zone 'UTC' else null end;
 insert into public.competence_certificates(id,assessment_id,employee_id,receipt_id,review_id,snapshot,request,reason,issued_by,issued_at,expires_at,warning_at) values(p_id,a.id,a.employee_id,e.id,v.id,
 jsonb_build_object('assignment',a.assignment_snapshot,'receipt',to_jsonb(e),'review',to_jsonb(v),'criteria_revision_id',d.id,'validity_months',d.validity_months,'warning_days',d.warning_days,
 'issuer',(select jsonb_build_object('id',p.id,'name',p.name,'role',p.role) from public.profiles p where p.id=auth.uid()),
 'issuer_roles',coalesce((select jsonb_agg(jsonb_build_object('role_id',r.id,'team_id',team.id) order by r.id,team.id) from public.crm_memberships m join public.crm_roles r on r.id=m.role_id join public.crm_teams team on team.id=m.team_id where m.user_id=auth.uid() and r.active and team.active and 'hr.manage'=any(r.permissions)),'[]'::jsonb)),req,trim(p_reason),auth.uid(),t,expiry,warning);
 return p_id;
end$$;
create function public.revoke_competence_certificate(p_id uuid,p_certificate uuid,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare c public.competence_certificates;r public.competence_certificate_revocations;req jsonb;
begin
 if auth.uid() is null or not public.is_staff() or not portal_private.hr_access() then raise exception 'Current HR or administrator certificate issuer required';end if;
 if p_id is null or p_certificate is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Actual certificate and revocation reason required';end if;
 perform 1 from public.profiles where id=auth.uid() for share;
 perform 1 from public.crm_memberships m join public.crm_roles role on role.id=m.role_id join public.crm_teams team on team.id=m.team_id where m.user_id=auth.uid() order by m.id for share of m,role,team;
 if not public.is_staff() or not portal_private.hr_access() then raise exception 'Current HR or administrator certificate issuer required';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_id::text,126));
 req:=jsonb_build_object('certificate_id',p_certificate,'reason',trim(p_reason));
 select * into r from public.competence_certificate_revocations where id=p_id;
 if r.id is not null then
  if r.actor_id=auth.uid() and r.request=req then return r.id;end if;
  raise exception 'Revocation request records different content or account';
 end if;
 select * into c from public.competence_certificates where id=p_certificate for update;
 if c.id is null or exists(select 1 from public.competence_certificate_revocations where certificate_id=c.id) then raise exception 'Actual issued certificate without an existing revocation required';end if;
 insert into public.competence_certificate_revocations(id,certificate_id,request,snapshot,reason,actor_id) values(p_id,c.id,req,jsonb_build_object('certificate',to_jsonb(c)),trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.competence_certificate_register(),public.competence_certificate_context(uuid),public.issue_competence_certificate(uuid,uuid,uuid,uuid,integer,text),public.revoke_competence_certificate(uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.competence_certificate_register(),public.competence_certificate_context(uuid),public.issue_competence_certificate(uuid,uuid,uuid,uuid,integer,text),public.revoke_competence_certificate(uuid,uuid,text) to authenticated;
commit;
