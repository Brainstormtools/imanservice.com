-- Portal-only reminders. No email/SMS/WhatsApp delivery or provider credentials.
begin;
create table public.portal_reminder_preferences(user_id uuid primary key references public.profiles,enabled boolean not null default true);
create table public.portal_reminders(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles,event_key text not null,
 title text not null,view text not null,project_id uuid references public.projects,task_id uuid references public.tasks,job_id uuid references public.it_jobs,ticket_id uuid references public.tickets,contract_id uuid references public.contracts,
 created_at timestamptz not null default now(),read_at timestamptz,unique(user_id,event_key)
);
alter table public.portal_reminder_preferences enable row level security;
alter table public.portal_reminders enable row level security;
create policy reminder_pref_read on public.portal_reminder_preferences for select to authenticated using(user_id=auth.uid() and exists(select 1 from public.profiles where id=auth.uid() and active));
create policy reminder_read on public.portal_reminders for select to authenticated using(user_id=auth.uid() and exists(select 1 from public.profiles where id=auth.uid() and active)
 and (project_id is null or public.can_project(project_id)) and (task_id is null or not portal_private.team_account() or portal_private.task_assigned(task_id))
 and (ticket_id is null or not portal_private.team_account() or portal_private.ticket_visible(ticket_id))
 and (contract_id is null or (not portal_private.team_account() and exists(select 1 from public.contracts c where c.id=contract_id and public.can_company(c.company_id))))
 and (job_id is null or exists(select 1 from public.it_jobs j where j.id=job_id and public.it_job_visible(j))));
grant select on public.portal_reminders,public.portal_reminder_preferences to authenticated;
create function public.save_portal_reminder_preferences(p_enabled boolean) returns void language plpgsql security definer set search_path='' as $$begin
 if not exists(select 1 from public.profiles where id=auth.uid() and active) or p_enabled is null then raise exception 'Active account and preference required';end if;
 insert into public.portal_reminder_preferences values(auth.uid(),p_enabled) on conflict(user_id) do update set enabled=excluded.enabled;
end$$;
create function public.read_portal_reminder(p_id uuid) returns void language plpgsql security invoker set search_path='' as $$begin
 update public.portal_reminders set read_at=coalesce(read_at,now()) where id=p_id and user_id=auth.uid();end$$;
grant update(read_at) on public.portal_reminders to authenticated;
create policy reminder_mark_read on public.portal_reminders for update to authenticated using(user_id=auth.uid() and exists(select 1 from public.profiles where id=auth.uid() and active)) with check(user_id=auth.uid());
create function portal_private.add_reminder(uid uuid,key text,label text,target text,pid uuid default null,tid uuid default null,jid uuid default null,ticket uuid default null,contract uuid default null) returns integer language plpgsql security definer set search_path='' as $$declare n integer;begin
 insert into public.portal_reminders(user_id,event_key,title,view,project_id,task_id,job_id,ticket_id,contract_id)
 select uid,key,label,target,pid,tid,jid,ticket,contract where exists(select 1 from public.profiles u left join public.portal_reminder_preferences p on p.user_id=u.id where u.id=uid and u.active and coalesce(p.enabled,true)) on conflict do nothing;
 get diagnostics n=row_count;return n;end$$;
