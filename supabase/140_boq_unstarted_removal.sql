begin;
-- Execution-only adoption. Accounting and original commercial evidence remain unchanged.
alter table public.tasks drop constraint tasks_status_check;
alter table public.tasks add constraint tasks_status_check check(status in ('To do','In progress','Done','Cancelled – change order'));
create table public.crm_boq_removal_plans (
 id uuid primary key, publication_id uuid not null references public.crm_boq_revision_publications,
 project_id uuid not null references public.projects, task_ids uuid[] not null check(cardinality(task_ids) between 1 and 100),
 snapshot jsonb not null, reason text not null check(length(trim(reason)) between 3 and 2000),
 proposed_by uuid not null references public.profiles, proposed_at timestamptz not null default now()
);
create table public.crm_boq_removal_adoptions (
 id uuid primary key default gen_random_uuid(), plan_id uuid not null unique references public.crm_boq_removal_plans,
 project_id uuid not null references public.projects, receipt jsonb not null,
 reason text not null check(length(trim(reason)) between 3 and 2000),
 approved_by uuid not null references public.profiles, approved_at timestamptz not null default now()
);
create index boq_removal_plan_project on public.crm_boq_removal_plans(project_id);
create index boq_removal_plan_proposer on public.crm_boq_removal_plans(proposed_by);
create index boq_removal_adoption_approver on public.crm_boq_removal_adoptions(approved_by);
create index boq_removal_plan_publication on public.crm_boq_removal_plans(publication_id);
create index boq_removal_adoption_project on public.crm_boq_removal_adoptions(project_id);
alter table public.crm_boq_removal_plans enable row level security;
alter table public.crm_boq_removal_adoptions enable row level security;
revoke all on public.crm_boq_removal_plans,public.crm_boq_removal_adoptions from public,anon,authenticated;
grant select on public.crm_boq_removal_plans,public.crm_boq_removal_adoptions to authenticated;
create policy boq_removal_plan_read on public.crm_boq_removal_plans for select to authenticated using(portal_private.execution_manager(project_id));
create policy boq_removal_adoption_read on public.crm_boq_removal_adoptions for select to authenticated using(portal_private.execution_manager(project_id));
create trigger boq_removal_plan_immutable before update or delete on public.crm_boq_removal_plans for each row execute function portal_private.boq_line_evidence_immutable();
create trigger boq_removal_adoption_immutable before update or delete on public.crm_boq_removal_adoptions for each row execute function portal_private.boq_line_evidence_immutable();

create function portal_private.boq_removal_source(p_publication uuid) returns jsonb language plpgsql set search_path='' as $$
declare pub public.crm_boq_revision_publications;d public.crm_boq_revision_decisions;q public.crm_boq_line_proposals;
begin
 select * into pub from public.crm_boq_revision_publications where id=p_publication;
 if auth.uid() is null or pub.id is null or not portal_private.execution_manager(pub.project_id) then raise exception 'Current assigned project manager access required';end if;
 perform portal_private.boq_revision_current(pub.proposal_id);
 select * into q from public.crm_boq_line_proposals where id=pub.proposal_id;
 select * into d from public.crm_boq_revision_decisions where publication_id=pub.id;
 if q.action is distinct from 'Remove' or d.outcome is distinct from 'Accepted' or not d.consent
  or exists(select 1 from public.crm_boq_revision_publications where proposal_id=q.id and revision>pub.revision)
 then raise exception 'Exact current client-Accepted removal required';end if;
 return jsonb_build_object('publication',to_jsonb(pub),'decision',to_jsonb(d),'proposal',to_jsonb(q));
end$$;

