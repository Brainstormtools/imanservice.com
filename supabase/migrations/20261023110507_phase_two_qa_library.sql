-- Unapplied. Manually reviewed master QA/SOP content; no standards or assignments seeded.
create table portal_private.crm_qa_library(id uuid primary key,revision integer not null check(revision>0));
create table portal_private.crm_qa_library_versions(
 id uuid primary key,library_id uuid not null references portal_private.crm_qa_library,revision integer not null,
 name text not null,kind text not null check(kind in ('QA','SOP')),steps jsonb not null,active boolean not null,
 reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),payload jsonb not null,
 unique(library_id,revision)
);
alter table portal_private.crm_qa_library enable row level security;
alter table portal_private.crm_qa_library_versions enable row level security;
revoke all on portal_private.crm_qa_library,portal_private.crm_qa_library_versions from public,anon,authenticated;
create trigger crm_qa_library_immutable before update or delete on portal_private.crm_qa_library_versions for each row execute function portal_private.lead_api_evidence_immutable();
create function public.crm_qa_library_context() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare admin boolean;begin
 select role='admin' into admin from public.profiles where id=auth.uid() and active and role in ('admin','team');
 if admin is null or not(admin or portal_private.crm_user_permission(auth.uid(),'project.own') or portal_private.crm_user_permission(auth.uid(),'sales.manage') or portal_private.crm_user_permission(auth.uid(),'sales.own')) then raise exception 'Current planning access required';end if;
 return jsonb_build_object('versions',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'library_id',v.library_id,'revision',v.revision,'current_revision',l.revision,'name',v.name,'kind',v.kind,'steps',v.steps,'active',v.active,'reason',v.reason,'actor_id',v.actor_id,'created_at',v.created_at) order by v.library_id,v.revision desc) from portal_private.crm_qa_library_versions v join portal_private.crm_qa_library l on l.id=v.library_id where admin or (v.revision=l.revision and v.active)),'[]'));
end$$;
create function public.save_crm_qa_library(p_request uuid,p_id uuid,p_version integer,p_name text,p_kind text,p_steps jsonb,p_active boolean,p_reason text,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$
declare previous portal_private.crm_qa_library_versions;lib portal_private.crm_qa_library;payload jsonb;new_id uuid;begin
 perform 1 from public.profiles where id=auth.uid() and active and role='admin' for share;if not found then raise exception 'Current Admin access required';end if;
 if p_request is null then raise exception 'Request identity required';end if;
 payload:=jsonb_build_object('id',p_id,'version',p_version,'name',p_name,'kind',p_kind,'steps',p_steps,'active',p_active,'reason',p_reason,'confirmed',p_confirm);
 perform pg_advisory_xact_lock(hashtext('qa-library-request:'||p_request));
 select * into previous from portal_private.crm_qa_library_versions where id=p_request;
 if found then if previous.actor_id<>auth.uid() or previous.payload is distinct from payload then raise exception 'Library retry meaning changed';end if;return previous.library_id;end if;
 if p_confirm is distinct from true or p_active is null or length(trim(coalesce(p_name,''))) not between 1 and 200 or p_kind is null or p_kind not in ('QA','SOP') or length(trim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'Actual name, kind, reason and explicit content review required';end if;
 if jsonb_typeof(p_steps) is distinct from 'array' or jsonb_array_length(p_steps) not between 1 and 100 then raise exception 'One to 100 actual checklist/procedure steps required';end if;
 if exists(select 1 from jsonb_array_elements(p_steps) s where jsonb_typeof(s)<>'string' or length(trim(s#>>'{}')) not between 1 and 1000) then raise exception 'Each step must contain actual text, at most 1000 characters';end if;
 if p_id is null then
  if p_version is not null then raise exception 'New library entry cannot name a prior version';end if;
  new_id:=gen_random_uuid();insert into portal_private.crm_qa_library values(new_id,1);lib.id:=new_id;lib.revision:=1;
 else
  select * into lib from portal_private.crm_qa_library where id=p_id for update;
  if not found or lib.revision is distinct from p_version then raise exception 'Library changed; refresh current version';end if;
  lib.revision:=lib.revision+1;update portal_private.crm_qa_library set revision=lib.revision where id=lib.id;
 end if;
 insert into portal_private.crm_qa_library_versions(id,library_id,revision,name,kind,steps,active,reason,actor_id,payload) values(p_request,lib.id,lib.revision,trim(p_name),p_kind,p_steps,p_active,trim(p_reason),auth.uid(),payload);
 return lib.id;
end$$;
revoke all on function public.crm_qa_library_context(),public.save_crm_qa_library(uuid,uuid,integer,text,text,jsonb,boolean,text,boolean) from public,anon;
grant execute on function public.crm_qa_library_context(),public.save_crm_qa_library(uuid,uuid,integer,text,text,jsonb,boolean,text,boolean) to authenticated;
