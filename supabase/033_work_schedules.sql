begin;
create table public.work_schedules(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles,
 link_kind text not null check(link_kind in ('Project','Ticket','Deal','Internal')),project_id uuid references public.projects,task_id uuid references public.tasks,ticket_id uuid references public.tickets,deal_id uuid references public.crm_deals,
 location text not null check(length(trim(location)) between 1 and 300),activity_type text not null check(activity_type in ('Installation','Survey','Complaint','Purchase / pickup','Meeting','Training','Office work','Travel')),description text not null check(length(trim(description)) between 1 and 2000),
 planned_start timestamptz not null,planned_end timestamptz not null,given_by uuid not null references public.profiles,
 status text not null default 'Scheduled' check(status in ('Scheduled','Cancelled')),version integer not null default 1,created_at timestamptz not null default now(),
 check(isfinite(planned_start) and isfinite(planned_end) and planned_end>planned_start and planned_end-planned_start<=interval '16 hours'),
 check((link_kind='Internal' and project_id is null and task_id is null and ticket_id is null and deal_id is null) or (link_kind='Project' and project_id is not null and ticket_id is null and deal_id is null) or (link_kind='Ticket' and project_id is not null and ticket_id is not null and deal_id is null) or (link_kind='Deal' and deal_id is not null and project_id is null and task_id is null and ticket_id is null))
);
create index work_schedules_user_time on public.work_schedules(user_id,planned_start,planned_end);
create index work_schedules_project on public.work_schedules(project_id,status);
create table public.work_schedule_history(id uuid primary key default gen_random_uuid(),schedule_id uuid not null references public.work_schedules,actor_id uuid not null references public.profiles,action text not null,note text not null,snapshot jsonb not null,created_at timestamptz not null default now());
create index work_schedule_history_parent on public.work_schedule_history(schedule_id);
alter table public.work_activities add column schedule_id uuid unique references public.work_schedules;
alter table public.work_activities add column schedule_snapshot jsonb;
create function portal_private.schedule_activity(s public.work_schedules) returns public.work_activities language sql immutable set search_path='' as $$select jsonb_populate_record(null::public.work_activities,to_jsonb(s));$$;
create function portal_private.schedule_read(s public.work_schedules) returns boolean language sql stable security definer set search_path='' as $$select public.is_staff() and (portal_private.activity_reviewer(portal_private.schedule_activity(s)) or (s.user_id=auth.uid() and portal_private.activity_worker_authorized(portal_private.schedule_activity(s)) and portal_private.activity_scope(s.link_kind,s.project_id,s.task_id,s.ticket_id,s.deal_id)));$$;
alter table public.work_schedules enable row level security;alter table public.work_schedule_history enable row level security;
revoke all on public.work_schedules,public.work_schedule_history from public,anon,authenticated;
grant select on public.work_schedules,public.work_schedule_history to authenticated;
create policy schedules_read on public.work_schedules for select to authenticated using(portal_private.schedule_read(work_schedules));
create policy schedule_history_read on public.work_schedule_history for select to authenticated using(exists(select 1 from public.work_schedules s where s.id=schedule_id));
create function public.save_work_schedule(p_id uuid,p_version integer,p_data jsonb,p_note text) returns uuid language plpgsql security definer set search_path='' as $$declare s public.work_schedules;old public.work_schedules;begin
 if not public.is_staff() or length(trim(coalesce(p_note,''))) not between 3 and 2000 then raise exception 'Active staff and scheduling reason required';end if;
 s:=jsonb_populate_record(null::public.work_schedules,p_data);s.given_by:=auth.uid();s.status:=coalesce(s.status,'Scheduled');
 if not portal_private.activity_reviewer(portal_private.schedule_activity(s)) or ((s.status<>'Cancelled' or p_id is null) and not portal_private.activity_worker_authorized(portal_private.schedule_activity(s))) then raise exception 'Authorized scheduler and currently assigned worker required';end if;
 if s.task_id is not null and not exists(select 1 from public.tasks where id=s.task_id and project_id=s.project_id and (s.link_kind<>'Ticket' or ticket_id=s.ticket_id)) or s.link_kind='Ticket' and not exists(select 1 from public.tickets where id=s.ticket_id and project_id=s.project_id) or s.link_kind='Deal' and not exists(select 1 from public.crm_deals where id=s.deal_id) then raise exception 'Valid linked work required';end if;
 perform portal_private.activity_open(s.project_id);perform pg_advisory_xact_lock(hashtextextended(s.user_id::text,24));
 if p_id is not null then
 select * into old from public.work_schedules where id=p_id for update;
 if old.id is null or not portal_private.schedule_read(old) or not portal_private.activity_reviewer(portal_private.schedule_activity(old)) or old.version is distinct from p_version then raise exception 'Current authorized schedule required';end if;
 if row(old.user_id,old.link_kind,old.project_id,old.task_id,old.ticket_id,old.deal_id) is distinct from row(s.user_id,s.link_kind,s.project_id,s.task_id,s.ticket_id,s.deal_id) then raise exception 'Schedule worker and work scope are fixed; cancel and create another';end if;
 if exists(select 1 from public.work_activities where schedule_id=old.id) then raise exception 'Recorded schedule is immutable';end if;
 end if;
 if s.planned_start is null or s.planned_end is null or not isfinite(s.planned_start) or not isfinite(s.planned_end) or s.planned_end<=s.planned_start or s.planned_end-s.planned_start>interval '16 hours' then raise exception 'Finite planned interval up to sixteen hours required';end if;
 if s.status='Scheduled' and exists(select 1 from public.work_schedules where user_id=s.user_id and id is distinct from p_id and status='Scheduled' and planned_start<s.planned_end and planned_end>s.planned_start) then raise exception 'Worker schedule overlaps existing planned work';end if;
 if p_id is null then insert into public.work_schedules(user_id,link_kind,project_id,task_id,ticket_id,deal_id,location,activity_type,description,planned_start,planned_end,given_by,status) values(s.user_id,s.link_kind,s.project_id,s.task_id,s.ticket_id,s.deal_id,trim(s.location),s.activity_type,trim(s.description),s.planned_start,s.planned_end,auth.uid(),s.status) returning * into s;
 else update public.work_schedules set location=trim(s.location),activity_type=s.activity_type,description=trim(s.description),planned_start=s.planned_start,planned_end=s.planned_end,status=s.status,given_by=auth.uid(),version=version+1 where id=p_id returning * into s;end if;
 insert into public.work_schedule_history(schedule_id,actor_id,action,note,snapshot) values(s.id,auth.uid(),case when p_id is null then 'Created' when s.status='Cancelled' then 'Cancelled' else 'Revised' end,trim(p_note),to_jsonb(s));return s.id;
