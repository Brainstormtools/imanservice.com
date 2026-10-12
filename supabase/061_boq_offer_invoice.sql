begin;
alter table public.invoices add column boq_offer_id uuid unique references public.crm_boq_offer_publications;
create table public.crm_boq_offer_invoice_links(
 offer_id uuid primary key references public.crm_boq_offer_publications,invoice_id uuid not null unique references public.invoices,
 project_id uuid not null references public.projects,publication_version integer not null,publication_snapshot jsonb not null,
 creation_request jsonb not null,details_version integer not null default 1,details_history jsonb not null default '[]',
 reason text not null check(length(trim(reason)) between 3 and 2000),created_by uuid not null references public.profiles,
 created_at timestamptz not null default now()
);
create index boq_invoice_links_project on public.crm_boq_offer_invoice_links(project_id);
create index boq_invoice_links_actor on public.crm_boq_offer_invoice_links(created_by);
alter table public.crm_boq_offer_invoice_links enable row level security;
revoke all on public.crm_boq_offer_invoice_links from public,anon,authenticated;
grant select on public.crm_boq_offer_invoice_links to authenticated;
create policy boq_invoice_link_read on public.crm_boq_offer_invoice_links for select to authenticated using(public.is_admin());

create function portal_private.boq_invoice_guard() returns trigger language plpgsql security definer set search_path='' as $$
declare source uuid;destination uuid;
begin
 if tg_table_name='invoices' then
  if old.boq_offer_id is not null then
   if tg_op='DELETE' then raise exception 'Source-linked BOQ invoice cannot be deleted';end if;
   if (to_jsonb(new)-array['status','due_on','bank_instructions']) is distinct from (to_jsonb(old)-array['status','due_on','bank_instructions']) then raise exception 'Accepted BOQ invoice amounts and source are fixed';end if;
  elsif tg_op='UPDATE' and new.boq_offer_id is not null then raise exception 'Use accepted BOQ invoice creation to bind a source';end if;
 elsif tg_table_name='invoice_items' then
  if tg_op<>'INSERT' then source:=old.invoice_id;end if;
  if tg_op<>'DELETE' then destination:=new.invoice_id;end if;
  if exists(select 1 from public.crm_boq_offer_invoice_links where invoice_id in (source,destination)) then raise exception 'Accepted BOQ invoice lines are fixed';end if;
 elsif tg_table_name='fin_invoice_projects' then
  if exists(select 1 from public.crm_boq_offer_invoice_links where invoice_id=old.id) then
   if tg_op='DELETE' then raise exception 'Accepted BOQ invoice project link is fixed';end if;
   if new.id is distinct from old.id or new.project_id is distinct from old.project_id then raise exception 'Accepted BOQ invoice project link is fixed';end if;
  elsif tg_op='UPDATE' and exists(select 1 from public.crm_boq_offer_invoice_links where invoice_id=new.id and project_id is distinct from new.project_id) then raise exception 'Accepted BOQ invoice project link is fixed';end if;
 end if;
 if tg_op='DELETE' then return old;end if;return new;
end$$;
revoke all on function portal_private.boq_invoice_guard() from public,anon,authenticated;
create trigger boq_invoice_header_guard before update or delete on public.invoices for each row execute function portal_private.boq_invoice_guard();
create trigger boq_invoice_item_guard before insert or update or delete on public.invoice_items for each row execute function portal_private.boq_invoice_guard();
create trigger boq_invoice_project_guard before update or delete on public.fin_invoice_projects for each row execute function portal_private.boq_invoice_guard();

