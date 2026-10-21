begin;
-- Supported no-claim/no-credit original-invoice cancellation and exact approved BOQ rebilling only.
alter table public.invoices drop constraint invoices_status_check;
alter table public.invoices add constraint invoices_status_check check(status in ('Draft','Issued','Void','Cancelled'));
create table public.fin_boq_invoice_rebills(
 id uuid primary key,preparation_id uuid not null unique references public.crm_boq_adjustment_preparations,
 review_id uuid not null unique references public.crm_boq_adjustment_reviews,invoice_id uuid not null unique references public.invoices,
 replacement_invoice_id uuid unique references public.invoices,company_id uuid not null references public.companies,
 project_id uuid not null references public.projects,request jsonb not null,receipt jsonb not null,
 reason text not null check(length(trim(reason)) between 3 and 2000),recorded_by uuid not null references public.profiles,recorded_at timestamptz not null default now()
);
create index boq_rebill_company on public.fin_boq_invoice_rebills(company_id);
create index boq_rebill_project on public.fin_boq_invoice_rebills(project_id);
create index boq_rebill_actor on public.fin_boq_invoice_rebills(recorded_by);
alter table public.fin_boq_invoice_rebills enable row level security;
revoke all on public.fin_boq_invoice_rebills from public,anon,authenticated;
grant select on public.fin_boq_invoice_rebills to authenticated;
create policy boq_rebill_private_read on public.fin_boq_invoice_rebills for select to authenticated using(portal_private.adjustment_access());
create trigger boq_rebill_immutable before update or delete on public.fin_boq_invoice_rebills for each row execute function portal_private.boq_line_evidence_immutable();
alter function portal_private.approved_adjustment(uuid,uuid) rename to approved_adjustment_before_rebill;
revoke all on function portal_private.approved_adjustment_before_rebill(uuid,uuid) from public,anon,authenticated;
create function portal_private.approved_adjustment(p_preparation uuid,p_review uuid) returns jsonb language plpgsql set search_path='' as $$
declare s jsonb;
begin
 s:=portal_private.approved_adjustment_before_rebill(p_preparation,p_review);
 if exists(select 1 from public.fin_boq_invoice_rebills where replacement_invoice_id=(s->'preparation'->>'invoice_id')::uuid) then raise exception 'Rebilled invoices require separate change-chain reconciliation';end if;
 return s;