create function portal_private.boq_removal_task(p_task uuid,p_project uuid) returns jsonb language plpgsql set search_path='' as $$
declare t public.tasks;plan public.crm_task_plans;r record;linked boolean;blocked text:='';
begin
 select * into t from public.tasks where id=p_task and project_id=p_project for update;
 select * into plan from public.crm_task_plans where task_id=t.id for update;
 if t.id is null or plan.task_id is null or not exists(select 1 from public.crm_project_workstreams w join public.crm_sales s on s.id=w.sale_id where w.id=plan.workstream_id and w.project_id=p_project and s.project_id=p_project) then raise exception 'Actual generated task on this sale project required';end if;
 if t.status<>'To do' then blocked:='Task is not unstarted';
 elsif exists(select 1 from public.task_items where task_id=t.id and done) then blocked:='Checklist work already recorded';
 elsif exists(select 1 from public.crm_task_plans where t.id=any(dependencies)) then blocked:='Dependent tasks require separate reconciliation';
 elsif exists(select 1 from public.crm_phases where project_id=p_project and phase=plan.phase and status<>'Draft') then blocked:='Phase has entered review';
 end if;
 -- Any operational/financial reference blocks this narrow increment, including drafts.
 -- Planning history and untouched checklists are frozen instead of deleted.
 for r in select c.conrelid::regclass rel,a.attname col from pg_catalog.pg_constraint c join pg_catalog.pg_attribute a on a.attrelid=c.conrelid and a.attnum=c.conkey[1]
  where c.contype='f' and c.confrelid='public.tasks'::regclass and cardinality(c.conkey)=1
   and c.conrelid not in ('public.crm_task_plans'::regclass,'public.task_items'::regclass,'public.crm_task_plan_history'::regclass)
 loop
  execute format('select exists(select 1 from %s where %I=$1)',r.rel,r.col) into linked using t.id;
  if linked then blocked:='Linked work, cost or operational record requires separate reconciliation';exit;end if;
 end loop;
 return jsonb_build_object('id',t.id,'title',t.title,'blocked',blocked,'snapshot',jsonb_build_object('task',to_jsonb(t),'plan',to_jsonb(plan),
  'checklist',coalesce((select jsonb_agg(to_jsonb(i) order by i.id) from public.task_items i where task_id=t.id),'[]'::jsonb),
  'plan_history',coalesce((select jsonb_agg(to_jsonb(h) order by h.revision) from public.crm_task_plan_history h where task_id=t.id),'[]'::jsonb)));
end$$;

