-- Unapplied: coordinate both pending Phase 2 migrations with matching UI release.
create table portal_private.crm_customer_identity_history(
 request_id uuid primary key,deal_id uuid not null references public.crm_deals,actor_id uuid not null references public.profiles,
 payload jsonb not null,evidence jsonb not null,company_id uuid not null references public.companies,created_at timestamptz not null default now()
);
create index crm_customer_identity_deal on portal_private.crm_customer_identity_history(deal_id,created_at);
create index crm_customer_identity_actor on portal_private.crm_customer_identity_history(actor_id);
create index crm_customer_identity_company on portal_private.crm_customer_identity_history(company_id);
alter table portal_private.crm_customer_identity_history enable row level security;
revoke all on portal_private.crm_customer_identity_history from public,anon,authenticated;
create trigger crm_customer_identity_immutable before update or delete on portal_private.crm_customer_identity_history for each row execute function portal_private.lead_api_evidence_immutable();
create function portal_private.crm_customer_matches(p_lead uuid) returns jsonb language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object('id',c.id,'name',c.name,'email',c.email,'phone',c.phone) order by c.id),'[]')
 from public.companies c join public.crm_leads l on l.id=p_lead
 where (l.email<>'' and lower(trim(c.email))=lower(trim(l.email)))
 or (l.phone<>'' and regexp_replace(c.phone,'[[:space:]().-]','','g')=regexp_replace(l.phone,'[[:space:]().-]','','g'))

 or exists(select 1 from public.client_contacts cc where cc.company_id=c.id and
 ((l.email<>'' and lower(trim(cc.email))=lower(trim(l.email))) or (l.phone<>'' and regexp_replace(cc.phone,'[[:space:]().-]','','g')=regexp_replace(l.phone,'[[:space:]().-]','','g'))));
$$;
revoke all on function portal_private.crm_customer_matches(uuid) from public,anon,authenticated;
create function public.crm_customer_identity_context(p_deal uuid,p_search text default '') returns jsonb language plpgsql stable security definer set search_path='' as $$declare d public.crm_deals;l public.crm_leads;begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active Administrator required';end if;
 if length(coalesce(p_search,''))>160 then raise exception 'Customer search is too long';end if;
 select * into d from public.crm_deals where id=p_deal;if not found then raise exception 'Deal unavailable';end if;select * into l from public.crm_leads where id=d.lead_id;
 return jsonb_build_object('deal',to_jsonb(d),'lead',jsonb_build_object('id',l.id,'version',l.version,'name',l.name,'email',l.email,'phone',l.phone,'company_name',l.company_name),'matches',portal_private.crm_customer_matches(l.id),
 'editable',d.stage not in ('won','lost') and not exists(select 1 from public.crm_sales where deal_id=d.id) and not exists(select 1 from public.crm_quote_publications where deal_id=d.id and status in ('Published','Accepted')),
 'companies',coalesce((select jsonb_agg(to_jsonb(x) order by x.name,x.id) from(select id,name,email,phone from public.companies where trim(coalesce(p_search,''))<>'' and position(lower(trim(p_search)) in lower(name))>0 order by name,id limit 50)x),'[]'),
 'history',coalesce((select jsonb_agg(to_jsonb(x) order by x.created_at desc,x.request_id desc) from(select request_id,actor_id,company_id,created_at,payload,evidence from portal_private.crm_customer_identity_history where deal_id=d.id order by created_at desc,request_id desc limit 100)x),'[]'));
