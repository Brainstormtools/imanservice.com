begin;
-- Explicit history between independently assessed, already-issued certificates; never extends validity.
create table public.competence_certificate_renewals(
 id uuid primary key,old_certificate_id uuid not null references public.competence_certificates,
 new_certificate_id uuid not null references public.competence_certificates,sequence integer not null,
 action text not null check(action in ('Linked','Withdrawn')),request jsonb not null,snapshot jsonb not null,
 reason text not null check(length(reason) between 3 and 2000),actor_id uuid not null references public.profiles,
 created_at timestamptz not null default now(),unique(new_certificate_id,sequence),check(old_certificate_id<>new_certificate_id)
);
create index competence_renewal_previous on public.competence_certificate_renewals(old_certificate_id);
create index competence_renewal_actor on public.competence_certificate_renewals(actor_id);
create function portal_private.competence_renewal_immutable() returns trigger language plpgsql set search_path='' as $$begin raise exception 'Certificate renewal history is immutable';end$$;
create trigger competence_renewal_history before update or delete on public.competence_certificate_renewals for each row execute function portal_private.competence_renewal_immutable();
revoke all on function portal_private.competence_renewal_immutable() from public,anon,authenticated;
alter table public.competence_certificate_renewals enable row level security;
revoke all on public.competence_certificate_renewals from public,anon,authenticated;
grant select on public.competence_certificate_renewals to authenticated;
create policy competence_renewal_scope on public.competence_certificate_renewals for select to authenticated using(exists(select 1 from public.competence_certificates c where c.id=new_certificate_id and portal_private.competence_certificate_read(c.assessment_id)));
create function public.competence_certificate_renewal_context(p_certificate uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare c public.competence_certificates;a public.competence_assessments;r public.competence_certificate_renewals;issuer boolean;eligible boolean;
begin
 select * into c from public.competence_certificates where id=p_certificate;
 if c.id is null or not coalesce(portal_private.competence_certificate_read(c.assessment_id),false) then raise exception 'Current own-employee or HR/Admin certificate access required';end if;
 select * into a from public.competence_assessments where id=c.assessment_id;
 select * into r from public.competence_certificate_renewals where new_certificate_id=c.id order by sequence desc limit 1;
 issuer:=portal_private.hr_access();eligible:=portal_private.competence_certificate_basis(a,c.review_id) and portal_private.competence_certificate_state(c,now()) in ('Current','Renewal due');
 return jsonb_build_object('certificate',to_jsonb(c),'state',portal_private.competence_certificate_state(c,now()),'server_time',now(),'previous_sequence',coalesce(r.sequence,0),
 'latest',case when r.id is not null then to_jsonb(r) else null end,'can_link',issuer and eligible and (r.id is null or r.action='Withdrawn'),'can_withdraw',issuer and coalesce(r.action='Linked',false),
 'candidates',case when issuer and eligible then coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'assessment_id',p.assessment_id,'issued_at',p.issued_at,'expires_at',p.expires_at,'state',portal_private.competence_certificate_state(p,now()),'title',p.snapshot->'assignment'->'criteria'->>'title') order by p.issued_at,p.id) from public.competence_certificates p where p.employee_id=c.employee_id and p.id<>c.id and p.issued_at<=c.issued_at and p.snapshot->'assignment'->'criteria'->>'definition_id'=c.snapshot->'assignment'->'criteria'->>'definition_id' and not exists(select 1 from public.competence_certificate_renewals v where v.old_certificate_id=p.id and v.new_certificate_id<>c.id and v.action='Linked' and not exists(select 1 from public.competence_certificate_renewals n where n.new_certificate_id=v.new_certificate_id and n.sequence>v.sequence))),'[]'::jsonb) else '[]'::jsonb end,
 'history',coalesce((select jsonb_agg(to_jsonb(h) order by h.created_at,h.id) from public.competence_certificate_renewals h where h.new_certificate_id=c.id or h.old_certificate_id=c.id),'[]'::jsonb));
