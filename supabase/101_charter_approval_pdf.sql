begin;
create table public.crm_client_charter_documents(
 approval_id uuid primary key references public.crm_client_charter_approvals,project_id uuid not null references public.projects,
 pdf bytea not null check(octet_length(pdf) between 100 and 5242880),sha256 text not null,receipt_hash text not null,
 renderer_version text not null,created_by uuid not null references public.profiles,created_at timestamptz not null default now()
);
create index charter_document_project on public.crm_client_charter_documents(project_id);
create index charter_document_author on public.crm_client_charter_documents(created_by);
alter table public.crm_client_charter_documents enable row level security;
revoke all on public.crm_client_charter_documents from public,anon,authenticated;
grant select(approval_id,project_id,sha256,receipt_hash,renderer_version,created_by,created_at) on public.crm_client_charter_documents to authenticated;
create function portal_private.charter_pdf_access(p_approval uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.crm_client_charter_approvals a join public.projects p on p.id=a.project_id where a.id=p_approval and (portal_private.execution_manager(a.project_id) or (a.actor_id=auth.uid() and exists(select 1 from public.profiles u where u.id=auth.uid() and u.active and u.role='client' and u.company_id=a.company_id and p.company_id=u.company_id))));
$$;
create policy charter_document_read on public.crm_client_charter_documents for select to authenticated using(portal_private.charter_pdf_access(approval_id));
create function public.charter_approval_pdf_source(p_approval uuid,p_gateway_token text) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare a public.crm_client_charter_approvals;d public.crm_client_charter_documents;
begin
 if auth.uid() is null or not portal_private.charter_pdf_access(p_approval) or not exists(select 1 from portal_private.charter_approval_gateway where id='approval' and token_hash=encode(sha256(convert_to(coalesce(p_gateway_token,''),'UTF8')),'hex')) then raise exception 'Authorized project approval endpoint required';end if;
 select * into a from public.crm_client_charter_approvals where id=p_approval;
 select * into d from public.crm_client_charter_documents where approval_id=p_approval;
 return jsonb_build_object('approval',to_jsonb(a),'receipt_hash',encode(sha256(convert_to(to_jsonb(a)::text,'UTF8')),'hex'),'document',case when d.approval_id is not null then jsonb_build_object('base64',encode(d.pdf,'base64'),'sha256',d.sha256,'receipt_hash',d.receipt_hash,'renderer_version',d.renderer_version,'created_at',d.created_at) end);
end$$;
create function public.archive_charter_approval_pdf(p_approval uuid,p_receipt_hash text,p_pdf_base64 text,p_gateway_token text) returns text language plpgsql security definer set search_path='' as $$
declare a public.crm_client_charter_approvals;d public.crm_client_charter_documents;bytes bytea;actual_hash text;
begin
 if auth.uid() is null or not portal_private.charter_pdf_access(p_approval) or not exists(select 1 from portal_private.charter_approval_gateway where id='approval' and token_hash=encode(sha256(convert_to(coalesce(p_gateway_token,''),'UTF8')),'hex')) then raise exception 'Authorized project approval endpoint required';end if;
 select * into a from public.crm_client_charter_approvals where id=p_approval for update;
 actual_hash:=encode(sha256(convert_to(to_jsonb(a)::text,'UTF8')),'hex');
 if p_receipt_hash is distinct from actual_hash then raise exception 'Exact immutable approval hash required';end if;
 select * into d from public.crm_client_charter_documents where approval_id=p_approval;
 if d.approval_id is not null then return d.sha256;end if;
 if p_pdf_base64 is null or length(p_pdf_base64)>7000000 then raise exception 'Bounded server PDF required';end if;
 bytes:=decode(p_pdf_base64,'base64');
 if octet_length(bytes) not between 100 and 5242880 or substring(bytes from 1 for 5)<>convert_to('%PDF-','UTF8') or position(convert_to('%%EOF','UTF8') in bytes)=0 then raise exception 'Valid bounded server PDF required';end if;
 insert into public.crm_client_charter_documents(approval_id,project_id,pdf,sha256,receipt_hash,renderer_version,created_by)
 values(a.id,a.project_id,bytes,encode(sha256(bytes),'hex'),actual_hash,'charter-pdf-v1',auth.uid()) returning * into d;
 return d.sha256;
end$$;
revoke all on function portal_private.charter_pdf_access(uuid),public.charter_approval_pdf_source(uuid,text),public.archive_charter_approval_pdf(uuid,text,text,text) from public,anon;
grant execute on function portal_private.charter_pdf_access(uuid),public.charter_approval_pdf_source(uuid,text),public.archive_charter_approval_pdf(uuid,text,text,text) to authenticated;
create or replace function public.client_charter_approval_context(p_publication uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare p public.crm_client_charter_publications;manager boolean;items jsonb;
begin
 select * into p from public.crm_client_charter_publications where id=p_publication;
 manager:=portal_private.execution_manager(p.project_id);
 if p.id is null or auth.uid() is null or not(manager or exists(select 1 from public.profiles u join public.projects j on j.id=p.project_id where u.id=auth.uid() and u.active and u.role='client' and u.company_id=p.company_id and j.company_id=p.company_id)) then raise exception 'Current project charter access required';end if;
 select coalesce(jsonb_agg(to_jsonb(a)||jsonb_build_object('pdf',(select jsonb_build_object('sha256',d.sha256,'created_at',d.created_at,'renderer_version',d.renderer_version) from public.crm_client_charter_documents d where d.approval_id=a.id)) order by created_at),'[]') into items from public.crm_client_charter_approvals a where publication_id=p.id and (manager or actor_id=auth.uid());
 return jsonb_build_object('eligible',portal_private.charter_signatory(p.project_id) and p.status='Published' and p.client_terms is not null and p.publication_sequence=(select max(publication_sequence) from public.crm_client_charter_publications where project_id=p.project_id),'approvals',items);
end$$;
notify pgrst,'reload schema';
commit;
