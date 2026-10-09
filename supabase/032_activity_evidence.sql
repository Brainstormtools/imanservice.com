begin;
alter table public.work_activities add column evidence_files uuid[] not null default '{}' check(cardinality(evidence_files)<=10);
create table public.work_activity_files(
 id uuid primary key default gen_random_uuid(),activity_id uuid not null references public.work_activities,
 user_id uuid not null references public.profiles,path text not null unique,name text not null check(length(name) between 1 and 160),
 size bigint not null check(size between 1 and 10485760),mime text not null,created_at timestamptz not null default now(),
 removed_at timestamptz,removed_by uuid references public.profiles,removal_note text not null default '' check(length(removal_note)<=2000),
 check((removed_at is null)=(removed_by is null))
);
create index work_activity_files_activity on public.work_activity_files(activity_id,created_at);
create function portal_private.activity_evidence_read(p_activity uuid) returns boolean language sql stable security definer set search_path='' as $$select public.is_staff() and exists(select 1 from public.work_activities a where a.id=p_activity and (portal_private.activity_reviewer(a) or (a.user_id=auth.uid() and portal_private.activity_worker_authorized(a) and portal_private.activity_scope(a.link_kind,a.project_id,a.task_id,a.ticket_id,a.deal_id))));$$;
create function portal_private.activity_evidence_upload(p_activity text) returns boolean language sql stable security definer set search_path='' as $$select public.is_staff() and exists(select 1 from public.work_activities a where a.id::text=p_activity and a.user_id=auth.uid() and a.status in ('Draft','Rejected') and portal_private.activity_scope(a.link_kind,a.project_id,a.task_id,a.ticket_id,a.deal_id) and portal_private.activity_worker_authorized(a) and not portal_private.hr_locked(a.user_id,(a.actual_start at time zone 'Asia/Karachi')::date) and cardinality(a.evidence_files)<10 and (select count(*) from public.work_activity_files where activity_id=a.id)<20 and (a.project_id is null or exists(select 1 from public.projects p where p.id=a.project_id and p.status<>'Completed' and not exists(select 1 from public.crm_handovers h where h.project_id=p.id and h.status in ('Awaiting signatures','Signed','Closed')))));$$;
alter table public.work_activity_files enable row level security;
revoke all on public.work_activity_files from public,anon,authenticated;
grant select on public.work_activity_files to authenticated;
create policy activity_files_read on public.work_activity_files for select to authenticated using(portal_private.activity_evidence_read(activity_id));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('activity-evidence','activity-evidence',false,10485760,array['application/pdf','image/png','image/jpeg','image/webp','text/plain','text/csv','application/zip','application/vnd.openxmlformats-officedocument.wordprocessingml.document','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']);
create policy activity_evidence_object_upload on storage.objects for insert to authenticated with check(bucket_id='activity-evidence' and owner_id=auth.uid()::text and name ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|png|jpg|jpeg|webp|txt|csv|zip|docx|xlsx)$' and portal_private.activity_evidence_upload(split_part(name,'/',1)));
create function portal_private.activity_evidence_object_read(p_path text,p_owner text) returns boolean language sql stable security definer set search_path='' as $$select public.is_staff() and (exists(select 1 from public.work_activity_files f where f.path=p_path and portal_private.activity_evidence_read(f.activity_id)) or (p_owner=auth.uid()::text and portal_private.activity_evidence_upload(split_part(p_path,'/',1))));$$;
create function portal_private.activity_evidence_orphan(p_path text) returns boolean language sql stable security definer set search_path='' as $$select not exists(select 1 from public.work_activity_files where path=p_path);$$;
create policy activity_evidence_object_read on storage.objects for select to authenticated using(bucket_id='activity-evidence' and portal_private.activity_evidence_object_read(name,owner_id));
create policy activity_evidence_object_cleanup on storage.objects for delete to authenticated using(bucket_id='activity-evidence' and public.is_staff() and owner_id=auth.uid()::text and portal_private.activity_evidence_orphan(name));
-- No UPDATE policy: registered bytes cannot be replaced or deleted by the uploader.
create function public.attach_activity_evidence(p_activity uuid,p_version integer,p_path text,p_name text) returns jsonb language plpgsql security definer set search_path='' as $$declare a public.work_activities;f public.work_activity_files;o storage.objects;ext text;begin
 select * into a from public.work_activities where id=p_activity;
 if a.id is null or a.user_id<>auth.uid() or not portal_private.activity_evidence_read(a.id) then raise exception 'Own assigned activity evidence required';end if;
 perform portal_private.activity_open(a.project_id);perform pg_advisory_xact_lock(hashtextextended(a.user_id::text,24));select * into a from public.work_activities where id=p_activity for update;
 select * into f from public.work_activity_files where path=p_path;
 if f.id is not null then if f.activity_id<>a.id or f.user_id<>auth.uid() or f.name is distinct from p_name or f.removed_at is not null then raise exception 'Existing evidence differs or was removed';end if;return jsonb_build_object('file_id',f.id,'activity_version',a.version);end if;
 if a.version is distinct from p_version or not portal_private.activity_evidence_upload(a.id::text) or p_path is null or p_path !~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|png|jpg|jpeg|webp|txt|csv|zip|docx|xlsx)$' or split_part(p_path,'/',1)<>a.id::text or p_name is null or length(trim(p_name)) not between 1 and 160 or p_name ~ '[[:cntrl:]]' or p_name ~ '[/\\]' then raise exception 'Current unlocked draft and safe evidence filename required';end if;
 select * into o from storage.objects where bucket_id='activity-evidence' and name=p_path and owner_id=auth.uid()::text;
 if o.id is null or coalesce(o.metadata->>'size','') !~ '^[0-9]+$' or (o.metadata->>'size')::numeric not between 1 and 10485760 then raise exception 'Upload a valid owned object before attaching evidence';end if;
 ext:=lower(substring(p_path from '\.([^.]+)$'));
 if ext is distinct from lower(substring(p_name from '\.([^.]+)$')) or (o.metadata->>'mimetype') is distinct from (case ext when 'pdf' then 'application/pdf' when 'png' then 'image/png' when 'jpg' then 'image/jpeg' when 'jpeg' then 'image/jpeg' when 'webp' then 'image/webp' when 'txt' then 'text/plain' when 'csv' then 'text/csv' when 'zip' then 'application/zip' when 'docx' then 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' when 'xlsx' then 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' end) then raise exception 'Evidence extension and stored content type must agree';end if;
 insert into public.work_activity_files(activity_id,user_id,path,name,size,mime) values(a.id,auth.uid(),p_path,trim(p_name),(o.metadata->>'size')::bigint,o.metadata->>'mimetype') returning * into f;
 update public.work_activities set evidence_files=array_append(evidence_files,f.id),version=version+1 where id=a.id returning * into a;
 insert into public.work_activity_history(activity_id,actor_id,action,note,snapshot) values(a.id,auth.uid(),'Evidence attached','Private evidence recorded',to_jsonb(a)||jsonb_build_object('file_id',f.id));
 return jsonb_build_object('file_id',f.id,'activity_version',a.version);
