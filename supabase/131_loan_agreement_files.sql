begin;
alter table public.fin_loans add column evidence_files uuid[] not null default '{}' check(cardinality(evidence_files)<=10);
create table public.fin_loan_files(
 id uuid primary key,loan_id uuid not null references public.fin_loans,path text not null unique,
 name text not null check(length(name) between 1 and 160),size bigint not null check(size between 1 and 10485760),mime text not null,
 actor_id uuid not null references public.profiles,reason text not null check(length(reason) between 3 and 2000),created_at timestamptz not null default now()
);
create index loan_file_loan on public.fin_loan_files(loan_id);
create index loan_file_actor on public.fin_loan_files(actor_id);
create table public.fin_loan_file_history(
 id uuid primary key,loan_id uuid not null references public.fin_loans,file_id uuid references public.fin_loan_files,
 loan_version integer not null,action text not null check(action in ('Attached','Excluded','Restored','Submitted','Approved')),
 request jsonb not null,snapshot jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(loan_id,loan_version)
);
create index loan_file_history_file on public.fin_loan_file_history(file_id);
create index loan_file_history_actor on public.fin_loan_file_history(actor_id);
create function portal_private.loan_file_read(p_loan uuid) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and public.is_staff() and exists(select 1 from public.fin_loans e where e.id=p_loan) and portal_private.payables_access();
$$;
create function portal_private.loan_file_edit(p_loan uuid) returns boolean language sql stable security definer set search_path='' as $$
 select portal_private.loan_file_read(p_loan) and exists(select 1 from public.fin_loans e where e.id=p_loan and e.status in ('Draft','Rejected'));
$$;
create function portal_private.loan_file_upload(p_path text) returns boolean language sql stable security definer set search_path='' as $$
 select p_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|png|jpg|jpeg|webp)$' and exists(select 1 from public.fin_loans e where e.id::text=split_part(p_path,'/',1) and portal_private.loan_file_edit(e.id) and cardinality(e.evidence_files)<10 and (select count(*) from public.fin_loan_files f where f.loan_id=e.id)<20);
$$;
create function portal_private.loan_file_object_read(p_path text,p_owner text) returns boolean language sql stable security definer set search_path='' as $$
 select portal_private.payables_access() and (exists(select 1 from public.fin_loan_files f where f.path=p_path and portal_private.loan_file_read(f.loan_id)) or (p_owner=auth.uid()::text and not exists(select 1 from public.fin_loan_files f where f.path=p_path)));
