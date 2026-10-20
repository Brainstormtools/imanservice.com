begin;
alter table public.payment_claims add column receipt_version integer not null default 1 check(receipt_version>0);
alter table public.payment_claims add column evidence_files uuid[] not null default '{}' check(cardinality(evidence_files)<=10);
create table public.billing_payment_files(
 id uuid primary key,payment_id uuid not null references public.payment_claims,path text not null unique,
 name text not null check(length(name) between 1 and 160),size bigint not null check(size between 1 and 10485760),mime text not null,
 actor_id uuid not null references public.profiles,reason text not null check(length(reason) between 3 and 2000),created_at timestamptz not null default now()
);
create index customer_receipt_payment on public.billing_payment_files(payment_id);
create index customer_receipt_actor on public.billing_payment_files(actor_id);
create table public.billing_payment_file_history(
 id uuid primary key,payment_id uuid not null references public.payment_claims,file_id uuid references public.billing_payment_files,
 receipt_version integer not null,action text not null check(action in ('Attached','Excluded','Restored','Verified','Rejected','Reversed')),
 request jsonb not null,snapshot jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(payment_id,receipt_version)
);
create index customer_receipt_history_file on public.billing_payment_file_history(file_id);
create index customer_receipt_history_actor on public.billing_payment_file_history(actor_id);
create function portal_private.customer_receipt_read(p_payment uuid) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from public.payment_claims e where e.id=p_payment and public.can_invoice(e.invoice_id));
$$;
create function portal_private.customer_receipt_edit(p_payment uuid) returns boolean language sql stable security definer set search_path='' as $$
 select portal_private.customer_receipt_read(p_payment) and exists(select 1 from public.payment_claims e where e.id=p_payment and e.status='Pending' and (e.submitted_by=auth.uid() or public.is_admin()) and exists(select 1 from public.invoices i where i.id=e.invoice_id and i.status='Issued'));
$$;
create function portal_private.customer_receipt_upload(p_path text) returns boolean language sql stable security definer set search_path='' as $$
 select p_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|png|jpg|jpeg|webp)$' and exists(select 1 from public.payment_claims e where e.id::text=split_part(p_path,'/',1) and portal_private.customer_receipt_edit(e.id) and cardinality(e.evidence_files)<10 and (select count(*) from public.billing_payment_files f where f.payment_id=e.id)<20);
