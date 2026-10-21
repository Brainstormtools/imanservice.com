begin;
-- Preparation/review only: never post credits, invoices, WHT, client credit or cash.
create table public.fin_adjustment_manager_designations (
 id uuid primary key,user_id uuid not null references public.profiles,revision integer not null check(revision>0),
 active boolean not null,reason text not null check(length(trim(reason)) between 3 and 2000),
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(user_id,revision)
);
create index adjustment_manager_actor on public.fin_adjustment_manager_designations(actor_id);
create table public.crm_boq_adjustment_preparations (
 id uuid primary key,publication_id uuid not null references public.crm_boq_revision_publications,
 project_id uuid not null references public.projects,invoice_id uuid not null references public.invoices,
 revision integer not null check(revision>0),previous_id uuid unique references public.crm_boq_adjustment_preparations,
 snapshot jsonb not null,reason text not null check(length(trim(reason)) between 3 and 2000),
 prepared_by uuid not null references public.profiles,prepared_at timestamptz not null default now(),unique(publication_id,revision)
);
create index boq_adjustment_project on public.crm_boq_adjustment_preparations(project_id);
create index boq_adjustment_invoice on public.crm_boq_adjustment_preparations(invoice_id);
create index boq_adjustment_preparer on public.crm_boq_adjustment_preparations(prepared_by);
create table public.crm_boq_adjustment_reviews (
 id uuid primary key default gen_random_uuid(),preparation_id uuid not null unique references public.crm_boq_adjustment_preparations,
 outcome text not null check(outcome in ('Approved','Returned')),reason text not null check(length(trim(reason)) between 3 and 2000),
 reviewed_by uuid not null references public.profiles,reviewed_at timestamptz not null default now(),
 designation_id uuid not null references public.fin_adjustment_manager_designations,receipt jsonb not null
);
create index boq_adjustment_reviewer on public.crm_boq_adjustment_reviews(reviewed_by);
create index boq_adjustment_designation on public.crm_boq_adjustment_reviews(designation_id);
create function portal_private.adjustment_manager(p_user uuid) returns uuid language sql stable security definer set search_path='' as $$
 select d.id from public.fin_adjustment_manager_designations d join public.profiles p on p.id=d.user_id
 where d.user_id=p_user and p.active and p.role in ('admin','team') and d.active
 and not exists(select 1 from public.fin_adjustment_manager_designations n where n.user_id=d.user_id and n.revision>d.revision);
$$;
create function portal_private.adjustment_access() returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and (portal_private.payables_access() or portal_private.adjustment_manager(auth.uid()) is not null);
$$;
do $$declare t text;begin
 foreach t in array array['fin_adjustment_manager_designations','crm_boq_adjustment_preparations','crm_boq_adjustment_reviews'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on public.%I from public,anon,authenticated',t);
  execute format('grant select on public.%I to authenticated',t);
  execute format('create trigger adjustment_evidence_immutable before update or delete on public.%I for each row execute function portal_private.boq_line_evidence_immutable()',t);
 end loop;
end$$;
create policy adjustment_manager_admin_read on public.fin_adjustment_manager_designations for select to authenticated using(public.is_admin());
create policy boq_adjustment_preparation_read on public.crm_boq_adjustment_preparations for select to authenticated using(portal_private.adjustment_access());
create policy boq_adjustment_review_read on public.crm_boq_adjustment_reviews for select to authenticated using(portal_private.adjustment_access());

create function public.boq_adjustment_access() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.is_staff() then raise exception 'Current internal portal account required';end if;
 return jsonb_build_object('prepare',portal_private.payables_access(),'manager_id',portal_private.adjustment_manager(auth.uid()),'configure',public.is_admin())
 ||case when public.is_admin() then jsonb_build_object('people',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name,'active',active,'role',role) order by name,id) from public.profiles p where (active and role in ('admin','team')) or exists(select 1 from public.fin_adjustment_manager_designations d where d.user_id=p.id)),'[]'::jsonb),
 'designation_history',coalesce((select jsonb_agg(to_jsonb(d) order by user_id,revision) from public.fin_adjustment_manager_designations d),'[]'::jsonb)) else '{}'::jsonb end;
