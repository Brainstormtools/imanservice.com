begin;
create table public.crm_project_lessons(id uuid primary key,project_id uuid not null references public.projects,details jsonb not null check(jsonb_typeof(details)='object'),version integer not null default 1,reason text not null check(length(trim(reason)) between 3 and 2000),created_by uuid not null references public.profiles,created_at timestamptz not null default now());
create index crm_lesson_project on public.crm_project_lessons(project_id);
create index crm_lesson_author on public.crm_project_lessons(created_by);
create table public.crm_project_lesson_history(id uuid primary key default gen_random_uuid(),lesson_id uuid not null references public.crm_project_lessons,project_id uuid not null references public.projects,revision integer not null,before_lesson jsonb,after_lesson jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(lesson_id,revision));
create index crm_lesson_history_project on public.crm_project_lesson_history(project_id);
create index crm_lesson_history_actor on public.crm_project_lesson_history(actor_id);
alter table public.crm_project_lessons enable row level security;
alter table public.crm_project_lesson_history enable row level security;
revoke all on public.crm_project_lessons,public.crm_project_lesson_history from public,anon,authenticated;
grant select on public.crm_project_lessons,public.crm_project_lesson_history to authenticated;
create policy project_lesson_read on public.crm_project_lessons for select to authenticated using(portal_private.execution_manager(project_id));
create policy project_lesson_history_read on public.crm_project_lesson_history for select to authenticated using(portal_private.execution_manager(project_id));
create function public.save_project_lesson(p_id uuid,p_version integer,p_project uuid,p_details jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare old public.crm_project_lessons;newrow public.crm_project_lessons;d jsonb;k text;
begin
 if not portal_private.execution_manager(p_project) then raise exception 'Assigned project manager access required';end if;
 perform 1 from public.projects where id=p_project for update;if not found then raise exception 'Project required';end if;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Lesson ID and revision reason required';end if;
 if p_details is null or jsonb_typeof(p_details)<>'object' or (select count(*) from jsonb_object_keys(p_details))<>7 then raise exception 'Complete lesson details required';end if;
 d:='{}'::jsonb;
 foreach k in array array['title','observation','cause','recommendation','applicability','status','source'] loop
  if jsonb_typeof(p_details->k) is distinct from 'string' then raise exception 'Complete text lesson fields required';end if;
  d:=d||jsonb_build_object(k,trim(p_details->>k));
 end loop;
 if length(d->>'title') not between 3 and 160 or length(d->>'observation') not between 3 and 4000 or length(d->>'cause')>4000 or length(d->>'recommendation')>4000 or length(d->>'applicability')>4000 or length(d->>'source')>4000 or d->>'status' not in ('Draft','Reviewed','Archived') then raise exception 'Bounded lesson observation and valid status required';end if;
 if d->>'status' in ('Reviewed','Archived') then
  if not public.is_admin() then raise exception 'Administrator reviews or archives lessons';end if;
  if length(d->>'recommendation')<3 or length(d->>'applicability')<3 then raise exception 'Review requires recommendation and applicability';end if;
 end if;
 select * into old from public.crm_project_lessons where id=p_id for update;
 if old.id is not null then
  if p_version is null then
   if old.created_by=auth.uid() and old.version=1 and old.project_id=p_project and old.details=d and old.reason=trim(p_reason) then return old.id;end if;
   raise exception 'Lesson ID already used with different data';
  end if;
  if old.project_id<>p_project or old.version is distinct from p_version then raise exception 'Current lesson version and fixed project required';end if;
  if old.details->>'status'='Archived' then raise exception 'Archived lesson is immutable';end if;
  if old.details->>'status'='Reviewed' and not public.is_admin() then raise exception 'Administrator must revise or withdraw lesson review';end if;
  if d->>'status'='Archived' and old.details->>'status'<>'Reviewed' then raise exception 'Review lesson before archiving';end if;
  update public.crm_project_lessons set details=d,reason=trim(p_reason),version=version+1 where id=p_id returning * into newrow;
 else
  if p_version is not null or d->>'status'<>'Draft' then raise exception 'New lesson must start Draft without a saved version';end if;
  insert into public.crm_project_lessons(id,project_id,details,reason,created_by) values(p_id,p_project,d,trim(p_reason),auth.uid()) returning * into newrow;
 end if;
 insert into public.crm_project_lesson_history(lesson_id,project_id,revision,before_lesson,after_lesson,reason,actor_id) values(p_id,p_project,newrow.version,case when old.id is null then null else to_jsonb(old) end,to_jsonb(newrow),trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.save_project_lesson(uuid,integer,uuid,jsonb,text) from public,anon;
grant execute on function public.save_project_lesson(uuid,integer,uuid,jsonb,text) to authenticated;
commit;