$$;
create function portal_private.loan_file_orphan(p_path text) returns boolean language plpgsql security definer set search_path='' as $$
begin perform pg_advisory_xact_lock(hashtextextended('loan-proof:'||p_path,0));return not exists(select 1 from public.fin_loan_files where path=p_path);end$$;
revoke all on function portal_private.loan_file_read(uuid),portal_private.loan_file_edit(uuid),portal_private.loan_file_upload(text),portal_private.loan_file_object_read(text,text),portal_private.loan_file_orphan(text) from public,anon,authenticated;
grant execute on function portal_private.loan_file_read(uuid),portal_private.loan_file_upload(text),portal_private.loan_file_object_read(text,text),portal_private.loan_file_orphan(text) to authenticated;
alter table public.fin_loan_files enable row level security;alter table public.fin_loan_file_history enable row level security;
revoke all on public.fin_loan_files,public.fin_loan_file_history from public,anon,authenticated;
grant select on public.fin_loan_files,public.fin_loan_file_history to authenticated;
create policy loan_file_read on public.fin_loan_files for select to authenticated using(portal_private.loan_file_read(loan_id));
create policy loan_file_history_read on public.fin_loan_file_history for select to authenticated using(portal_private.loan_file_read(loan_id));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('finance-loan-evidence','finance-loan-evidence',false,10485760,array['application/pdf','image/png','image/jpeg','image/webp']);
create policy loan_proof_upload on storage.objects for insert to authenticated with check(bucket_id='finance-loan-evidence' and owner_id=auth.uid()::text and portal_private.loan_file_upload(name));
create policy loan_proof_read on storage.objects for select to authenticated using(bucket_id='finance-loan-evidence' and portal_private.loan_file_object_read(name,owner_id));
create policy loan_proof_cleanup on storage.objects for delete to authenticated using(bucket_id='finance-loan-evidence' and portal_private.payables_access() and owner_id=auth.uid()::text and portal_private.loan_file_orphan(name));
-- No object UPDATE policy; exclusion does not make a registered file an orphan.
create function public.loan_agreement_context(p_loan uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare e public.fin_loans;files jsonb;history jsonb;
begin
 if not coalesce(portal_private.loan_file_read(p_loan),false) then raise exception 'Current loan access required';end if;
 select * into e from public.fin_loans where id=p_loan;
 select coalesce(jsonb_agg(to_jsonb(f)||jsonb_build_object('active',f.id=any(e.evidence_files),'stored_metadata_matches',o.id is not null and o.owner_id=f.actor_id::text and o.metadata->>'size'=f.size::text and o.metadata->>'mimetype'=f.mime) order by f.created_at,f.id),'[]') into files from public.fin_loan_files f left join storage.objects o on o.bucket_id='finance-loan-evidence' and o.name=f.path where f.loan_id=e.id;
 select coalesce(jsonb_agg(to_jsonb(h) order by h.loan_version),'[]') into history from public.fin_loan_file_history h where h.loan_id=e.id;
 return jsonb_build_object('loan_id',e.id,'version',e.version,'status',e.status,'can_edit',portal_private.loan_file_edit(e.id),'files',files,'history',history);
end$$;
create function public.attach_loan_agreement_file(p_id uuid,p_loan uuid,p_version integer,p_path text,p_name text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare e public.fin_loans;old public.fin_loan_file_history;o storage.objects;f public.fin_loan_files;req jsonb;ext text;
begin
 if not coalesce(portal_private.loan_file_read(p_loan),false) then raise exception 'Current loan access required';end if;
 if p_id is null or p_path is null or p_name is null or length(trim(p_name)) not between 1 and 160 or (p_name ~ '[[:cntrl:]]' or p_name ~ '[/\\]') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit file identity, safe filename and actual reason required';end if;
 ext:=lower(substring(p_path from '\.([^.]+)$'));
 if ext is null or ext not in ('pdf','png','jpg','jpeg','webp') or p_path is distinct from p_loan::text||'/'||p_id::text||'.'||ext or lower(substring(p_name from '\.([^.]+)$')) is distinct from ext then raise exception 'Exact loan/file path and matching PDF/image filename required';end if;
 req:=jsonb_build_object('loan_id',p_loan,'version',p_version,'path',p_path,'name',trim(p_name),'reason',trim(p_reason),'action','Attached');
 perform pg_advisory_xact_lock(hashtextextended('loan-proof:'||p_path,0));
 select * into e from public.fin_loans where id=p_loan for update;
 perform 1 from public.profiles where id=auth.uid() for share;
 perform 1 from public.crm_memberships where user_id=auth.uid() for share;
 if not coalesce(portal_private.loan_file_read(e.id),false) then raise exception 'Current loan access required';end if;
 select * into old from public.fin_loan_file_history where id=p_id;
 if old.id is not null then if old.actor_id=auth.uid() and old.request=req then return old.file_id;end if;raise exception 'Receipt request records different content or account';end if;
 if e.version is distinct from p_version or not portal_private.loan_file_edit(e.id) or cardinality(e.evidence_files)>=10 or (select count(*) from public.fin_loan_files where loan_id=e.id)>=20 then raise exception 'Exact editable loan version and available receipt capacity required';end if;
 select * into o from storage.objects where bucket_id='finance-loan-evidence' and name=p_path and owner_id=auth.uid()::text for share;
 if o.id is null or coalesce(o.metadata->>'size','') !~ '^[0-9]+$' or (o.metadata->>'size')::numeric not between 1 and 10485760 or (o.metadata->>'mimetype') is distinct from (case ext when 'pdf' then 'application/pdf' when 'png' then 'image/png' when 'jpg' then 'image/jpeg' when 'jpeg' then 'image/jpeg' when 'webp' then 'image/webp' end) then raise exception 'Upload a valid owned matching PDF/image object first';end if;
 insert into public.fin_loan_files(id,loan_id,path,name,size,mime,actor_id,reason) values(p_id,e.id,p_path,trim(p_name),(o.metadata->>'size')::bigint,o.metadata->>'mimetype',auth.uid(),trim(p_reason)) returning * into f;
 update public.fin_loans set evidence_files=array_append(evidence_files,f.id),version=version+1 where id=e.id returning * into e;
 insert into public.fin_loan_file_history(id,loan_id,file_id,loan_version,action,request,snapshot,reason,actor_id) values(p_id,e.id,f.id,e.version,'Attached',req,jsonb_build_object('file',to_jsonb(f),'active_file_ids',e.evidence_files,'loan_version',e.version,'status',e.status),trim(p_reason),auth.uid());
 perform portal_private.finance_audit(null,e.id,'Agreement file attached',trim(p_reason));return f.id;
end$$;
create function public.change_loan_agreement_file(p_id uuid,p_file uuid,p_version integer,p_action text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare e public.fin_loans;f public.fin_loan_files;old public.fin_loan_file_history;req jsonb;
begin
 select * into f from public.fin_loan_files where id=p_file;
 if f.id is null or not coalesce(portal_private.loan_file_read(f.loan_id),false) then raise exception 'Current loan receipt access required';end if;
 if p_id is null or p_action is null or p_action not in ('Excluded','Restored') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit receipt action identity and actual reason required';end if;
 req:=jsonb_build_object('file_id',p_file,'version',p_version,'action',p_action,'reason',trim(p_reason));
 select * into e from public.fin_loans where id=f.loan_id for update;
 perform 1 from public.profiles where id=auth.uid() for share;
 perform 1 from public.crm_memberships where user_id=auth.uid() for share;
 if not coalesce(portal_private.loan_file_read(e.id),false) then raise exception 'Current loan access required';end if;
 select * into old from public.fin_loan_file_history where id=p_id;
 if old.id is not null then if old.actor_id=auth.uid() and old.request=req then return old.id;end if;raise exception 'Receipt request records different content or account';end if;
 if e.version is distinct from p_version or not portal_private.loan_file_edit(e.id) then raise exception 'Exact editable loan version required';end if;
 if p_action='Excluded' then
  if not(f.id=any(e.evidence_files)) then raise exception 'Receipt is already excluded';end if;
  update public.fin_loans set evidence_files=array_remove(evidence_files,f.id),version=version+1 where id=e.id returning * into e;
 else
  if f.id=any(e.evidence_files) or cardinality(e.evidence_files)>=10 then raise exception 'Excluded receipt and available capacity required';end if;
  perform 1 from storage.objects o where o.bucket_id='finance-loan-evidence' and o.name=f.path and o.owner_id=f.actor_id::text and o.metadata->>'size'=f.size::text and o.metadata->>'mimetype'=f.mime for share;
  if not found then raise exception 'Original intact registered receipt required for restoration';end if;
  update public.fin_loans set evidence_files=array_append(evidence_files,f.id),version=version+1 where id=e.id returning * into e;
 end if;
 insert into public.fin_loan_file_history(id,loan_id,file_id,loan_version,action,request,snapshot,reason,actor_id) values(p_id,e.id,f.id,e.version,p_action,req,jsonb_build_object('file',to_jsonb(f),'active_file_ids',e.evidence_files,'loan_version',e.version,'status',e.status),trim(p_reason),auth.uid());
 perform portal_private.finance_audit(null,e.id,'Agreement file '||lower(p_action),trim(p_reason));return p_id;
end$$;
alter function public.finance_ledger_action(text,uuid,integer,text,text) rename to finance_ledger_action_before_loan_files;
revoke all on function public.finance_ledger_action_before_loan_files(text,uuid,integer,text,text) from public,anon,authenticated;
create function public.finance_ledger_action(p_kind text,p_id uuid,p_version integer,p_action text,p_note text default '') returns void language plpgsql security definer set search_path='' as $$
declare e public.fin_loans;files jsonb;
begin
 if p_kind='Loan' and p_action in ('Submit','Approve') then
  if not coalesce(portal_private.loan_file_read(p_id),false) then raise exception 'Current loan access required';end if;
  perform portal_private.finance_lock('Loan',p_id,p_version);select * into e from public.fin_loans where id=p_id;
  perform 1 from public.fin_loan_files f join storage.objects o on o.bucket_id='finance-loan-evidence' and o.name=f.path where f.id=any(e.evidence_files) for share of f,o;
  if exists(select 1 from unnest(e.evidence_files) i(id) left join public.fin_loan_files f on f.id=i.id left join storage.objects o on o.bucket_id='finance-loan-evidence' and o.name=f.path where f.id is null or f.loan_id<>e.id or o.id is null or o.owner_id is distinct from f.actor_id::text or o.metadata->>'size' is distinct from f.size::text or o.metadata->>'mimetype' is distinct from f.mime) then raise exception 'Resolve missing or changed active receipt evidence before submission/approval';end if;
  select coalesce(jsonb_agg(to_jsonb(f) order by f.id),'[]') into files from public.fin_loan_files f where f.id=any(e.evidence_files);
 end if;
 perform public.finance_ledger_action_before_loan_files(p_kind,p_id,p_version,p_action,p_note);
 if p_kind='Loan' and p_action in ('Submit','Approve') then
  select * into e from public.fin_loans where id=p_id;
  insert into public.fin_loan_file_history(id,loan_id,loan_version,action,request,snapshot,reason,actor_id) values(gen_random_uuid(),e.id,e.version,case p_action when 'Submit' then 'Submitted' else 'Approved' end,jsonb_build_object('version',p_version,'action',p_action,'note',p_note),jsonb_build_object('loan',to_jsonb(e),'active_file_ids',e.evidence_files,'files',files,'loan_version',e.version,'status',e.status),coalesce(p_note,''),auth.uid());
 end if;
end$$;
revoke all on function public.loan_agreement_context(uuid),public.attach_loan_agreement_file(uuid,uuid,integer,text,text,text),public.change_loan_agreement_file(uuid,uuid,integer,text,text),public.finance_ledger_action(text,uuid,integer,text,text) from public,anon;
grant execute on function public.loan_agreement_context(uuid),public.attach_loan_agreement_file(uuid,uuid,integer,text,text,text),public.change_loan_agreement_file(uuid,uuid,integer,text,text),public.finance_ledger_action(text,uuid,integer,text,text) to authenticated;
create function portal_private.loan_file_immutable() returns trigger language plpgsql set search_path='' as $$begin raise exception 'Loan agreement file evidence is immutable';end$$;
revoke all on function portal_private.loan_file_immutable() from public,anon,authenticated;
create trigger loan_file_immutable before update or delete on public.fin_loan_files for each row execute function portal_private.loan_file_immutable();
create trigger loan_file_history_immutable before update or delete on public.fin_loan_file_history for each row execute function portal_private.loan_file_immutable();
notify pgrst,'reload schema';
commit;
