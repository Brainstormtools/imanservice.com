-- APPLIED via native connected migration 20261027194157 local UTC scaffold; CLI binary unavailable. Private unreviewed supporting files.
create table portal_private.crm_criteria_files(id uuid primary key,observation_id uuid not null references portal_private.crm_criteria_observations,path text not null unique,name text not null,size bigint not null check(size between 1 and 10485760),mime text not null,reason text not null,source jsonb not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),payload jsonb not null);
create index crm_criteria_files_observation on portal_private.crm_criteria_files(observation_id);
create index crm_criteria_files_actor on portal_private.crm_criteria_files(actor_id);
alter table portal_private.crm_criteria_files enable row level security;
revoke all on portal_private.crm_criteria_files from public,anon,authenticated,service_role;
create trigger crm_criteria_files_immutable before update or delete on portal_private.crm_criteria_files for each row execute function portal_private.lead_api_evidence_immutable();
create function portal_private.criteria_file_current(p_observation uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from portal_private.crm_criteria_observations o join public.projects p on p.id=o.project_id where o.id=p_observation and portal_private.project_criteria_access(p.id) and p.status<>'Completed' and o.definition_id=(select id from portal_private.crm_project_criteria_versions where project_id=p.id order by revision desc limit 1) and o.review_id=(select id from portal_private.crm_project_criteria_reviews where definition_id=o.definition_id order by sequence desc limit 1) and exists(select 1 from portal_private.crm_project_criteria_reviews r where r.id=o.review_id and r.decision='Approved') and o.sequence=(select max(sequence) from portal_private.crm_criteria_observations where definition_id=o.definition_id and position=o.position));
$$;
create function portal_private.criteria_file_upload(p_path text) returns boolean language sql stable security definer set search_path='' as $$
 select p_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|png|jpg|jpeg|webp)$' and exists(select 1 from portal_private.crm_criteria_observations o where o.id::text=split_part(p_path,'/',1) and portal_private.criteria_file_current(o.id) and (select count(*) from portal_private.crm_criteria_files where observation_id=o.id)<20);
$$;
create function portal_private.criteria_file_read(p_path text,p_owner text) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from portal_private.crm_criteria_observations o where o.id::text=split_part(p_path,'/',1) and portal_private.project_criteria_access(o.project_id)) and (p_owner=auth.uid()::text or exists(select 1 from portal_private.crm_criteria_files where path=p_path));
$$;
create function portal_private.criteria_file_orphan(p_path text) returns boolean language plpgsql security definer set search_path='' as $$begin perform pg_advisory_xact_lock(hashtextextended('criteria-file:'||p_path,0));return not exists(select 1 from portal_private.crm_criteria_files where path=p_path);end$$;
revoke all on function portal_private.criteria_file_current(uuid),portal_private.criteria_file_upload(text),portal_private.criteria_file_read(text,text),portal_private.criteria_file_orphan(text) from public,anon,authenticated,service_role;
grant execute on function portal_private.criteria_file_upload(text),portal_private.criteria_file_read(text,text),portal_private.criteria_file_orphan(text) to authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('crm-criteria-files','crm-criteria-files',false,10485760,array['application/pdf','image/png','image/jpeg','image/webp']);
create policy crm_criteria_files_upload on storage.objects for insert to authenticated with check(bucket_id='crm-criteria-files' and owner_id=auth.uid()::text and portal_private.criteria_file_upload(name));
create policy crm_criteria_files_read on storage.objects for select to authenticated using(bucket_id='crm-criteria-files' and portal_private.criteria_file_read(name,owner_id));
create policy crm_criteria_files_cleanup on storage.objects for delete to authenticated using(bucket_id='crm-criteria-files' and owner_id=auth.uid()::text and portal_private.criteria_file_orphan(name));
create policy crm_criteria_files_read_boundary on storage.objects as restrictive for select to authenticated using(bucket_id<>'crm-criteria-files' or portal_private.criteria_file_read(name,owner_id));
create policy crm_criteria_files_upload_boundary on storage.objects as restrictive for insert to authenticated with check(bucket_id<>'crm-criteria-files' or owner_id=auth.uid()::text and portal_private.criteria_file_upload(name));
create policy crm_criteria_files_cleanup_boundary on storage.objects as restrictive for delete to authenticated using(bucket_id<>'crm-criteria-files' or owner_id=auth.uid()::text and portal_private.criteria_file_orphan(name));
create policy crm_criteria_files_no_overwrite on storage.objects as restrictive for update to authenticated using(bucket_id<>'crm-criteria-files') with check(bucket_id<>'crm-criteria-files');
create policy crm_criteria_files_no_anon on storage.objects as restrictive for all to anon using(bucket_id<>'crm-criteria-files') with check(bucket_id<>'crm-criteria-files');
create function portal_private.protect_criteria_file_object() returns trigger language plpgsql security definer set search_path='' as $$begin
 if old.bucket_id='crm-criteria-files' then perform pg_advisory_xact_lock(hashtextextended('criteria-file:'||old.name,0));if exists(select 1 from portal_private.crm_criteria_files where path=old.name) then raise exception 'Registered observation file bytes and path are retained';end if;end if;
 if tg_op='DELETE' then return old;end if;return new;
