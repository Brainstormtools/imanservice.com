begin;
-- Actual client requests and explicitly designated Owner/Director approval only. No payout or credit reservation.
create table public.fin_refund_approver_designations(
 id uuid primary key,user_id uuid not null references public.profiles,revision integer not null check(revision>0),
 authority text not null check(authority in ('Owner','Director')),active boolean not null,reason text not null check(length(trim(reason)) between 3 and 2000),
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(user_id,revision)
);
create index refund_approver_actor on public.fin_refund_approver_designations(actor_id);
create table public.fin_client_refund_requests(
 id uuid primary key,origin_id uuid not null references public.crm_boq_credit_postings,company_id uuid not null references public.companies,
 amount numeric(14,2) not null check(amount>0 and amount<100000000),reason text not null check(length(trim(reason)) between 3 and 2000),
 request jsonb not null,receipt jsonb not null,requested_by uuid not null references public.profiles,requested_at timestamptz not null default now()
);
create index client_refund_origin on public.fin_client_refund_requests(origin_id);
create index client_refund_company on public.fin_client_refund_requests(company_id);
create index client_refund_actor on public.fin_client_refund_requests(requested_by);
create table public.fin_client_refund_reviews(
 id uuid primary key default gen_random_uuid(),request_id uuid not null unique references public.fin_client_refund_requests,
 outcome text not null check(outcome in ('Approved','Returned','Withdrawn')),designation_id uuid references public.fin_refund_approver_designations,
 reason text not null check(length(trim(reason)) between 3 and 2000),receipt jsonb not null,
 reviewed_by uuid not null references public.profiles,reviewed_at timestamptz not null default now(),
 check((outcome='Withdrawn')=(designation_id is null))
);
create index client_refund_review_actor on public.fin_client_refund_reviews(reviewed_by);
create index client_refund_review_designation on public.fin_client_refund_reviews(designation_id);
create function portal_private.refund_approver(p_user uuid) returns uuid language sql stable security definer set search_path='' as $$
 select d.id from public.fin_refund_approver_designations d join public.profiles p on p.id=d.user_id where d.user_id=p_user and d.active and p.active and p.role in ('admin','team')
 and not exists(select 1 from public.fin_refund_approver_designations n where n.user_id=d.user_id and n.revision>d.revision);