end$$;
create function public.set_boq_adjustment_manager(p_id uuid,p_user uuid,p_previous integer,p_active boolean,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare old public.fin_adjustment_manager_designations;latest integer;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Current administrator designation required';end if;
 if p_id is null or p_user is null or p_previous is null or p_previous<0 or p_active is null or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Actual account, prior revision, grant/revoke choice and reason required';end if;
 perform 1 from public.profiles where id=p_user for update;
 if not found or (p_active and not exists(select 1 from public.profiles where id=p_user and active and role in ('admin','team'))) then raise exception 'Actual active internal Manager account required for a grant';end if;
 select * into old from public.fin_adjustment_manager_designations where id=p_id;
 if old.id is not null then
  if old.user_id=p_user and old.revision=p_previous+1 and old.active=p_active and old.reason=trim(p_reason) and old.actor_id=auth.uid() then return old.id;end if;
  raise exception 'Designation ID already has different immutable evidence';
 end if;
 select coalesce(max(revision),0) into latest from public.fin_adjustment_manager_designations where user_id=p_user;
 if latest<>p_previous or (latest=0 and not p_active) then raise exception 'Exact prior Manager designation revision required';end if;
 insert into public.fin_adjustment_manager_designations(id,user_id,revision,active,reason,actor_id) values(p_id,p_user,latest+1,p_active,trim(p_reason),auth.uid());return p_id;
end$$;

create function portal_private.boq_adjustment_basis(p_publication uuid,p_invoice uuid) returns jsonb language plpgsql set search_path='' as $$
declare pub public.crm_boq_revision_publications;q public.crm_boq_line_proposals;d public.crm_boq_revision_decisions;i public.invoices;original numeric;replacement numeric;delta numeric;items jsonb;
begin
 select * into pub from public.crm_boq_revision_publications where id=p_publication;
 if pub.id is null then raise exception 'Actual frozen BOQ revision required';end if;
 perform portal_private.boq_revision_current(pub.proposal_id);
 select * into q from public.crm_boq_line_proposals where id=pub.proposal_id;
 select * into d from public.crm_boq_revision_decisions where publication_id=pub.id;
 if pub.internal_snapshot->'proposal' is distinct from to_jsonb(q) or pub.client_data->>'action' is distinct from q.action or pub.client_data->'original' is distinct from q.source or pub.client_data->'replacement' is distinct from coalesce(q.replacement,'null'::jsonb) or d.outcome is distinct from 'Accepted' or d.consent is distinct from true or exists(select 1 from public.crm_boq_revision_publications where proposal_id=q.id and revision>pub.revision) then raise exception 'Exact current client-Accepted line revision required';end if;
 select * into i from public.invoices where id=p_invoice for update;
 if i.id is null or i.status<>'Issued' or i.company_id<>pub.company_id or i.currency<>'PKR' or pub.client_data->>'currency'<>'PKR'
  or not exists(select 1 from portal_private.finance_invoice_links() l where l.invoice_id=i.id and l.project_id=q.project_id)
  or exists(select 1 from portal_private.finance_invoice_links() l where l.invoice_id=i.id and l.project_id<>q.project_id)
  or i.boq_offer_id is not null then raise exception 'Issued PKR original project invoice for the same company required';end if;
 original:=(q.source->>'total')::numeric;
 replacement:=case when q.action='Remove' then 0 else round((q.replacement->>'quantity')::numeric*(q.replacement->>'unit_price')::numeric,2) end;
 delta:=replacement-original;
 if original is null or original<=0 or original<>round(original,2) or delta is null or delta=0 or abs(delta)>=100000000 then raise exception 'Positive original net amount and bounded nonzero line difference required';end if;
 select coalesce(jsonb_agg(to_jsonb(l) order by l.position,l.id),'[]'::jsonb) into items from public.invoice_items l where invoice_id=i.id;
 return jsonb_build_object('source',jsonb_build_object('publication_id',pub.id,'publication_revision',pub.revision,'published_at',pub.published_at,'client_data',pub.client_data,
  'proposal_id',q.id,'review_id',pub.review_id,'project_id',q.project_id,'company_id',pub.company_id,'sale_id',q.sale_id,'change_id',q.change_id,'change_version',q.change_version,
  'baseline_id',q.baseline_id,'baseline_version',q.baseline_version,'line_position',q.line_position,'action',q.action,'original',q.source,'replacement',q.replacement,
  'acceptance',jsonb_build_object('id',d.id,'actor_id',d.actor_id,'decided_at',d.decided_at,'note',d.note,'consent',d.consent)),
  'invoice',to_jsonb(i),'invoice_items',items,'kind',case when delta<0 then 'Credit note' else 'Debit note' end,'original_net',original,'replacement_net',replacement,'difference_net',abs(delta));
end$$;
create function public.boq_adjustment_invoice_context(p_publication uuid,p_invoice uuid) returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Current Accounts preparation access required';end if;
 return portal_private.boq_adjustment_basis(p_publication,p_invoice);
end$$;

create function portal_private.boq_adjustment_preview(p_publication uuid,p_invoice uuid,p_lines jsonb,p_wht jsonb) returns jsonb language plpgsql set search_path='' as $$
declare b jsonb;r jsonb;l public.invoice_items;net numeric;tax numeric;net_total numeric:=0;tax_total numeric:=0;lines jsonb:='[]';wht jsonb;
begin
 b:=portal_private.boq_adjustment_basis(p_publication,p_invoice);
 if jsonb_typeof(p_lines) is distinct from 'array' or jsonb_array_length(p_lines) not between 1 and 100 then raise exception 'Explicit original invoice-line mapping required';end if;
 if exists(select 1 from jsonb_array_elements(p_lines) x group by (x->>'item_id')::uuid having count(*)>1) then raise exception 'Original invoice line cannot be mapped twice';end if;
 for r in select value from jsonb_array_elements(p_lines) order by value->>'item_id' loop
  if jsonb_typeof(r) is distinct from 'object' or (select count(*) from jsonb_object_keys(r))<>2 or not(r ?& array['item_id','net']) or coalesce(r->>'net','') !~ '^\d{1,9}(\.\d{1,2})?$' then raise exception 'Explicit line ID and positive cent-precision net amount required';end if;
  select * into l from public.invoice_items where id=(r->>'item_id')::uuid and invoice_id=p_invoice for share;
  net:=(r->>'net')::numeric;
  if l.id is null or net<=0 or net>=100000000 or (b->>'kind'='Credit note' and net>l.net) then raise exception 'Actual original invoice line and supported net amount required';end if;
  tax:=round(net*l.tax_percent/100,2);net_total:=net_total+net;tax_total:=tax_total+tax;
  lines:=lines||jsonb_build_array(jsonb_build_object('item_id',l.id,'description',l.description,'original_net',l.net,'tax_percent',l.tax_percent,'net',net,'tax',tax,'gross',net+tax));
 end loop;
 if net_total<>(b->>'difference_net')::numeric then raise exception 'Mapped invoice-line nets must equal the exact accepted BOQ net difference';end if;
 if p_wht is not null and p_wht<>'null'::jsonb then
  if jsonb_typeof(p_wht) is distinct from 'object' or (select count(*) from jsonb_object_keys(p_wht))<>2 or not(p_wht ?& array['amount','certificate_reference']) or coalesce(p_wht->>'amount','') !~ '^-?\d{1,9}(\.\d{1,2})?$'
   or (p_wht->>'amount')::numeric=0 or abs((p_wht->>'amount')::numeric)>=100000000 or jsonb_typeof(p_wht->'certificate_reference') is distinct from 'string' or length(trim(p_wht->>'certificate_reference')) not between 1 and 200 then raise exception 'Manual nonzero WHT amount and actual certificate reference required';end if;
  wht:=jsonb_build_object('amount',(p_wht->>'amount')::numeric,'certificate_reference',trim(p_wht->>'certificate_reference'));
 end if;
 return b||jsonb_build_object('lines',lines,'net',net_total,'tax',tax_total,'gross',net_total+tax_total,'manual_wht',wht,'posting_state','Preparation only; not issued or posted');
end$$;
create function public.preview_boq_adjustment(p_publication uuid,p_invoice uuid,p_lines jsonb,p_wht jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Current Accounts preparation access required';end if;
 return portal_private.boq_adjustment_preview(p_publication,p_invoice,p_lines,p_wht);
end$$;

create function public.prepare_boq_adjustment(p_id uuid,p_publication uuid,p_invoice uuid,p_previous uuid,p_lines jsonb,p_wht jsonb,p_expected jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare s jsonb;old public.crm_boq_adjustment_preparations;latest public.crm_boq_adjustment_preparations;
begin
 if auth.uid() is null or not portal_private.payables_access() then raise exception 'Current Accounts preparation access required';end if;
 if p_id is null or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Preparation ID and actual invoice-line mapping reason required';end if;
 -- Source/project/invoice locks also serialize preparations and decisions for this revision.
 s:=portal_private.boq_adjustment_preview(p_publication,p_invoice,p_lines,p_wht);
 if s is distinct from p_expected then raise exception 'Exact current calculated adjustment preview required';end if;
 select * into old from public.crm_boq_adjustment_preparations where id=p_id;
 if old.id is not null then
  if old.publication_id=p_publication and old.invoice_id=p_invoice and old.previous_id is not distinct from p_previous and old.snapshot=s and old.reason=trim(p_reason) and old.prepared_by=auth.uid() then return old.id;end if;
  raise exception 'Preparation ID already has different immutable evidence';
 end if;
 select * into latest from public.crm_boq_adjustment_preparations where publication_id=p_publication order by revision desc limit 1;
 if latest.id is distinct from p_previous or (latest.id is not null and not exists(select 1 from public.crm_boq_adjustment_reviews where preparation_id=latest.id and outcome='Returned')) then raise exception 'Exact latest Returned preparation required before a correction';end if;
 insert into public.crm_boq_adjustment_preparations(id,publication_id,project_id,invoice_id,revision,previous_id,snapshot,reason,prepared_by)
 values(p_id,p_publication,(s->'source'->>'project_id')::uuid,p_invoice,coalesce(latest.revision,0)+1,p_previous,s,trim(p_reason),auth.uid());return p_id;
end$$;
create function public.review_boq_adjustment(p_preparation uuid,p_manager uuid,p_expected jsonb,p_outcome text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare p public.crm_boq_adjustment_preparations;r public.crm_boq_adjustment_reviews;d public.fin_adjustment_manager_designations;current_snapshot jsonb;lines jsonb;
begin
 perform 1 from public.profiles where id=auth.uid() for update;
 if auth.uid() is null or portal_private.adjustment_manager(auth.uid()) is distinct from p_manager or p_manager is null then raise exception 'Exact current designated Manager approval authority required';end if;
 select * into d from public.fin_adjustment_manager_designations where id=p_manager;
 if p_outcome is null or p_outcome not in ('Approved','Returned') or length(coalesce(trim(p_reason),'')) not between 3 and 2000 then raise exception 'Explicit approval/return and actual decision reason required';end if;
 select * into p from public.crm_boq_adjustment_preparations where id=p_preparation;
 if p.id is null or p.prepared_by=auth.uid() or p.snapshot is distinct from p_expected then raise exception 'Different Manager and exact frozen Accounts preparation required';end if;
 perform 1 from public.projects where id=p.project_id for update;
 select * into r from public.crm_boq_adjustment_reviews where preparation_id=p.id;
 if r.id is not null then
  if r.reviewed_by=auth.uid() and r.designation_id=p_manager and r.outcome=p_outcome and r.reason=trim(p_reason) then return r.id;end if;
  raise exception 'Preparation already has a different immutable decision';
 end if;
 if exists(select 1 from public.crm_boq_adjustment_preparations where publication_id=p.publication_id and revision>p.revision) then raise exception 'Exact latest preparation required';end if;
 if p_outcome='Approved' then
  if not portal_private.crm_user_permission(p.prepared_by,'finance.manage') then raise exception 'Current Accounts preparer authority required';end if;
  select jsonb_agg(jsonb_build_object('item_id',x->>'item_id','net',x->>'net') order by x->>'item_id') into lines from jsonb_array_elements(p.snapshot->'lines') x;
  current_snapshot:=portal_private.boq_adjustment_preview(p.publication_id,p.invoice_id,lines,p.snapshot->'manual_wht');
  if current_snapshot is distinct from p.snapshot then raise exception 'Invoice or BOQ source changed; return and prepare a fresh adjustment';end if;
 end if;
 insert into public.crm_boq_adjustment_reviews(preparation_id,outcome,reason,reviewed_by,designation_id,receipt)
 values(p.id,p_outcome,trim(p_reason),auth.uid(),p_manager,jsonb_build_object('preparation',to_jsonb(p),'manager_designation',to_jsonb(d),'posting_state','Approved/Returned preparation only; no balance, client credit, WHT or cash posting')) returning * into r;return r.id;
end$$;

create function public.boq_adjustment_register() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not portal_private.adjustment_access() then raise exception 'Current Accounts or designated Manager access required';end if;
 return jsonb_build_object('preparations',coalesce((select jsonb_agg(to_jsonb(p)||jsonb_build_object('review',(select to_jsonb(r) from public.crm_boq_adjustment_reviews r where r.preparation_id=p.id)) order by p.prepared_at,p.id) from public.crm_boq_adjustment_preparations p),'[]'::jsonb))
 ||case when portal_private.payables_access() then jsonb_build_object('sources',coalesce((select jsonb_agg(jsonb_build_object('id',pub.id,'project_id',pub.project_id,'data',pub.client_data,'revision',pub.revision) order by pub.published_at,pub.id) from public.crm_boq_revision_publications pub join public.crm_boq_revision_decisions d on d.publication_id=pub.id where d.outcome='Accepted' and d.consent and pub.client_data->>'currency'='PKR'),'[]'::jsonb),
 'invoices',coalesce((select jsonb_agg(jsonb_build_object('id',i.id,'number',i.number,'project_id',l.project_id,'company_id',i.company_id,'currency',i.currency) order by i.number,i.id) from public.invoices i join portal_private.finance_invoice_links() l on l.invoice_id=i.id where i.status='Issued' and i.currency='PKR' and i.boq_offer_id is null),'[]'::jsonb)) else '{}'::jsonb end;
end$$;
revoke all on function portal_private.adjustment_manager(uuid),portal_private.adjustment_access(),portal_private.boq_adjustment_basis(uuid,uuid),portal_private.boq_adjustment_preview(uuid,uuid,jsonb,jsonb) from public,anon,authenticated;
-- Read policies need only this boolean authority helper, never the private source/calculation core.
grant execute on function portal_private.adjustment_access() to authenticated;
revoke all on function public.boq_adjustment_access(),public.set_boq_adjustment_manager(uuid,uuid,integer,boolean,text),public.boq_adjustment_invoice_context(uuid,uuid),public.preview_boq_adjustment(uuid,uuid,jsonb,jsonb),public.prepare_boq_adjustment(uuid,uuid,uuid,uuid,jsonb,jsonb,jsonb,text),public.review_boq_adjustment(uuid,uuid,jsonb,text,text),public.boq_adjustment_register() from public,anon,authenticated;
grant execute on function public.boq_adjustment_access(),public.set_boq_adjustment_manager(uuid,uuid,integer,boolean,text),public.boq_adjustment_invoice_context(uuid,uuid),public.preview_boq_adjustment(uuid,uuid,jsonb,jsonb),public.prepare_boq_adjustment(uuid,uuid,uuid,uuid,jsonb,jsonb,jsonb,text),public.review_boq_adjustment(uuid,uuid,jsonb,text,text),public.boq_adjustment_register() to authenticated;
commit;