end$$;
create function portal_private.invoice_rebill_basis(p_preparation uuid,p_review uuid) returns jsonb language plpgsql set search_path='' as $$
declare s jsonb;i public.invoices;l public.invoice_items;m jsonb;lines jsonb:='[]';net numeric;tax numeric;net_total numeric:=0;tax_total numeric:=0;sign numeric;description text;
begin
 s:=portal_private.approved_adjustment(p_preparation,p_review);
 select * into i from public.invoices where id=(s->'preparation'->>'invoice_id')::uuid for update;
 if s->'snapshot'->'manual_wht' is distinct from 'null'::jsonb then raise exception 'Manual WHT requires separate cancellation/rebill reconciliation';end if;
 if exists(select 1 from public.payment_claims where invoice_id=i.id) or exists(select 1 from public.credit_notes where invoice_id=i.id)
  or exists(select 1 from public.crm_boq_credit_postings where invoice_id=i.id) or exists(select 1 from public.crm_boq_debit_postings where invoice_id=i.id or supplementary_invoice_id=i.id)
  or exists(select 1 from public.invoice_schedules where source_invoice=i.id) or exists(select 1 from public.invoice_schedule_runs where invoice_id=i.id)
  or exists(select 1 from public.fin_boq_invoice_rebills where invoice_id=i.id or replacement_invoice_id=i.id) then raise exception 'No payment-claim, credit, posting, recurring or rebill history permitted; reconcile those separately';end if;
 if i.subtotal is distinct from (select sum(original.net) from public.invoice_items original where original.invoice_id=i.id) or i.tax_total is distinct from (select sum(original.tax) from public.invoice_items original where original.invoice_id=i.id) or i.total<>i.subtotal+i.tax_total then raise exception 'Exact original invoice totals and lines required';end if;
 sign:=case when s->'snapshot'->>'kind'='Credit note' then -1 else 1 end;
 for l in select * from public.invoice_items where invoice_id=i.id order by position,id loop
  if l.net<>round(l.quantity*l.unit_price,2) or l.tax<>round(l.net*l.tax_percent/100,2) then raise exception 'Original invoice rounding requires separate reconciliation';end if;
  select value into m from jsonb_array_elements(s->'snapshot'->'lines') where value->>'item_id'=l.id::text;
  net:=l.net+sign*coalesce((m->>'net')::numeric,0);tax:=round(net*l.tax_percent/100,2);description:=l.description;
  if net<0 or tax<>l.tax+sign*coalesce((m->>'tax')::numeric,0) then raise exception 'Mapped net/tax rounding requires separate reconciliation';end if;
  if m is not null and s->'snapshot'->'source'->>'action'='Replace' then description:=s->'snapshot'->'source'->'replacement'->>'description';end if;
  if net>0 then
   lines:=lines||jsonb_build_array(jsonb_build_object('original_item_id',l.id,'description',description,'quantity',case when m is null then l.quantity else 1 end,'unit_price',case when m is null then l.unit_price else net end,'tax_percent',l.tax_percent,'net',net,'tax',tax,'gross',net+tax));
  end if;
  net_total:=net_total+net;tax_total:=tax_total+tax;
 end loop;
 if net_total<>i.subtotal+sign*(s->'snapshot'->>'net')::numeric or tax_total<>i.tax_total+sign*(s->'snapshot'->>'tax')::numeric then raise exception 'Exact approved invoice difference required';end if;
 return s||jsonb_build_object('replacement_lines',lines,'replacement_net',net_total,'replacement_tax',tax_total,'replacement_gross',net_total+tax_total,'cancel_only',net_total+tax_total=0);
