begin;
-- No provider credentials, Page connections, actual contacts or assignments are seeded.
create table portal_private.crm_meta_receipts(
 page_id text not null check(page_id ~ '^[0-9]{1,40}$'),event_id text not null check(event_id ~ '^[0-9]{1,40}$'),
 payload jsonb not null,provider jsonb not null,lead_id uuid references public.crm_leads,
 review_issue text,received_at timestamptz not null default now(),primary key(page_id,event_id),
 check((lead_id is null)=(review_issue is not null))
);
create index crm_meta_receipt_lead on portal_private.crm_meta_receipts(lead_id);
create index crm_meta_review_cursor on portal_private.crm_meta_receipts(received_at desc,page_id desc,event_id desc) where review_issue is not null;
create table portal_private.crm_meta_resolutions(
 page_id text not null,event_id text not null,payload jsonb not null,lead_id uuid not null references public.crm_leads,
 actor_id uuid not null references public.profiles,reason text not null check(length(trim(reason)) between 3 and 1000),
 created_at timestamptz not null default now(),primary key(page_id,event_id),
 foreign key(page_id,event_id) references portal_private.crm_meta_receipts
);
create index crm_meta_resolution_actor on portal_private.crm_meta_resolutions(actor_id);
create index crm_meta_resolution_lead on portal_private.crm_meta_resolutions(lead_id);
alter table portal_private.crm_meta_receipts enable row level security;
alter table portal_private.crm_meta_resolutions enable row level security;
revoke all on portal_private.crm_meta_receipts,portal_private.crm_meta_resolutions from public,anon,authenticated,service_role;
create trigger meta_receipt_immutable before update or delete on portal_private.crm_meta_receipts for each row execute function portal_private.lead_api_evidence_immutable();
create trigger meta_resolution_immutable before update or delete on portal_private.crm_meta_resolutions for each row execute function portal_private.lead_api_evidence_immutable();
create function portal_private.apply_meta_crm_lead(p_page text,p_event text,p_data jsonb) returns uuid language plpgsql set search_path='' as $$
declare canonical jsonb;mail text;v_phone text;v_name text;v_company text;v_city text;v_country text;v_message text;v_form_name text;v_campaign text;v_utm jsonb;v_tags text[];v_activity text;eid uuid;pid uuid;lid uuid;cid uuid;cids uuid[];lead public.crm_leads;
begin
 if p_event is null or length(trim(p_event)) not between 1 and 200 or p_event ~ '[[:cntrl:]]' or jsonb_typeof(p_data) is distinct from 'object' then raise exception using errcode='P0422',message='Stable event identity and lead object required';end if;
 if exists(select 1 from jsonb_each(p_data) e where e.key not in ('name','email','phone','company','city','country','message','form','campaign','utm','tags') or (e.key not in ('utm','tags') and jsonb_typeof(e.value)<>'string')) then raise exception using errcode='P0422',message='Supported lead fields required';end if;
 v_name:=trim(coalesce(p_data->>'name',''));mail:=lower(trim(coalesce(p_data->>'email','')));v_phone:=regexp_replace(coalesce(p_data->>'phone',''),'[[:space:]().-]','','g');v_company:=trim(coalesce(p_data->>'company',''));v_city:=trim(coalesce(p_data->>'city',''));v_country:=trim(coalesce(p_data->>'country',''));v_message:=coalesce(p_data->>'message','');v_form_name:=trim(coalesce(p_data->>'form',''));v_campaign:=trim(coalesce(p_data->>'campaign',''));v_utm:=coalesce(p_data->'utm','{}');
 if length(v_name) not between 2 and 160 or (mail='' and v_phone='') or (mail<>'' and (length(mail)>254 or mail !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$')) or (v_phone<>'' and v_phone !~ '^\+[1-9][0-9]{7,14}$') or length(v_company)>160 or length(v_city)>100 or length(v_country)>100 or length(v_message)>8000 or length(v_form_name)>100 or length(v_campaign)>300 then raise exception using errcode='P0422',message='Valid bounded contact and enquiry fields required';end if;
 if jsonb_typeof(v_utm) is distinct from 'object' or length(v_utm::text)>1800 or exists(select 1 from jsonb_each(v_utm) e where e.key not in ('utm_source','utm_medium','utm_campaign','utm_term','utm_content') or jsonb_typeof(e.value)<>'string' or length(e.value#>>'{}')>300) then raise exception using errcode='P0422',message='Bounded UTM metadata required';end if;
 if jsonb_typeof(coalesce(p_data->'tags','[]')) is distinct from 'array' or exists(select 1 from jsonb_array_elements(coalesce(p_data->'tags','[]')) t where jsonb_typeof(t)<>'string') then raise exception using errcode='P0422',message='Actual tag labels required';end if;
 select coalesce(array_agg(t#>>'{}'),'{}'::text[]) into v_tags from jsonb_array_elements(coalesce(p_data->'tags','[]')) t;
 if not public.valid_labels(v_tags) then raise exception using errcode='P0422',message='At most 20 actual tags of 1–40 characters required';end if;
 canonical:=jsonb_build_object('name',v_name,'email',mail,'phone',v_phone,'company',v_company,'city',v_city,'country',v_country,'message',v_message,'form',v_form_name,'campaign',v_campaign,'utm',v_utm,'tags',to_jsonb(v_tags));
 v_activity:='Meta Page: '||p_page||E'\nEvent: '||trim(p_event)||E'\nAcquisition: '||(canonical-'name'-'email'-'phone'-'company'-'message')::text||E'\n'||coalesce(nullif(v_message,''),'Enquiry received');
 if length(v_activity)>10000 then raise exception using errcode='P0422',message='Combined enquiry and acquisition exceed the supported timeline budget';end if;
 perform pg_advisory_xact_lock(hashtext('crm-lead-intake'));
 select id into eid from public.crm_leads where email=mail and mail<>'';
 select id into pid from public.crm_leads where crm_leads.phone=v_phone and v_phone<>'';
 if eid is not null and pid is not null and eid<>pid then raise exception using errcode='P0422',message='Contact conflict requires private review';end if;
 lid:=coalesce(eid,pid);
 if lid is null then
  select array_agg(id) into cids from public.companies where (mail<>'' and lower(trim(email))=mail) or (v_phone<>'' and regexp_replace(companies.phone,'[[:space:]().-]','','g')=v_phone);
  if cardinality(cids)>1 then raise exception using errcode='P0422',message='Multiple customer matches require private review';end if;cid:=cids[1];
  insert into public.crm_leads(name,email,phone,company_name,city,country,source,campaign,form_name,utm,message,tags,company_id) values(v_name,mail,v_phone,v_company,v_city,v_country,'Meta',coalesce(nullif(v_campaign,''),v_utm->>'utm_campaign',''),coalesce(nullif(v_form_name,''),p_page),v_utm,v_message,v_tags,cid) returning id into lid;
 else update public.crm_leads set updated_at=now() where id=lid;end if;
 insert into public.crm_sales_activity(lead_id,kind,body,actor_id) values(lid,'Enquiry',v_activity,null);
 update public.crm_deals set last_activity_at=now() where lead_id=lid;
 select * into lead from public.crm_leads where id=lid;
 insert into public.portal_reminders(user_id,event_key,title,view)
 select p.id,'meta-enquiry:'||p_page||':'||trim(p_event),'Meta enquiry received',case when lead.status='Assigned' then 'sales_boards' else 'raw_leads' end from public.profiles p
 where p.active and p.role in ('admin','team') and (p.role='admin' or exists(select 1 from public.crm_memberships m join public.crm_roles r on r.id=m.role_id join public.crm_teams t on t.id=m.team_id where m.user_id=p.id and r.active and t.active and r.permissions && array['sales.manage','sales.own']))
 and ((lead.owner_id is not null and p.id=lead.owner_id) or (lead.owner_id is null and (p.role='admin' or exists(select 1 from public.crm_memberships m join public.crm_roles r on r.id=m.role_id join public.crm_teams t on t.id=m.team_id where m.user_id=p.id and r.active and t.active and 'sales.manage'=any(r.permissions)))))
 and coalesce((select enabled from public.portal_reminder_preferences where user_id=p.id),true) on conflict(user_id,event_key) do nothing;
 return lid;
end$$;
create function public.capture_meta_crm_lead(p_page text,p_event text,p_data jsonb,p_provider jsonb) returns void language plpgsql security definer set search_path='' as $$
declare lid uuid;issue text;
begin
 if p_page is null or p_page !~ '^[0-9]{1,40}$' or p_event is null or p_event !~ '^[0-9]{1,40}$' or jsonb_typeof(p_data) is distinct from 'object' or jsonb_typeof(p_provider) is distinct from 'object' or octet_length(p_data::text||p_provider::text)>65536 then raise exception 'Bounded actual provider identities and fields required';end if;
 if p_provider->>'page_id' is distinct from p_page or p_provider->>'lead_id' is distinct from p_event or jsonb_typeof(p_provider->'field_data') is distinct from 'object' or exists(select 1 from jsonb_each(p_provider) e where e.key not in ('page_id','lead_id','form_id','ad_id','adgroup_id','adset_id','campaign_id','campaign_name','platform','created_time','field_data') or (e.key<>'field_data' and jsonb_typeof(e.value)<>'string')) then raise exception 'Explicit provider evidence required';end if;
 perform pg_advisory_xact_lock(hashtext('crm-lead-intake'));
 -- Provider lead identity is authoritative; retain the first receipt, including its original values.
 if exists(select 1 from portal_private.crm_meta_receipts where page_id=p_page and event_id=p_event) then return;end if;
 begin lid:=portal_private.apply_meta_crm_lead(p_page,p_event,p_data);
 exception when sqlstate 'P0422' then issue:=sqlerrm;end;
 insert into portal_private.crm_meta_receipts(page_id,event_id,payload,provider,lead_id,review_issue) values(p_page,p_event,p_data,p_provider,lid,issue);
 if issue is not null then
  insert into public.portal_reminders(user_id,event_key,title,view)
  select id,'meta-review:'||p_page||':'||p_event,'Meta enquiry needs contact review','sales_configuration' from public.profiles p where p.active and p.role='admin' and coalesce((select enabled from public.portal_reminder_preferences where user_id=p.id),true) on conflict(user_id,event_key) do nothing;
 end if;
end$$;
create function public.resolve_meta_crm_lead(p_page text,p_event text,p_data jsonb,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare actor public.profiles;r portal_private.crm_meta_receipts;prior portal_private.crm_meta_resolutions;lid uuid;
begin
 select * into actor from public.profiles where id=auth.uid() for share;
 if actor.id is null or not actor.active or actor.role<>'admin' then raise exception 'Current Administrator access required';end if;
 if length(coalesce(trim(p_reason),'')) not between 3 and 1000 then raise exception 'Actual correction reason required';end if;
 perform pg_advisory_xact_lock(hashtext('crm-lead-intake'));
 select * into r from portal_private.crm_meta_receipts where page_id=p_page and event_id=p_event;
 if r.event_id is null or r.review_issue is null then raise exception 'Actual unresolved Meta receipt required';end if;
 select * into prior from portal_private.crm_meta_resolutions where page_id=p_page and event_id=p_event;
 if found then
  if prior.actor_id=actor.id and prior.reason=trim(p_reason) and prior.payload=p_data then return;end if;
  raise exception 'Receipt already resolved; reload current review register';
 end if;
 lid:=portal_private.apply_meta_crm_lead(p_page,p_event,p_data);
 insert into portal_private.crm_meta_resolutions(page_id,event_id,payload,lead_id,actor_id,reason) values(p_page,p_event,p_data,lid,actor.id,trim(p_reason));
end$$;
create function public.crm_meta_review_register(p_before timestamptz default null,p_page text default '',p_event text default '') returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Current Administrator access required';end if;
 return jsonb_build_object('receipts',coalesce((select jsonb_agg(to_jsonb(r)||jsonb_build_object('resolution',(select to_jsonb(c) from portal_private.crm_meta_resolutions c where c.page_id=r.page_id and c.event_id=r.event_id)) order by r.received_at desc,r.page_id desc,r.event_id desc) from (select * from portal_private.crm_meta_receipts where review_issue is not null and (p_before is null or (received_at,page_id,event_id)<(p_before,p_page,p_event)) order by received_at desc,page_id desc,event_id desc limit 100) r),'[]'::jsonb));
end$$;
revoke all on function portal_private.apply_meta_crm_lead(text,text,jsonb) from public,anon,authenticated,service_role;
revoke all on function public.capture_meta_crm_lead(text,text,jsonb,jsonb),public.resolve_meta_crm_lead(text,text,jsonb,text),public.crm_meta_review_register(timestamptz,text,text) from public,anon,authenticated,service_role;
grant execute on function public.capture_meta_crm_lead(text,text,jsonb,jsonb) to service_role;
grant execute on function public.resolve_meta_crm_lead(text,text,jsonb,text),public.crm_meta_review_register(timestamptz,text,text) to authenticated;
commit;
