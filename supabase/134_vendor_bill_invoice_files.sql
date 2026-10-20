begin;
alter table public.sc_bills add column evidence_files uuid[] not null default '{}' check(cardinality(evidence_files)<=10);
create table public.sc_bill_invoice_files(
 id uuid primary key,bill_id uuid not null references public.sc_bills,path text not null unique,
 name text not null check(length(name) between 1 and 160),size bigint not null check(size between 1 and 10485760),mime text not null,
 actor_id uuid not null references public.profiles,reason text not null check(length(reason) between 3 and 2000),created_at timestamptz not null default now()
);
create index bill_invoice_file_bill on public.sc_bill_invoice_files(bill_id);
create index bill_invoice_file_actor on public.sc_bill_invoice_files(actor_id);
create table public.sc_bill_invoice_file_history(
 id uuid primary key,bill_id uuid not null references public.sc_bills,file_id uuid references public.sc_bill_invoice_files,
 bill_version integer not null,action text not null check(action in ('Attached','Excluded','Restored','Matched','Held','Approved','Rework','Cancel')),
 request jsonb not null,snapshot jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(bill_id,bill_version)
);
create index bill_invoice_file_history_file on public.sc_bill_invoice_file_history(file_id);
create index bill_invoice_file_history_actor on public.sc_bill_invoice_file_history(actor_id);
create function portal_private.bill_invoice_file_read(p_bill uuid) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and public.is_staff() and exists(select 1 from public.sc_bills e where e.id=p_bill) and portal_private.payables_access();
$$;
create function portal_private.bill_invoice_file_edit(p_bill uuid) returns boolean language sql stable security definer set search_path='' as $$
 select portal_private.bill_invoice_file_read(p_bill) and exists(select 1 from public.sc_bills e where e.id=p_bill and e.status in ('Draft','Held'));
$$;
create function portal_private.bill_invoice_file_upload(p_path text) returns boolean language sql stable security definer set search_path='' as $$
 select p_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|png|jpg|jpeg|webp)$' and exists(select 1 from public.sc_bills e where e.id::text=split_part(p_path,'/',1) and portal_private.bill_invoice_file_edit(e.id) and cardinality(e.evidence_files)<10 and (select count(*) from public.sc_bill_invoice_files f where f.bill_id=e.id)<20);
$$;
create function portal_private.bill_invoice_file_object_read(p_path text,p_owner text) returns boolean language sql stable security definer set search_path='' as $$
 select portal_private.payables_access() and (exists(select 1 from public.sc_bill_invoice_files f where f.path=p_path and portal_private.bill_invoice_file_read(f.bill_id)) or (p_owner=auth.uid()::text and not exists(select 1 from public.sc_bill_invoice_files f where f.path=p_path)));