end$$;
create function public.remove_activity_evidence(p_file uuid,p_version integer,p_note text) returns void language plpgsql security definer set search_path='' as $$declare a public.work_activities;f public.work_activity_files;begin
 select * into f from public.work_activity_files where id=p_file;select * into a from public.work_activities where id=f.activity_id;
 if f.id is null or a.user_id<>auth.uid() or not portal_private.activity_evidence_read(a.id) or length(trim(coalesce(p_note,''))) not between 3 and 2000 then raise exception 'Own assigned evidence and removal reason required';end if;
 perform portal_private.activity_open(a.project_id);perform pg_advisory_xact_lock(hashtextextended(a.user_id::text,24));select * into a from public.work_activities where id=a.id for update;select * into f from public.work_activity_files where id=p_file for update;
 if a.version is distinct from p_version or a.status not in ('Draft','Rejected') or f.removed_at is not null or portal_private.hr_locked(a.user_id,(a.actual_start at time zone 'Asia/Karachi')::date) then raise exception 'Current unlocked draft required';end if;
 update public.work_activity_files set removed_at=now(),removed_by=auth.uid(),removal_note=trim(p_note) where id=f.id;
 update public.work_activities set evidence_files=array_remove(evidence_files,f.id),version=version+1 where id=a.id returning * into a;
 insert into public.work_activity_history(activity_id,actor_id,action,note,snapshot) values(a.id,auth.uid(),'Evidence removed','Private evidence retained in history',to_jsonb(a)||jsonb_build_object('file_id',f.id));
end$$;
-- Submission/review validates registered object references; revisions preserve exact file IDs.
alter function public.work_activity_action(uuid,integer,text,text) rename to work_activity_action_recorded;
create function public.work_activity_action(p_id uuid,p_version integer,p_action text,p_note text default '') returns void language plpgsql security definer set search_path='' as $$declare a public.work_activities;begin
 select * into a from public.work_activities where id=p_id;
 if a.id is null or not portal_private.activity_read(a) then raise exception 'Activity unavailable';end if;
 perform portal_private.activity_open(a.project_id);perform pg_advisory_xact_lock(hashtextextended(a.user_id::text,24));select * into a from public.work_activities where id=p_id for update;
 if p_action in ('Submit','Approve') and exists(select 1 from unnest(a.evidence_files) file_id left join public.work_activity_files f on f.id=file_id left join storage.objects o on o.bucket_id='activity-evidence' and o.name=f.path where f.id is null or f.activity_id<>a.id or f.user_id<>a.user_id or f.removed_at is not null or o.id is null or o.owner_id<>a.user_id::text or (o.metadata->>'size') is distinct from f.size::text or (o.metadata->>'mimetype') is distinct from f.mime) then raise exception 'Resolve missing or changed evidence before submission/review';end if;
 perform public.work_activity_action_recorded(p_id,p_version,p_action,p_note);
end$$;
revoke all on function public.work_activity_action_recorded(uuid,integer,text,text) from public,anon,authenticated;
revoke all on function public.work_activity_action(uuid,integer,text,text),public.attach_activity_evidence(uuid,integer,text,text),public.remove_activity_evidence(uuid,integer,text) from public,anon;
grant execute on function public.work_activity_action(uuid,integer,text,text),public.attach_activity_evidence(uuid,integer,text,text),public.remove_activity_evidence(uuid,integer,text) to authenticated;
revoke all on function portal_private.activity_evidence_read(uuid),portal_private.activity_evidence_upload(text),portal_private.activity_evidence_object_read(text,text),portal_private.activity_evidence_orphan(text) from public,anon;
grant execute on function portal_private.activity_evidence_read(uuid),portal_private.activity_evidence_upload(text),portal_private.activity_evidence_object_read(text,text),portal_private.activity_evidence_orphan(text) to authenticated;
commit;
