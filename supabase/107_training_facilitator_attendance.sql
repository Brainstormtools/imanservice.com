begin;
create function portal_private.training_facilitator_access(p_register uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles u join public.crm_training_attendee_registers r on r.id=p_register
 where u.id=auth.uid() and u.active and u.role in ('admin','team')
 and not exists(select 1 from public.crm_training_attendee_registers n where n.source_kind=r.source_kind and n.source_id=r.source_id and n.sequence>r.sequence)
 and case r.source_kind when 'Project' then exists(
 select 1 from public.crm_training_session_definitions d join public.crm_project_training t on t.id=d.training_id
 where d.id=r.project_definition_id and d.training_version=r.source_version and t.version=r.source_version and t.details->>'status'='Draft'
 and not exists(select 1 from public.crm_training_session_definitions n where n.training_id=d.training_id and n.sequence>d.sequence)
 and (u.role='admin' or (d.facilitator_id=u.id and exists(select 1 from public.project_assignments a where a.project_id=d.project_id and a.technician_id=u.id))))
 when 'Internal' then exists(select 1 from public.crm_internal_training t where t.id=r.internal_training_id and t.version=r.source_version and t.status='Draft' and (u.role='admin' or t.facilitator_id=u.id)) else false end);
$$;
revoke all on function portal_private.training_facilitator_access(uuid) from public,anon,authenticated;
create table public.crm_training_attendance(
 id uuid primary key,register_id uuid not null references public.crm_training_attendee_registers,
 sequence integer not null,previous_id uuid references public.crm_training_attendance,
 attendees_snapshot jsonb not null,entries jsonb not null,request jsonb not null,reason text not null,
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(register_id,sequence)
);
create index training_attendance_previous on public.crm_training_attendance(previous_id);
create index training_attendance_actor on public.crm_training_attendance(actor_id);
alter table public.crm_training_attendance enable row level security;
revoke all on public.crm_training_attendance from public,anon,authenticated;
grant select on public.crm_training_attendance to authenticated;
create policy training_attendance_coordinator_read on public.crm_training_attendance for select to authenticated using(exists(select 1 from public.crm_training_attendee_registers r where r.id=register_id and portal_private.training_attendee_access(r.source_kind,r.source_id)));
create function public.facilitated_training_sessions() returns setof jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not exists(select 1 from public.profiles u where u.id=auth.uid() and u.active and u.role in ('admin','team')) then raise exception 'Active staff access required';end if;
 return query select jsonb_build_object('register_id',r.id,'source_kind',r.source_kind,'source_id',r.source_id,'source_version',r.source_version,
 'training_type',case when r.source_kind='Project' then d.training_type else 'Internal' end,
 'title',case when r.source_kind='Project' then t.details->>'title' else i.title end,
 'objective',case when r.source_kind='Project' then t.details->>'objective' else i.objective end,
 'project_id',d.project_id,'facilitator_id',coalesce(d.facilitator_id,i.facilitator_id),
 'attendees',(select coalesce(jsonb_agg(jsonb_strip_nulls(jsonb_build_object('kind',a->>'kind','profile_id',a->>'profile_id','name',a->>'name','phone',a->>'phone','email',a->>'email')) order by ordinal),'[]') from jsonb_array_elements(r.attendees) with ordinality v(a,ordinal)),
 'attendance_id',h.id,'attendance_revision',h.sequence,'entries',coalesce(h.entries,'[]'))
 from public.crm_training_attendee_registers r
 left join public.crm_training_session_definitions d on d.id=r.project_definition_id
 left join public.crm_project_training t on t.id=d.training_id
 left join public.crm_internal_training i on i.id=r.internal_training_id
 left join lateral(select a.* from public.crm_training_attendance a where a.register_id=r.id order by a.sequence desc limit 1) h on true
 where portal_private.training_facilitator_access(r.id) order by r.created_at desc,r.id;
