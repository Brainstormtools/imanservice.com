begin;
-- Supplemental evidence added after posting. Never rewrite original cash or infer approval.
create table public.fin_cash_files(
 id uuid primary key,cash_id uuid not null references public.fin_cash_entries,path text not null unique,
 name text not null check(length(name) between 1 and 160),size bigint not null check(size between 1 and 10485760),mime text not null,
 actor_id uuid not null references public.profiles,reason text not null check(length(reason) between 3 and 2000),
 created_at timestamptz not null default now(),request jsonb not null,cash_snapshot jsonb not null
);
create index cash_files_cash on public.fin_cash_files(cash_id);
create index cash_files_actor on public.fin_cash_files(actor_id);
create table public.fin_cash_file_history(
 id uuid primary key,cash_id uuid not null references public.fin_cash_entries,file_id uuid unique references public.fin_cash_files,
 action text not null check(action in ('Attached','Reversed')),snapshot jsonb not null,reason text not null,
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now()
);
create index cash_file_history_cash on public.fin_cash_file_history(cash_id);
create unique index cash_file_one_reversal on public.fin_cash_file_history(cash_id) where action='Reversed';
alter table public.fin_cash_files enable row level security;alter table public.fin_cash_file_history enable row level security;
revoke all on public.fin_cash_files,public.fin_cash_file_history from public,anon,authenticated;
grant select on public.fin_cash_files,public.fin_cash_file_history to authenticated;
create function portal_private.cash_file_read(p_cash uuid) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and portal_private.payables_access() and exists(select 1 from public.fin_cash_entries where id=p_cash);
$$;
create function portal_private.cash_file_upload(p_path text) returns boolean language sql stable security definer set search_path='' as $$
 select p_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|png|jpg|jpeg|webp)$' and exists(select 1 from public.fin_cash_entries c where c.id::text=split_part(p_path,'/',1) and c.reversed_by is null and portal_private.cash_file_read(c.id) and (select count(*) from public.fin_cash_files f where f.cash_id=c.id)<20);
$$;
create function portal_private.cash_file_object_read(p_path text,p_owner text) returns boolean language sql stable security definer set search_path='' as $$
 select portal_private.payables_access() and (exists(select 1 from public.fin_cash_files f where f.path=p_path and portal_private.cash_file_read(f.cash_id)) or (p_owner=auth.uid()::text and not exists(select 1 from public.fin_cash_files f where f.path=p_path)));
