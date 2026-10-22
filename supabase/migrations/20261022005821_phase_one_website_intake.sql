begin;
-- Server-only request receipts. No public contact lookup or arbitrary assignment.
create table if not exists portal_private.website_lead_receipts(
 request_id uuid primary key,
 payload jsonb not null,
 lead_id uuid not null references public.crm_leads,
 created_at timestamptz not null default now()
);
alter table portal_private.website_lead_receipts enable row level security;
revoke all on portal_private.website_lead_receipts from public,anon,authenticated,service_role;
create or replace function public.capture_website_crm_lead(p_request uuid,p_form text,p_name text,p_email text,p_phone text,p_company text,p_message text,p_utm jsonb)
returns void language plpgsql security definer set search_path='' as $$
declare mail text:=lower(trim(coalesce(p_email,''))); norm_phone text:=regexp_replace(coalesce(p_phone,''),'[[:space:]().-]','','g');
 payload jsonb;old_payload jsonb;lid uuid;eid uuid;pid uuid;cid uuid;cids uuid[];
begin
 if p_request is null or p_form is null or p_form not in ('contact','proposal') then raise exception 'Valid website submission required';end if;
 if length(trim(coalesce(p_name,''))) not between 2 and 100 or length(mail)>254 or mail !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then raise exception 'Valid contact required';end if;
 if norm_phone<>'' and norm_phone !~ '^\+[1-9][0-9]{7,14}$' then raise exception 'International phone required';end if;
 if p_company is null or length(p_company)>100 or length(coalesce(p_message,'')) not between 1 and 8000 then raise exception 'Bounded enquiry required';end if;
 if p_utm is null or jsonb_typeof(p_utm)<>'object' or length(p_utm::text)>1800 then raise exception 'UTM object required';end if;
 if exists(select 1 from jsonb_each(p_utm) e where e.key not in ('utm_source','utm_medium','utm_campaign','utm_term','utm_content') or jsonb_typeof(e.value)<>'string' or length(e.value#>>'{}')>300) then raise exception 'Invalid UTM metadata';end if;
 payload:=jsonb_build_object('form',p_form,'name',trim(p_name),'email',mail,'phone',norm_phone,'company',trim(p_company),'message',p_message,'utm',p_utm);
 -- Share the manual/import lock: concurrent channels cannot create two leads.
 perform pg_advisory_xact_lock(hashtext('crm-lead-intake'));
 select r.payload into old_payload from portal_private.website_lead_receipts r where request_id=p_request;
 if found then
  if old_payload is distinct from payload then raise exception 'Submission identity already used';end if;
  return;
 end if;
 select id into eid from public.crm_leads where email=mail;
 select id into pid from public.crm_leads where crm_leads.phone=norm_phone and norm_phone<>'';
 if eid is not null and pid is not null and eid<>pid then raise exception 'Contact conflict requires private review';end if;
 lid:=coalesce(eid,pid);
 if lid is null then
  select array_agg(id) into cids from public.companies where lower(trim(email))=mail or (norm_phone<>'' and regexp_replace(companies.phone,'[[:space:]().-]','','g')=norm_phone);
  if cardinality(cids)>1 then raise exception 'Multiple customer matches require private review';end if;
  cid:=cids[1];
  insert into public.crm_leads(name,email,phone,company_name,source,campaign,form_name,utm,message,owner_id,status,company_id)
  values(trim(p_name),mail,norm_phone,trim(p_company),'Website',coalesce(p_utm->>'utm_campaign',''),p_form,p_utm,p_message,null,'New',cid) returning id into lid;
 else
  update public.crm_leads set updated_at=now() where id=lid;
 end if;
 -- Preserve attribution and original text for every genuine repeat enquiry.
 insert into public.crm_sales_activity(lead_id,kind,body,actor_id)
 values(lid,'Enquiry','Website ('||p_form||')'||E'\n'||coalesce((select string_agg(replace(e.key,'utm_','')||': '||(e.value#>>'{}'),E'\n' order by e.key)||E'\n' from jsonb_each(p_utm) e),'')||p_message,null);
 insert into portal_private.website_lead_receipts(request_id,payload,lead_id) values(p_request,payload,lid);
end$$;
revoke all on function public.capture_website_crm_lead(uuid,text,text,text,text,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.capture_website_crm_lead(uuid,text,text,text,text,text,text,jsonb) to service_role;
-- Reconcile the earlier hosted-only intake implementation and add durable public abuse limits.
create table portal_private.website_intake_limits(
 fingerprint text primary key check(fingerprint ~ '^[0-9a-f]{64}$'),
 window_started timestamptz not null default now(),attempts integer not null check(attempts>0)
);
create index website_intake_limit_window on portal_private.website_intake_limits(window_started);
alter table portal_private.website_intake_limits enable row level security;
revoke all on portal_private.website_intake_limits from public,anon,authenticated,service_role;
create function public.capture_website_crm_lead_v2(p_request uuid,p_form text,p_name text,p_email text,p_phone text,p_company text,p_message text,p_utm jsonb,p_fingerprint text,p_limit integer default 20)
returns void language plpgsql security definer set search_path='' as $$
declare n integer;replayed boolean;lead public.crm_leads;
begin
 if p_fingerprint is null or p_fingerprint !~ '^[0-9a-f]{64}$' or p_limit is null or p_limit not between 1 and 100 then raise exception 'Server intake identity and bounded limit required';end if;
 -- Exact retries still work after the new-enquiry budget is exhausted.
 replayed:=exists(select 1 from portal_private.website_lead_receipts where request_id=p_request);
 if not replayed then
  delete from portal_private.website_intake_limits where window_started<now()-interval '1 day';
  insert into portal_private.website_intake_limits(fingerprint,attempts) values(p_fingerprint,1)
  on conflict(fingerprint) do update set
   attempts=case when website_intake_limits.window_started<=now()-interval '10 minutes' then 1 else website_intake_limits.attempts+1 end,
   window_started=case when website_intake_limits.window_started<=now()-interval '10 minutes' then now() else website_intake_limits.window_started end
  returning attempts into n;
  if n>p_limit then raise exception using errcode='P0429',message='Website intake limit reached';end if;
 end if;
 perform public.capture_website_crm_lead(p_request,p_form,p_name,p_email,p_phone,p_company,p_message,p_utm);
 if not replayed then
  select l.* into lead from public.crm_leads l join portal_private.website_lead_receipts r on r.lead_id=l.id where r.request_id=p_request;
  insert into public.portal_reminders(user_id,event_key,title,view)
  select p.id,'website-enquiry:'||p_request,'Website enquiry received',case when lead.status='Assigned' then 'sales_boards' else 'raw_leads' end
  from public.profiles p where p.active and p.role in ('admin','team')
   and (p.role='admin' or exists(select 1 from public.crm_memberships m join public.crm_roles r on r.id=m.role_id join public.crm_teams t on t.id=m.team_id where m.user_id=p.id and r.active and t.active and r.permissions && array['sales.manage','sales.own']))
   and ((lead.owner_id is not null and p.id=lead.owner_id) or (lead.owner_id is null and (p.role='admin' or exists(select 1 from public.crm_memberships m join public.crm_roles r on r.id=m.role_id join public.crm_teams t on t.id=m.team_id where m.user_id=p.id and r.active and t.active and 'sales.manage'=any(r.permissions)))))
   and coalesce((select enabled from public.portal_reminder_preferences where user_id=p.id),true)
  on conflict(user_id,event_key) do nothing;
 end if;
end$$;
revoke all on function public.capture_website_crm_lead_v2(uuid,text,text,text,text,text,text,jsonb,text,integer) from public,anon,authenticated;
grant execute on function public.capture_website_crm_lead_v2(uuid,text,text,text,text,text,text,jsonb,text,integer) to service_role;
commit;