end$$;
revoke all on function portal_private.protect_criteria_file_object() from public,anon,authenticated,service_role;
create trigger crm_criteria_file_object_retention before update or delete on storage.objects for each row execute function portal_private.protect_criteria_file_object();
create function public.criteria_file_context(p_observation uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$declare o portal_private.crm_criteria_observations;files jsonb;begin
 select * into o from portal_private.crm_criteria_observations where id=p_observation;
 if not found or not portal_private.project_criteria_access(o.project_id) then raise exception 'Current actual Admin or assigned PM required';end if;
 select coalesce(jsonb_agg((to_jsonb(f)-'payload')||jsonb_build_object('stored_metadata_matches',s.id is not null and s.owner_id=f.actor_id::text and s.metadata->>'size'=f.size::text and s.metadata->>'mimetype'=f.mime) order by f.created_at,f.id),'[]') into files from portal_private.crm_criteria_files f left join storage.objects s on s.bucket_id='crm-criteria-files' and s.name=f.path where f.observation_id=p_observation;
 return jsonb_build_object('observation',to_jsonb(o)-'payload','can_attach',portal_private.criteria_file_current(p_observation),'files',files);
end$$;
create function public.attach_criteria_file(p_id uuid,p_observation uuid,p_source jsonb,p_path text,p_name text,p_reason text,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$declare o portal_private.crm_criteria_observations;f portal_private.crm_criteria_files;s storage.objects;payload jsonb;ext text;mime text;begin
 perform 1 from public.profiles where id=auth.uid() and active and role in ('admin','team') for share;if not found then raise exception 'Current criteria file authority required';end if;
 perform 1 from public.crm_memberships where user_id=auth.uid() order by role_id,team_id for share;perform 1 from public.crm_roles order by id for share;perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id=auth.uid()) order by id for share;
 select * into o from portal_private.crm_criteria_observations where id=p_observation;if not found then raise exception 'Actual observation required';end if;
 perform 1 from public.projects where id=o.project_id for update;
 if not portal_private.project_criteria_access(o.project_id) then raise exception 'Current actual Admin or assigned PM required after waiting';end if;
 if p_id is null or p_path is null or p_name is null or length(trim(p_name)) not between 1 and 160 or p_name ~ '[[:cntrl:]/\\]' or length(trim(coalesce(p_reason,''))) not between 3 and 2000 or p_confirm is distinct from true then raise exception 'Safe actual filename reason identity and confirmation required';end if;
 ext:=lower(substring(p_path from '\.([^.]+)$'));mime:=case ext when 'pdf' then 'application/pdf' when 'png' then 'image/png' when 'jpg' then 'image/jpeg' when 'jpeg' then 'image/jpeg' when 'webp' then 'image/webp' end;
 if mime is null or p_path is distinct from p_observation::text||'/'||p_id::text||'.'||ext or lower(substring(p_name from '\.([^.]+)$')) is distinct from ext then raise exception 'Actual observation/file path and matching PDF/image filename required';end if;
 payload:=jsonb_build_object('observation',p_observation,'source',p_source,'path',p_path,'name',p_name,'reason',p_reason,'confirmed',p_confirm);
 perform pg_advisory_xact_lock(hashtextextended('criteria-file:'||p_path,0));select * into f from portal_private.crm_criteria_files where id=p_id;
 if found then if f.actor_id<>auth.uid() or f.payload is distinct from payload then raise exception 'File request meaning changed';end if;return f.id;end if;
 if not portal_private.criteria_file_current(p_observation) or p_source is distinct from to_jsonb(o)-'payload' then raise exception 'Observation or current approved source changed; refresh before attaching evidence';end if;
 if (select count(*) from portal_private.crm_criteria_files where observation_id=p_observation)>=20 then raise exception 'Technical file count limit reached';end if;
 select * into s from storage.objects where bucket_id='crm-criteria-files' and name=p_path and owner_id=auth.uid()::text for share;
 if not found or s.metadata->>'mimetype' is distinct from mime or coalesce(s.metadata->>'size','')!~'^[0-9]{1,8}$' or (s.metadata->>'size')::bigint not between 1 and 10485760 then raise exception 'Actual uploaded file metadata missing or mismatched';end if;
 insert into portal_private.crm_criteria_files values(p_id,p_observation,p_path,trim(p_name),(s.metadata->>'size')::bigint,mime,trim(p_reason),to_jsonb(o)-'payload',auth.uid(),now(),payload);return p_id;
end$$;
revoke all on function public.criteria_file_context(uuid),public.attach_criteria_file(uuid,uuid,jsonb,text,text,text,boolean) from public,anon,service_role;
grant execute on function public.criteria_file_context(uuid),public.attach_criteria_file(uuid,uuid,jsonb,text,text,text,boolean) to authenticated;