end$$;
create function public.resolve_crm_customer_identity(p_request uuid,p_deal uuid,p_version integer,p_lead_version integer,p_mode text,p_company uuid,p_name text,p_matches jsonb,p_target jsonb,p_reason text,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$
declare d public.crm_deals;l public.crm_leads;c public.companies;r portal_private.crm_customer_identity_history;matches jsonb;payload jsonb;old_company uuid;
begin
 perform 1 from public.profiles where id=auth.uid() and active and role='admin' for share;if not found then raise exception 'Active Administrator required';end if;
 payload:=jsonb_build_object('deal',p_deal,'version',p_version,'lead_version',p_lead_version,'mode',p_mode,'company',p_company,'name',p_name,'matches',p_matches,'target',p_target,'reason',p_reason,'confirmed',p_confirm);
 if p_request is null then raise exception 'Request identity required';end if;
 perform pg_advisory_xact_lock(hashtext('crm-customer-identity'));
 select * into r from portal_private.crm_customer_identity_history where request_id=p_request;
 if found then if r.actor_id<>auth.uid() or r.payload is distinct from payload then raise exception 'Customer identity retry meaning changed';end if;return r.company_id;end if;
 select * into d from public.crm_deals where id=p_deal for update;if not found then raise exception 'Deal unavailable';end if;
 select * into l from public.crm_leads where id=d.lead_id for update;
 if d.version is distinct from p_version or l.version is distinct from p_lead_version then raise exception 'Customer source changed; refresh identity review';end if;
 if p_confirm is distinct from true or length(trim(coalesce(p_reason,''))) not between 3 and 1000 or p_mode is null or p_mode not in ('Link','Create') then raise exception 'Explicit customer decision, confirmation and reason required';end if;
 if d.stage in ('won','lost') or exists(select 1 from public.crm_sales where deal_id=d.id) or exists(select 1 from public.crm_quote_publications where deal_id=d.id and status in ('Published','Accepted')) then raise exception 'Customer identity is locked; withdraw published quotation first or use the accepted change workflow';end if;
 -- Serialize against all directory writers, including those that do not use our advisory lock.
 lock table public.companies,public.client_contacts in share row exclusive mode;
 matches:=portal_private.crm_customer_matches(l.id);
 if matches is distinct from p_matches then raise exception 'Customer matches changed; refresh identity review';end if;
 old_company:=d.company_id;
 if p_mode='Create' then
  if p_company is not null or p_target is not null or length(trim(coalesce(p_name,''))) not between 1 and 160 or (l.email='' and l.phone='') then raise exception 'Actual customer name and lead contact required';end if;
  if jsonb_array_length(matches)>0 then raise exception 'Existing customer match found; explicitly review and link instead of duplicating';end if;
  insert into public.companies(name,email,phone) values(trim(p_name),l.email,l.phone) returning * into c;
 else
  if p_company is null or coalesce(p_name,'')<>'' then raise exception 'Choose the actual existing customer';end if;
  select * into c from public.companies where id=p_company;if not found then raise exception 'Customer unavailable';end if;
  if jsonb_build_object('id',c.id,'name',c.name,'email',c.email,'phone',c.phone) is distinct from p_target then raise exception 'Selected customer changed; refresh identity review';end if;
 end if;
 update public.crm_deals set company_id=c.id,version=version+1 where id=d.id;
 update public.crm_leads set company_id=c.id,version=version+1,updated_at=now() where id=l.id;
 if old_company is distinct from c.id then
  update public.crm_quotes set version=version+1 where deal_id=d.id;
  insert into public.crm_quote_history(deal_id,quote_id,action,actor_id) select d.id,id,'Customer identity changed; review draft quotation',auth.uid() from public.crm_quotes where deal_id=d.id;
 end if;
 insert into portal_private.crm_customer_identity_history(request_id,deal_id,actor_id,payload,evidence,company_id) values(p_request,d.id,auth.uid(),payload,jsonb_build_object('old_company',old_company,'lead_before',to_jsonb(l),'matches',matches,'selected_customer',jsonb_build_object('id',c.id,'name',c.name,'email',c.email,'phone',c.phone),'mode',p_mode),c.id);
 return c.id;
end$$;
revoke all on function public.crm_customer_identity_context(uuid,text),public.resolve_crm_customer_identity(uuid,uuid,integer,integer,text,uuid,text,jsonb,jsonb,text,boolean) from public,anon;
grant execute on function public.crm_customer_identity_context(uuid,text),public.resolve_crm_customer_identity(uuid,uuid,integer,integer,text,uuid,text,jsonb,jsonb,text,boolean) to authenticated;
-- Never let legacy publication silently choose a customer outside the reviewed workflow.
do $$declare definition text;hook text:='if deal.company_id is null then if not public.is_admin()';begin
 definition:=pg_get_functiondef('public.publish_crm_quote(uuid,integer,uuid,boolean)'::regprocedure);
 if position(hook in definition)=0 then raise exception 'Unexpected quotation customer-link source';end if;
 definition:=replace(definition,hook,$guard$
 if not exists(select 1 from portal_private.crm_customer_identity_history h join public.crm_leads l on l.id=deal.lead_id join public.companies c on c.id=p_company where h.deal_id=deal.id and h.company_id=p_company and h.evidence->'selected_customer'=jsonb_build_object('id',c.id,'name',c.name,'email',c.email,'phone',c.phone) and h.evidence->'lead_before'->>'email'=l.email and h.evidence->'lead_before'->>'phone'=l.phone) then raise exception 'Administrator must review and resolve actual customer identity before publishing';end if;
 if deal.company_id is null then if not public.is_admin()$guard$);
 execute definition;
end$$;