end$$;
create function public.record_competence_certificate_renewal(p_id uuid,p_old uuid,p_new uuid,p_previous integer,p_action text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare c public.competence_certificates;previous public.competence_certificates;a public.competence_assessments;d public.competence_definition_revisions;reviewer uuid;r public.competence_certificate_renewals;old public.competence_certificate_renewals;req jsonb;
begin
 if auth.uid() is null or not public.is_staff() or not portal_private.hr_access() then raise exception 'Current HR or administrator renewal coordination required';end if;
 if p_id is null or p_old is null or p_new is null or p_previous is null or p_action is null or p_action not in ('Link','Withdraw') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Actual previous/new certificates, sequence, action and reason required';end if;
 select * into c from public.competence_certificates where id=p_new;
 select * into a from public.competence_assessments where id=c.assessment_id;
 select v.reviewer_id into reviewer from public.competence_assessment_reviews v where v.id=c.review_id;
 perform 1 from public.profiles where id in(auth.uid(),c.employee_id,a.assessor_id,reviewer) order by id for share;
 perform 1 from public.crm_memberships m join public.crm_roles role on role.id=m.role_id join public.crm_teams team on team.id=m.team_id where m.user_id in(auth.uid(),reviewer) order by m.id for share of m,role,team;
 if not public.is_staff() or not portal_private.hr_access() then raise exception 'Current HR or administrator renewal coordination required';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_id::text,127));
 req:=jsonb_build_object('old_certificate_id',p_old,'new_certificate_id',p_new,'previous_sequence',p_previous,'action',p_action,'reason',trim(p_reason));
 select * into old from public.competence_certificate_renewals where id=p_id;
 if old.id is not null then
  if old.actor_id=auth.uid() and old.request=req then return old.id;end if;
  raise exception 'Renewal request records different content or account';
 end if;
 if c.id is null or a.id is null then raise exception 'Actual issued new certificate required';end if;
 perform pg_advisory_xact_lock(hashtextextended(a.assessor_id::text,123));
 select * into d from public.competence_definition_revisions where id=a.definition_revision_id;
 perform pg_advisory_xact_lock(hashtextextended(d.definition_id::text,122));
 select * into a from public.competence_assessments where id=c.assessment_id for update;
 -- Serialize graph edits before certificate row locks to prevent forks/cycles under concurrent actions.
 perform pg_advisory_xact_lock(hashtextextended('competence-renewal-graph',127));
 perform 1 from public.competence_certificates where id in(p_old,p_new) order by id for update;
 select * into previous from public.competence_certificates where id=p_old;
 select * into r from public.competence_certificate_renewals where new_certificate_id=c.id order by sequence desc limit 1;
 if coalesce(r.sequence,0)<>p_previous then raise exception 'Exact current renewal sequence required';end if;
 if p_action='Withdraw' then
  if r.id is null or r.action<>'Linked' or r.old_certificate_id<>p_old then raise exception 'Exact current linked predecessor required for withdrawal';end if;
 else
  if previous.id is null or previous.id=c.id or previous.employee_id<>c.employee_id or previous.assessment_id=c.assessment_id or previous.issued_at>c.issued_at or (previous.snapshot->'assignment'->'criteria'->>'definition_id') is distinct from (c.snapshot->'assignment'->'criteria'->>'definition_id') then raise exception 'Distinct earlier issued certificate for the same actual employee and competency required';end if;
  if (r.id is not null and r.action<>'Withdrawn') or not portal_private.competence_certificate_basis(a,c.review_id) or portal_private.competence_certificate_state(c,now()) not in ('Current','Renewal due') then raise exception 'New valid unrevoked certificate with current independently Approved Pass required; withdraw existing linkage before correction';end if;
  if exists(select 1 from public.competence_certificate_renewals v where v.old_certificate_id=p_old and v.new_certificate_id<>p_new and v.action='Linked' and not exists(select 1 from public.competence_certificate_renewals n where n.new_certificate_id=v.new_certificate_id and n.sequence>v.sequence)) then raise exception 'Previous certificate already has a current linked successor';end if;
  if exists(with recursive path(id) as(select p_new union select v.new_certificate_id from path p join public.competence_certificate_renewals v on v.old_certificate_id=p.id where v.action='Linked' and not exists(select 1 from public.competence_certificate_renewals n where n.new_certificate_id=v.new_certificate_id and n.sequence>v.sequence)) select 1 from path where id=p_old) then raise exception 'Renewal linkage must not create a cycle';end if;
 end if;
 insert into public.competence_certificate_renewals(id,old_certificate_id,new_certificate_id,sequence,action,request,snapshot,reason,actor_id) values(p_id,p_old,p_new,coalesce(r.sequence,0)+1,case when p_action='Link' then 'Linked' else 'Withdrawn' end,req,
 jsonb_build_object('previous_certificate',to_jsonb(previous),'new_certificate',to_jsonb(c),'previous_state',portal_private.competence_certificate_state(previous,now()),'new_state',portal_private.competence_certificate_state(c,now())),trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.competence_certificate_renewal_context(uuid),public.record_competence_certificate_renewal(uuid,uuid,uuid,integer,text,text) from public,anon,authenticated;
grant execute on function public.competence_certificate_renewal_context(uuid),public.record_competence_certificate_renewal(uuid,uuid,uuid,integer,text,text) to authenticated;
commit;