$$;
create function portal_private.customer_receipt_object_read(p_path text,p_owner text) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.billing_payment_files f where f.path=p_path and portal_private.customer_receipt_read(f.payment_id)) or (p_owner=auth.uid()::text and exists(select 1 from public.payment_claims c where c.id::text=split_part(p_path,'/',1) and portal_private.customer_receipt_read(c.id) and (c.submitted_by=auth.uid() or public.is_admin())) and not exists(select 1 from public.billing_payment_files f where f.path=p_path));
$$;
create function portal_private.customer_receipt_orphan(p_path text) returns boolean language plpgsql security definer set search_path='' as $$
begin if not exists(select 1 from public.payment_claims c where c.id::text=split_part(p_path,'/',1) and portal_private.customer_receipt_read(c.id) and (c.submitted_by=auth.uid() or public.is_admin())) then return false;end if;perform pg_advisory_xact_lock(hashtextextended('customer-receipt-proof:'||p_path,0));return not exists(select 1 from public.billing_payment_files where path=p_path);end$$;
revoke all on function portal_private.customer_receipt_read(uuid),portal_private.customer_receipt_edit(uuid),portal_private.customer_receipt_upload(text),portal_private.customer_receipt_object_read(text,text),portal_private.customer_receipt_orphan(text) from public,anon,authenticated;
grant execute on function portal_private.customer_receipt_read(uuid),portal_private.customer_receipt_upload(text),portal_private.customer_receipt_object_read(text,text),portal_private.customer_receipt_orphan(text) to authenticated;
alter table public.billing_payment_files enable row level security;alter table public.billing_payment_file_history enable row level security;
revoke all on public.billing_payment_files,public.billing_payment_file_history from public,anon,authenticated;
grant select on public.billing_payment_files,public.billing_payment_file_history to authenticated;
create policy customer_receipt_read on public.billing_payment_files for select to authenticated using(portal_private.customer_receipt_read(payment_id));
create policy customer_receipt_history_read on public.billing_payment_file_history for select to authenticated using(portal_private.customer_receipt_read(payment_id));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('billing-payment-evidence','billing-payment-evidence',false,10485760,array['application/pdf','image/png','image/jpeg','image/webp']);
create policy payment_proof_upload on storage.objects for insert to authenticated with check(bucket_id='billing-payment-evidence' and owner_id=auth.uid()::text and portal_private.customer_receipt_upload(name));
create policy payment_proof_read on storage.objects for select to authenticated using(bucket_id='billing-payment-evidence' and portal_private.customer_receipt_object_read(name,owner_id));
create policy payment_proof_cleanup on storage.objects for delete to authenticated using(bucket_id='billing-payment-evidence' and owner_id=auth.uid()::text and portal_private.customer_receipt_orphan(name));
-- No object UPDATE policy; exclusion does not make a registered file an orphan.
create function public.customer_payment_receipt_context(p_payment uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare e public.payment_claims;files jsonb;history jsonb;
begin
 if not coalesce(portal_private.customer_receipt_read(p_payment),false) then raise exception 'Current payment access required';end if;
 select * into e from public.payment_claims where id=p_payment;
 select coalesce(jsonb_agg(to_jsonb(f)||jsonb_build_object('active',f.id=any(e.evidence_files),'stored_metadata_matches',coalesce(o.id is not null and o.owner_id=f.actor_id::text and o.metadata->>'size'=f.size::text and o.metadata->>'mimetype'=f.mime,false)) order by f.created_at,f.id),'[]') into files from public.billing_payment_files f left join storage.objects o on o.bucket_id='billing-payment-evidence' and o.name=f.path where f.payment_id=e.id;
 select coalesce(jsonb_agg(to_jsonb(h) order by h.receipt_version),'[]') into history from public.billing_payment_file_history h where h.payment_id=e.id;
 return jsonb_build_object('payment_id',e.id,'version',e.receipt_version,'claim_snapshot',to_jsonb(e),'status',e.status,'can_edit',portal_private.customer_receipt_edit(e.id),'files',files,'history',history);
end$$;
create function public.attach_customer_payment_receipt_file(p_id uuid,p_payment uuid,p_version integer,p_path text,p_name text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare e public.payment_claims;old public.billing_payment_file_history;o storage.objects;f public.billing_payment_files;req jsonb;ext text;
begin
 if not coalesce(portal_private.customer_receipt_read(p_payment),false) then raise exception 'Current payment access required';end if;
 if p_id is null or p_path is null or p_name is null or length(trim(p_name)) not between 1 and 160 or (p_name ~ '[[:cntrl:]]' or p_name ~ '[/\\]') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit file identity, safe filename and actual reason required';end if;
 ext:=lower(substring(p_path from '\.([^.]+)$'));
 if ext is null or ext not in ('pdf','png','jpg','jpeg','webp') or p_path is distinct from p_payment::text||'/'||p_id::text||'.'||ext or lower(substring(p_name from '\.([^.]+)$')) is distinct from ext then raise exception 'Exact payment/file path and matching PDF/image filename required';end if;
 req:=jsonb_build_object('payment_id',p_payment,'version',p_version,'path',p_path,'name',trim(p_name),'reason',trim(p_reason),'action','Attached');
 perform pg_advisory_xact_lock(hashtextextended('customer-receipt-proof:'||p_path,0));
 perform 1 from public.invoices where id=(select invoice_id from public.payment_claims where id=p_payment) for update;
 select * into e from public.payment_claims where id=p_payment for update;
 perform 1 from public.profiles where id=auth.uid() for share;
 perform 1 from public.crm_memberships where user_id=auth.uid() for share;
 if not coalesce(portal_private.customer_receipt_read(e.id),false) then raise exception 'Current payment access required';end if;
 select * into old from public.billing_payment_file_history where id=p_id;
 if old.id is not null then if old.actor_id=auth.uid() and old.request=req then return old.file_id;end if;raise exception 'Receipt request records different content or account';end if;
 if e.receipt_version is distinct from p_version or not portal_private.customer_receipt_edit(e.id) or cardinality(e.evidence_files)>=10 or (select count(*) from public.billing_payment_files where payment_id=e.id)>=20 then raise exception 'Exact editable payment version and available receipt capacity required';end if;
 select * into o from storage.objects where bucket_id='billing-payment-evidence' and name=p_path and owner_id=auth.uid()::text for share;
 if o.id is null or coalesce(o.metadata->>'size','') !~ '^[0-9]+$' or (o.metadata->>'size')::numeric not between 1 and 10485760 or (o.metadata->>'mimetype') is distinct from (case ext when 'pdf' then 'application/pdf' when 'png' then 'image/png' when 'jpg' then 'image/jpeg' when 'jpeg' then 'image/jpeg' when 'webp' then 'image/webp' end) then raise exception 'Upload a valid owned matching PDF/image object first';end if;
 insert into public.billing_payment_files(id,payment_id,path,name,size,mime,actor_id,reason) values(p_id,e.id,p_path,trim(p_name),(o.metadata->>'size')::bigint,o.metadata->>'mimetype',auth.uid(),trim(p_reason)) returning * into f;
 update public.payment_claims set evidence_files=array_append(evidence_files,f.id),receipt_version=receipt_version+1 where id=e.id returning * into e;
 insert into public.billing_payment_file_history(id,payment_id,file_id,receipt_version,action,request,snapshot,reason,actor_id) values(p_id,e.id,f.id,e.receipt_version,'Attached',req,jsonb_build_object('file',to_jsonb(f),'active_file_ids',e.evidence_files,'receipt_version',e.receipt_version,'status',e.status),trim(p_reason),auth.uid());
 insert into public.billing_events(invoice_id,action,detail) values(e.invoice_id,'Receipt file attached',e.id::text);return f.id;
end$$;
create function public.change_customer_payment_receipt_file(p_id uuid,p_file uuid,p_version integer,p_action text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare e public.payment_claims;f public.billing_payment_files;old public.billing_payment_file_history;req jsonb;
begin
 select * into f from public.billing_payment_files where id=p_file;
 if f.id is null or not coalesce(portal_private.customer_receipt_read(f.payment_id),false) then raise exception 'Current payment receipt access required';end if;
 if p_id is null or p_action is null or p_action not in ('Excluded','Restored') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit receipt action identity and actual reason required';end if;
 req:=jsonb_build_object('file_id',p_file,'version',p_version,'action',p_action,'reason',trim(p_reason));
 perform 1 from public.invoices where id=(select invoice_id from public.payment_claims where id=f.payment_id) for update;
 select * into e from public.payment_claims where id=f.payment_id for update;
 perform 1 from public.profiles where id=auth.uid() for share;
 perform 1 from public.crm_memberships where user_id=auth.uid() for share;
 if not coalesce(portal_private.customer_receipt_read(e.id),false) then raise exception 'Current payment access required';end if;
 select * into old from public.billing_payment_file_history where id=p_id;
 if old.id is not null then if old.actor_id=auth.uid() and old.request=req then return old.id;end if;raise exception 'Receipt request records different content or account';end if;
 if e.receipt_version is distinct from p_version or not portal_private.customer_receipt_edit(e.id) then raise exception 'Exact editable payment version required';end if;
 if p_action='Excluded' then
  if not(f.id=any(e.evidence_files)) then raise exception 'Receipt is already excluded';end if;
  update public.payment_claims set evidence_files=array_remove(evidence_files,f.id),receipt_version=receipt_version+1 where id=e.id returning * into e;
 else
  if f.id=any(e.evidence_files) or cardinality(e.evidence_files)>=10 then raise exception 'Excluded receipt and available capacity required';end if;
  perform 1 from storage.objects o where o.bucket_id='billing-payment-evidence' and o.name=f.path and o.owner_id=f.actor_id::text and o.metadata->>'size'=f.size::text and o.metadata->>'mimetype'=f.mime for share;
  if not found then raise exception 'Original intact registered receipt required for restoration';end if;
  update public.payment_claims set evidence_files=array_append(evidence_files,f.id),receipt_version=receipt_version+1 where id=e.id returning * into e;
 end if;
 insert into public.billing_payment_file_history(id,payment_id,file_id,receipt_version,action,request,snapshot,reason,actor_id) values(p_id,e.id,f.id,e.receipt_version,p_action,req,jsonb_build_object('file',to_jsonb(f),'active_file_ids',e.evidence_files,'receipt_version',e.receipt_version,'status',e.status),trim(p_reason),auth.uid());
 insert into public.billing_events(invoice_id,action,detail) values(e.invoice_id,'Receipt file '||lower(p_action),e.id::text);return p_id;
end$$;
alter function public.review_payment(uuid,text,text) rename to review_payment_before_receipt_files;
revoke all on function public.review_payment_before_receipt_files(uuid,text,text) from public,anon,authenticated;
create function public.review_payment(p_payment uuid,p_version integer,p_payment_snapshot jsonb,p_action text,p_note text) returns void language plpgsql security definer set search_path='' as $$
declare e public.payment_claims;before_claim public.payment_claims;i public.invoices;files jsonb;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required';end if;
 select * into before_claim from public.payment_claims where id=p_payment;
 if before_claim.id is null then raise exception 'Payment unavailable';end if;
 select * into i from public.invoices where id=before_claim.invoice_id for update;
 select * into before_claim from public.payment_claims where id=p_payment for update;
 perform 1 from public.profiles where id=auth.uid() for share;
 if not public.is_admin() then raise exception 'Administrator access required';end if;
 if p_version is distinct from before_claim.receipt_version or p_payment_snapshot is distinct from to_jsonb(before_claim) then raise exception 'Exact current payment claim and receipt version required; refresh receipts';end if;
 if p_action='verify' then
  perform 1 from public.billing_payment_files f join storage.objects o on o.bucket_id='billing-payment-evidence' and o.name=f.path where f.id=any(before_claim.evidence_files) for share of f,o;
  if exists(select 1 from unnest(before_claim.evidence_files) x(id) left join public.billing_payment_files f on f.id=x.id left join storage.objects o on o.bucket_id='billing-payment-evidence' and o.name=f.path where f.id is null or f.payment_id<>before_claim.id or o.id is null or o.owner_id is distinct from f.actor_id::text or o.metadata->>'size' is distinct from f.size::text or o.metadata->>'mimetype' is distinct from f.mime) then raise exception 'Resolve missing or changed active payment receipt evidence before verification';end if;
 end if;
 select coalesce(jsonb_agg(to_jsonb(f)||jsonb_build_object('active',f.id=any(before_claim.evidence_files),'stored_metadata_matches',coalesce(o.id is not null and o.owner_id=f.actor_id::text and o.metadata->>'size'=f.size::text and o.metadata->>'mimetype'=f.mime,false)) order by f.id),'[]') into files from public.billing_payment_files f left join storage.objects o on o.bucket_id='billing-payment-evidence' and o.name=f.path where f.payment_id=before_claim.id;
 perform public.review_payment_before_receipt_files(p_payment,p_action,p_note);
 update public.payment_claims set receipt_version=receipt_version+1 where id=p_payment returning * into e;
 insert into public.billing_payment_file_history(id,payment_id,receipt_version,action,request,snapshot,reason,actor_id) values(gen_random_uuid(),e.id,e.receipt_version,case p_action when 'verify' then 'Verified' when 'reject' then 'Rejected' else 'Reversed' end,jsonb_build_object('version',p_version,'action',p_action,'note',p_note),jsonb_build_object('claim_before',to_jsonb(before_claim),'claim',to_jsonb(e),'invoice',jsonb_build_object('id',i.id,'number',i.number,'company_id',i.company_id,'currency',i.currency,'total',i.total,'status',i.status),'active_file_ids',e.evidence_files,'files',files,'receipt_version',e.receipt_version,'status',e.status),coalesce(p_note,''),auth.uid());
end$$;
revoke all on function public.customer_payment_receipt_context(uuid),public.attach_customer_payment_receipt_file(uuid,uuid,integer,text,text,text),public.change_customer_payment_receipt_file(uuid,uuid,integer,text,text),public.review_payment(uuid,integer,jsonb,text,text) from public,anon,authenticated;
grant execute on function public.customer_payment_receipt_context(uuid),public.attach_customer_payment_receipt_file(uuid,uuid,integer,text,text,text),public.change_customer_payment_receipt_file(uuid,uuid,integer,text,text),public.review_payment(uuid,integer,jsonb,text,text) to authenticated;
create function portal_private.customer_receipt_immutable() returns trigger language plpgsql set search_path='' as $$begin raise exception 'Customer payment receipt file evidence is immutable';end$$;
revoke all on function portal_private.customer_receipt_immutable() from public,anon,authenticated;
create trigger customer_receipt_immutable before update or delete on public.billing_payment_files for each row execute function portal_private.customer_receipt_immutable();
create trigger customer_receipt_history_immutable before update or delete on public.billing_payment_file_history for each row execute function portal_private.customer_receipt_immutable();
notify pgrst,'reload schema';
commit;
