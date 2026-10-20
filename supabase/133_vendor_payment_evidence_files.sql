begin;
-- Supplemental evidence added after posting. Never rewrite original vendor_payment or infer approval.
create table public.sc_vendor_payment_files(
 id uuid primary key,vendor_payment_id uuid not null references public.sc_vendor_payments,path text not null unique,
 name text not null check(length(name) between 1 and 160),size bigint not null check(size between 1 and 10485760),mime text not null,
 actor_id uuid not null references public.profiles,reason text not null check(length(reason) between 3 and 2000),
 created_at timestamptz not null default now(),request jsonb not null,vendor_payment_snapshot jsonb not null
);
create index vendor_payment_files_vendor_payment on public.sc_vendor_payment_files(vendor_payment_id);
create index vendor_payment_files_actor on public.sc_vendor_payment_files(actor_id);
create table public.sc_vendor_payment_file_history(
 id uuid primary key,vendor_payment_id uuid not null references public.sc_vendor_payments,file_id uuid unique references public.sc_vendor_payment_files,
 action text not null check(action in ('Attached','Reversed')),snapshot jsonb not null,reason text not null,
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now()
);
create index vendor_payment_file_history_vendor_payment on public.sc_vendor_payment_file_history(vendor_payment_id);
create unique index vendor_payment_file_one_reversal on public.sc_vendor_payment_file_history(vendor_payment_id) where action='Reversed';
alter table public.sc_vendor_payment_files enable row level security;alter table public.sc_vendor_payment_file_history enable row level security;
revoke all on public.sc_vendor_payment_files,public.sc_vendor_payment_file_history from public,anon,authenticated;
grant select on public.sc_vendor_payment_files,public.sc_vendor_payment_file_history to authenticated;
create function portal_private.vendor_payment_file_read(p_vendor_payment uuid) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and portal_private.payables_access() and exists(select 1 from public.sc_vendor_payments where id=p_vendor_payment);
$$;
create function portal_private.vendor_payment_file_upload(p_path text) returns boolean language sql stable security definer set search_path='' as $$
 select p_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|png|jpg|jpeg|webp)$' and exists(select 1 from public.sc_vendor_payments c where c.id::text=split_part(p_path,'/',1) and c.reversed_by is null and portal_private.vendor_payment_file_read(c.id) and (select count(*) from public.sc_vendor_payment_files f where f.vendor_payment_id=c.id)<20);
$$;
create function portal_private.vendor_payment_file_object_read(p_path text,p_owner text) returns boolean language sql stable security definer set search_path='' as $$
 select portal_private.payables_access() and (exists(select 1 from public.sc_vendor_payment_files f where f.path=p_path and portal_private.vendor_payment_file_read(f.vendor_payment_id)) or (p_owner=auth.uid()::text and not exists(select 1 from public.sc_vendor_payment_files f where f.path=p_path)));