create function public.queue_portal_reminders() returns integer language plpgsql security definer set search_path='' as $$declare t public.tasks;j public.it_jobs;u public.profiles;c public.task_completions;v public.tickets;r public.contracts;n integer:=0;day date:=(now() at time zone 'UTC')::date;begin
 if not public.is_admin() and coalesce(auth.role(),'')<>'service_role' and not(auth.uid() is null and session_user='postgres') then raise exception 'Administrator or scheduler required';end if;
 if not pg_try_advisory_xact_lock(hashtext('portal-reminders')) then return 0;end if;
 for t in select * from public.tasks where status<>'Done' and deadline<=day+2 loop
 for u in select * from public.profiles where active and (role='admin' or (role='team' and (id=t.assignee or id=any(t.collaborators) or exists(select 1 from public.project_assignments a where a.project_id=t.project_id and a.technician_id=id) or exists(select 1 from public.it_jobs linked_job where linked_job.task_id=t.id and linked_job.technician_id=profiles.id and linked_job.status<>'Cancelled')))) loop
 n:=n+portal_private.add_reminder(u.id,'task-due:'||t.id||':'||t.deadline||':'||case when t.deadline<day then 'overdue' else 'soon' end,case when t.deadline<day then 'Assigned task overdue' else 'Assigned task due soon' end,'projects',t.project_id,t.id);
 end loop;end loop;
 for c in select * from public.task_completions where status in ('Submitted','Published','Changes requested') loop
 for u in select recipient.* from public.profiles recipient join public.projects p on p.id=c.project_id where recipient.active and ((c.status='Submitted' and recipient.role='admin') or (c.status='Published' and recipient.role='client' and recipient.company_id=p.company_id and exists(select 1 from public.tasks related_task where related_task.id=c.task_id and not related_task.internal)) or (c.status='Changes requested' and (recipient.role='admin' or (recipient.role='team' and (recipient.id=c.technician_id or exists(select 1 from public.tasks related_task where related_task.id=c.task_id and (related_task.assignee=recipient.id or recipient.id=any(related_task.collaborators)))))))) loop
 n:=n+portal_private.add_reminder(u.id,'task-review:'||c.task_id||':'||c.version,'Task '||case c.status when 'Submitted' then 'awaiting administrator review' when 'Published' then 'ready for client review' else 'changes requested' end,'projects',c.project_id,c.task_id);
 end loop;end loop;
 for j in select * from public.it_jobs where status in ('Submitted','Published','Changes requested') or (status='Scheduled' and scheduled_at<=now()+interval '24 hours' and ends_at>=now()-interval '24 hours') loop
 for u in select * from public.profiles where active and ((j.status='Submitted' and role='admin') or (j.status='Published' and role='client' and company_id=j.company_id) or (j.status in ('Scheduled','Changes requested') and (role='admin' or (role='team' and id=j.technician_id)))) loop
 n:=n+portal_private.add_reminder(u.id,'job:'||j.id||':'||j.version||':'||j.status,case j.status when 'Scheduled' then 'Assigned appointment due' when 'Submitted' then 'Work awaiting administrator review' when 'Published' then 'Published work ready for client review' else 'Work changes requested' end,case j.kind when 'Audit' then 'audits' else 'visits' end,j.project_id,j.task_id,j.id);
 end loop;end loop;
 for v in select * from public.tickets where status<>'Resolved' and ((first_response_at is null and response_due_at<now()) or resolution_due_at<now()) loop
 for u in select recipient.* from public.profiles recipient join public.projects p on p.id=v.project_id where recipient.active and (recipient.role='admin' or (recipient.role='client' and recipient.company_id=p.company_id) or (recipient.role='team' and (exists(select 1 from public.project_assignments a where a.project_id=p.id and a.technician_id=recipient.id) or exists(select 1 from public.tasks k where k.ticket_id=v.id and (k.assignee=recipient.id or recipient.id=any(k.collaborators)))))) loop
 n:=n+portal_private.add_reminder(u.id,'sla:'||v.id||':'||coalesce(v.response_due_at::text,'')||':'||coalesce(v.resolution_due_at::text,''),'Support SLA deadline overdue','support',v.project_id,null,null,v.id);
 end loop;end loop;
 for r in select * from public.contracts where status='Active' and renewal_date<=day+30 loop
 for u in select * from public.profiles where active and (role='admin' or (role='client' and company_id=r.company_id)) loop
 n:=n+portal_private.add_reminder(u.id,'renewal:'||r.id||':'||r.renewal_date,'AMC renewal follow-up due','contracts',null,null,null,null,r.id);
 end loop;end loop;
 return n;
end$$;
revoke all on function portal_private.add_reminder(uuid,text,text,text,uuid,uuid,uuid,uuid,uuid) from public,anon,authenticated;
revoke all on function public.save_portal_reminder_preferences(boolean),public.read_portal_reminder(uuid),public.queue_portal_reminders() from public,anon;
grant execute on function public.save_portal_reminder_preferences(boolean),public.read_portal_reminder(uuid),public.queue_portal_reminders() to authenticated;
grant execute on function public.queue_portal_reminders() to service_role;
create index portal_reminders_inbox on public.portal_reminders(user_id,created_at desc);
-- Dedicated database job works even when the website is closed. Existing billing/SLA jobs remain.
do $$begin
 if exists(select 1 from pg_extension where extname='pg_cron') then
 execute $cron$select cron.schedule('iman-portal-reminders','*/15 * * * *','select public.queue_portal_reminders()')$cron$;
 end if;
end$$;
notify pgrst,'reload schema';
commit;