$$;
create function portal_private.cash_file_orphan(p_path text) returns boolean language plpgsql security definer set search_path='' as $$
begin if not portal_private.payables_access() then return false;end if;perform pg_advisory_xact_lock(hashtextextended('cash-proof:'||p_path,0));return not exists(select 1 from public.fin_cash_files where path=p_path);end$$;
revoke all on function portal_private.cash_file_read(uuid),portal_private.cash_file_upload(text),portal_private.cash_file_object_read(text,text),portal_private.cash_file_orphan(text) from public,anon,authenticated;
grant execute on function portal_private.cash_file_read(uuid),portal_private.cash_file_upload(text),portal_private.cash_file_object_read(text,text),portal_private.cash_file_orphan(text) to authenticated;
create policy cash_file_read on public.fin_cash_files for select to authenticated using(portal_private.cash_file_read(cash_id));
create policy cash_file_history_read on public.fin_cash_file_history for select to authenticated using(portal_private.cash_file_read(cash_id));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('finance-cash-evidence','finance-cash-evidence',false,10485760,array['application/pdf','image/png','image/jpeg','image/webp']);
create policy cash_proof_upload on storage.objects for insert to authenticated with check(bucket_id='finance-cash-evidence' and owner_id=auth.uid()::text and portal_private.cash_file_upload(name));
create policy cash_proof_read on storage.objects for select to authenticated using(bucket_id='finance-cash-evidence' and portal_private.cash_file_object_read(name,owner_id));
create policy cash_proof_cleanup on storage.objects for delete to authenticated using(bucket_id='finance-cash-evidence' and portal_private.payables_access() and owner_id=auth.uid()::text and portal_private.cash_file_orphan(name));
create function portal_private.cash_file_immutable() returns trigger language plpgsql set search_path='' as $$begin raise exception 'Supplemental cash evidence is immutable';end$$;
revoke all on function portal_private.cash_file_immutable() from public,anon,authenticated;
create trigger cash_file_immutable before update or delete on public.fin_cash_files for each row execute function portal_private.cash_file_immutable();
create trigger cash_file_history_immutable before update or delete on public.fin_cash_file_history for each row execute function portal_private.cash_file_immutable();
create function public.cash_evidence_context(p_cash uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare c public.fin_cash_entries;files jsonb;history jsonb;
begin
 if not coalesce(portal_private.cash_file_read(p_cash),false) then raise exception 'Current Accounts cash evidence access required';end if;
 select * into c from public.fin_cash_entries where id=p_cash;
 select coalesce(jsonb_agg(to_jsonb(f)||jsonb_build_object('stored_metadata_matches',o.id is not null and o.owner_id=f.actor_id::text and o.metadata->>'size'=f.size::text and o.metadata->>'mimetype'=f.mime) order by f.created_at,f.id),'[]'::jsonb) into files from public.fin_cash_files f left join storage.objects o on o.bucket_id='finance-cash-evidence' and o.name=f.path where f.cash_id=c.id;
 select coalesce(jsonb_agg(to_jsonb(h) order by h.created_at,h.id),'[]'::jsonb) into history from public.fin_cash_file_history h where h.cash_id=c.id;
 return jsonb_build_object('cash_id',c.id,'cash_snapshot',to_jsonb(c),'version',jsonb_array_length(files),'can_add',c.reversed_by is null and jsonb_array_length(files)<20,'files',files,'history',history);
end$$;
create function public.attach_cash_evidence(p_id uuid,p_cash uuid,p_version integer,p_cash_snapshot jsonb,p_path text,p_name text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare c public.fin_cash_entries;f public.fin_cash_files;o storage.objects;req jsonb;ext text;
begin
 if not coalesce(portal_private.cash_file_read(p_cash),false) then raise exception 'Current Accounts cash evidence access required';end if;
 if p_id is null or p_path is null or p_name is null or length(trim(p_name)) not between 1 and 160 or p_name ~ '[[:cntrl:]]' or p_name ~ '[/\\]' or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit safe file identity and actual reason required';end if;
 ext:=lower(substring(p_path from '\.([^.]+)$'));
 if ext is null or ext not in ('pdf','png','jpg','jpeg','webp') or p_path is distinct from p_cash::text||'/'||p_id::text||'.'||ext or lower(substring(p_name from '\.([^.]+)$')) is distinct from ext then raise exception 'Exact cash/file path and matching PDF/image filename required';end if;
 req:=jsonb_build_object('cash_id',p_cash,'version',p_version,'cash_snapshot',p_cash_snapshot,'path',p_path,'name',trim(p_name),'reason',trim(p_reason));
 perform pg_advisory_xact_lock(hashtextextended('cash-proof:'||p_path,0));
 select * into c from public.fin_cash_entries where id=p_cash for update;
 perform 1 from public.profiles where id=auth.uid() for share;
 perform 1 from public.crm_memberships where user_id=auth.uid() for share;
 if not coalesce(portal_private.cash_file_read(c.id),false) then raise exception 'Current Accounts cash evidence access required';end if;
 select * into f from public.fin_cash_files where id=p_id;
 if f.id is not null then if f.actor_id=auth.uid() and f.request=req then return f.id;end if;raise exception 'File identity records different cash evidence or account';end if;
 if c.reversed_by is not null or p_cash_snapshot is distinct from to_jsonb(c) or p_version is distinct from (select count(*)::integer from public.fin_cash_files where cash_id=c.id) or p_version>=20 then raise exception 'Exact unreversed cash snapshot, evidence version and available capacity required';end if;
 select * into o from storage.objects where bucket_id='finance-cash-evidence' and name=p_path and owner_id=auth.uid()::text for share;
 if o.id is null or coalesce(o.metadata->>'size','') !~ '^[0-9]+$' or (o.metadata->>'size')::numeric not between 1 and 10485760 or o.metadata->>'mimetype' is distinct from (case ext when 'pdf' then 'application/pdf' when 'png' then 'image/png' when 'jpg' then 'image/jpeg' when 'jpeg' then 'image/jpeg' when 'webp' then 'image/webp' end) then raise exception 'Upload actual owned matching PDF/image first';end if;
 insert into public.fin_cash_files(id,cash_id,path,name,size,mime,actor_id,reason,request,cash_snapshot) values(p_id,c.id,p_path,trim(p_name),(o.metadata->>'size')::bigint,o.metadata->>'mimetype',auth.uid(),trim(p_reason),req,to_jsonb(c)) returning * into f;
 insert into public.fin_cash_file_history(id,cash_id,file_id,action,snapshot,reason,actor_id) values(p_id,c.id,f.id,'Attached',jsonb_build_object('timing','Supplemental evidence added after posting','cash',to_jsonb(c),'file',to_jsonb(f),'evidence_version',p_version+1),trim(p_reason),auth.uid());return f.id;
end$$;
alter function public.reverse_finance_cash(uuid,integer,text) rename to reverse_finance_cash_before_files;
revoke all on function public.reverse_finance_cash_before_files(uuid,integer,text) from public,anon,authenticated;
create function public.reverse_finance_cash(p_id uuid,p_version integer,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare c public.fin_cash_entries;files jsonb;after_cash public.fin_cash_entries;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Administrator required';end if;
 select * into c from public.fin_cash_entries where id=p_id;
 if c.id is null then raise exception 'Cash record unavailable';end if;
 perform portal_private.finance_lock(case when c.expense_id is not null then 'Expense' else 'Loan' end,coalesce(c.expense_id,c.loan_id),p_version);
 select * into c from public.fin_cash_entries where id=p_id for update;
 -- Archive observed proof, including missing-object flags. Evidence does not block or approve financial reversal.
 select coalesce(jsonb_agg(to_jsonb(f)||jsonb_build_object('stored_metadata_matches',o.id is not null and o.owner_id=f.actor_id::text and o.metadata->>'size'=f.size::text and o.metadata->>'mimetype'=f.mime) order by f.created_at,f.id),'[]'::jsonb) into files from public.fin_cash_files f left join storage.objects o on o.bucket_id='finance-cash-evidence' and o.name=f.path where f.cash_id=c.id;
 perform public.reverse_finance_cash_before_files(p_id,p_version,p_reason);
 select * into after_cash from public.fin_cash_entries where id=p_id;
 insert into public.fin_cash_file_history(id,cash_id,action,snapshot,reason,actor_id) values(gen_random_uuid(),c.id,'Reversed',jsonb_build_object('cash_before',to_jsonb(c),'cash_after',to_jsonb(after_cash),'supplemental_files',files),trim(p_reason),auth.uid());
end$$;
revoke all on function public.cash_evidence_context(uuid),public.attach_cash_evidence(uuid,uuid,integer,jsonb,text,text,text),public.reverse_finance_cash(uuid,integer,text) from public,anon,authenticated;
grant execute on function public.cash_evidence_context(uuid),public.attach_cash_evidence(uuid,uuid,integer,jsonb,text,text,text),public.reverse_finance_cash(uuid,integer,text) to authenticated;
notify pgrst,'reload schema';
commit;
