begin;
alter table public.fin_expenses add column evidence_files uuid[] not null default '{}' check(cardinality(evidence_files)<=10);
create table public.fin_expense_files(
 id uuid primary key,expense_id uuid not null references public.fin_expenses,path text not null unique,
 name text not null check(length(name) between 1 and 160),size bigint not null check(size between 1 and 10485760),mime text not null,
 actor_id uuid not null references public.profiles,reason text not null check(length(reason) between 3 and 2000),created_at timestamptz not null default now()
);
create index expense_file_expense on public.fin_expense_files(expense_id);
create index expense_file_actor on public.fin_expense_files(actor_id);
create table public.fin_expense_file_history(
 id uuid primary key,expense_id uuid not null references public.fin_expenses,file_id uuid references public.fin_expense_files,
 expense_version integer not null,action text not null check(action in ('Attached','Excluded','Restored','Submitted','Approved')),
 request jsonb not null,snapshot jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(expense_id,expense_version)
);
create index expense_file_history_file on public.fin_expense_file_history(file_id);
create index expense_file_history_actor on public.fin_expense_file_history(actor_id);
create function portal_private.expense_file_read(p_expense uuid) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and public.is_staff() and exists(select 1 from public.fin_expenses e where e.id=p_expense) and portal_private.expense_read(p_expense);
$$;
create function portal_private.expense_file_edit(p_expense uuid) returns boolean language sql stable security definer set search_path='' as $$
 select portal_private.expense_file_read(p_expense) and exists(select 1 from public.fin_expenses e where e.id=p_expense and e.status in ('Draft','Rejected') and (e.created_by=auth.uid() or portal_private.payables_access()) and portal_private.expense_scope(e.project_id,e.task_id));
$$;
create function portal_private.expense_file_upload(p_path text) returns boolean language sql stable security definer set search_path='' as $$
 select p_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|png|jpg|jpeg|webp)$' and exists(select 1 from public.fin_expenses e where e.id::text=split_part(p_path,'/',1) and portal_private.expense_file_edit(e.id) and cardinality(e.evidence_files)<10 and (select count(*) from public.fin_expense_files f where f.expense_id=e.id)<20);
$$;
create function portal_private.expense_file_object_read(p_path text,p_owner text) returns boolean language sql stable security definer set search_path='' as $$
 select public.is_staff() and (exists(select 1 from public.fin_expense_files f where f.path=p_path and portal_private.expense_file_read(f.expense_id)) or (p_owner=auth.uid()::text and not exists(select 1 from public.fin_expense_files f where f.path=p_path)));