end$$;
-- Scheduled activity revisions retain the original planned interval and assigning person.
alter function public.save_work_activity(uuid,integer,jsonb) rename to save_work_activity_recorded;
create function public.save_work_activity(p_id uuid,p_version integer,p_data jsonb) returns uuid language plpgsql security definer set search_path='' as $$declare a public.work_activities;begin
 if p_id is not null then select * into a from public.work_activities where id=p_id;if a.schedule_id is not null then p_data:=p_data||jsonb_build_object('planned_start',a.planned_start,'planned_end',a.planned_end,'given_by',a.given_by);end if;end if;
 return public.save_work_activity_recorded(p_id,p_version,p_data);
end$$;
create function public.save_scheduled_activity(p_schedule uuid,p_version integer,p_data jsonb) returns uuid language plpgsql security definer set search_path='' as $$declare s public.work_schedules;result uuid;existing uuid;begin
 select * into s from public.work_schedules where id=p_schedule;
 if not public.is_staff() or s.id is null or s.user_id<>auth.uid() or not portal_private.schedule_read(s) then raise exception 'Own assigned schedule required';end if;
 perform portal_private.activity_open(s.project_id);perform pg_advisory_xact_lock(hashtextextended(s.user_id::text,24));select * into s from public.work_schedules where id=p_schedule for update;
 if s.version is distinct from p_version or s.status<>'Scheduled' or not portal_private.schedule_read(s) then raise exception 'Current active assigned schedule required';end if;
 select id into existing from public.work_activities where schedule_id=s.id;
 if existing is not null then raise exception 'Schedule already recorded; revise the existing activity';end if;
 p_data:=p_data||jsonb_build_object('link_kind',s.link_kind,'project_id',s.project_id,'task_id',s.task_id,'ticket_id',s.ticket_id,'deal_id',s.deal_id,'location',s.location,'activity_type',s.activity_type,'description',s.description,'planned_start',s.planned_start,'planned_end',s.planned_end,'given_by',s.given_by);
 result:=public.save_work_activity(null,null,p_data);
 update public.work_activities set schedule_id=s.id,schedule_snapshot=to_jsonb(s) where id=result;
 insert into public.work_activity_history(activity_id,actor_id,action,note,snapshot) select result,auth.uid(),'Schedule linked','Recorded actual work against assigned plan',to_jsonb(a) from public.work_activities a where a.id=result;
 return result;
end$$;
revoke all on function public.save_work_activity_recorded(uuid,integer,jsonb) from public,anon,authenticated;
revoke all on function portal_private.schedule_activity(public.work_schedules),portal_private.schedule_read(public.work_schedules) from public,anon;
grant execute on function portal_private.schedule_activity(public.work_schedules),portal_private.schedule_read(public.work_schedules) to authenticated;
revoke all on function public.save_work_schedule(uuid,integer,jsonb,text),public.save_scheduled_activity(uuid,integer,jsonb),public.save_work_activity(uuid,integer,jsonb) from public,anon;
grant execute on function public.save_work_schedule(uuid,integer,jsonb,text),public.save_scheduled_activity(uuid,integer,jsonb),public.save_work_activity(uuid,integer,jsonb) to authenticated;
notify pgrst,'reload schema';
commit;
