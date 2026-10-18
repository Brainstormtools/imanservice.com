begin;
create function portal_private.training_attendee_access(p_kind text,p_source uuid) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and case p_kind
 when 'Project' then exists(select 1 from public.crm_training_session_definitions d where d.id=p_source and portal_private.execution_manager(d.project_id))
 when 'Internal' then exists(select 1 from public.crm_internal_training t where t.id=p_source and (portal_private.hr_access() or (t.created_by=auth.uid() and portal_private.crm_permission('team.own'))))
 else false end;
$$;
revoke all on function portal_private.training_attendee_access(text,uuid) from public,anon;
grant execute on function portal_private.training_attendee_access(text,uuid) to authenticated;
create table public.crm_training_attendee_registers(
 id uuid primary key,source_kind text not null check(source_kind in ('Project','Internal')),
 project_definition_id uuid references public.crm_training_session_definitions,internal_training_id uuid references public.crm_internal_training,
 source_id uuid generated always as (coalesce(project_definition_id,internal_training_id)) stored,
 source_version integer not null,sequence integer not null,previous_id uuid references public.crm_training_attendee_registers,
 source_snapshot jsonb not null,attendees jsonb not null,request jsonb not null,reason text not null,
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),
 check((source_kind='Project' and project_definition_id is not null and internal_training_id is null) or (source_kind='Internal' and internal_training_id is not null and project_definition_id is null)),
 unique(source_kind,source_id,sequence)
);
create index attendee_register_project on public.crm_training_attendee_registers(project_definition_id);
create index attendee_register_internal on public.crm_training_attendee_registers(internal_training_id);
create index attendee_register_previous on public.crm_training_attendee_registers(previous_id);
create index attendee_register_actor on public.crm_training_attendee_registers(actor_id);
create table public.crm_training_attendee_accounts(
 register_id uuid not null references public.crm_training_attendee_registers,profile_id uuid not null references public.profiles,
 primary key(register_id,profile_id)
);
create index attendee_account_profile on public.crm_training_attendee_accounts(profile_id);
alter table public.crm_training_attendee_registers enable row level security;
alter table public.crm_training_attendee_accounts enable row level security;
revoke all on public.crm_training_attendee_registers,public.crm_training_attendee_accounts from public,anon,authenticated;
grant select on public.crm_training_attendee_registers,public.crm_training_attendee_accounts to authenticated;
create policy attendee_register_read on public.crm_training_attendee_registers for select to authenticated using(portal_private.training_attendee_access(source_kind,source_id));
create policy attendee_account_read on public.crm_training_attendee_accounts for select to authenticated using(exists(select 1 from public.crm_training_attendee_registers r where r.id=register_id and portal_private.training_attendee_access(r.source_kind,r.source_id)));
create function public.training_attendee_candidates(p_kind text,p_source uuid) returns table(id uuid,name text) language plpgsql stable security definer set search_path='' as $$
begin
 if not portal_private.training_attendee_access(p_kind,p_source) then raise exception 'Training coordinator access required';end if;
 return query select u.id,u.name from public.profiles u where u.active and u.role in ('admin','team') and case p_kind when 'Internal' then portal_private.internal_training_facilitator(u.id) else exists(select 1 from public.project_assignments a join public.crm_training_session_definitions d on d.project_id=a.project_id where d.id=p_source and a.technician_id=u.id) end order by u.name,u.id;