$$;
create function portal_private.expense_file_orphan(p_path text) returns boolean language plpgsql security definer set search_path='' as $$
begin perform pg_advisory_xact_lock(hashtextextended('expense-proof:'||p_path,0));return not exists(select 1 from public.fin_expense_files where path=p_path);end$$;
revoke all on function portal_private.expense_file_read(uuid),portal_private.expense_file_edit(uuid),portal_private.expense_file_upload(text),portal_private.expense_file_object_read(text,text),portal_private.expense_file_orphan(text) from public,anon,authenticated;
grant execute on function portal_private.expense_file_read(uuid),portal_private.expense_file_upload(text),portal_private.expense_file_object_read(text,text),portal_private.expense_file_orphan(text) to authenticated;
alter table public.fin_expense_files enable row level security;alter table public.fin_expense_file_history enable row level security;
revoke all on public.fin_expense_files,public.fin_expense_file_history from public,anon,authenticated;
grant select on public.fin_expense_files,public.fin_expense_file_history to authenticated;
create policy expense_file_read on public.fin_expense_files for select to authenticated using(portal_private.expense_file_read(expense_id));
create policy expense_file_history_read on public.fin_expense_file_history for select to authenticated using(portal_private.expense_file_read(expense_id));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('finance-expense-evidence','finance-expense-evidence',false,10485760,array['application/pdf','image/png','image/jpeg','image/webp']);
create policy expense_proof_upload on storage.objects for insert to authenticated with check(bucket_id='finance-expense-evidence' and owner_id=auth.uid()::text and portal_private.expense_file_upload(name));
create policy expense_proof_read on storage.objects for select to authenticated using(bucket_id='finance-expense-evidence' and portal_private.expense_file_object_read(name,owner_id));
create policy expense_proof_cleanup on storage.objects for delete to authenticated using(bucket_id='finance-expense-evidence' and public.is_staff() and owner_id=auth.uid()::text and portal_private.expense_file_orphan(name));
-- No object UPDATE policy; exclusion does not make a registered file an orphan.
create function public.expense_receipt_context(p_expense uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare e public.fin_expenses;files jsonb;history jsonb;
begin
 if not coalesce(portal_private.expense_file_read(p_expense),false) then raise exception 'Current expense access required';end if;
 select * into e from public.fin_expenses where id=p_expense;
 select coalesce(jsonb_agg(to_jsonb(f)||jsonb_build_object('active',f.id=any(e.evidence_files),'stored_metadata_matches',o.id is not null and o.owner_id=f.actor_id::text and o.metadata->>'size'=f.size::text and o.metadata->>'mimetype'=f.mime) order by f.created_at,f.id),'[]') into files from public.fin_expense_files f left join storage.objects o on o.bucket_id='finance-expense-evidence' and o.name=f.path where f.expense_id=e.id;
 select coalesce(jsonb_agg(to_jsonb(h) order by h.expense_version),'[]') into history from public.fin_expense_file_history h where h.expense_id=e.id;
 return jsonb_build_object('expense_id',e.id,'version',e.version,'status',e.status,'can_edit',portal_private.expense_file_edit(e.id),'files',files,'history',history);
end$$;
create function public.attach_expense_receipt(p_id uuid,p_expense uuid,p_version integer,p_path text,p_name text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare e public.fin_expenses;old public.fin_expense_file_history;o storage.objects;f public.fin_expense_files;req jsonb;ext text;
begin
 if not coalesce(portal_private.expense_file_read(p_expense),false) then raise exception 'Current expense access required';end if;
 if p_id is null or p_path is null or p_name is null or length(trim(p_name)) not between 1 and 160 or (p_name ~ '[[:cntrl:]]' or p_name ~ '[/\\]') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit file identity, safe filename and actual reason required';end if;
 ext:=lower(substring(p_path from '\.([^.]+)$'));
 if ext is null or ext not in ('pdf','png','jpg','jpeg','webp') or p_path is distinct from p_expense::text||'/'||p_id::text||'.'||ext or lower(substring(p_name from '\.([^.]+)$')) is distinct from ext then raise exception 'Exact expense/file path and matching PDF/image filename required';end if;
 req:=jsonb_build_object('expense_id',p_expense,'version',p_version,'path',p_path,'name',trim(p_name),'reason',trim(p_reason),'action','Attached');
 perform pg_advisory_xact_lock(hashtextextended('expense-proof:'||p_path,0));
 select * into e from public.fin_expenses where id=p_expense for update;
 perform 1 from public.profiles where id=auth.uid() for share;
 perform 1 from public.crm_memberships where user_id=auth.uid() for share;
 perform 1 from public.project_assignments where project_id=e.project_id and technician_id=auth.uid() for share;
 perform 1 from public.tasks where id=e.task_id for share;
 if not coalesce(portal_private.expense_file_read(e.id),false) then raise exception 'Current expense access required';end if;
 select * into old from public.fin_expense_file_history where id=p_id;
 if old.id is not null then if old.actor_id=auth.uid() and old.request=req then return old.file_id;end if;raise exception 'Receipt request records different content or account';end if;
 if e.version is distinct from p_version or not portal_private.expense_file_edit(e.id) or cardinality(e.evidence_files)>=10 or (select count(*) from public.fin_expense_files where expense_id=e.id)>=20 then raise exception 'Exact editable expense version and available receipt capacity required';end if;
 select * into o from storage.objects where bucket_id='finance-expense-evidence' and name=p_path and owner_id=auth.uid()::text for share;
 if o.id is null or coalesce(o.metadata->>'size','') !~ '^[0-9]+$' or (o.metadata->>'size')::numeric not between 1 and 10485760 or (o.metadata->>'mimetype') is distinct from (case ext when 'pdf' then 'application/pdf' when 'png' then 'image/png' when 'jpg' then 'image/jpeg' when 'jpeg' then 'image/jpeg' when 'webp' then 'image/webp' end) then raise exception 'Upload a valid owned matching PDF/image object first';end if;
 insert into public.fin_expense_files(id,expense_id,path,name,size,mime,actor_id,reason) values(p_id,e.id,p_path,trim(p_name),(o.metadata->>'size')::bigint,o.metadata->>'mimetype',auth.uid(),trim(p_reason)) returning * into f;
 update public.fin_expenses set evidence_files=array_append(evidence_files,f.id),version=version+1 where id=e.id returning * into e;
 insert into public.fin_expense_file_history(id,expense_id,file_id,expense_version,action,request,snapshot,reason,actor_id) values(p_id,e.id,f.id,e.version,'Attached',req,jsonb_build_object('file',to_jsonb(f),'active_file_ids',e.evidence_files,'expense_version',e.version,'status',e.status),trim(p_reason),auth.uid());
 perform portal_private.finance_audit(e.id,null,'Receipt attached',trim(p_reason));return f.id;
end$$;
create function public.change_expense_receipt(p_id uuid,p_file uuid,p_version integer,p_action text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare e public.fin_expenses;f public.fin_expense_files;old public.fin_expense_file_history;req jsonb;
begin
 select * into f from public.fin_expense_files where id=p_file;
 if f.id is null or not coalesce(portal_private.expense_file_read(f.expense_id),false) then raise exception 'Current expense receipt access required';end if;
 if p_id is null or p_action is null or p_action not in ('Excluded','Restored') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit receipt action identity and actual reason required';end if;
 req:=jsonb_build_object('file_id',p_file,'version',p_version,'action',p_action,'reason',trim(p_reason));
 select * into e from public.fin_expenses where id=f.expense_id for update;
 perform 1 from public.profiles where id=auth.uid() for share;
 perform 1 from public.crm_memberships where user_id=auth.uid() for share;
 perform 1 from public.project_assignments where project_id=e.project_id and technician_id=auth.uid() for share;
 perform 1 from public.tasks where id=e.task_id for share;
 if not coalesce(portal_private.expense_file_read(e.id),false) then raise exception 'Current expense access required';end if;
 select * into old from public.fin_expense_file_history where id=p_id;
 if old.id is not null then if old.actor_id=auth.uid() and old.request=req then return old.id;end if;raise exception 'Receipt request records different content or account';end if;
 if e.version is distinct from p_version or not portal_private.expense_file_edit(e.id) then raise exception 'Exact editable expense version required';end if;
 if p_action='Excluded' then
  if not(f.id=any(e.evidence_files)) then raise exception 'Receipt is already excluded';end if;
  update public.fin_expenses set evidence_files=array_remove(evidence_files,f.id),version=version+1 where id=e.id returning * into e;
 else
  if f.id=any(e.evidence_files) or cardinality(e.evidence_files)>=10 then raise exception 'Excluded receipt and available capacity required';end if;
  perform 1 from storage.objects o where o.bucket_id='finance-expense-evidence' and o.name=f.path and o.owner_id=f.actor_id::text and o.metadata->>'size'=f.size::text and o.metadata->>'mimetype'=f.mime for share;
  if not found then raise exception 'Original intact registered receipt required for restoration';end if;
  update public.fin_expenses set evidence_files=array_append(evidence_files,f.id),version=version+1 where id=e.id returning * into e;
 end if;
 insert into public.fin_expense_file_history(id,expense_id,file_id,expense_version,action,request,snapshot,reason,actor_id) values(p_id,e.id,f.id,e.version,p_action,req,jsonb_build_object('file',to_jsonb(f),'active_file_ids',e.evidence_files,'expense_version',e.version,'status',e.status),trim(p_reason),auth.uid());
 perform portal_private.finance_audit(e.id,null,'Receipt '||lower(p_action),trim(p_reason));return p_id;
end$$;
alter function public.finance_ledger_action(text,uuid,integer,text,text) rename to finance_ledger_action_before_receipt_files;
revoke all on function public.finance_ledger_action_before_receipt_files(text,uuid,integer,text,text) from public,anon,authenticated;
create function public.finance_ledger_action(p_kind text,p_id uuid,p_version integer,p_action text,p_note text default '') returns void language plpgsql security definer set search_path='' as $$
declare e public.fin_expenses;files jsonb;
begin
 if p_kind='Expense' and p_action in ('Submit','Approve') then
  if not coalesce(portal_private.expense_file_read(p_id),false) then raise exception 'Current expense access required';end if;
  perform portal_private.finance_lock('Expense',p_id,p_version);select * into e from public.fin_expenses where id=p_id;
  perform 1 from public.fin_expense_files f join storage.objects o on o.bucket_id='finance-expense-evidence' and o.name=f.path where f.id=any(e.evidence_files) for share of f,o;
  if exists(select 1 from unnest(e.evidence_files) i(id) left join public.fin_expense_files f on f.id=i.id left join storage.objects o on o.bucket_id='finance-expense-evidence' and o.name=f.path where f.id is null or f.expense_id<>e.id or o.id is null or o.owner_id is distinct from f.actor_id::text or o.metadata->>'size' is distinct from f.size::text or o.metadata->>'mimetype' is distinct from f.mime) then raise exception 'Resolve missing or changed active receipt evidence before submission/approval';end if;
  select coalesce(jsonb_agg(to_jsonb(f) order by f.id),'[]') into files from public.fin_expense_files f where f.id=any(e.evidence_files);
 end if;
 perform public.finance_ledger_action_before_receipt_files(p_kind,p_id,p_version,p_action,p_note);
 if p_kind='Expense' and p_action in ('Submit','Approve') then
  select * into e from public.fin_expenses where id=p_id;
  insert into public.fin_expense_file_history(id,expense_id,expense_version,action,request,snapshot,reason,actor_id) values(gen_random_uuid(),e.id,e.version,case p_action when 'Submit' then 'Submitted' else 'Approved' end,jsonb_build_object('version',p_version,'action',p_action,'note',p_note),jsonb_build_object('expense',to_jsonb(e),'active_file_ids',e.evidence_files,'files',files,'expense_version',e.version,'status',e.status),coalesce(p_note,''),auth.uid());
 end if;
end$$;
revoke all on function public.expense_receipt_context(uuid),public.attach_expense_receipt(uuid,uuid,integer,text,text,text),public.change_expense_receipt(uuid,uuid,integer,text,text),public.finance_ledger_action(text,uuid,integer,text,text) from public,anon;
grant execute on function public.expense_receipt_context(uuid),public.attach_expense_receipt(uuid,uuid,integer,text,text,text),public.change_expense_receipt(uuid,uuid,integer,text,text),public.finance_ledger_action(text,uuid,integer,text,text) to authenticated;
notify pgrst,'reload schema';
commit;