end$$;
create function public.preview_boq_invoice_rebill(p_preparation uuid,p_review uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare b public.fin_boq_invoice_rebills;
begin
 if not portal_private.adjustment_access() then raise exception 'Current Accounts or designated Manager access required';end if;
 select * into b from public.fin_boq_invoice_rebills where preparation_id=p_preparation;
 if b.id is not null then
  if b.review_id is distinct from p_review then raise exception 'Exact recorded review required';end if;
  return jsonb_build_object('record',to_jsonb(b)||jsonb_build_object('original_number',(select number from public.invoices where id=b.invoice_id),'replacement_number',(select number from public.invoices where id=b.replacement_invoice_id)));
 end if;return portal_private.invoice_rebill_basis(p_preparation,p_review);
end$$;
create function public.cancel_rebill_boq_invoice(p_id uuid,p_preparation uuid,p_review uuid,p_expected jsonb,p_details jsonb,p_reason text,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$
declare old public.fin_boq_invoice_rebills;s jsonb;req jsonb;i public.invoices;replacement public.invoices;x jsonb;idx integer:=0;issue_date date;due_date date;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Current Accounts cancellation/rebill access required';end if;
 if p_id is null or p_confirm is distinct from true or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Explicit cancellation/rebill confirmation and actual client-visible reason required';end if;
 req:=jsonb_build_object('preparation',p_preparation,'review',p_review,'expected',p_expected,'details',p_details,'reason',trim(p_reason),'confirmed',true);
 select * into old from public.fin_boq_invoice_rebills where id=p_id;
 if old.id is not null then
  if old.request=req and old.recorded_by=auth.uid() then return old.id;end if;raise exception 'Rebill ID already has different immutable evidence';
 end if;
 s:=portal_private.invoice_rebill_basis(p_preparation,p_review);
 if s is distinct from p_expected then raise exception 'Source or invoice changed; reload exact cancellation/rebill evidence';end if;
 select * into i from public.invoices where id=(s->'preparation'->>'invoice_id')::uuid;
 if not (s->>'cancel_only')::boolean then
  if jsonb_typeof(p_details) is distinct from 'object' or (select count(*) from jsonb_object_keys(p_details))<>3 or not(p_details ?& array['issued_on','due_on','bank_instructions']) or coalesce(p_details->>'issued_on','') !~ '^\d{4}-\d{2}-\d{2}$' or coalesce(p_details->>'due_on','') !~ '^\d{4}-\d{2}-\d{2}$' or jsonb_typeof(p_details->'bank_instructions') is distinct from 'string' or length(trim(p_details->>'bank_instructions')) not between 1 and 4000 then raise exception 'Actual replacement issue/due dates and bank instructions required';end if;
  issue_date:=(p_details->>'issued_on')::date;due_date:=(p_details->>'due_on')::date;
  if due_date<issue_date then raise exception 'Replacement due date cannot precede issue date';end if;
  insert into public.invoices(company_id,company_name,currency,issued_on,due_on,notes,bank_instructions,subtotal,tax_total,total,author_id)
  values(i.company_id,i.company_name,i.currency,issue_date,due_date,'Rebill of cancelled invoice '||i.number||' · accepted change order '||(s->'snapshot'->'source'->>'change_id')||E'\nChanged lines are monetary billing allocations; accepted scope quantities remain in the accepted change order.\n'||trim(p_reason),trim(p_details->>'bank_instructions'),(s->>'replacement_net')::numeric,(s->>'replacement_tax')::numeric,(s->>'replacement_gross')::numeric,auth.uid()) returning * into replacement;
  for x in select value from jsonb_array_elements(s->'replacement_lines') loop
   idx:=idx+1;insert into public.invoice_items(invoice_id,description,quantity,unit_price,tax_percent,net,tax,position)
    values(replacement.id,x->>'description',(x->>'quantity')::numeric,(x->>'unit_price')::numeric,(x->>'tax_percent')::numeric,(x->>'net')::numeric,(x->>'tax')::numeric,idx);
  end loop;
  insert into public.fin_invoice_projects(id,project_id,linked_by) values(replacement.id,(s->'preparation'->>'project_id')::uuid,auth.uid());
  update public.invoices set status='Issued' where id=replacement.id returning * into replacement;
 elsif p_details is not null and p_details<>'null'::jsonb then raise exception 'Zero remaining scope creates no replacement invoice or payment details';end if;
 insert into public.fin_boq_invoice_rebills(id,preparation_id,review_id,invoice_id,replacement_invoice_id,company_id,project_id,request,receipt,reason,recorded_by)
 values(p_id,p_preparation,p_review,i.id,replacement.id,i.company_id,(s->'preparation'->>'project_id')::uuid,req,jsonb_build_object('basis',s,'replacement_invoice',case when replacement.id is not null then to_jsonb(replacement) else null end),trim(p_reason),auth.uid());
 update public.invoices set status='Cancelled' where id=i.id;
 insert into public.billing_events(invoice_id,action,detail,actor_id) values(i.id,'Cancelled – approved BOQ rebill',trim(p_reason)||case when replacement.id is null then ' · no remaining amount to rebill' else ' · replacement '||replacement.number end,auth.uid());
 if replacement.id is not null then insert into public.billing_events(invoice_id,action,detail,actor_id) values(replacement.id,'Issued – approved BOQ rebill','Original retained as Cancelled: '||i.number,auth.uid());end if;
 return p_id;
end$$;
create function portal_private.invoice_rebill_guard() returns trigger language plpgsql security definer set search_path='' as $$
declare src uuid;dest uuid;b public.fin_boq_invoice_rebills;
begin
 if tg_table_name='invoices' then
  select * into b from public.fin_boq_invoice_rebills where invoice_id=old.id or replacement_invoice_id=old.id;
  if b.id is not null then
   if tg_op='UPDATE' and b.invoice_id=old.id and old.status='Issued' and new.status='Cancelled' and (to_jsonb(new)-'status')=(to_jsonb(old)-'status') and b.receipt->'basis'->'snapshot'->'invoice'=to_jsonb(old) then return new;end if;
   raise exception 'Cancelled originals and issued rebills are immutable';
  end if;
  if tg_op='UPDATE' and new.status='Cancelled' then raise exception 'Use exact approved no-payment cancellation/rebill workflow';end if;
 elsif tg_table_name='invoice_items' then
  if tg_op<>'INSERT' then src:=old.invoice_id;end if;if tg_op<>'DELETE' then dest:=new.invoice_id;end if;
  perform 1 from public.invoices where id in(src,dest) order by id for update;
  if exists(select 1 from public.fin_boq_invoice_rebills where invoice_id in(src,dest) or replacement_invoice_id in(src,dest)) then raise exception 'Cancelled original and replacement invoice lines are immutable';end if;
 else
  if tg_op<>'INSERT' then src:=old.id;end if;if tg_op<>'DELETE' then dest:=new.id;end if;
  if exists(select 1 from public.fin_boq_invoice_rebills where invoice_id in(src,dest) or replacement_invoice_id in(src,dest)) then raise exception 'Cancellation/rebill project attribution is immutable';end if;
 end if;
 if tg_op='DELETE' then return old;end if;return new;
end$$;
create trigger invoice_rebill_header_guard before update or delete on public.invoices for each row execute function portal_private.invoice_rebill_guard();
create trigger invoice_rebill_items_guard before insert or update or delete on public.invoice_items for each row execute function portal_private.invoice_rebill_guard();
create trigger invoice_rebill_project_guard before insert or update or delete on public.fin_invoice_projects for each row execute function portal_private.invoice_rebill_guard();
alter function public.save_invoice_schedule(uuid,text,date,integer) rename to save_invoice_schedule_before_rebill;
revoke all on function public.save_invoice_schedule_before_rebill(uuid,text,date,integer) from public,anon,authenticated;
create function public.save_invoice_schedule(p_source uuid,p_title text,p_start date,p_due integer) returns uuid language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required';end if;
 perform 1 from public.invoices where id=p_source for update;
 if exists(select 1 from public.invoices where id=p_source and status='Cancelled') or exists(select 1 from public.fin_boq_invoice_rebills where replacement_invoice_id=p_source) then raise exception 'Cancelled/rebilled invoice requires separate recurring-billing reconciliation';end if;
 return public.save_invoice_schedule_before_rebill(p_source,p_title,p_start,p_due);
end$$;
create function public.boq_invoice_rebill_register() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare internal boolean:=portal_private.adjustment_access();company uuid;
begin
 if not internal then select company_id into company from public.profiles where id=auth.uid() and active and role='client';if company is null then raise exception 'Current Accounts, designated Manager or own-company client access required';end if;end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',b.id,'original_invoice_id',i.id,'original_number',i.number,'original_status',i.status,'original_gross',i.total,'replacement_invoice_id',n.id,'replacement_number',n.number,'replacement_gross',n.total,'change_id',b.receipt->'basis'->'snapshot'->'source'->>'change_id','reason',b.reason,'replacement_lines',b.receipt->'basis'->'replacement_lines','recorded_by',b.recorded_by,'recorded_at',b.recorded_at)||case when internal then jsonb_build_object('private_receipt',b.receipt) else '{}'::jsonb end order by b.recorded_at,b.id)
 from public.fin_boq_invoice_rebills b join public.invoices i on i.id=b.invoice_id left join public.invoices n on n.id=b.replacement_invoice_id where internal or b.company_id=company),'[]'::jsonb);
end$$;
revoke all on function portal_private.approved_adjustment(uuid,uuid),portal_private.invoice_rebill_basis(uuid,uuid),portal_private.invoice_rebill_guard() from public,anon,authenticated;
revoke all on function public.preview_boq_invoice_rebill(uuid,uuid),public.cancel_rebill_boq_invoice(uuid,uuid,uuid,jsonb,jsonb,text,boolean),public.boq_invoice_rebill_register(),public.save_invoice_schedule(uuid,text,date,integer) from public,anon,authenticated;
grant execute on function public.preview_boq_invoice_rebill(uuid,uuid),public.cancel_rebill_boq_invoice(uuid,uuid,uuid,jsonb,jsonb,text,boolean),public.boq_invoice_rebill_register(),public.save_invoice_schedule(uuid,text,date,integer) to authenticated;
commit;
