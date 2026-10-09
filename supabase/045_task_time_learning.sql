begin;
create table public.crm_activity_plan_basis(activity_id uuid primary key references public.work_activities,project_id uuid not null references public.projects,task_id uuid not null references public.tasks,snapshot jsonb not null,captured_at timestamptz not null default now());
create index crm_activity_basis_project on public.crm_activity_plan_basis(project_id);
create index crm_activity_basis_task on public.crm_activity_plan_basis(task_id);
create table public.crm_task_learning_reviews(id uuid primary key default gen_random_uuid(),project_id uuid not null references public.projects,task_id uuid not null references public.tasks,revision integer not null,quantity numeric not null check(quantity>0 and quantity<=100000),source_hash text not null,snapshot jsonb not null,reason text not null check(length(trim(reason)) between 3 and 2000),reviewer_id uuid not null references public.profiles,reviewed_at timestamptz not null default now(),unique(task_id,revision));
create index crm_learning_project on public.crm_task_learning_reviews(project_id);
create index crm_learning_reviewer on public.crm_task_learning_reviews(reviewer_id);
alter table public.crm_activity_plan_basis enable row level security;
alter table public.crm_task_learning_reviews enable row level security;
revoke all on public.crm_activity_plan_basis,public.crm_task_learning_reviews from public,anon,authenticated;
grant select on public.crm_activity_plan_basis,public.crm_task_learning_reviews to authenticated;
create policy activity_basis_read on public.crm_activity_plan_basis for select to authenticated using(portal_private.execution_manager(project_id));
create policy learning_review_read on public.crm_task_learning_reviews for select to authenticated using(portal_private.execution_manager(project_id));
create function portal_private.capture_activity_plan_basis() returns trigger language plpgsql security definer set search_path='' as $$begin
insert into public.crm_activity_plan_basis(activity_id,project_id,task_id,snapshot)
select new.id,new.project_id,new.task_id,jsonb_build_object('task_plan',to_jsonb(p),'template_version',s.template_version_id) from public.crm_task_plans p join public.crm_project_workstreams s on s.id=p.workstream_id where p.task_id=new.task_id and s.project_id=new.project_id;
return new;end$$;
revoke all on function portal_private.capture_activity_plan_basis() from public,anon,authenticated;
create trigger capture_activity_plan_basis after insert on public.work_activities for each row execute function portal_private.capture_activity_plan_basis();
-- No historical backfill: missing or mixed captured bases leave comparisons unknown.
create function portal_private.task_learning_source(p_task uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$declare t public.tasks;activities jsonb;basis jsonb;approved_count integer;pending_count integer;missing_count integer;mixed_count integer;minutes numeric;lost numeric;completion jsonb;hash text;ready boolean;begin
select * into t from public.tasks where id=p_task;
select jsonb_build_object('status',c.status,'version',c.version) into completion from public.task_completions c where c.task_id=p_task;
select coalesce(jsonb_agg(jsonb_build_object('id',a.id,'version',a.version,'status',a.status,'start',a.actual_start,'end',a.actual_end,'lost_minutes',a.lost_minutes,'basis',b.snapshot) order by a.id),'[]') into activities from public.work_activities a left join public.crm_activity_plan_basis b on b.activity_id=a.id where a.task_id=p_task;
select count(*) filter(where a.status='Approved'),count(*) filter(where a.status not in ('Approved','Voided')),count(*) filter(where a.status='Approved' and b.activity_id is null),count(distinct b.snapshot::text) filter(where a.status='Approved'),coalesce(sum(extract(epoch from a.actual_end-a.actual_start)/60) filter(where a.status='Approved'),0),coalesce(sum(a.lost_minutes) filter(where a.status='Approved'),0) into approved_count,pending_count,missing_count,mixed_count,minutes,lost from public.work_activities a left join public.crm_activity_plan_basis b on b.activity_id=a.id where a.task_id=p_task;
select b.snapshot into basis from public.crm_activity_plan_basis b join public.work_activities a on a.id=b.activity_id where a.task_id=p_task and a.status='Approved' order by a.id limit 1;
ready:=coalesce(t.status='Done' and completion->>'status' in ('Published','Confirmed') and approved_count>0 and pending_count=0 and missing_count=0 and mixed_count=1 and (basis->'task_plan'->>'quantity')::numeric>0 and (basis->'task_plan'->>'duration_minutes')::numeric>0 and (basis->'task_plan'->>'crew')::integer>0,false);
hash:=md5(jsonb_build_array(t.project_id,t.status,completion,activities)::text);
return jsonb_build_object('task_id',p_task,'project_id',t.project_id,'title',t.title,'ready',ready,'source_hash',hash,'approved_count',approved_count,'pending_count',pending_count,'missing_basis_count',missing_count,'basis_count',mixed_count,'basis',basis,'worker_minutes',minutes,'lost_minutes',lost,'note','Approved individual elapsed intervals only; crew metadata does not multiply time. Output quantity requires separate administrator review.');end$$;
revoke all on function portal_private.task_learning_source(uuid) from public,anon,authenticated;
create function public.review_crm_task_learning(p_task uuid,p_version integer,p_source_hash text,p_quantity numeric,p_reason text) returns void language plpgsql security definer set search_path='' as $$declare pid uuid;v integer;src jsonb;baseline numeric;actual numeric;begin
if not public.is_admin() then raise exception 'Administrator reviews measured output';end if;
select project_id into pid from public.tasks where id=p_task;perform 1 from public.projects where id=pid for update;
perform 1 from public.tasks where id=p_task and project_id=pid for update;if not found or not exists(select 1 from public.crm_task_plans p join public.crm_project_workstreams s on s.id=p.workstream_id where p.task_id=p_task and s.project_id=pid) then raise exception 'Generated project task required';end if;
select coalesce(max(revision),0) into v from public.crm_task_learning_reviews where task_id=p_task;
if v is distinct from p_version then raise exception 'Current learning review version required';end if;
src:=portal_private.task_learning_source(p_task);
if not (src->>'ready')::boolean or src->>'source_hash' is distinct from p_source_hash then raise exception 'Current complete approved activity and captured planning evidence required';end if;
if p_quantity is null or not(p_quantity>0 and p_quantity<=100000) or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Verified output quantity and reason required';end if;
baseline:=(src->'basis'->'task_plan'->>'duration_minutes')::numeric*(src->'basis'->'task_plan'->>'crew')::numeric/(src->'basis'->'task_plan'->>'quantity')::numeric;
actual:=(src->>'worker_minutes')::numeric/p_quantity;
insert into public.crm_task_learning_reviews(project_id,task_id,revision,quantity,source_hash,snapshot,reason,reviewer_id) values(pid,p_task,v+1,p_quantity,src->>'source_hash',src||jsonb_build_object('reviewed_quantity',p_quantity,'baseline_worker_minutes_per_unit',baseline,'actual_worker_minutes_per_unit',actual,'variance_percent',(actual/baseline-1)*100),trim(p_reason),auth.uid());
end$$;
create function public.crm_project_task_learning(p_project uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$declare result jsonb:='[]';t record;src jsonb;r public.crm_task_learning_reviews;valid boolean;begin
if not exists(select 1 from public.projects where id=p_project) or not portal_private.execution_manager(p_project) then raise exception 'Assigned project manager access required';end if;
for t in select x.id from public.tasks x join public.crm_task_plans p on p.task_id=x.id join public.crm_project_workstreams s on s.id=p.workstream_id where x.project_id=p_project and s.project_id=p_project order by x.id loop
src:=portal_private.task_learning_source(t.id);select * into r from public.crm_task_learning_reviews where task_id=t.id order by revision desc limit 1;
valid:=coalesce(r.id is not null and (src->>'ready')::boolean and r.source_hash=src->>'source_hash',false);
result:=result||jsonb_build_array(src||jsonb_build_object('review_version',coalesce(r.revision,0),'review_current',valid,'reviewed_quantity',case when valid then r.quantity end,'baseline_worker_minutes_per_unit',case when valid then r.snapshot->'baseline_worker_minutes_per_unit' end,'actual_worker_minutes_per_unit',case when valid then r.snapshot->'actual_worker_minutes_per_unit' end,'variance_percent',case when valid then r.snapshot->'variance_percent' end,'unit',src->'basis'->'task_plan'->>'unit'));
end loop;return result;end$$;
revoke all on function public.review_crm_task_learning(uuid,integer,text,numeric,text),public.crm_project_task_learning(uuid) from public,anon;
grant execute on function public.review_crm_task_learning(uuid,integer,text,numeric,text),public.crm_project_task_learning(uuid) to authenticated;
commit;