create function public.create_boq_offer_invoice(p_offer uuid,p_version integer,p_issue date,p_due date,p_bank text,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare pub public.crm_boq_offer_publications;link public.crm_boq_offer_invoice_links;inv public.invoices;bucket integer;remaining numeric;chunk numeric;rate numeric;position integer:=0;notes text;request jsonb;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator creates source-linked invoices';end if;
 select * into pub from public.crm_boq_offer_publications where id=p_offer;
 perform 1 from public.projects where id=pub.project_id for update;
 select * into pub from public.crm_boq_offer_publications where id=p_offer for update;
 if pub.id is null or pub.status is distinct from 'Accepted' or not pub.consent or pub.version is distinct from p_version then raise exception 'Current client-approved BOQ offer required';end if;
 if not exists(select 1 from public.projects where id=pub.project_id and company_id=pub.company_id) or not exists(select 1 from public.crm_boq_offers o join public.crm_sales s on s.id=o.sale_id where o.id=pub.id and s.project_id=pub.project_id and s.company_id=pub.company_id and s.currency=pub.currency) then raise exception 'Original project customer and currency must match';end if;
 if p_issue is null or p_due is null or p_due<p_issue or length(trim(coalesce(p_bank,''))) not between 3 and 4000 or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit invoice dates, bank instructions and reason required';end if;
 request:=jsonb_build_object('issued_on',p_issue,'due_on',p_due,'bank',trim(p_bank),'reason',trim(p_reason));
 select * into link from public.crm_boq_offer_invoice_links where offer_id=pub.id;
 if link.offer_id is not null then
  if link.created_by=auth.uid() and link.creation_request=request then return link.invoice_id;end if;
  raise exception 'Offer already has a source-linked invoice; open it instead';
 end if;
 notes:='Accepted additional BOQ offer '||pub.number||' revision '||pub.revision||'. Itemized scope and complete terms remain in that accepted offer.'||E'\nClient WHT: '||pub.wht_percent||'% ('||pub.wht_total||'). Net payment after withholding: '||pub.receivable||'. Withholding is not recorded as a verified receipt or credit by invoice creation.';
 insert into public.invoices(company_id,company_name,currency,issued_on,due_on,notes,bank_instructions,subtotal,tax_total,total,author_id,boq_offer_id)
 values(pub.company_id,pub.company_name,pub.currency,p_issue,p_due,notes,trim(p_bank),pub.subtotal,pub.tax_total,pub.total,auth.uid(),pub.id) returning * into inv;
 -- Summary buckets preserve the explicit taxable base without guessing item tax allocation.
 -- Multiples of 100 avoid per-chunk rounding drift with a rate precision of 0.01%.
 for bucket in 0..1 loop
  remaining:=case when bucket=0 then pub.subtotal-pub.service_tax_base else pub.service_tax_base end;
  rate:=case when bucket=0 then 0 else pub.pra_percent end;
  while remaining>0 loop
   chunk:=least(remaining,9999999900.00);position:=position+1;
   insert into public.invoice_items(invoice_id,description,quantity,unit_price,tax_percent,net,tax,position)
    values(inv.id,pub.number||' revision '||pub.revision||case when bucket=0 then ' — additional scope outside the recorded services-tax base' else ' — recorded taxable services' end,1,chunk,rate,chunk,round(chunk*rate/100,2),position);
   remaining:=remaining-chunk;
  end loop;
 end loop;
 if not exists(select 1 from public.invoice_items where invoice_id=inv.id) or (select sum(net) from public.invoice_items where invoice_id=inv.id) is distinct from pub.subtotal or (select sum(tax) from public.invoice_items where invoice_id=inv.id) is distinct from pub.tax_total then raise exception 'Exact offer-to-invoice calculation required';end if;
 insert into public.fin_invoice_projects(id,project_id,linked_by) values(inv.id,pub.project_id,auth.uid());
 insert into public.crm_boq_offer_invoice_links(offer_id,invoice_id,project_id,publication_version,publication_snapshot,creation_request,reason,created_by)
  values(pub.id,inv.id,pub.project_id,pub.version,to_jsonb(pub),request,trim(p_reason),auth.uid());
 insert into public.billing_events(invoice_id,action,detail,actor_id) values(inv.id,'BOQ offer draft created',pub.number||' revision '||pub.revision,auth.uid());
 insert into public.crm_boq_offer_history(offer_id,project_id,action,after_record,reason,actor_id)
  values(pub.id,pub.project_id,'Invoice draft created',jsonb_build_object('invoice_id',inv.id,'invoice_number',inv.number,'status',inv.status,'publication_version',pub.version,'subtotal',pub.subtotal,'tax_total',pub.tax_total,'total',pub.total),trim(p_reason),auth.uid());
 return inv.id;
end$$;

create function public.revise_boq_invoice_details(p_invoice uuid,p_version integer,p_due date,p_bank text,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare inv public.invoices;link public.crm_boq_offer_invoice_links;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator revises invoice details';end if;
 select * into link from public.crm_boq_offer_invoice_links where invoice_id=p_invoice;
 select * into inv from public.invoices where id=p_invoice for update;
 if link.invoice_id is null or inv.status is distinct from 'Draft' then raise exception 'Source-linked draft invoice required';end if;
 if p_due is null or p_due<inv.issued_on or length(trim(coalesce(p_bank,''))) not between 3 and 4000 or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Valid due date, bank instructions and reason required';end if;
 select * into link from public.crm_boq_offer_invoice_links where invoice_id=p_invoice for update;
 if link.details_version is distinct from p_version then raise exception 'Payment details changed; refresh before revising';end if;
 if inv.due_on=p_due and inv.bank_instructions=trim(p_bank) then return;end if;
 update public.invoices set due_on=p_due,bank_instructions=trim(p_bank) where id=inv.id;
 update public.crm_boq_offer_invoice_links set details_version=details_version+1,details_history=details_history||jsonb_build_array(jsonb_build_object('before',jsonb_build_object('due_on',inv.due_on,'bank',inv.bank_instructions),'after',jsonb_build_object('due_on',p_due,'bank',trim(p_bank)),'reason',trim(p_reason),'actor_id',auth.uid(),'created_at',now())) where offer_id=link.offer_id;
 insert into public.billing_events(invoice_id,action,detail,actor_id) values(inv.id,'BOQ invoice payment details revised','Draft payment details updated; revision '||(link.details_version+1)::text,auth.uid());
 insert into public.crm_boq_offer_history(offer_id,project_id,action,before_record,after_record,reason,actor_id)
  values(link.offer_id,link.project_id,'Invoice payment details revised',jsonb_build_object('invoice_id',inv.id,'due_on',inv.due_on),jsonb_build_object('invoice_id',inv.id,'due_on',p_due,'bank_instructions_updated',true),trim(p_reason),auth.uid());
end$$;

create function public.boq_offer_invoice_directory() returns table(offer_id uuid,invoice_id uuid,invoice_number text,invoice_status text,issued_on date,due_on date,currency text,total numeric,details_version integer)
language sql stable security definer set search_path='' as $$
 select l.offer_id,i.id,i.number,i.status,i.issued_on,i.due_on,i.currency,i.total,l.details_version from public.crm_boq_offer_invoice_links l join public.invoices i on i.id=l.invoice_id
 where auth.uid() is not null and (portal_private.execution_manager(l.project_id) or public.can_invoice(i.id))
$$;
revoke all on function public.create_boq_offer_invoice(uuid,integer,date,date,text,text),public.revise_boq_invoice_details(uuid,integer,date,text,text),public.boq_offer_invoice_directory() from public,anon;
grant execute on function public.create_boq_offer_invoice(uuid,integer,date,date,text,text),public.revise_boq_invoice_details(uuid,integer,date,text,text),public.boq_offer_invoice_directory() to authenticated;
commit;
