begin;
create table public.crm_project_communication_execution(
 id uuid primary key,plan_id uuid not null references public.crm_project_communication_drafts,project_id uuid not null references public.projects,
 plan_version integer not null,review_id uuid not null references public.crm_project_communication_reviews,
 previous_id uuid unique references public.crm_project_communication_execution,
 details jsonb not null,plan_snapshot jsonb not null,review_snapshot jsonb not null,request jsonb not null,
 reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now()
);
create index communication_execution_plan on public.crm_project_communication_execution(plan_id);
create index communication_execution_project on public.crm_project_communication_execution(project_id);
create index communication_execution_review on public.crm_project_communication_execution(review_id);
create index communication_execution_actor on public.crm_project_communication_execution(actor_id);
alter table public.crm_project_communication_execution enable row level security;
revoke all on public.crm_project_communication_execution from public,anon,authenticated;
grant select on public.crm_project_communication_execution to authenticated;
create policy communication_execution_read on public.crm_project_communication_execution for select to authenticated using(portal_private.execution_manager(project_id));
create function public.record_project_communication_execution(p_id uuid,p_plan uuid,p_version integer,p_review uuid,p_previous uuid,p_details jsonb,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare d public.crm_project_communication_drafts;c public.crm_project_charters;r public.crm_project_communication_reviews;
 prior public.crm_project_communication_execution;retry public.crm_project_communication_execution;v jsonb:='{}';req jsonb;k text;occurred timestamptz;ps jsonb;rs jsonb;
begin
 select * into d from public.crm_project_communication_drafts where id=p_plan;
 if auth.uid() is null or d.id is null or not portal_private.execution_manager(d.project_id) then raise exception 'Active assigned project manager access required';end if;
 perform 1 from public.projects where id=d.project_id for update;
 select * into d from public.crm_project_communication_drafts where id=p_plan for update;
 if p_id is null or p_version is null or p_review is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit identity/plan version/review/manual reason required';end if;
 if jsonb_typeof(p_details) is distinct from 'object' or (select count(*) from jsonb_object_keys(p_details))<>5 or (p_details-array['occurred_at','channel','participants','outcome','evidence'])<>'{}'::jsonb then raise exception 'Exact manual occurrence fields required';end if;
 foreach k in array array['occurred_at','channel','participants','outcome','evidence'] loop
  if jsonb_typeof(p_details->k) is distinct from 'string' then raise exception 'Manual occurrence text required';end if;
  v:=v||jsonb_build_object(k,trim(p_details->>k));
 end loop;
 if length(v->>'channel') not between 1 and 100 or length(v->>'participants') not between 1 and 2000 or length(v->>'outcome') not between 3 and 4000 or length(v->>'evidence')>4000 then raise exception 'Bounded actual channel/participants/outcome/evidence required';end if;
 if v->>'occurred_at'!~'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d{1,6})?)?(Z|[+-]\d{2}:\d{2})$' then raise exception 'Explicit ISO occurrence time and timezone required';end if;
 occurred:=(v->>'occurred_at')::timestamptz;
 if not isfinite(occurred) or occurred>clock_timestamp() then raise exception 'Actual finite occurrence cannot be in the future';end if;
 v:=v||jsonb_build_object('occurred_at',to_char(occurred at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'));
 req:=jsonb_build_object('plan_id',p_plan,'version',p_version,'review_id',p_review,'previous_id',p_previous,'details',v,'reason',trim(p_reason));
 select * into retry from public.crm_project_communication_execution where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=req then return retry.id;end if;
  raise exception 'Occurrence identity records a different request';
 end if;
 if p_previous is not null then
  select * into prior from public.crm_project_communication_execution where id=p_previous for update;
  if prior.id is null or prior.plan_id is distinct from d.id or prior.project_id is distinct from d.project_id or prior.plan_version is distinct from p_version or prior.review_id is distinct from p_review or exists(select 1 from public.crm_project_communication_execution where previous_id=prior.id) then raise exception 'Exact latest occurrence/version/review required for correction';end if;
  ps:=prior.plan_snapshot;rs:=prior.review_snapshot;
 else
  if d.version is distinct from p_version then raise exception 'Communication plan changed; refresh version';end if;
  select * into r from public.crm_project_communication_reviews where plan_id=d.id and plan_version=d.version order by sequence desc limit 1;
  select * into c from public.crm_project_charters where id=d.charter_id for share;
  if r.id is null or r.id is distinct from p_review or r.action is distinct from 'Reviewed' or r.snapshot is distinct from to_jsonb(d) or c.id is null or c.details->>'status' is distinct from 'Reviewed' or d.source_snapshot is distinct from to_jsonb(c) then raise exception 'Exact current Reviewed plan and charter evidence required';end if;
  ps:=to_jsonb(d);rs:=to_jsonb(r);
 end if;
 insert into public.crm_project_communication_execution(id,plan_id,project_id,plan_version,review_id,previous_id,details,plan_snapshot,review_snapshot,request,reason,actor_id)
 values(p_id,d.id,d.project_id,p_version,p_review,p_previous,v,ps,rs,req,trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.record_project_communication_execution(uuid,uuid,integer,uuid,uuid,jsonb,text) from public,anon;
grant execute on function public.record_project_communication_execution(uuid,uuid,integer,uuid,uuid,jsonb,text) to authenticated;
notify pgrst,'reload schema';
commit;