$$;
create function portal_private.vendor_payment_file_orphan(p_path text) returns boolean language plpgsql security definer set search_path='' as $$
begin if not portal_private.payables_access() then return false;end if;perform pg_advisory_xact_lock(hashtextextended('vendor_payment-proof:'||p_path,0));return not exists(select 1 from public.sc_vendor_payment_files where path=p_path);end$$;
revoke all on function portal_private.vendor_payment_file_read(uuid),portal_private.vendor_payment_file_upload(text),portal_private.vendor_payment_file_object_read(text,text),portal_private.vendor_payment_file_orphan(text) from public,anon,authenticated;
grant execute on function portal_private.vendor_payment_file_read(uuid),portal_private.vendor_payment_file_upload(text),portal_private.vendor_payment_file_object_read(text,text),portal_private.vendor_payment_file_orphan(text) to authenticated;
create policy vendor_payment_file_read on public.sc_vendor_payment_files for select to authenticated using(portal_private.vendor_payment_file_read(vendor_payment_id));
create policy vendor_payment_file_history_read on public.sc_vendor_payment_file_history for select to authenticated using(portal_private.vendor_payment_file_read(vendor_payment_id));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('finance-vendor-payment-evidence','finance-vendor-payment-evidence',false,10485760,array['application/pdf','image/png','image/jpeg','image/webp']);
create policy vendor_payment_proof_upload on storage.objects for insert to authenticated with check(bucket_id='finance-vendor-payment-evidence' and owner_id=auth.uid()::text and portal_private.vendor_payment_file_upload(name));
create policy vendor_payment_proof_read on storage.objects for select to authenticated using(bucket_id='finance-vendor-payment-evidence' and portal_private.vendor_payment_file_object_read(name,owner_id));
create policy vendor_payment_proof_cleanup on storage.objects for delete to authenticated using(bucket_id='finance-vendor-payment-evidence' and portal_private.payables_access() and owner_id=auth.uid()::text and portal_private.vendor_payment_file_orphan(name));
create function portal_private.vendor_payment_file_immutable() returns trigger language plpgsql set search_path='' as $$begin raise exception 'Supplemental vendor payment evidence is immutable';end$$;
revoke all on function portal_private.vendor_payment_file_immutable() from public,anon,authenticated;
create trigger vendor_payment_file_immutable before update or delete on public.sc_vendor_payment_files for each row execute function portal_private.vendor_payment_file_immutable();
create trigger vendor_payment_file_history_immutable before update or delete on public.sc_vendor_payment_file_history for each row execute function portal_private.vendor_payment_file_immutable();
create function public.vendor_payment_evidence_context(p_vendor_payment uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare c public.sc_vendor_payments;files jsonb;history jsonb;
begin
 if not coalesce(portal_private.vendor_payment_file_read(p_vendor_payment),false) then raise exception 'Current Accounts vendor payment evidence access required';end if;
 select * into c from public.sc_vendor_payments where id=p_vendor_payment;
 select coalesce(jsonb_agg(to_jsonb(f)||jsonb_build_object('stored_metadata_matches',coalesce(o.id is not null and o.owner_id=f.actor_id::text and o.metadata->>'size'=f.size::text and o.metadata->>'mimetype'=f.mime,false)) order by f.created_at,f.id),'[]'::jsonb) into files from public.sc_vendor_payment_files f left join storage.objects o on o.bucket_id='finance-vendor-payment-evidence' and o.name=f.path where f.vendor_payment_id=c.id;
 select coalesce(jsonb_agg(to_jsonb(h) order by h.created_at,h.id),'[]'::jsonb) into history from public.sc_vendor_payment_file_history h where h.vendor_payment_id=c.id;
 return jsonb_build_object('vendor_payment_id',c.id,'vendor_payment_snapshot',to_jsonb(c),'version',jsonb_array_length(files),'can_add',c.reversed_by is null and jsonb_array_length(files)<20,'files',files,'history',history);
end$$;
create function public.attach_vendor_payment_evidence(p_id uuid,p_vendor_payment uuid,p_version integer,p_vendor_payment_snapshot jsonb,p_path text,p_name text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare c public.sc_vendor_payments;f public.sc_vendor_payment_files;o storage.objects;req jsonb;ext text;
begin
 if not coalesce(portal_private.vendor_payment_file_read(p_vendor_payment),false) then raise exception 'Current Accounts vendor payment evidence access required';end if;
 if p_id is null or p_path is null or p_name is null or length(trim(p_name)) not between 1 and 160 or p_name ~ '[[:cntrl:]]' or p_name ~ '[/\\]' or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit safe file identity and actual reason required';end if;
 ext:=lower(substring(p_path from '\.([^.]+)$'));
 if ext is null or ext not in ('pdf','png','jpg','jpeg','webp') or p_path is distinct from p_vendor_payment::text||'/'||p_id::text||'.'||ext or lower(substring(p_name from '\.([^.]+)$')) is distinct from ext then raise exception 'Exact vendor payment/file path and matching PDF/image filename required';end if;
 req:=jsonb_build_object('vendor_payment_id',p_vendor_payment,'version',p_version,'vendor_payment_snapshot',p_vendor_payment_snapshot,'path',p_path,'name',trim(p_name),'reason',trim(p_reason));
 perform pg_advisory_xact_lock(hashtextextended('vendor_payment-proof:'||p_path,0));
 select * into c from public.sc_vendor_payments where id=p_vendor_payment for update;
 perform 1 from public.profiles where id=auth.uid() for share;
 perform 1 from public.crm_memberships where user_id=auth.uid() for share;
 if not coalesce(portal_private.vendor_payment_file_read(c.id),false) then raise exception 'Current Accounts vendor payment evidence access required';end if;
 select * into f from public.sc_vendor_payment_files where id=p_id;
 if f.id is not null then if f.actor_id=auth.uid() and f.request=req then return f.id;end if;raise exception 'File identity records different vendor payment evidence or account';end if;
 if c.reversed_by is not null or p_vendor_payment_snapshot is distinct from to_jsonb(c) or p_version is distinct from (select count(*)::integer from public.sc_vendor_payment_files where vendor_payment_id=c.id) or p_version>=20 then raise exception 'Exact unreversed vendor payment snapshot, evidence version and available capacity required';end if;
 select * into o from storage.objects where bucket_id='finance-vendor-payment-evidence' and name=p_path and owner_id=auth.uid()::text for share;
 if o.id is null or coalesce(o.metadata->>'size','') !~ '^[0-9]+$' or (o.metadata->>'size')::numeric not between 1 and 10485760 or o.metadata->>'mimetype' is distinct from (case ext when 'pdf' then 'application/pdf' when 'png' then 'image/png' when 'jpg' then 'image/jpeg' when 'jpeg' then 'image/jpeg' when 'webp' then 'image/webp' end) then raise exception 'Upload actual owned matching PDF/image first';end if;
 insert into public.sc_vendor_payment_files(id,vendor_payment_id,path,name,size,mime,actor_id,reason,request,vendor_payment_snapshot) values(p_id,c.id,p_path,trim(p_name),(o.metadata->>'size')::bigint,o.metadata->>'mimetype',auth.uid(),trim(p_reason),req,to_jsonb(c)) returning * into f;
 insert into public.sc_vendor_payment_file_history(id,vendor_payment_id,file_id,action,snapshot,reason,actor_id) values(p_id,c.id,f.id,'Attached',jsonb_build_object('timing','Supplemental evidence added after posting','vendor_payment',to_jsonb(c),'file',to_jsonb(f),'evidence_version',p_version+1),trim(p_reason),auth.uid());return f.id;
end$$;
alter function public.reverse_vendor_payment(uuid,integer,text) rename to reverse_vendor_payment_before_files;
revoke all on function public.reverse_vendor_payment_before_files(uuid,integer,text) from public,anon,authenticated;
create function public.reverse_vendor_payment(p_payment uuid,p_bill_version integer,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare c public.sc_vendor_payments;files jsonb;after_payment public.sc_vendor_payments;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Administrator required';end if;
 select * into c from public.sc_vendor_payments where id=p_payment;
 if c.id is null then raise exception 'Payment unavailable';end if;
 perform portal_private.bill_lock(c.bill_id,p_bill_version);
 select * into c from public.sc_vendor_payments where id=p_payment for update;
 select coalesce(jsonb_agg(to_jsonb(f)||jsonb_build_object('stored_metadata_matches',coalesce(o.id is not null and o.owner_id=f.actor_id::text and o.metadata->>'size'=f.size::text and o.metadata->>'mimetype'=f.mime,false)) order by f.created_at,f.id),'[]'::jsonb) into files from public.sc_vendor_payment_files f left join storage.objects o on o.bucket_id='finance-vendor-payment-evidence' and o.name=f.path where f.vendor_payment_id=c.id;
 perform public.reverse_vendor_payment_before_files(p_payment,p_bill_version,p_reason);
 select * into after_payment from public.sc_vendor_payments where id=p_payment;
 insert into public.sc_vendor_payment_file_history(id,vendor_payment_id,action,snapshot,reason,actor_id) values(gen_random_uuid(),c.id,'Reversed',jsonb_build_object('vendor_payment_before',to_jsonb(c),'vendor_payment_after',to_jsonb(after_payment),'supplemental_files',files),trim(p_reason),auth.uid());
end$$;
revoke all on function public.vendor_payment_evidence_context(uuid),public.attach_vendor_payment_evidence(uuid,uuid,integer,jsonb,text,text,text),public.reverse_vendor_payment(uuid,integer,text) from public,anon,authenticated;
grant execute on function public.vendor_payment_evidence_context(uuid),public.attach_vendor_payment_evidence(uuid,uuid,integer,jsonb,text,text,text),public.reverse_vendor_payment(uuid,integer,text) to authenticated;
notify pgrst,'reload schema';
commit;
