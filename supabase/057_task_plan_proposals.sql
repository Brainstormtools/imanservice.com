begin;
create table public.crm_task_plan_proposals(
 id uuid primary key,project_id uuid not null references public.projects,task_id uuid not null references public.tasks,
 change_id uuid not null references public.crm_project_changes,change_version integer not null,task_version integer not null,
 before_plan jsonb not null,proposed_plan jsonb not null,reason text not null,
 status text not null default 'Submitted' check(status in ('Submitted','Approved','Rejected','Applied')),
 submitted_by uuid not null references public.profiles,submitted_at timestamptz not null default now(),
 reviewed_by uuid references public.profiles,reviewed_at timestamptz,decision_note text,
 applied_by uuid references public.profiles,applied_at timestamptz,applied_revision integer,
 check(reviewed_by is null or reviewed_by<>submitted_by)
);
create index crm_proposals_project on public.crm_task_plan_proposals(project_id);
create index crm_proposals_task on public.crm_task_plan_proposals(task_id);
create index crm_proposals_change on public.crm_task_plan_proposals(change_id);
create index crm_proposals_submitter on public.crm_task_plan_proposals(submitted_by);
create index crm_proposals_reviewer on public.crm_task_plan_proposals(reviewed_by);
create index crm_proposals_applier on public.crm_task_plan_proposals(applied_by);
alter table public.crm_task_plan_proposals enable row level security;
revoke all on public.crm_task_plan_proposals from public,anon,authenticated;
grant select on public.crm_task_plan_proposals to authenticated;
create policy task_proposal_read on public.crm_task_plan_proposals for select to authenticated using(portal_private.execution_manager(project_id));
alter table public.crm_task_plan_history add column proposal_id uuid references public.crm_task_plan_proposals;
create index crm_plan_history_proposal on public.crm_task_plan_history(proposal_id);

