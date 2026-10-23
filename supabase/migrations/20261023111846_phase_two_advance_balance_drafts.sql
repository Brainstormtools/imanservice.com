-- Unapplied: finite Advance balance drafts, not an unbounded recurring schedule.
create table portal_private.crm_advance_balance_drafts(
 sale_id uuid primary key references public.crm_sales,request_id uuid not null unique,invoice_id uuid not null unique references public.invoices,
 actor_id uuid not null references public.profiles,payload jsonb not null,evidence jsonb not null,created_at timestamptz not null default now()
);
create index crm_advance_balance_actor on portal_private.crm_advance_balance_drafts(actor_id);
alter table portal_private.crm_advance_balance_drafts enable row level security;
revoke all on portal_private.crm_advance_balance_drafts from public,anon,authenticated;
create trigger crm_advance_balance_immutable before update or delete on portal_private.crm_advance_balance_drafts for each row execute function portal_private.lead_api_evidence_immutable();
create function portal_private.crm_advance_balance_basis(p_sale uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare s public.crm_sales;p public.crm_quote_publications;i public.invoices;percent numeric;first_total numeric;first_tax numeric;first_net numeric;first_base numeric;base numeric;rate numeric;net numeric;tax numeric;total numeric;items jsonb;
begin
 select * into s from public.crm_sales where id=p_sale;if not found then raise exception 'Converted sale unavailable';end if;
 if s.payment_terms->>'kind' is distinct from 'Advance' then raise exception 'This increment supports Advance balances only';end if;
 percent:=(s.payment_terms->>'first_percent')::numeric;if percent is null or percent<=0 or percent>=100 then raise exception 'A finite remaining Advance balance is required';end if;
 select * into p from public.crm_quote_publications where id=s.publication_id;
 select * into i from public.invoices where id=s.invoice_id;
 first_total:=round(p.total*percent/100,2);first_tax:=round(p.tax_total*percent/100,2);first_net:=first_total-first_tax;
 base:=(s.planned_budget->'quote'->>'service_tax_base')::numeric;rate:=(s.planned_budget->'quote'->>'pra_percent')::numeric;first_base:=round(base*percent/100,2);
 if p.status<>'Accepted' or s.total is distinct from p.total or s.currency is distinct from p.currency or s.company_id is distinct from p.company_id or p.total is distinct from p.subtotal+p.tax_total then raise exception 'Accepted commercial source changed; separate payment review required';end if;
 if i.id is null or i.status='Void' or i.total is distinct from first_total or i.tax_total is distinct from first_tax or i.subtotal is distinct from first_net or i.company_id is distinct from s.company_id or i.currency is distinct from s.currency then raise exception 'Original advance invoice changed; separate payment review required';end if;
 if base is null or rate is null or base<0 or rate<0 or rate>100 then raise exception 'Frozen accepted tax basis unavailable';end if;
 if exists(select 1 from public.credit_notes where invoice_id=i.id and status='Issued') or exists(select 1 from public.crm_boq_offer_publications bp join public.crm_boq_offers bo on bo.id=bp.id where bo.sale_id=s.id and bp.status='Accepted') then raise exception 'Credits or accepted commercial changes require separate payment review';end if;
 if exists(select 1 from public.invoice_items x where x.invoice_id=i.id and (x.tax_percent not in (0,rate) or x.net<0 or x.tax<0)) or (select coalesce(sum(x.net),0) from public.invoice_items x where x.invoice_id=i.id)<>first_net or (select coalesce(sum(x.tax),0) from public.invoice_items x where x.invoice_id=i.id)<>first_tax or (rate>0 and (select coalesce(sum(x.net),0) from public.invoice_items x where x.invoice_id=i.id and x.tax_percent=rate)<>first_base) then raise exception 'Original advance tax lines changed; separate payment review required';end if;
 net:=p.subtotal-first_net;tax:=p.tax_total-first_tax;total:=p.total-first_total;
 if total<=0 or net<0 or tax<0 or base-first_base<0 or base-first_base>net or round((base-first_base)*rate/100,2)<>tax then raise exception 'Remaining accepted amounts require separate tax review';end if;
 select coalesce(jsonb_agg(jsonb_build_object('net',x.net,'tax',x.tax,'tax_percent',x.tax_percent) order by x.position,x.id),'[]') into items from public.invoice_items x where x.invoice_id=i.id;
 return jsonb_build_object('sale_id',s.id,'publication_id',p.id,'quote_number',p.number,'quote_revision',p.revision,'company_id',p.company_id,'company_name',p.company_name,'currency',p.currency,'first_invoice_id',i.id,'first_invoice_number',i.number,'first_invoice_status',i.status,'first_total',first_total,'first_tax',first_tax,'first_net',first_net,'first_items',items,'accepted_total',p.total,'balance_net',net,'balance_tax',tax,'balance_total',total,'taxable_balance',base-first_base,'tax_percent',rate,'project_id',s.project_id);
end$$;
revoke all on function portal_private.crm_advance_balance_basis(uuid) from public,anon,authenticated;
create function public.crm_advance_balance_context(p_sale uuid default null) returns jsonb language plpgsql stable security definer set search_path='' as $$declare r portal_private.crm_advance_balance_drafts;begin
 if auth.uid() is null or not public.is_staff() or not portal_private.payables_access() then raise exception 'Current Accounts access required';end if;
 if p_sale is null then return jsonb_build_object('sales',coalesce((select jsonb_agg(to_jsonb(x) order by x.won_at desc,x.id) from(select s.id,p.number,p.company_name,s.currency,s.won_at from public.crm_sales s join public.crm_quote_publications p on p.id=s.publication_id where s.payment_terms->>'kind'='Advance' order by s.won_at desc,s.id limit 200)x),'[]'));end if;
 select * into r from portal_private.crm_advance_balance_drafts where sale_id=p_sale;
 if found then return jsonb_build_object('draft',(select jsonb_build_object('id',id,'number',number,'status',status,'currency',currency,'total',total,'issued_on',issued_on,'due_on',due_on) from public.invoices where id=r.invoice_id),'receipt',to_jsonb(r));end if;
 return jsonb_build_object('basis',portal_private.crm_advance_balance_basis(p_sale),'draft',null);
end$$;
create function public.create_crm_advance_balance_draft(p_request uuid,p_sale uuid,p_basis jsonb,p_bill date,p_due date,p_reason text,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$
declare s public.crm_sales;r portal_private.crm_advance_balance_drafts;basis jsonb;payload jsonb;invoice uuid;net numeric;taxable numeric;tax numeric;rate numeric;begin
 perform 1 from public.profiles where id=auth.uid() and active and role in ('admin','team') for share;
 if not found or not portal_private.payables_access() then raise exception 'Current Accounts access required';end if;
 perform 1 from public.crm_memberships where user_id=auth.uid() order by role_id,team_id for share;
 perform 1 from public.crm_roles order by id for share;
 perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id=auth.uid()) order by id for share;
 if not portal_private.payables_access() then raise exception 'Current Accounts authority required after waiting';end if;
 if p_request is null or p_sale is null then raise exception 'Actual sale and request identity required';end if;
 payload:=jsonb_build_object('sale',p_sale,'basis',p_basis,'bill',p_bill,'due',p_due,'reason',p_reason,'confirmed',p_confirm);
 perform pg_advisory_xact_lock(hashtext('crm-advance-balance:'||p_request));
 select * into r from portal_private.crm_advance_balance_drafts where request_id=p_request;
 if found then if r.actor_id<>auth.uid() or r.payload is distinct from payload then raise exception 'Balance retry meaning changed';end if;return r.invoice_id;end if;
 select * into s from public.crm_sales where id=p_sale;if not found then raise exception 'Converted sale unavailable';end if;
 perform 1 from public.projects where id=s.project_id for update;
 select * into s from public.crm_sales where id=p_sale for update;
 if exists(select 1 from portal_private.crm_advance_balance_drafts where sale_id=p_sale) then raise exception 'Advance balance draft already exists; review its original invoice';end if;
 perform 1 from public.crm_quote_publications where id=s.publication_id for share;
 perform 1 from public.invoices where id=s.invoice_id for update;
 perform 1 from public.invoice_items where invoice_id=s.invoice_id order by id for share;
 -- Existing credit posting locks this advance invoice; accepted change decisions lock this project.
 basis:=portal_private.crm_advance_balance_basis(p_sale);
 if basis is distinct from p_basis then raise exception 'Payment source changed; refresh balance review';end if;
 if p_bill is null or p_due is null or not isfinite(p_bill) or not isfinite(p_due) or p_due<p_bill or p_confirm is distinct from true or length(trim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'Actual billing/due dates, confirmation and reason required';end if;
 net:=(basis->>'balance_net')::numeric;tax:=(basis->>'balance_tax')::numeric;taxable:=(basis->>'taxable_balance')::numeric;rate:=(basis->>'tax_percent')::numeric;
 insert into public.invoices(company_id,company_name,currency,issued_on,due_on,notes,subtotal,tax_total,total) values(s.company_id,basis->>'company_name',s.currency,p_bill,p_due,'Advance balance draft from '||(basis->>'quote_number')||' v'||(basis->>'quote_revision'),net,tax,(basis->>'balance_total')::numeric) returning id into invoice;
 if net>taxable then insert into public.invoice_items(invoice_id,description,quantity,unit_price,tax_percent,net,tax,position) values(invoice,'Accepted quotation — remaining non-taxable amount',1,net-taxable,0,net-taxable,0,0);end if;
 if taxable>0 then insert into public.invoice_items(invoice_id,description,quantity,unit_price,tax_percent,net,tax,position) values(invoice,'Accepted quotation — remaining taxable services',1,taxable,rate,taxable,tax,1);end if;
 if s.project_id is not null then insert into public.fin_invoice_projects(id,project_id,linked_by) values(invoice,s.project_id,auth.uid());end if;
 insert into public.billing_events(invoice_id,action,detail) values(invoice,'Draft created','Finite balance of accepted Advance sale');
 insert into portal_private.crm_advance_balance_drafts(sale_id,request_id,invoice_id,actor_id,payload,evidence) values(s.id,p_request,invoice,auth.uid(),payload,jsonb_build_object('basis',basis,'bill',p_bill,'due',p_due,'reason',p_reason));
 return invoice;
end$$;
revoke all on function public.crm_advance_balance_context(uuid),public.create_crm_advance_balance_draft(uuid,uuid,jsonb,date,date,text,boolean) from public,anon;
grant execute on function public.crm_advance_balance_context(uuid),public.create_crm_advance_balance_draft(uuid,uuid,jsonb,date,date,text,boolean) to authenticated;
