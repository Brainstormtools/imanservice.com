begin;
-- Assessments are append-only recorded judgments, separate from frozen change decisions.
create table public.crm_change_fulfilment (
 id uuid primary key,
 change_id uuid not null references public.crm_project_changes,
 project_id uuid not null references public.projects,
 change_version integer not null,
 revision integer not null check(revision>0),
 previous_id uuid references public.crm_change_fulfilment,
 status text not null check(status in ('Not fulfilled','Partially fulfilled','Fulfilled')),
 coverage text not null check(length(coverage) between 3 and 4000),
 remaining_work text not null check(length(remaining_work) between 3 and 4000),
 evidence text not null check(length(evidence) between 3 and 4000),
 reason text not null check(length(reason) between 3 and 2000),
 decision_snapshot jsonb not null,
 application_snapshot jsonb not null,
 actor_id uuid not null references public.profiles,
 created_at timestamptz not null default now(),
 unique(change_id,revision)
);
create index crm_change_fulfilment_project on public.crm_change_fulfilment(project_id);
create index crm_change_fulfilment_actor on public.crm_change_fulfilment(actor_id);
create index crm_change_fulfilment_previous on public.crm_change_fulfilment(previous_id);
alter table public.crm_change_fulfilment enable row level security;
revoke all on public.crm_change_fulfilment from public,anon,authenticated;
grant select on public.crm_change_fulfilment to authenticated;
create policy change_fulfilment_read on public.crm_change_fulfilment for select to authenticated using(portal_private.execution_manager(project_id));
create function public.record_change_fulfilment(p_id uuid,p_change uuid,p_change_version integer,p_previous uuid,p_status text,p_coverage text,p_remaining_work text,p_evidence text,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare c public.crm_project_changes; prior public.crm_change_fulfilment; existing public.crm_change_fulfilment; links jsonb;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator required';end if;
 select * into c from public.crm_project_changes where id=p_change;
 if c.id is null then raise exception 'Change request required';end if;
 perform 1 from public.projects where id=c.project_id for update;
 select * into c from public.crm_project_changes where id=p_change for update;
 if c.details->>'status'<>'Approved' or c.version is distinct from p_change_version then raise exception 'Current Approved change decision required';end if;
 if p_id is null or p_status is null or p_status not in ('Not fulfilled','Partially fulfilled','Fulfilled')
 or length(trim(coalesce(p_coverage,''))) not between 3 and 4000
 or length(trim(coalesce(p_remaining_work,''))) not between 3 and 4000
 or length(trim(coalesce(p_evidence,''))) not between 3 and 4000
 or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Bounded status, coverage, remaining work, evidence and reason required';end if;
 select * into existing from public.crm_change_fulfilment where id=p_id;
 if existing.id is not null then
  if existing.change_id=p_change and existing.change_version=p_change_version and existing.previous_id is not distinct from p_previous
   and existing.actor_id=auth.uid() and existing.status=p_status and existing.coverage=trim(p_coverage)
   and existing.remaining_work=trim(p_remaining_work) and existing.evidence=trim(p_evidence) and existing.reason=trim(p_reason) then return p_id;end if;
  raise exception 'Assessment ID already used with different data';
 end if;
 select * into prior from public.crm_change_fulfilment where change_id=p_change order by revision desc limit 1;
 if prior.id is distinct from p_previous then raise exception 'Current prior assessment required; refresh before recording';end if;
 select coalesce(jsonb_agg(jsonb_build_object('history_id',h.id,'task_id',h.task_id,'revision',h.revision,'proposal_id',h.proposal_id,'actor_id',h.actor_id,'created_at',h.created_at,'reason',h.reason,'current_plan_version',p.version) order by h.task_id,h.revision),'[]'::jsonb)
 into links from public.crm_task_plan_history h left join public.crm_task_plans p on p.task_id=h.task_id
 where h.change_id=c.id and h.project_id=c.project_id and h.change_version=c.version;
 insert into public.crm_change_fulfilment(id,change_id,project_id,change_version,revision,previous_id,status,coverage,remaining_work,evidence,reason,decision_snapshot,application_snapshot,actor_id)
 values(p_id,c.id,c.project_id,c.version,coalesce(prior.revision,0)+1,p_previous,p_status,trim(p_coverage),trim(p_remaining_work),trim(p_evidence),trim(p_reason),to_jsonb(c),links,auth.uid());
 return p_id;
end$$;
revoke all on function public.record_change_fulfilment(uuid,uuid,integer,uuid,text,text,text,text,text) from public,anon;
grant execute on function public.record_change_fulfilment(uuid,uuid,integer,uuid,text,text,text,text,text) to authenticated;
commit;