create function public.submit_task_plan_proposal(p_id uuid,p_task uuid,p_task_version integer,p_change uuid,p_change_version integer,p_plan jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare pid uuid;c public.crm_project_changes;t public.crm_task_plans;old public.crm_task_plan_proposals;k text;
begin
 select project_id into pid from public.tasks where id=p_task;
 if not portal_private.execution_manager(pid) then raise exception 'Assigned project manager access required';end if;
 perform 1 from public.projects where id=pid and status<>'Completed' for update;if not found then raise exception 'Open project required';end if;
 select * into c from public.crm_project_changes where id=p_change for update;
 if c.id is null or c.project_id is distinct from pid or c.version is distinct from p_change_version or c.details->>'status'<>'Approved' then raise exception 'Current approved change for this task project required';end if;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Proposal ID and reason required';end if;
 if p_plan is null or jsonb_typeof(p_plan)<>'object' or (select count(*) from jsonb_object_keys(p_plan))<>5 then raise exception 'Exact five-field plan required';end if;
 foreach k in array array['quantity','duration_minutes','crew'] loop
  if jsonb_typeof(p_plan->k) is distinct from 'number' then raise exception 'Numeric planning fields required';end if;
 end loop;
 foreach k in array array['tools','preconditions'] loop
  if jsonb_typeof(p_plan->k) is distinct from 'string' or length(p_plan->>k)>2000 then raise exception 'Bounded planning notes required';end if;
 end loop;
 if not((p_plan->>'quantity')::numeric>0 and (p_plan->>'quantity')::numeric<=100000 and (p_plan->>'duration_minutes')::numeric>0 and (p_plan->>'duration_minutes')::numeric<=1000000 and (p_plan->>'crew')::numeric between 1 and 100 and (p_plan->>'crew')::numeric=trunc((p_plan->>'crew')::numeric)) then raise exception 'Bounded quantity duration and integer crew required';end if;
 select * into old from public.crm_task_plan_proposals where id=p_id;
 if old.id is not null then
  if old.submitted_by=auth.uid() and old.task_id=p_task and old.task_version=p_task_version and old.change_id=p_change and old.change_version=p_change_version and old.proposed_plan=p_plan and old.reason=trim(p_reason) then return old.id;end if;
  raise exception 'Proposal ID already used with different data';
 end if;
 perform 1 from public.tasks where id=p_task for update;
 select * into t from public.crm_task_plans where task_id=p_task for update;
 if t.task_id is null or t.version is distinct from p_task_version or not exists(select 1 from public.crm_project_workstreams where id=t.workstream_id and project_id=pid) then raise exception 'Current generated task plan required';end if;
 insert into public.crm_task_plan_proposals(id,project_id,task_id,change_id,change_version,task_version,before_plan,proposed_plan,reason,submitted_by) values(p_id,pid,p_task,p_change,p_change_version,p_task_version,to_jsonb(t),p_plan,trim(p_reason),auth.uid());
 return p_id;
end$$;

create function public.review_task_plan_proposal(p_id uuid,p_approve boolean,p_note text) returns void language plpgsql security definer set search_path='' as $$
declare r public.crm_task_plan_proposals;pid uuid;
begin
 if not public.is_admin() then raise exception 'Separate administrator review required';end if;
 select project_id into pid from public.crm_task_plan_proposals where id=p_id;
 perform 1 from public.projects where id=pid and status<>'Completed' for update;if not found then raise exception 'Open project required';end if;
 select * into r from public.crm_task_plan_proposals where id=p_id for update;
 if r.id is null or r.status<>'Submitted' or r.submitted_by=auth.uid() then raise exception 'Separate administrator reviews a submitted proposal';end if;
 if p_approve is null or length(trim(coalesce(p_note,''))) not between 3 and 2000 then raise exception 'Explicit review decision and note required';end if;
 if p_approve and (not exists(select 1 from public.crm_task_plans where task_id=r.task_id and version=r.task_version) or not exists(select 1 from public.crm_project_changes where id=r.change_id and project_id=r.project_id and version=r.change_version and details->>'status'='Approved')) then raise exception 'Proposal baseline or change decision is stale';end if;
 update public.crm_task_plan_proposals set status=case when p_approve then 'Approved' else 'Rejected' end,reviewed_by=auth.uid(),reviewed_at=now(),decision_note=trim(p_note) where id=p_id;
end$$;

create function public.apply_task_plan_proposal(p_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare r public.crm_task_plan_proposals;pid uuid;
begin
 if not public.is_admin() then raise exception 'Administrator applies reviewed proposals';end if;
 select project_id into pid from public.crm_task_plan_proposals where id=p_id;
 perform 1 from public.projects where id=pid for update;if not found then raise exception 'Proposal project required';end if;
 select * into r from public.crm_task_plan_proposals where id=p_id for update;
 if r.status='Applied' then return;end if;
 if r.id is null or r.status<>'Approved' or r.reviewed_by is null or r.reviewed_by=r.submitted_by then raise exception 'Separately approved proposal required';end if;
 perform public.apply_crm_task_change(r.change_id,r.change_version,r.task_id,r.task_version,(r.proposed_plan->>'quantity')::numeric,(r.proposed_plan->>'duration_minutes')::numeric,(r.proposed_plan->>'crew')::integer,r.proposed_plan->>'tools',r.proposed_plan->>'preconditions',r.reason);
 update public.crm_task_plan_history set proposal_id=r.id where task_id=r.task_id and revision=r.task_version+1;
 if not found then raise exception 'Atomic proposal history required';end if;
 update public.crm_task_plan_proposals set status='Applied',applied_by=auth.uid(),applied_at=now(),applied_revision=r.task_version+1 where id=r.id;
end$$;
revoke all on function public.submit_task_plan_proposal(uuid,uuid,integer,uuid,integer,jsonb,text),public.review_task_plan_proposal(uuid,boolean,text),public.apply_task_plan_proposal(uuid) from public,anon;
grant execute on function public.submit_task_plan_proposal(uuid,uuid,integer,uuid,integer,jsonb,text),public.review_task_plan_proposal(uuid,boolean,text),public.apply_task_plan_proposal(uuid) to authenticated;
commit;
