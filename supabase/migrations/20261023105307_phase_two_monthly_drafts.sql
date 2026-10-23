-- Unapplied. Finite recorded conversion Monthly periods; no dates/cadence or completion inferred.
create table portal_private.crm_monthly_payment_drafts(
 sale_id uuid not null references public.crm_sales,position integer not null check(position between 2 and 120),request_id uuid not null unique,
 invoice_id uuid not null unique references public.invoices,actor_id uuid not null references public.profiles,payload jsonb not null,evidence jsonb not null,
 created_at timestamptz not null default now(),primary key(sale_id,position)
);
create index crm_monthly_payment_actor on portal_private.crm_monthly_payment_drafts(actor_id);
alter table portal_private.crm_monthly_payment_drafts enable row level security;
revoke all on portal_private.crm_monthly_payment_drafts from public,anon,authenticated;
create trigger crm_monthly_payment_immutable before update or delete on portal_private.crm_monthly_payment_drafts for each row execute function portal_private.lead_api_evidence_immutable();
create function portal_private.crm_monthly_payment_plan(p_sale uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare s public.crm_sales;p public.crm_quote_publications;months numeric;plan jsonb:='[]';position integer:=0;count integer;percent numeric;total numeric;tax numeric;base numeric;remaining_total numeric;remaining_tax numeric;remaining_base numeric;rate numeric;
begin
 select * into s from public.crm_sales where id=p_sale;if not found then raise exception 'Converted sale unavailable';end if;
 if s.payment_terms->>'kind' is distinct from 'Monthly' then raise exception 'Recorded Monthly conversion terms required';end if;
 months:=(s.payment_terms->>'months')::numeric;percent:=(s.payment_terms->>'first_percent')::numeric;
 if jsonb_typeof(s.payment_terms->'months') is distinct from 'number' or months is null or months not between 1 and 120 or months<>trunc(months) or percent is null or not(percent>0 and percent<=100) or abs(percent-100/months)>0.01 then raise exception 'Valid recorded finite Monthly periods and original percentage required';end if;
 select * into p from public.crm_quote_publications where id=s.publication_id;
 base:=(s.planned_budget->'quote'->>'service_tax_base')::numeric;rate:=(s.planned_budget->'quote'->>'pra_percent')::numeric;
 if p.status<>'Accepted' or s.total is distinct from p.total or s.currency is distinct from p.currency or s.company_id is distinct from p.company_id or p.total is distinct from p.subtotal+p.tax_total then raise exception 'Accepted commercial source changed; separate payment review required';end if;
 if p.total<=0 or p.total::text in ('NaN','Infinity','-Infinity') or p.tax_total<0 or p.tax_total::text in ('NaN','Infinity','-Infinity') or p.subtotal<0 or p.subtotal::text in ('NaN','Infinity','-Infinity') or base is null or rate is null or base<0 or base::text in ('NaN','Infinity','-Infinity') or rate::text in ('NaN','Infinity','-Infinity') or rate<0 or rate>100 then raise exception 'Finite accepted amounts and original tax basis required';end if;
 count:=months::integer;remaining_total:=p.total;remaining_tax:=p.tax_total;remaining_base:=base;
 for position in 1..count loop
  percent:=(s.payment_terms->>'first_percent')::numeric;
  if position=count then total:=remaining_total;tax:=remaining_tax;base:=remaining_base;
  else total:=round(p.total*percent/100,2);tax:=round(p.tax_total*percent/100,2);base:=round((s.planned_budget->'quote'->>'service_tax_base')::numeric*percent/100,2);end if;
  plan:=plan||jsonb_build_array(jsonb_build_object('position',position,'title','Period '||position||' of '||count,'percent',case when position=count then 100-percent*(count-1) else percent end,'total',total,'net',total-tax,'tax',tax,'taxable',base,'tax_percent',rate));
  remaining_total:=remaining_total-total;remaining_tax:=remaining_tax-tax;remaining_base:=remaining_base-base;
 end loop;
 if exists(select 1 from jsonb_array_elements(plan) a where (a->>'total')::numeric<=0 or (a->>'net')::numeric<0 or (a->>'tax')::numeric<0 or (a->>'taxable')::numeric<0 or (a->>'taxable')::numeric>(a->>'net')::numeric) then raise exception 'Recorded Monthly allocation needs separate review before finite billing';end if;
 return plan;
end$$;
create function portal_private.crm_monthly_payment_basis(p_sale uuid,p_position integer) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare s public.crm_sales;p public.crm_quote_publications;plan jsonb;amount jsonb;first_invoice public.invoices;prior_invoice public.invoices;prior portal_private.crm_monthly_payment_drafts;previous jsonb:='[]';n integer;rate numeric;begin
 plan:=portal_private.crm_monthly_payment_plan(p_sale);
 if p_position is null or p_position<2 or p_position>jsonb_array_length(plan) then raise exception 'Choose an actual later Monthly position';end if;
 select * into s from public.crm_sales where id=p_sale;select * into p from public.crm_quote_publications where id=s.publication_id;
 rate:=(s.planned_budget->'quote'->>'pra_percent')::numeric;
 if exists(select 1 from portal_private.crm_milestone_payment_drafts where sale_id=s.id) or exists(select 1 from portal_private.crm_advance_balance_drafts where sale_id=s.id) or exists(select 1 from public.credit_notes where invoice_id=s.invoice_id and status='Issued') or exists(select 1 from public.crm_boq_offer_publications bp join public.crm_boq_offers bo on bo.id=bp.id where bo.sale_id=s.id and bp.status='Accepted') then raise exception 'Existing balance, credits or accepted commercial changes require separate payment review';end if;
 if exists(select 1 from public.invoice_schedules where source_invoice=s.invoice_id and active) or exists(select 1 from public.invoice_schedule_runs r join public.invoice_schedules q on q.id=r.schedule_id where q.source_invoice=s.invoice_id) then raise exception 'Existing recurring billing requires reconciliation before finite Monthly drafts';end if;
 if not portal_private.crm_milestone_invoice_matches(s.invoice_id,s.company_id,s.currency,plan->0,rate) then raise exception 'Original first invoice changed; separate payment review required';end if;
 select * into first_invoice from public.invoices where id=s.invoice_id;
 previous:=previous||jsonb_build_array(jsonb_build_object('position',1,'invoice_id',first_invoice.id,'status',first_invoice.status,'total',first_invoice.total,'net',first_invoice.subtotal,'tax',first_invoice.tax_total));
 for n in 2..p_position-1 loop
  select * into prior from portal_private.crm_monthly_payment_drafts where sale_id=s.id and position=n;
  if not found then raise exception 'Prepare each earlier Monthly period first';end if;
  if prior.evidence->'basis'->'payment_terms' is distinct from s.payment_terms or not portal_private.crm_milestone_invoice_matches(prior.invoice_id,s.company_id,s.currency,plan->(n-1),rate) or exists(select 1 from public.credit_notes where invoice_id=prior.invoice_id and status='Issued') then raise exception 'Earlier Monthly invoice changed or credited; separate payment review required';end if;
  select * into prior_invoice from public.invoices where id=prior.invoice_id;
  previous:=previous||jsonb_build_array(jsonb_build_object('position',n,'invoice_id',prior_invoice.id,'status',prior_invoice.status,'total',prior_invoice.total,'net',prior_invoice.subtotal,'tax',prior_invoice.tax_total));
 end loop;
 amount:=plan->(p_position-1);
 if (amount->>'total')::numeric<=0 or (amount->>'net')::numeric<0 or (amount->>'tax')::numeric<0 or (amount->>'taxable')::numeric<0 or (amount->>'taxable')::numeric>(amount->>'net')::numeric or round((amount->>'taxable')::numeric*rate/100,2)<>(amount->>'tax')::numeric then raise exception 'Monthly amount or tax remainder requires separate Accounts review';end if;
 return jsonb_build_object('sale_id',s.id,'position',p_position,'title',amount->>'title','percent',amount->'percent','payment_terms',s.payment_terms,'plan',plan,'previous',previous,'publication_id',p.id,'quote_number',p.number,'quote_revision',p.revision,'company_id',p.company_id,'company_name',p.company_name,'currency',p.currency,'project_id',s.project_id,'accepted_total',p.total,'amount_total',amount->'total','amount_net',amount->'net','amount_tax',amount->'tax','taxable_amount',amount->'taxable','tax_percent',rate);
end$$;
revoke all on function portal_private.crm_monthly_payment_plan(uuid),portal_private.crm_monthly_payment_basis(uuid,integer) from public,anon,authenticated;
create function public.crm_monthly_payment_context(p_sale uuid default null,p_position integer default null) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare r portal_private.crm_monthly_payment_drafts;plan jsonb;metadata jsonb;begin
 if auth.uid() is null or not public.is_staff() or not portal_private.payables_access() then raise exception 'Current Accounts access required';end if;
 if p_sale is null then return jsonb_build_object('sales',coalesce((select jsonb_agg(to_jsonb(x) order by x.won_at desc,x.id) from(select s.id,p.number,p.company_name,s.currency,s.won_at from public.crm_sales s join public.crm_quote_publications p on p.id=s.publication_id where s.payment_terms->>'kind'='Monthly' order by s.won_at desc,s.id limit 200)x),'[]'));end if;
 select * into r from portal_private.crm_monthly_payment_drafts where sale_id=p_sale and position=p_position;
 if found then
  plan:=r.evidence->'basis'->'plan';metadata:=jsonb_build_object('id',p_sale,'number',r.evidence->'basis'->>'quote_number','company_name',r.evidence->'basis'->>'company_name','currency',r.evidence->'basis'->>'currency');
  return jsonb_build_object('sale',metadata,'payments',(select jsonb_agg(x order by (x->>'position')::integer) from jsonb_array_elements(plan)x where (x->>'position')::integer>1),'draft',(select jsonb_build_object('id',id,'number',number,'status',status,'currency',currency,'total',total,'issued_on',issued_on,'due_on',due_on) from public.invoices where id=r.invoice_id),'receipt',to_jsonb(r));
 end if;
 plan:=portal_private.crm_monthly_payment_plan(p_sale);
 select jsonb_build_object('id',s.id,'number',p.number,'company_name',p.company_name,'currency',p.currency) into metadata from public.crm_sales s join public.crm_quote_publications p on p.id=s.publication_id where s.id=p_sale;
 return jsonb_build_object('sale',metadata,'payments',(select jsonb_agg(x order by (x->>'position')::integer) from jsonb_array_elements(plan)x where (x->>'position')::integer>1),'basis',case when p_position is null then null else portal_private.crm_monthly_payment_basis(p_sale,p_position) end,'draft',null);
end$$;
create function public.create_crm_monthly_payment_draft(p_request uuid,p_sale uuid,p_position integer,p_basis jsonb,p_bill date,p_due date,p_reason text,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$
declare s public.crm_sales;r portal_private.crm_monthly_payment_drafts;basis jsonb;payload jsonb;invoice uuid;net numeric;taxable numeric;tax numeric;rate numeric;begin
 perform 1 from public.profiles where id=auth.uid() and active and role in ('admin','team') for share;if not found or not portal_private.payables_access() then raise exception 'Current Accounts access required';end if;
 perform 1 from public.crm_memberships where user_id=auth.uid() order by role_id,team_id for share;perform 1 from public.crm_roles order by id for share;perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id=auth.uid()) order by id for share;
 if not portal_private.payables_access() then raise exception 'Current Accounts authority required after waiting';end if;
 if p_request is null or p_sale is null then raise exception 'Actual sale and request identity required';end if;
 payload:=jsonb_build_object('sale',p_sale,'position',p_position,'basis',p_basis,'bill',p_bill,'due',p_due,'reason',p_reason,'confirmed',p_confirm);
 perform pg_advisory_xact_lock(hashtext('crm-monthly-payment:'||p_request));
 select * into r from portal_private.crm_monthly_payment_drafts where request_id=p_request;
 if found then if r.actor_id<>auth.uid() or r.payload is distinct from payload then raise exception 'Monthly retry meaning changed';end if;return r.invoice_id;end if;
 select * into s from public.crm_sales where id=p_sale;if not found then raise exception 'Converted sale unavailable';end if;perform 1 from public.projects where id=s.project_id for update;select * into s from public.crm_sales where id=p_sale for update;
 if exists(select 1 from portal_private.crm_monthly_payment_drafts where sale_id=s.id and position=p_position) then raise exception 'Monthly draft already exists; review original invoice';end if;
 perform 1 from public.crm_quote_publications where id=s.publication_id for share;
 perform 1 from public.invoices where id=s.invoice_id or id in(select invoice_id from portal_private.crm_monthly_payment_drafts where sale_id=s.id) order by id for update;
 perform 1 from public.invoice_items where invoice_id=s.invoice_id or invoice_id in(select d.invoice_id from portal_private.crm_monthly_payment_drafts d where d.sale_id=s.id) order by id for share;
 basis:=portal_private.crm_monthly_payment_basis(s.id,p_position);
 if basis is distinct from p_basis then raise exception 'Monthly payment source changed; refresh review';end if;
 if p_bill is null or p_due is null or not isfinite(p_bill) or not isfinite(p_due) or p_due<p_bill or p_confirm is distinct from true or length(trim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'Actual dates, confirmation and reason required';end if;
 net:=(basis->>'amount_net')::numeric;tax:=(basis->>'amount_tax')::numeric;taxable:=(basis->>'taxable_amount')::numeric;rate:=(basis->>'tax_percent')::numeric;
 insert into public.invoices(company_id,company_name,currency,issued_on,due_on,notes,subtotal,tax_total,total) values(s.company_id,basis->>'company_name',s.currency,p_bill,p_due,'Recorded monthly '||p_position||': '||(basis->>'title')||' · '||(basis->>'quote_number'),net,tax,(basis->>'amount_total')::numeric) returning id into invoice;
 if net>taxable then insert into public.invoice_items(invoice_id,description,quantity,unit_price,tax_percent,net,tax,position) values(invoice,'Monthly — non-taxable amount',1,net-taxable,0,net-taxable,0,0);end if;
 if taxable>0 then insert into public.invoice_items(invoice_id,description,quantity,unit_price,tax_percent,net,tax,position) values(invoice,'Monthly — taxable services',1,taxable,rate,taxable,tax,1);end if;
 if s.project_id is not null then insert into public.fin_invoice_projects(id,project_id,linked_by) values(invoice,s.project_id,auth.uid());end if;
 insert into public.billing_events(invoice_id,action,detail) values(invoice,'Draft created','Finite recorded Monthly period');
 insert into portal_private.crm_monthly_payment_drafts(sale_id,position,request_id,invoice_id,actor_id,payload,evidence) values(s.id,p_position,p_request,invoice,auth.uid(),payload,jsonb_build_object('basis',basis,'bill',p_bill,'due',p_due,'reason',p_reason));
 return invoice;
end$$;
revoke all on function public.crm_monthly_payment_context(uuid,integer),public.create_crm_monthly_payment_draft(uuid,uuid,integer,jsonb,date,date,text,boolean) from public,anon;
grant execute on function public.crm_monthly_payment_context(uuid,integer),public.create_crm_monthly_payment_draft(uuid,uuid,integer,jsonb,date,date,text,boolean) to authenticated;

-- Finite Monthly sale invoices cannot seed a new unbounded recurring schedule.
-- Existing legacy schedules are retained for explicit reconciliation; pausing stays available.
create function portal_private.guard_monthly_finite_recurrence() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.active and (exists(select 1 from public.crm_sales s where s.invoice_id=new.source_invoice and s.payment_terms->>'kind'='Monthly') or exists(select 1 from portal_private.crm_monthly_payment_drafts d where d.invoice_id=new.source_invoice)) then
  raise exception 'Finite Monthly sale billing must use recorded periods; recurring billing requires separate reconciliation';
 end if;
 return new;
end$$;
revoke all on function portal_private.guard_monthly_finite_recurrence() from public,anon,authenticated;
create trigger guard_monthly_finite_recurrence before insert or update on public.invoice_schedules for each row execute function portal_private.guard_monthly_finite_recurrence();
