begin;
create table public.crm_project_lesson_adoptions(
 id uuid primary key,source_lesson_id uuid not null references public.crm_project_lessons,source_project_id uuid not null references public.projects,
 source_version integer not null,target_project_id uuid not null references public.projects,target_lesson_id uuid not null unique references public.crm_project_lessons,
 source_snapshot jsonb not null,source_review_snapshot jsonb not null,target_snapshot jsonb not null,request jsonb not null,
 reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(source_lesson_id,source_version,target_project_id),check(source_project_id<>target_project_id)
);
create index lesson_adoption_source_project on public.crm_project_lesson_adoptions(source_project_id);
create index lesson_adoption_target_project on public.crm_project_lesson_adoptions(target_project_id);
create index lesson_adoption_actor on public.crm_project_lesson_adoptions(actor_id);
alter table public.crm_project_lesson_adoptions enable row level security;
revoke all on public.crm_project_lesson_adoptions from public,anon,authenticated;
grant select on public.crm_project_lesson_adoptions to authenticated;
create policy lesson_adoption_read on public.crm_project_lesson_adoptions for select to authenticated using(portal_private.execution_manager(target_project_id));
create function public.adopt_reviewed_project_lesson(p_id uuid,p_source uuid,p_source_version integer,p_target uuid,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare s public.crm_project_lessons;h public.crm_project_lesson_history;a public.crm_project_lesson_adoptions;t public.crm_project_lessons;req jsonb;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator required to share a reviewed lesson';end if;
 if p_id is null or p_source is null or p_source_version is null or p_target is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit identity/source version/target/reason required';end if;
 req:=jsonb_build_object('source_lesson_id',p_source,'source_version',p_source_version,'target_project_id',p_target,'reason',trim(p_reason));
 perform 1 from public.projects where id=p_target for update;if not found then raise exception 'Existing target project required';end if;
 select * into a from public.crm_project_lesson_adoptions where id=p_id;
 if a.id is not null then
  if a.actor_id=auth.uid() and a.request=req then return a.target_lesson_id;end if;
  raise exception 'Adoption identity records another request';
 end if;
 select * into s from public.crm_project_lessons where id=p_source for share;
 if s.id is null or s.version is distinct from p_source_version or s.details->>'status' is distinct from 'Reviewed' then raise exception 'Exact current Reviewed source lesson required';end if;
 if s.project_id=p_target then raise exception 'Choose a different target project';end if;
 select * into h from public.crm_project_lesson_history where lesson_id=s.id and revision=s.version;
 if h.id is null or h.after_lesson is distinct from to_jsonb(s) then raise exception 'Complete current reviewed source provenance required';end if;
 if exists(select 1 from public.crm_project_lesson_adoptions where source_lesson_id=s.id and source_version=s.version and target_project_id=p_target) then raise exception 'This source version is already adopted into the target project';end if;
 if exists(select 1 from public.crm_project_lessons where id=p_id) then raise exception 'Target lesson identity is already in use';end if;
 perform public.save_project_lesson(p_id,null,p_target,s.details||jsonb_build_object('status','Draft'),trim(p_reason));
 select * into t from public.crm_project_lessons where id=p_id;
 insert into public.crm_project_lesson_adoptions(id,source_lesson_id,source_project_id,source_version,target_project_id,target_lesson_id,source_snapshot,source_review_snapshot,target_snapshot,request,reason,actor_id)
 values(p_id,s.id,s.project_id,s.version,p_target,t.id,to_jsonb(s),to_jsonb(h),to_jsonb(t),req,trim(p_reason),auth.uid());
 return t.id;
end$$;
revoke all on function public.adopt_reviewed_project_lesson(uuid,uuid,integer,uuid,text) from public,anon;
grant execute on function public.adopt_reviewed_project_lesson(uuid,uuid,integer,uuid,text) to authenticated;
notify pgrst,'reload schema';
commit;