end$$;
create function public.save_training_attendance(p_id uuid,p_register uuid,p_previous uuid,p_entries jsonb,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare r public.crm_training_attendee_registers;d public.crm_training_session_definitions;old public.crm_training_attendance;retry public.crm_training_attendance;
 req jsonb;values_saved jsonb:='[]';e jsonb;ordinal integer:=0;checkin timestamptz;checkout timestamptz;
begin
 if not portal_private.training_facilitator_access(p_register) then raise exception 'Current selected facilitator or administrator access required';end if;
 select * into r from public.crm_training_attendee_registers where id=p_register;
 if r.source_kind='Project' then
  select * into d from public.crm_training_session_definitions where id=r.project_definition_id;
  perform 1 from public.projects where id=d.project_id for update;
  perform 1 from public.crm_project_training where id=d.training_id for update;
  -- Keep the actual facilitator assignment stable through this write.
  if not exists(select 1 from public.profiles where id=auth.uid() and role='admin') then perform 1 from public.project_assignments where project_id=d.project_id and technician_id=auth.uid() for share;end if;
 else perform 1 from public.crm_internal_training where id=r.internal_training_id for update;end if;
 perform 1 from public.profiles where id=auth.uid() for share;
 if not portal_private.training_facilitator_access(p_register) then raise exception 'Current selected facilitator or administrator access required';end if;
 if p_id is null or p_entries is null or jsonb_typeof(p_entries)<>'array' or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit attendance identity/entries/manual reason required';end if;
 req:=jsonb_build_object('register_id',p_register,'previous_id',p_previous,'entries',p_entries,'reason',trim(p_reason));
 select * into retry from public.crm_training_attendance where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=req then return retry.id;end if;
  raise exception 'Attendance identity records a different request';
 end if;
 select * into old from public.crm_training_attendance where register_id=r.id order by sequence desc limit 1;
 if old.id is distinct from p_previous then raise exception 'Attendance changed; refresh latest revision';end if;
 if jsonb_array_length(p_entries)<>jsonb_array_length(r.attendees) then raise exception 'Provide exactly one entry per registered attendee';end if;
 for e in select value from jsonb_array_elements(p_entries) loop
  if jsonb_typeof(e)<>'object' then raise exception 'Attendance entry must be an object';end if;
  if (select array_agg(k order by k) from jsonb_object_keys(e) k) is distinct from array['check_in','check_out','ordinal']::text[] or jsonb_typeof(e->'ordinal')<>'number' or (e->>'ordinal')::numeric<>ordinal then raise exception 'Exact ordered attendee ordinal and check-in/out fields required';end if;
  checkin:=null;checkout:=null;
  if e->'check_in'='null'::jsonb and e->'check_out'='null'::jsonb then null;
  else
   if jsonb_typeof(e->'check_in')<>'string' or jsonb_typeof(e->'check_out')<>'string' or length(e->>'check_in')>40 or length(e->>'check_out')>40 or (e->>'check_in') !~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?(Z|[+-]\d{2}:\d{2})$' or (e->>'check_out') !~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?(Z|[+-]\d{2}:\d{2})$' then raise exception 'Enter both actual times with explicit timezone, or leave both unrecorded';end if;
   checkin:=(e->>'check_in')::timestamptz;checkout:=(e->>'check_out')::timestamptz;
   if not isfinite(checkin) or not isfinite(checkout) or checkout<=checkin or checkout>now() then raise exception 'Actual checkout must follow check-in and cannot be future';end if;
  end if;
  values_saved:=values_saved||jsonb_build_array(jsonb_build_object('ordinal',ordinal,'check_in',checkin,'check_out',checkout));ordinal:=ordinal+1;
 end loop;
 insert into public.crm_training_attendance(id,register_id,sequence,previous_id,attendees_snapshot,entries,request,reason,actor_id)
 values(p_id,r.id,coalesce(old.sequence,0)+1,old.id,r.attendees,values_saved,req,trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.facilitated_training_sessions(),public.save_training_attendance(uuid,uuid,uuid,jsonb,text) from public,anon;
grant execute on function public.facilitated_training_sessions(),public.save_training_attendance(uuid,uuid,uuid,jsonb,text) to authenticated;
notify pgrst,'reload schema';
commit;