create function public.boq_removal_context(p_publication uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare source jsonb;tasks jsonb:='[]';t record;pid uuid;
begin
 source:=portal_private.boq_removal_source(p_publication);pid:=(source->'proposal'->>'project_id')::uuid;
 for t in select x.id from public.tasks x join public.crm_task_plans p on p.task_id=x.id where x.project_id=pid order by x.id loop
  tasks:=tasks||jsonb_build_array(portal_private.boq_removal_task(t.id,pid));
 end loop;
 return jsonb_build_object('source',source,'tasks',tasks,'plans',coalesce((select jsonb_agg(to_jsonb(p)||jsonb_build_object('adoption',(select to_jsonb(a) from public.crm_boq_removal_adoptions a where a.plan_id=p.id)) order by p.proposed_at,p.id) from public.crm_boq_removal_plans p where publication_id=p_publication),'[]'::jsonb));
end$$;

create function public.propose_boq_removal(p_id uuid,p_publication uuid,p_tasks uuid[],p_expected jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare source jsonb;tasks jsonb:='[]';t uuid;item jsonb;old public.crm_boq_removal_plans;pid uuid;
begin
 source:=portal_private.boq_removal_source(p_publication);pid:=(source->'proposal'->>'project_id')::uuid;
 if p_id is null or p_tasks is null or cardinality(p_tasks) not between 1 and 100 or cardinality(p_tasks)<>(select count(distinct x) from unnest(p_tasks) x) or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Explicit unique task mapping, request ID and reason required';end if;
 select * into old from public.crm_boq_removal_plans where id=p_id;
 if old.id is not null then
  if old.publication_id=p_publication and old.task_ids=p_tasks and old.snapshot=p_expected and old.reason=trim(p_reason) and old.proposed_by=auth.uid() then return old.id;end if;
  raise exception 'Removal plan ID already has different evidence';
 end if;
 for t in select x from unnest(p_tasks) x order by x loop
  item:=portal_private.boq_removal_task(t,pid);
  if item->>'blocked'<>'' then raise exception 'Only unstarted tasks without work, cost, dependent or operational records may be cancelled';end if;
  tasks:=tasks||jsonb_build_array(item);
 end loop;
 if p_expected is distinct from jsonb_build_object('source',source,'tasks',tasks) then raise exception 'Exact current source and selected task snapshots required';end if;
 insert into public.crm_boq_removal_plans(id,publication_id,project_id,task_ids,snapshot,reason,proposed_by) values(p_id,p_publication,pid,p_tasks,p_expected,trim(p_reason),auth.uid());return p_id;
end$$;

create function public.adopt_boq_removal(p_plan uuid,p_expected jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare p public.crm_boq_removal_plans;a public.crm_boq_removal_adoptions;source jsonb;tasks jsonb:='[]';item jsonb;t uuid;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Current administrator BOQ adoption required';end if;
 select * into p from public.crm_boq_removal_plans where id=p_plan;
 if p.id is null or p.snapshot is distinct from p_expected or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Exact frozen removal plan and approval reason required';end if;
 perform 1 from public.projects where id=p.project_id for update;
 select * into a from public.crm_boq_removal_adoptions where plan_id=p.id;
 if a.id is not null then
  if a.approved_by=auth.uid() and a.reason=trim(p_reason) then return a.id;end if;
  raise exception 'Removal adoption already has different immutable evidence';
 end if;
 source:=portal_private.boq_removal_source(p.publication_id);
 -- A withdrawn PM assignment must not leave an adoptable proposal.
 if not (portal_private.crm_user_permission(p.proposed_by,'project.own') and (exists(select 1 from public.profiles where id=p.proposed_by and active and role='admin') or exists(select 1 from public.project_assignments where project_id=p.project_id and technician_id=p.proposed_by))) then raise exception 'Current proposing PM authority required';end if;
 for t in select x from unnest(p.task_ids) x order by x loop
  item:=portal_private.boq_removal_task(t,p.project_id);
  if item->>'blocked'<>'' then raise exception 'Recorded, started or linked work cannot be adopted as unstarted';end if;
  tasks:=tasks||jsonb_build_array(item);
 end loop;
 if p.snapshot is distinct from jsonb_build_object('source',source,'tasks',tasks) then raise exception 'Task or source changed after proposal; submit a fresh removal plan';end if;
 insert into public.crm_boq_removal_adoptions(plan_id,project_id,receipt,reason,approved_by)
 values(p.id,p.project_id,jsonb_build_object('plan',to_jsonb(p),'before',p.snapshot,'status','Cancelled – change order','accounting','Separate settlement required; no financial change'),trim(p_reason),auth.uid()) returning * into a;
 update public.tasks set status='Cancelled – change order' where id=any(p.task_ids);
 return a.id;
end$$;

create function portal_private.boq_cancelled_task_guard() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if tg_op<>'INSERT' and old.status='Cancelled – change order' then raise exception 'Adopted cancelled task is immutable';end if;
 if tg_op<>'DELETE' and new.status='Cancelled – change order' then
  if tg_op='INSERT' or old.status<>'To do' or (to_jsonb(new)-'status') is distinct from (to_jsonb(old)-'status')
   or not public.is_admin() or not exists(select 1 from public.crm_boq_removal_adoptions a join public.crm_boq_removal_plans p on p.id=a.plan_id where new.id=any(p.task_ids) and a.approved_by=auth.uid()) then raise exception 'Only approved BOQ removal adoption may cancel an unstarted task';end if;
 end if;
 if tg_op='DELETE' then return old;end if;return new;
end$$;
create trigger boq_cancelled_task_guard before insert or update or delete on public.tasks for each row execute function portal_private.boq_cancelled_task_guard();

-- Lock the referenced task before any child write, closing insert-vs-adoption races.
create function portal_private.boq_cancelled_child_guard() returns trigger language plpgsql security definer set search_path='' as $$
declare tid uuid;s text;
begin
 if tg_table_name='crm_task_plans' and tg_op<>'DELETE' then
  for tid in select x::uuid from jsonb_array_elements_text(to_jsonb(new)->'dependencies') x order by x loop
   select status into s from public.tasks where id=tid for update;
   if s='Cancelled – change order' then raise exception 'A dependency cannot target an adopted cancelled task';end if;
  end loop;
 end if;
 for tid in select distinct x from unnest(array[case when tg_op<>'INSERT' then (to_jsonb(old)->>tg_argv[0])::uuid end,case when tg_op<>'DELETE' then (to_jsonb(new)->>tg_argv[0])::uuid end]) x where x is not null order by x loop
  select status into s from public.tasks where id=tid for update;
  if s='Cancelled – change order' then raise exception 'No work or record changes on an adopted cancelled task';end if;
 end loop;
 if tg_op='DELETE' then return old;end if;return new;
end$$;
do $$declare r record;begin
 for r in select distinct c.conrelid::regclass rel,a.attname col from pg_catalog.pg_constraint c join pg_catalog.pg_attribute a on a.attrelid=c.conrelid and a.attnum=c.conkey[1] where c.contype='f' and c.confrelid='public.tasks'::regclass and cardinality(c.conkey)=1 loop
  execute format('create trigger boq_cancelled_child_%I before insert or update or delete on %s for each row execute function portal_private.boq_cancelled_child_guard(%L)',r.col,r.rel,r.col);
 end loop;
end$$;
revoke all on function portal_private.boq_removal_source(uuid),portal_private.boq_removal_task(uuid,uuid),portal_private.boq_cancelled_task_guard(),portal_private.boq_cancelled_child_guard() from public,anon,authenticated;
revoke all on function public.boq_removal_context(uuid),public.propose_boq_removal(uuid,uuid,uuid[],jsonb,text),public.adopt_boq_removal(uuid,jsonb,text) from public,anon,authenticated;
grant execute on function public.boq_removal_context(uuid),public.propose_boq_removal(uuid,uuid,uuid[],jsonb,text),public.adopt_boq_removal(uuid,jsonb,text) to authenticated;
commit;