$$;
create function portal_private.bill_invoice_file_orphan(p_path text) returns boolean language plpgsql security definer set search_path='' as $$
begin if not portal_private.payables_access() then return false;end if;perform pg_advisory_xact_lock(hashtextextended('bill-invoice-proof:'||p_path,0));return not exists(select 1 from public.sc_bill_invoice_files where path=p_path);end$$;
revoke all on function portal_private.bill_invoice_file_read(uuid),portal_private.bill_invoice_file_edit(uuid),portal_private.bill_invoice_file_upload(text),portal_private.bill_invoice_file_object_read(text,text),portal_private.bill_invoice_file_orphan(text) from public,anon,authenticated;
grant execute on function portal_private.bill_invoice_file_read(uuid),portal_private.bill_invoice_file_upload(text),portal_private.bill_invoice_file_object_read(text,text),portal_private.bill_invoice_file_orphan(text) to authenticated;
alter table public.sc_bill_invoice_files enable row level security;alter table public.sc_bill_invoice_file_history enable row level security;
revoke all on public.sc_bill_invoice_files,public.sc_bill_invoice_file_history from public,anon,authenticated;
grant select on public.sc_bill_invoice_files,public.sc_bill_invoice_file_history to authenticated;
create policy bill_invoice_file_read on public.sc_bill_invoice_files for select to authenticated using(portal_private.bill_invoice_file_read(bill_id));
create policy bill_invoice_file_history_read on public.sc_bill_invoice_file_history for select to authenticated using(portal_private.bill_invoice_file_read(bill_id));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('finance-vendor-bill-evidence','finance-vendor-bill-evidence',false,10485760,array['application/pdf','image/png','image/jpeg','image/webp']);
create policy bill_proof_upload on storage.objects for insert to authenticated with check(bucket_id='finance-vendor-bill-evidence' and owner_id=auth.uid()::text and portal_private.bill_invoice_file_upload(name));
create policy bill_proof_read on storage.objects for select to authenticated using(bucket_id='finance-vendor-bill-evidence' and portal_private.bill_invoice_file_object_read(name,owner_id));
create policy bill_proof_cleanup on storage.objects for delete to authenticated using(bucket_id='finance-vendor-bill-evidence' and portal_private.payables_access() and owner_id=auth.uid()::text and portal_private.bill_invoice_file_orphan(name));
-- No object UPDATE policy; exclusion does not make a registered file an orphan.
create function public.vendor_bill_invoice_context(p_bill uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare e public.sc_bills;files jsonb;history jsonb;
begin
 if not coalesce(portal_private.bill_invoice_file_read(p_bill),false) then raise exception 'Current bill access required';end if;
 select * into e from public.sc_bills where id=p_bill;
 select coalesce(jsonb_agg(to_jsonb(f)||jsonb_build_object('active',f.id=any(e.evidence_files),'stored_metadata_matches',coalesce(o.id is not null and o.owner_id=f.actor_id::text and o.metadata->>'size'=f.size::text and o.metadata->>'mimetype'=f.mime,false)) order by f.created_at,f.id),'[]') into files from public.sc_bill_invoice_files f left join storage.objects o on o.bucket_id='finance-vendor-bill-evidence' and o.name=f.path where f.bill_id=e.id;
 select coalesce(jsonb_agg(to_jsonb(h) order by h.bill_version),'[]') into history from public.sc_bill_invoice_file_history h where h.bill_id=e.id;
 return jsonb_build_object('bill_id',e.id,'version',e.version,'status',e.status,'can_edit',portal_private.bill_invoice_file_edit(e.id),'files',files,'history',history);
end$$;
create function public.attach_vendor_bill_invoice_file(p_id uuid,p_bill uuid,p_version integer,p_path text,p_name text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare e public.sc_bills;old public.sc_bill_invoice_file_history;o storage.objects;f public.sc_bill_invoice_files;req jsonb;ext text;
begin
 if not coalesce(portal_private.bill_invoice_file_read(p_bill),false) then raise exception 'Current bill access required';end if;
 if p_id is null or p_path is null or p_name is null or length(trim(p_name)) not between 1 and 160 or (p_name ~ '[[:cntrl:]]' or p_name ~ '[/\\]') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit file identity, safe filename and actual reason required';end if;
 ext:=lower(substring(p_path from '\.([^.]+)$'));
 if ext is null or ext not in ('pdf','png','jpg','jpeg','webp') or p_path is distinct from p_bill::text||'/'||p_id::text||'.'||ext or lower(substring(p_name from '\.([^.]+)$')) is distinct from ext then raise exception 'Exact bill/file path and matching PDF/image filename required';end if;
 req:=jsonb_build_object('bill_id',p_bill,'version',p_version,'path',p_path,'name',trim(p_name),'reason',trim(p_reason),'action','Attached');
 perform pg_advisory_xact_lock(hashtextextended('bill-invoice-proof:'||p_path,0));
 perform 1 from public.sc_orders where id=(select order_id from public.sc_bills where id=p_bill) for update;
 select * into e from public.sc_bills where id=p_bill for update;
 perform 1 from public.profiles where id=auth.uid() for share;
 perform 1 from public.crm_memberships where user_id=auth.uid() for share;
 if not coalesce(portal_private.bill_invoice_file_read(e.id),false) then raise exception 'Current bill access required';end if;
 select * into old from public.sc_bill_invoice_file_history where id=p_id;
 if old.id is not null then if old.actor_id=auth.uid() and old.request=req then return old.file_id;end if;raise exception 'Receipt request records different content or account';end if;
 if e.version is distinct from p_version or not portal_private.bill_invoice_file_edit(e.id) or cardinality(e.evidence_files)>=10 or (select count(*) from public.sc_bill_invoice_files where bill_id=e.id)>=20 then raise exception 'Exact editable bill version and available receipt capacity required';end if;
 select * into o from storage.objects where bucket_id='finance-vendor-bill-evidence' and name=p_path and owner_id=auth.uid()::text for share;
 if o.id is null or coalesce(o.metadata->>'size','') !~ '^[0-9]+$' or (o.metadata->>'size')::numeric not between 1 and 10485760 or (o.metadata->>'mimetype') is distinct from (case ext when 'pdf' then 'application/pdf' when 'png' then 'image/png' when 'jpg' then 'image/jpeg' when 'jpeg' then 'image/jpeg' when 'webp' then 'image/webp' end) then raise exception 'Upload a valid owned matching PDF/image object first';end if;
 insert into public.sc_bill_invoice_files(id,bill_id,path,name,size,mime,actor_id,reason) values(p_id,e.id,p_path,trim(p_name),(o.metadata->>'size')::bigint,o.metadata->>'mimetype',auth.uid(),trim(p_reason)) returning * into f;
 update public.sc_bills set evidence_files=array_append(evidence_files,f.id),version=version+1 where id=e.id returning * into e;
 insert into public.sc_bill_invoice_file_history(id,bill_id,file_id,bill_version,action,request,snapshot,reason,actor_id) values(p_id,e.id,f.id,e.version,'Attached',req,jsonb_build_object('file',to_jsonb(f),'active_file_ids',e.evidence_files,'bill_version',e.version,'status',e.status),trim(p_reason),auth.uid());
 perform portal_private.bill_audit(e.id,'Invoice file attached',trim(p_reason));return f.id;
end$$;
create function public.change_vendor_bill_invoice_file(p_id uuid,p_file uuid,p_version integer,p_action text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare e public.sc_bills;f public.sc_bill_invoice_files;old public.sc_bill_invoice_file_history;req jsonb;
begin
 select * into f from public.sc_bill_invoice_files where id=p_file;
 if f.id is null or not coalesce(portal_private.bill_invoice_file_read(f.bill_id),false) then raise exception 'Current bill receipt access required';end if;
 if p_id is null or p_action is null or p_action not in ('Excluded','Restored') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit receipt action identity and actual reason required';end if;
 req:=jsonb_build_object('file_id',p_file,'version',p_version,'action',p_action,'reason',trim(p_reason));
 perform 1 from public.sc_orders where id=(select order_id from public.sc_bills where id=f.bill_id) for update;
 select * into e from public.sc_bills where id=f.bill_id for update;
 perform 1 from public.profiles where id=auth.uid() for share;
 perform 1 from public.crm_memberships where user_id=auth.uid() for share;
 if not coalesce(portal_private.bill_invoice_file_read(e.id),false) then raise exception 'Current bill access required';end if;
 select * into old from public.sc_bill_invoice_file_history where id=p_id;
 if old.id is not null then if old.actor_id=auth.uid() and old.request=req then return old.id;end if;raise exception 'Receipt request records different content or account';end if;
 if e.version is distinct from p_version or not portal_private.bill_invoice_file_edit(e.id) then raise exception 'Exact editable bill version required';end if;
 if p_action='Excluded' then
  if not(f.id=any(e.evidence_files)) then raise exception 'Receipt is already excluded';end if;
  update public.sc_bills set evidence_files=array_remove(evidence_files,f.id),version=version+1 where id=e.id returning * into e;
 else
  if f.id=any(e.evidence_files) or cardinality(e.evidence_files)>=10 then raise exception 'Excluded receipt and available capacity required';end if;
  perform 1 from storage.objects o where o.bucket_id='finance-vendor-bill-evidence' and o.name=f.path and o.owner_id=f.actor_id::text and o.metadata->>'size'=f.size::text and o.metadata->>'mimetype'=f.mime for share;
  if not found then raise exception 'Original intact registered receipt required for restoration';end if;
  update public.sc_bills set evidence_files=array_append(evidence_files,f.id),version=version+1 where id=e.id returning * into e;
 end if;
 insert into public.sc_bill_invoice_file_history(id,bill_id,file_id,bill_version,action,request,snapshot,reason,actor_id) values(p_id,e.id,f.id,e.version,p_action,req,jsonb_build_object('file',to_jsonb(f),'active_file_ids',e.evidence_files,'bill_version',e.version,'status',e.status),trim(p_reason),auth.uid());
 perform portal_private.bill_audit(e.id,'Invoice file '||lower(p_action),trim(p_reason));return p_id;
end$$;
alter function public.vendor_bill_action(uuid,integer,text,text) rename to vendor_bill_action_before_invoice_files;
revoke all on function public.vendor_bill_action_before_invoice_files(uuid,integer,text,text) from public,anon,authenticated;
create function public.vendor_bill_action(p_bill uuid,p_version integer,p_action text,p_note text default '') returns void language plpgsql security definer set search_path='' as $$
declare e public.sc_bills;before_bill public.sc_bills;files jsonb;matched public.sc_bill_invoice_file_history;allocations jsonb;
begin
 if not coalesce(portal_private.bill_invoice_file_read(p_bill),false) then raise exception 'Current bill invoice access required';end if;
 before_bill:=portal_private.bill_lock(p_bill,p_version);
 perform 1 from public.profiles where id=auth.uid() for share;
 perform 1 from public.crm_memberships where user_id=auth.uid() for share;
 if not coalesce(portal_private.bill_invoice_file_read(p_bill),false) then raise exception 'Current bill invoice access required';end if;
 if p_action in ('Match','Approve') then
  perform 1 from public.sc_bill_invoice_files f join storage.objects o on o.bucket_id='finance-vendor-bill-evidence' and o.name=f.path where f.id=any(before_bill.evidence_files) for share of f,o;
  if exists(select 1 from unnest(before_bill.evidence_files) i(id) left join public.sc_bill_invoice_files f on f.id=i.id left join storage.objects o on o.bucket_id='finance-vendor-bill-evidence' and o.name=f.path where f.id is null or f.bill_id<>before_bill.id or o.id is null or o.owner_id is distinct from f.actor_id::text or o.metadata->>'size' is distinct from f.size::text or o.metadata->>'mimetype' is distinct from f.mime) then raise exception 'Resolve missing or changed active invoice evidence before matching/approval';end if;
  if p_action='Approve' then
   select * into matched from public.sc_bill_invoice_file_history where bill_id=before_bill.id and action='Matched' order by bill_version desc limit 1;
   if matched.id is null then
    if cardinality(before_bill.evidence_files)>0 then raise exception 'Current frozen invoice match receipt required';end if;
   elsif matched.bill_version<>before_bill.version or matched.snapshot->'bill' is distinct from to_jsonb(before_bill) or matched.snapshot->'active_file_ids' is distinct from to_jsonb(before_bill.evidence_files) then raise exception 'Current frozen invoice match receipt required';end if;
  end if;
 end if;
 select coalesce(jsonb_agg(to_jsonb(f)||jsonb_build_object('active',f.id=any(before_bill.evidence_files),'stored_metadata_matches',coalesce(o.id is not null and o.owner_id=f.actor_id::text and o.metadata->>'size'=f.size::text and o.metadata->>'mimetype'=f.mime,false)) order by f.id),'[]') into files from public.sc_bill_invoice_files f left join storage.objects o on o.bucket_id='finance-vendor-bill-evidence' and o.name=f.path where f.bill_id=before_bill.id;
 select coalesce(jsonb_agg(to_jsonb(l) order by l.id),'[]') into allocations from public.sc_bill_receipts l where l.bill_id=before_bill.id;
 perform public.vendor_bill_action_before_invoice_files(p_bill,p_version,p_action,p_note);
 select * into e from public.sc_bills where id=p_bill;
 insert into public.sc_bill_invoice_file_history(id,bill_id,bill_version,action,request,snapshot,reason,actor_id) values(gen_random_uuid(),e.id,e.version,case when p_action='Match' then e.status when p_action='Approve' then 'Approved' else p_action end,jsonb_build_object('version',p_version,'action',p_action,'note',p_note),jsonb_build_object('bill_before',to_jsonb(before_bill),'bill',to_jsonb(e),'bill_receipts',allocations,'active_file_ids',e.evidence_files,'files',files,'bill_version',e.version,'status',e.status,'matched_receipt_id',matched.id,'legacy_text_match',p_action='Approve' and matched.id is null),coalesce(p_note,''),auth.uid());
end$$;
revoke all on function public.vendor_bill_invoice_context(uuid),public.attach_vendor_bill_invoice_file(uuid,uuid,integer,text,text,text),public.change_vendor_bill_invoice_file(uuid,uuid,integer,text,text),public.vendor_bill_action(uuid,integer,text,text) from public,anon,authenticated;
grant execute on function public.vendor_bill_invoice_context(uuid),public.attach_vendor_bill_invoice_file(uuid,uuid,integer,text,text,text),public.change_vendor_bill_invoice_file(uuid,uuid,integer,text,text),public.vendor_bill_action(uuid,integer,text,text) to authenticated;
create function portal_private.bill_invoice_file_immutable() returns trigger language plpgsql set search_path='' as $$begin raise exception 'Vendor bill invoice file evidence is immutable';end$$;
revoke all on function portal_private.bill_invoice_file_immutable() from public,anon,authenticated;
create trigger bill_invoice_file_immutable before update or delete on public.sc_bill_invoice_files for each row execute function portal_private.bill_invoice_file_immutable();
create trigger bill_invoice_file_history_immutable before update or delete on public.sc_bill_invoice_file_history for each row execute function portal_private.bill_invoice_file_immutable();
notify pgrst,'reload schema';
commit;
