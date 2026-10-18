begin;
create table public.crm_training_evidence(
 id uuid primary key,attendance_id uuid not null references public.crm_training_attendance,register_id uuid not null references public.crm_training_attendee_registers,
 path text not null unique,name text not null,size bigint not null check(size between 1 and 10485760),mime text not null,
 kind text not null check(kind in ('Photo','Signed attendance sheet')),reason text not null,request jsonb not null,
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now()
);
create index training_evidence_attendance on public.crm_training_evidence(attendance_id);
create index training_evidence_register on public.crm_training_evidence(register_id);
create index training_evidence_actor on public.crm_training_evidence(actor_id);
create function portal_private.training_evidence_current(p_attendance text) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.crm_training_attendance a where a.id::text=p_attendance and portal_private.training_facilitator_access(a.register_id) and not exists(select 1 from public.crm_training_attendance n where n.register_id=a.register_id and n.sequence>a.sequence));
$$;
create function portal_private.training_evidence_read(p_attendance uuid) returns boolean language sql stable security definer set search_path='' as $$
 select portal_private.training_evidence_current(p_attendance::text) or exists(select 1 from public.crm_training_attendance a join public.crm_training_attendee_registers r on r.id=a.register_id where a.id=p_attendance and portal_private.training_attendee_access(r.source_kind,r.source_id));
$$;
alter table public.crm_training_evidence enable row level security;
revoke all on public.crm_training_evidence from public,anon,authenticated;
grant select on public.crm_training_evidence to authenticated;
create policy training_evidence_metadata_read on public.crm_training_evidence for select to authenticated using(portal_private.training_evidence_read(attendance_id));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('training-evidence','training-evidence',false,10485760,array['application/pdf','image/png','image/jpeg','image/webp']);
create function portal_private.training_evidence_object_read(p_path text,p_owner text) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.crm_training_evidence e where e.path=p_path and portal_private.training_evidence_read(e.attendance_id)) or (p_owner=auth.uid()::text and exists(select 1 from public.profiles p where p.id=auth.uid() and p.active and p.role in ('admin','team')) and (portal_private.training_evidence_current(split_part(p_path,'/',1)) or not exists(select 1 from public.crm_training_evidence e where e.path=p_path)));
$$;
create function portal_private.training_evidence_orphan(p_path text) returns boolean language plpgsql security definer set search_path='' as $$
begin
 perform pg_advisory_xact_lock(hashtextextended('training-proof:'||p_path,0));
 return not exists(select 1 from public.crm_training_evidence where path=p_path);
end$$;
create policy training_evidence_upload on storage.objects for insert to authenticated with check(bucket_id='training-evidence' and owner_id=auth.uid()::text and name ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|png|jpg|jpeg|webp)$' and portal_private.training_evidence_current(split_part(name,'/',1)));
create policy training_evidence_download on storage.objects for select to authenticated using(bucket_id='training-evidence' and portal_private.training_evidence_object_read(name,owner_id));
-- Only unregistered owned uploads may be cleaned up. Registered proof is immutable.
create policy training_evidence_orphan_cleanup on storage.objects for delete to authenticated using(bucket_id='training-evidence' and owner_id=auth.uid()::text and exists(select 1 from public.profiles p where p.id=auth.uid() and p.active and p.role in ('admin','team')) and portal_private.training_evidence_orphan(name));
-- No UPDATE policy, no linked-file DELETE policy, no public bucket or public URL.
create function public.attach_training_evidence(p_id uuid,p_attendance uuid,p_path text,p_name text,p_kind text,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare a public.crm_training_attendance;r public.crm_training_attendee_registers;d public.crm_training_session_definitions;old public.crm_training_evidence;o storage.objects;req jsonb;ext text;mime text;
begin
 if not portal_private.training_evidence_current(p_attendance::text) then raise exception 'Current selected facilitator or administrator attendance receipt required';end if;
 select * into a from public.crm_training_attendance where id=p_attendance;
 select * into r from public.crm_training_attendee_registers where id=a.register_id;
 if r.source_kind='Project' then
  select * into d from public.crm_training_session_definitions where id=r.project_definition_id;
  perform 1 from public.projects where id=d.project_id for update;
  perform 1 from public.crm_project_training where id=d.training_id for update;
  if not exists(select 1 from public.profiles where id=auth.uid() and role='admin') then perform 1 from public.project_assignments where project_id=d.project_id and technician_id=auth.uid() for share;end if;
 else perform 1 from public.crm_internal_training where id=r.internal_training_id for update;end if;
 perform 1 from public.profiles where id=auth.uid() for share;
 if not portal_private.training_evidence_current(p_attendance::text) then raise exception 'Current selected facilitator or administrator attendance receipt required';end if;
 if p_id is null or p_path is null or p_path !~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|png|jpg|jpeg|webp)$' or split_part(p_path,'/',1)<>p_attendance::text or split_part(p_path,'/',2) not like p_id::text||'.%' or p_name is null or length(trim(p_name)) not between 1 and 160 or p_name ~ '[[:cntrl:]]' or p_name ~ '[/\\]' or p_kind is null or p_kind not in ('Photo','Signed attendance sheet') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit evidence identity, safe actual filename/path, type and manual reason required';end if;
 perform pg_advisory_xact_lock(hashtextextended('training-proof:'||p_path,0));
 req:=jsonb_build_object('attendance_id',p_attendance,'path',p_path,'name',trim(p_name),'kind',p_kind,'reason',trim(p_reason));
 select * into old from public.crm_training_evidence where id=p_id;
 if old.id is not null then
  if old.actor_id=auth.uid() and old.request=req then return old.id;end if;
  raise exception 'Evidence identity records a different upload request';
 end if;
 select * into o from storage.objects where bucket_id='training-evidence' and name=p_path and owner_id=auth.uid()::text for update;
 if o.id is null or coalesce(o.metadata->>'size','') !~ '^[0-9]+$' or (o.metadata->>'size')::numeric not between 1 and 10485760 then raise exception 'Upload a valid owned object before attaching evidence';end if;
 ext:=lower(substring(p_path from '\.([^.]+)$'));mime:=case ext when 'pdf' then 'application/pdf' when 'png' then 'image/png' when 'jpg' then 'image/jpeg' when 'jpeg' then 'image/jpeg' when 'webp' then 'image/webp' end;
 if ext is distinct from lower(substring(trim(p_name) from '\.([^.]+)$')) or o.metadata->>'mimetype' is distinct from mime or p_kind='Photo' and ext='pdf' then raise exception 'Actual filename, evidence type and stored content type must agree';end if;
 insert into public.crm_training_evidence(id,attendance_id,register_id,path,name,size,mime,kind,reason,request,actor_id)
 values(p_id,a.id,r.id,p_path,trim(p_name),(o.metadata->>'size')::bigint,mime,p_kind,trim(p_reason),req,auth.uid());
 return p_id;
end$$;
revoke all on function public.attach_training_evidence(uuid,uuid,text,text,text,text) from public,anon;
grant execute on function public.attach_training_evidence(uuid,uuid,text,text,text,text) to authenticated;
revoke all on function portal_private.training_evidence_current(text),portal_private.training_evidence_read(uuid),portal_private.training_evidence_object_read(text,text),portal_private.training_evidence_orphan(text) from public,anon;
grant execute on function portal_private.training_evidence_current(text),portal_private.training_evidence_read(uuid),portal_private.training_evidence_object_read(text,text),portal_private.training_evidence_orphan(text) to authenticated;
notify pgrst,'reload schema';
commit;
