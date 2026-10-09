begin;
alter table public.portal_reminders add column schedule_id uuid references public.work_schedules;
alter table public.portal_reminders add column schedule_version integer;
alter table public.portal_reminders add constraint reminder_schedule_reference check((schedule_id is null)=(schedule_version is null));
create index reminder_schedule on public.portal_reminders(schedule_id) where schedule_id is not null;
create function portal_private.schedule_reminder_visible(p_schedule uuid,p_version integer) returns boolean language sql stable security definer set search_path='' as $$select p_schedule is null or exists(select 1 from public.work_schedules s where s.id=p_schedule and s.version=p_version and s.user_id=auth.uid() and s.status='Scheduled' and s.planned_end>=now()-interval '24 hours' and portal_private.schedule_read(s) and not exists(select 1 from public.work_activities a where a.schedule_id=s.id));$$;
create policy schedule_reminder_scope on public.portal_reminders as restrictive for all to authenticated using(portal_private.schedule_reminder_visible(schedule_id,schedule_version)) with check(portal_private.schedule_reminder_visible(schedule_id,schedule_version));
alter function public.queue_portal_reminders() set schema portal_private;
alter function portal_private.queue_portal_reminders() rename to queue_reminders_before_schedules;
revoke all on function portal_private.queue_reminders_before_schedules() from public,anon,authenticated,service_role;
create function public.queue_portal_reminders() returns integer language plpgsql security definer set search_path='' as $$declare s public.work_schedules;n integer;added integer;previous text:=current_setting('request.jwt.claim.sub',true);begin
 -- The original scanner retains scheduler authorization, opt-out and existing workflows.
 n:=portal_private.queue_reminders_before_schedules();
 if not pg_try_advisory_xact_lock(hashtext('schedule-reminders')) then return n;end if;
 for s in select * from public.work_schedules where status='Scheduled' and planned_start<=now()+interval '24 hours' and planned_end>=now()-interval '24 hours' loop
 perform set_config('request.jwt.claim.sub',s.user_id::text,true);
 if portal_private.schedule_reminder_visible(s.id,s.version) then
 insert into public.portal_reminders(user_id,event_key,title,view,schedule_id,schedule_version)
 select s.user_id,'schedule-due:'||s.id||':'||s.version,'Assigned work schedule due','activity_log',s.id,s.version
 where coalesce((select enabled from public.portal_reminder_preferences where user_id=s.user_id),true) on conflict do nothing;
 get diagnostics added=row_count;n:=n+added;
 end if;
 end loop;
 perform set_config('request.jwt.claim.sub',coalesce(previous,''),true);return n;
 exception when others then perform set_config('request.jwt.claim.sub',coalesce(previous,''),true);raise;
end$$;
-- Push delivery must enforce the same current schedule scope, including queued retries.
alter function portal_private.push_visible(uuid,uuid) rename to push_visible_before_schedules;
revoke all on function portal_private.push_visible_before_schedules(uuid,uuid) from public,anon,authenticated,service_role;
create function portal_private.push_visible(p_uid uuid,p_reminder uuid) returns boolean language plpgsql security definer set search_path='' as $$declare previous text:=current_setting('request.jwt.claim.sub',true);visible boolean;begin
 if not portal_private.push_visible_before_schedules(p_uid,p_reminder) then return false;end if;
 perform set_config('request.jwt.claim.sub',p_uid::text,true);
 select portal_private.schedule_reminder_visible(schedule_id,schedule_version) into visible from public.portal_reminders where id=p_reminder and user_id=p_uid;
 perform set_config('request.jwt.claim.sub',coalesce(previous,''),true);return coalesce(visible,false);
 exception when others then perform set_config('request.jwt.claim.sub',coalesce(previous,''),true);raise;
end$$;
revoke all on function portal_private.schedule_reminder_visible(uuid,integer) from public,anon;
grant execute on function portal_private.schedule_reminder_visible(uuid,integer) to authenticated;
revoke all on function public.queue_portal_reminders() from public,anon;
grant execute on function public.queue_portal_reminders() to authenticated,service_role;
revoke all on function portal_private.push_visible(uuid,uuid) from public,anon,authenticated;
grant execute on function portal_private.push_visible(uuid,uuid) to service_role;
notify pgrst,'reload schema';
commit;