$$;
create function portal_private.refund_access() returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and (portal_private.payables_access() or portal_private.refund_approver(auth.uid()) is not null);
$$;
do $$declare t text;begin
 foreach t in array array['fin_refund_approver_designations','fin_client_refund_requests','fin_client_refund_reviews'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on public.%I from public,anon,authenticated',t);
  execute format('grant select on public.%I to authenticated',t);
  execute format('create trigger refund_evidence_immutable before update or delete on public.%I for each row execute function portal_private.boq_line_evidence_immutable()',t);
 end loop;
end$$;
create policy refund_designation_admin_read on public.fin_refund_approver_designations for select to authenticated using(public.is_admin());
create policy refund_request_internal_read on public.fin_client_refund_requests for select to authenticated using(portal_private.refund_access());
create policy refund_review_internal_read on public.fin_client_refund_reviews for select to authenticated using(portal_private.refund_access());
create function public.client_refund_access() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare p public.profiles;
begin
 select * into p from public.profiles where id=auth.uid() and active;
 if p.id is null then raise exception 'Current active account required';end if;
 return jsonb_build_object('client',p.role='client' and p.company_id is not null,'internal',portal_private.refund_access(),'approver_id',portal_private.refund_approver(p.id),'configure',public.is_admin())
 ||case when public.is_admin() then jsonb_build_object('people',coalesce((select jsonb_agg(jsonb_build_object('id',person.id,'name',person.name,'active',person.active) order by person.name,person.id) from public.profiles person where (person.active and person.role in ('admin','team')) or exists(select 1 from public.fin_refund_approver_designations d where d.user_id=person.id)),'[]'::jsonb),'designation_history',coalesce((select jsonb_agg(to_jsonb(d) order by user_id,revision) from public.fin_refund_approver_designations d),'[]'::jsonb)) else '{}'::jsonb end;
end$$;
create function public.set_client_refund_approver(p_id uuid,p_user uuid,p_previous integer,p_authority text,p_active boolean,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare old public.fin_refund_approver_designations;latest integer;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Current administrator designation required';end if;
 if p_id is null or p_user is null or p_previous is null or p_previous<0 or p_active is null or p_authority is null or p_authority not in ('Owner','Director') or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Actual account, prior revision, Owner/Director authority, action and reason required';end if;
 perform 1 from public.profiles where id=p_user for update;
 if not found or (p_active and not exists(select 1 from public.profiles where id=p_user and active and role in ('admin','team'))) then raise exception 'Actual active internal Owner/Director account required for a grant';end if;
 select * into old from public.fin_refund_approver_designations where id=p_id;
 if old.id is not null then
  if old.user_id=p_user and old.revision=p_previous+1 and old.authority=p_authority and old.active=p_active and old.reason=trim(p_reason) and old.actor_id=auth.uid() then return old.id;end if;
  raise exception 'Designation ID already has different immutable evidence';
 end if;
 select coalesce(max(revision),0) into latest from public.fin_refund_approver_designations where user_id=p_user;
 if latest<>p_previous or (latest=0 and not p_active) then raise exception 'Exact prior refund designation revision required';end if;
 insert into public.fin_refund_approver_designations(id,user_id,revision,authority,active,reason,actor_id) values(p_id,p_user,latest+1,p_authority,p_active,trim(p_reason),auth.uid());return p_id;
end$$;
create function portal_private.refund_credit_basis(p_origin uuid) returns jsonb language plpgsql set search_path='' as $$
declare b public.crm_boq_credit_postings;used numeric;apps jsonb;
begin
 select * into b from public.crm_boq_credit_postings where id=p_origin;
 if b.id is null or b.client_credit<=0 then raise exception 'Actual issued carried client credit required';end if;
 select coalesce(sum(amount),0),coalesce(jsonb_agg(jsonb_build_object('id',id,'invoice_id',invoice_id,'amount',amount,'applied_at',applied_at) order by id),'[]'::jsonb) into used,apps from public.fin_client_credit_applications where origin_id=b.id;
 return jsonb_build_object('origin_id',b.id,'company_id',b.company_id,'credit_number',(select number from public.credit_notes where id=b.credit_note_id),'original_invoice_number',(select number from public.invoices where id=b.invoice_id),'currency','PKR','created',b.client_credit,'available',b.client_credit-used,'applications',apps);
end$$;
create function public.request_client_refund(p_id uuid,p_origin uuid,p_amount numeric,p_expected jsonb,p_confirm boolean,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare p public.profiles;b public.crm_boq_credit_postings;old public.fin_client_refund_requests;s jsonb;req jsonb;
begin
 select * into p from public.profiles where id=auth.uid() and active and role='client';
 select * into b from public.crm_boq_credit_postings where id=p_origin;
 if p.id is null or b.id is null or b.company_id is distinct from p.company_id or not public.can_invoice(b.invoice_id) then raise exception 'Actual active own-company client request required';end if;
 if p_id is null or p_confirm is distinct from true or p_amount is null or p_amount<=0 or p_amount>=100000000 or p_amount<>round(p_amount,2) or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Explicit cash-refund request, cent-precision amount and actual reason required';end if;
 req:=jsonb_build_object('origin',p_origin,'amount',p_amount,'expected',p_expected,'confirmed',p_confirm,'reason',trim(p_reason));
 select * into old from public.fin_client_refund_requests where id=p_id;
 if old.id is not null then
  if old.request=req and old.requested_by=p.id then return old.id;end if;raise exception 'Request ID already has different immutable evidence';
 end if;
 perform 1 from public.companies where id=b.company_id for update;
 s:=portal_private.refund_credit_basis(b.id);
 if s is distinct from p_expected or p_amount>(s->>'available')::numeric then raise exception 'Current available client credit changed; reload request evidence';end if;
 if exists(select 1 from public.fin_client_refund_requests r left join public.fin_client_refund_reviews v on v.request_id=r.id where r.origin_id=b.id and (v.id is null or (v.outcome='Approved' and v.receipt->'expected'->'credit'=s))) then raise exception 'An unresolved or approved request already exists for this credit';end if;
 insert into public.fin_client_refund_requests(id,origin_id,company_id,amount,reason,request,receipt,requested_by)
 values(p_id,b.id,b.company_id,p_amount,trim(p_reason),req,jsonb_build_object('credit',s,'actual_account',p.id,'account_name',p.name,'confirmed',true,'effect','Request only; no cash payout or credit reservation'),p.id);return p_id;
end$$;
create function public.preview_client_refund_review(p_request uuid,p_designation uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.fin_client_refund_requests;s jsonb;
begin
 if auth.uid() is null or p_designation is null or portal_private.refund_approver(auth.uid()) is distinct from p_designation then raise exception 'Current explicitly designated Owner/Director required';end if;
 select * into r from public.fin_client_refund_requests where id=p_request;
 if r.id is null then raise exception 'Actual refund request required';end if;
 perform 1 from public.companies where id=r.company_id for update;
 if exists(select 1 from public.fin_client_refund_reviews where request_id=r.id) then raise exception 'Request already has a terminal decision';end if;
 if not exists(select 1 from public.profiles where id=r.requested_by and active and role='client' and company_id=r.company_id) then raise exception 'Requesting client is no longer eligible';end if;
 s:=portal_private.refund_credit_basis(r.origin_id);
 if r.amount>(s->>'available')::numeric then raise exception 'Requested amount exceeds current available credit';end if;
 return jsonb_build_object('request',to_jsonb(r),'credit',s,'designation',(select to_jsonb(d) from public.fin_refund_approver_designations d where id=p_designation),'effect','Approval only; no payout or credit reservation');
end$$;
create function public.review_client_refund(p_request uuid,p_designation uuid,p_expected jsonb,p_outcome text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare r public.fin_client_refund_requests;old public.fin_client_refund_reviews;s jsonb;result uuid;
begin
 if auth.uid() is null or portal_private.refund_approver(auth.uid()) is distinct from p_designation or p_designation is null then raise exception 'Current explicitly designated Owner/Director required';end if;
 if p_outcome is null or p_outcome not in ('Approved','Returned') or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Actual approval/return decision and reason required';end if;
 select * into r from public.fin_client_refund_requests where id=p_request;
 if r.id is null then raise exception 'Actual refund request required';end if;
 perform 1 from public.companies where id=r.company_id for update;
 select * into old from public.fin_client_refund_reviews where request_id=r.id;
 if old.id is not null then
  if old.outcome=p_outcome and old.reason=trim(p_reason) and old.reviewed_by=auth.uid() and old.designation_id=p_designation and old.receipt->'expected'=p_expected then return old.id;end if;raise exception 'Request decision is immutable';
 end if;
 if p_outcome='Approved' then s:=public.preview_client_refund_review(p_request,p_designation);
  if s is distinct from p_expected then raise exception 'Exact current request/credit evidence required';end if;
 else
  if p_expected->'request' is distinct from to_jsonb(r) then raise exception 'Exact returned request evidence required';end if;
  s:=p_expected;
 end if;
 insert into public.fin_client_refund_reviews(request_id,outcome,designation_id,reason,receipt,reviewed_by)
 values(r.id,p_outcome,p_designation,trim(p_reason),jsonb_build_object('expected',s,'designation',(select to_jsonb(d) from public.fin_refund_approver_designations d where id=p_designation),'effect','Decision only; no cash payout or credit reservation'),auth.uid()) returning id into result;return result;
end$$;
create function public.withdraw_client_refund(p_request uuid,p_expected jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare r public.fin_client_refund_requests;v public.fin_client_refund_reviews;result uuid;
begin
 select r0.* into r from public.fin_client_refund_requests r0 join public.profiles p on p.id=auth.uid() and p.active and p.role='client' and p.company_id=r0.company_id where r0.id=p_request and r0.requested_by=p.id;
 if r.id is null or p_expected is distinct from to_jsonb(r) or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Actual requesting client, exact pending request and withdrawal reason required';end if;
 perform 1 from public.companies where id=r.company_id for update;
 select * into v from public.fin_client_refund_reviews where request_id=r.id;
 if v.id is not null then
  if v.outcome='Withdrawn' and v.reviewed_by=auth.uid() and v.reason=trim(p_reason) then return v.id;end if;raise exception 'Only an undecided request can be withdrawn';end if;
 insert into public.fin_client_refund_reviews(request_id,outcome,reason,receipt,reviewed_by)
 values(r.id,'Withdrawn',trim(p_reason),jsonb_build_object('request',to_jsonb(r)),auth.uid()) returning id into result;return result;
end$$;
create function public.client_refund_register() returns jsonb language plpgsql security definer set search_path='' as $$
declare internal boolean:=portal_private.refund_access();company uuid;actor uuid:=auth.uid();
begin
 if not internal then
  select company_id into company from public.profiles where id=actor and active and role='client';
  if company is null then raise exception 'Current Accounts, designated Owner/Director or own-company client access required';end if;
 end if;
 return jsonb_build_object('credits',coalesce((select jsonb_agg(portal_private.refund_credit_basis(b.id) order by b.issued_at,b.id) from public.crm_boq_credit_postings b where b.client_credit>0 and (internal or b.company_id=company)),'[]'::jsonb),
 'requests',coalesce((select jsonb_agg(to_jsonb(r)||jsonb_build_object('review',case when v.id is null then null when internal then to_jsonb(v) else jsonb_build_object('id',v.id,'outcome',v.outcome,'reviewed_by',v.reviewed_by,'reviewed_at',v.reviewed_at) end,'approval_current',case when v.outcome='Approved' then v.receipt->'expected'->'credit'=portal_private.refund_credit_basis(r.origin_id) and exists(select 1 from public.profiles p where p.id=r.requested_by and p.active and p.role='client' and p.company_id=r.company_id) else false end) order by r.requested_at,r.id)
  from public.fin_client_refund_requests r left join public.fin_client_refund_reviews v on v.request_id=r.id where internal or r.company_id=company),'[]'::jsonb));
end$$;
revoke all on function portal_private.refund_approver(uuid),portal_private.refund_access(),portal_private.refund_credit_basis(uuid) from public,anon,authenticated;
grant execute on function portal_private.refund_access() to authenticated;
revoke all on function public.client_refund_access(),public.set_client_refund_approver(uuid,uuid,integer,text,boolean,text),public.request_client_refund(uuid,uuid,numeric,jsonb,boolean,text),public.preview_client_refund_review(uuid,uuid),public.review_client_refund(uuid,uuid,jsonb,text,text),public.withdraw_client_refund(uuid,jsonb,text),public.client_refund_register() from public,anon,authenticated;
grant execute on function public.client_refund_access(),public.set_client_refund_approver(uuid,uuid,integer,text,boolean,text),public.request_client_refund(uuid,uuid,numeric,jsonb,boolean,text),public.preview_client_refund_review(uuid,uuid),public.review_client_refund(uuid,uuid,jsonb,text,text),public.withdraw_client_refund(uuid,jsonb,text),public.client_refund_register() to authenticated;
commit;