end$$;
create function public.save_training_attendees(p_id uuid,p_kind text,p_source uuid,p_version integer,p_previous uuid,p_attendees jsonb,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare d public.crm_training_session_definitions;t public.crm_project_training;i public.crm_internal_training;old public.crm_training_attendee_registers;retry public.crm_training_attendee_registers;
 req jsonb;snapshot jsonb;people jsonb:='[]';a jsonb;person jsonb;uid uuid;seen uuid[]:='{}';external_seen jsonb:='[]';
begin
 if not portal_private.training_attendee_access(p_kind,p_source) then raise exception 'Training coordinator access required';end if;
 if p_kind='Project' then
  select * into d from public.crm_training_session_definitions where id=p_source;
  perform 1 from public.projects where id=d.project_id for update;
  select * into t from public.crm_project_training where id=d.training_id for update;
  snapshot:=to_jsonb(d);
 else
  select * into i from public.crm_internal_training where id=p_source for update;
  snapshot:=to_jsonb(i);
 end if;
 -- Recheck fresh authority after waiting for the source lock.
 if not portal_private.training_attendee_access(p_kind,p_source) then raise exception 'Training coordinator access required';end if;
 if p_id is null or p_version is null or p_attendees is null or jsonb_typeof(p_attendees)<>'array' or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit register identity/version/attendee array/manual reason required';end if;
 if jsonb_array_length(p_attendees)>100 then raise exception 'At most 100 attendees per revision';end if;
 req:=jsonb_build_object('kind',p_kind,'source',p_source,'version',p_version,'previous',p_previous,'attendees',p_attendees,'reason',trim(p_reason));
 select * into retry from public.crm_training_attendee_registers where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=req then return retry.id;end if;
  raise exception 'Register identity records a different request';
 end if;
 if p_kind='Project' then
  if d.training_version is distinct from p_version or t.version is distinct from p_version or t.details->>'status' is distinct from 'Draft' or exists(select 1 from public.crm_training_session_definitions n where n.training_id=d.training_id and n.sequence>d.sequence) then raise exception 'Latest definition and exact current Draft training version required';end if;
 else
  if i.version is distinct from p_version or i.status<>'Draft' then raise exception 'Exact current Internal Draft version required';end if;
 end if;
 select * into old from public.crm_training_attendee_registers where source_kind=p_kind and source_id=p_source order by sequence desc limit 1;
 if old.id is distinct from p_previous then raise exception 'Attendee register changed; refresh latest revision';end if;
 for a in select value from jsonb_array_elements(p_attendees) loop
  if jsonb_typeof(a)<>'object' then raise exception 'Attendee must be an explicit object';end if;
  if a->>'kind'='Internal' then
   if (select array_agg(k order by k) from jsonb_object_keys(a) k) is distinct from array['kind','profile_id']::text[] or jsonb_typeof(a->'profile_id')<>'string' then raise exception 'Internal attendee requires only kind and actual profile ID';end if;
   uid:=(a->>'profile_id')::uuid;
   if uid=any(seen) then raise exception 'Duplicate internal attendee';end if;
   if p_kind='Project' then
    select jsonb_build_object('kind','Internal','profile_id',u.id,'name',u.name,'role',u.role) into person from public.profiles u join public.project_assignments pa on pa.technician_id=u.id and pa.project_id=d.project_id where u.id=uid and u.active and u.role in ('admin','team') for share of u,pa;
   else
    select jsonb_build_object('kind','Internal','profile_id',u.id,'name',u.name,'role',u.role) into person from public.profiles u where u.id=uid and u.active and u.role in ('admin','team') and portal_private.internal_training_facilitator(u.id) for share;
   end if;
   if person is null then raise exception 'Choose an eligible active internal account';end if;
   seen:=array_append(seen,uid);
  elsif a->>'kind'='External' then
   if (select array_agg(k order by k) from jsonb_object_keys(a) k) is distinct from array['email','kind','name','phone']::text[] or jsonb_typeof(a->'name')<>'string' or jsonb_typeof(a->'phone')<>'string' or jsonb_typeof(a->'email')<>'string' or length(trim(coalesce(a->>'name',''))) not between 1 and 160 or length(trim(coalesce(a->>'phone',''))) not between 1 and 80 or length(trim(coalesce(a->>'email',''))) not between 3 and 254 or trim(a->>'email') !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then raise exception 'External attendee requires actual name, phone and valid email';end if;
   person:=jsonb_build_object('kind','External','name',trim(a->>'name'),'phone',trim(a->>'phone'),'email',trim(a->>'email'));
   if external_seen @> jsonb_build_array(person) then raise exception 'Duplicate external attendee';end if;
   external_seen:=external_seen||jsonb_build_array(person);
  else raise exception 'Choose Internal or External attendee';end if;
  people:=people||jsonb_build_array(person);
 end loop;
 insert into public.crm_training_attendee_registers(id,source_kind,project_definition_id,internal_training_id,source_version,sequence,previous_id,source_snapshot,attendees,request,reason,actor_id)
 values(p_id,p_kind,case when p_kind='Project' then p_source end,case when p_kind='Internal' then p_source end,p_version,coalesce(old.sequence,0)+1,old.id,snapshot,people,req,trim(p_reason),auth.uid());
 insert into public.crm_training_attendee_accounts(register_id,profile_id) select p_id,unnest(seen);
 return p_id;
end$$;
revoke all on function public.training_attendee_candidates(text,uuid),public.save_training_attendees(uuid,text,uuid,integer,uuid,jsonb,text) from public,anon;
grant execute on function public.training_attendee_candidates(text,uuid),public.save_training_attendees(uuid,text,uuid,integer,uuid,jsonb,text) to authenticated;
notify pgrst,'reload schema';
commit;
