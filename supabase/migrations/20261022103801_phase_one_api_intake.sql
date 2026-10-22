begin;
-- Actual administrator-created server-to-server sources. No sources or assignments are seeded.
create table portal_private.crm_lead_api_sources(
 id uuid primary key,name text not null check(length(trim(name)) between 2 and 100),
 key_hash text not null unique check(key_hash ~ '^[0-9a-f]{64}$'),key_suffix text not null,
 active boolean not null default true,version integer not null default 1,
 created_by uuid not null references public.profiles,created_at timestamptz not null default now(),
 revoked_by uuid references public.profiles,revoked_at timestamptz
);
create index lead_api_source_creator on portal_private.crm_lead_api_sources(created_by);
create index lead_api_source_revoker on portal_private.crm_lead_api_sources(revoked_by);
create table portal_private.crm_lead_api_history(
 id uuid primary key default gen_random_uuid(),source_id uuid not null references portal_private.crm_lead_api_sources,
 action text not null check(action in ('Created','Revoked')),actor_id uuid not null references public.profiles,
 reason text not null check(length(trim(reason)) between 3 and 1000),snapshot jsonb not null,created_at timestamptz not null default now()
);
create index lead_api_history_source on portal_private.crm_lead_api_history(source_id,created_at);
create index lead_api_history_actor on portal_private.crm_lead_api_history(actor_id);
create table portal_private.crm_lead_api_receipts(
 source_id uuid not null references portal_private.crm_lead_api_sources,event_id text not null check(length(event_id) between 1 and 200),
 payload jsonb not null,lead_id uuid not null references public.crm_leads,received_at timestamptz not null default now(),primary key(source_id,event_id)
);
create index lead_api_receipt_lead on portal_private.crm_lead_api_receipts(lead_id);
create function portal_private.lead_api_evidence_immutable() returns trigger language plpgsql set search_path='' as $$
begin raise exception 'Lead intake evidence is immutable';end$$;
do $$declare t text;begin
 foreach t in array array['crm_lead_api_sources','crm_lead_api_history','crm_lead_api_receipts'] loop
  execute format('alter table portal_private.%I enable row level security',t);
  execute format('revoke all on portal_private.%I from public,anon,authenticated,service_role',t);
 end loop;
 foreach t in array array['crm_lead_api_history','crm_lead_api_receipts'] loop
  execute format('create trigger lead_api_evidence_immutable before update or delete on portal_private.%I for each row execute function portal_private.lead_api_evidence_immutable()',t);
 end loop;
end$$;
create function portal_private.lead_api_source_summary(s portal_private.crm_lead_api_sources) returns jsonb language sql stable set search_path='' as $$
 select jsonb_build_object('id',s.id,'name',s.name,'key_suffix',s.key_suffix,'active',s.active,'version',s.version,'created_by',s.created_by,'created_at',s.created_at,'revoked_by',s.revoked_by,'revoked_at',s.revoked_at);
$$;
create function public.create_crm_lead_api_source(p_id uuid,p_name text,p_reason text) returns jsonb language plpgsql security definer set search_path='' as $$
declare s portal_private.crm_lead_api_sources;actor public.profiles;secret text;summary jsonb;
begin
 select * into actor from public.profiles where id=auth.uid() for share;
 if actor.id is null or not actor.active or actor.role<>'admin' then raise exception 'Current Administrator access required';end if;
 if p_id is null or length(coalesce(trim(p_name),'')) not between 2 and 100 or length(coalesce(trim(p_reason),'')) not between 3 and 1000 then raise exception 'Actual source name and reason required';end if;
 perform pg_advisory_xact_lock(hashtext('crm-api-source:'||p_id));
 select * into s from portal_private.crm_lead_api_sources where id=p_id;
 if found then
  if s.created_by<>auth.uid() or s.name<>trim(p_name) or not exists(select 1 from portal_private.crm_lead_api_history where source_id=s.id and action='Created' and reason=trim(p_reason)) then raise exception 'Source identity already has different evidence';end if;
  return jsonb_build_object('source',portal_private.lead_api_source_summary(s),'key',null,'already_created',true);
 end if;
 secret:='iman_lead_'||replace(gen_random_uuid()::text||gen_random_uuid()::text,'-','');
 insert into portal_private.crm_lead_api_sources(id,name,key_hash,key_suffix,created_by)
 values(p_id,trim(p_name),encode(sha256(convert_to(secret,'UTF8')),'hex'),right(secret,6),auth.uid()) returning * into s;
 summary:=portal_private.lead_api_source_summary(s);
 insert into portal_private.crm_lead_api_history(source_id,action,actor_id,reason,snapshot) values(s.id,'Created',auth.uid(),trim(p_reason),summary);
 return jsonb_build_object('source',summary,'key',secret,'already_created',false);
end$$;
create function public.revoke_crm_lead_api_source(p_id uuid,p_version integer,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare s portal_private.crm_lead_api_sources;actor public.profiles;
begin
 select * into actor from public.profiles where id=auth.uid() for share;
 if actor.id is null or not actor.active or actor.role<>'admin' then raise exception 'Current Administrator access required';end if;
 if p_version is null or length(coalesce(trim(p_reason),'')) not between 3 and 1000 then raise exception 'Exact current source version and actual reason required';end if;
 select * into s from portal_private.crm_lead_api_sources where id=p_id for update;
 if s.id is null then raise exception 'Actual source required';end if;
 if not s.active and s.version=p_version+1 and s.revoked_by=auth.uid() and exists(select 1 from portal_private.crm_lead_api_history where source_id=s.id and action='Revoked' and actor_id=auth.uid() and reason=trim(p_reason)) then return;end if;
 if not s.active or s.version<>p_version then raise exception 'Source changed; reload current source register';end if;
 update portal_private.crm_lead_api_sources set active=false,version=version+1,revoked_by=auth.uid(),revoked_at=now() where id=s.id returning * into s;
 insert into portal_private.crm_lead_api_history(source_id,action,actor_id,reason,snapshot) values(s.id,'Revoked',auth.uid(),trim(p_reason),portal_private.lead_api_source_summary(s));
end$$;
create function public.crm_lead_api_source_register() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Current Administrator access required';end if;
 return jsonb_build_object('endpoint','/api/leads','sources',coalesce((select jsonb_agg(portal_private.lead_api_source_summary(s)||jsonb_build_object('history',coalesce((select jsonb_agg(to_jsonb(h) order by h.created_at,h.id) from portal_private.crm_lead_api_history h where h.source_id=s.id),'[]'::jsonb)) order by s.created_at,s.id) from portal_private.crm_lead_api_sources s),'[]'::jsonb));
end$$;
create function public.capture_api_crm_lead(p_key text,p_event text,p_data jsonb,p_fingerprint text,p_limit integer default 100) returns void language plpgsql security definer set search_path='' as $$
declare s portal_private.crm_lead_api_sources;canonical jsonb;prior jsonb;mail text;v_phone text;v_name text;v_company text;v_city text;v_country text;v_message text;v_form_name text;v_campaign text;v_utm jsonb;v_tags text[];v_activity text;n integer;eid uuid;pid uuid;lid uuid;cid uuid;cids uuid[];lead public.crm_leads;
begin
 if p_key is null or p_key !~ '^iman_lead_[0-9a-f]{64}$' then raise exception using errcode='P0401',message='Invalid or revoked intake key';end if;
 select * into s from portal_private.crm_lead_api_sources where active and key_hash=encode(sha256(convert_to(p_key,'UTF8')),'hex') for share;
 if s.id is null then raise exception using errcode='P0401',message='Invalid or revoked intake key';end if;
 if p_event is null or length(trim(p_event)) not between 1 and 200 or p_event ~ '[[:cntrl:]]' or jsonb_typeof(p_data) is distinct from 'object' then raise exception using errcode='P0422',message='Stable event identity and lead object required';end if;
 if exists(select 1 from jsonb_each(p_data) e where e.key not in ('name','email','phone','company','city','country','message','form','campaign','utm','tags') or (e.key not in ('utm','tags') and jsonb_typeof(e.value)<>'string')) then raise exception using errcode='P0422',message='Supported lead fields required';end if;
 v_name:=trim(coalesce(p_data->>'name',''));mail:=lower(trim(coalesce(p_data->>'email','')));v_phone:=regexp_replace(coalesce(p_data->>'phone',''),'[[:space:]().-]','','g');v_company:=trim(coalesce(p_data->>'company',''));v_city:=trim(coalesce(p_data->>'city',''));v_country:=trim(coalesce(p_data->>'country',''));v_message:=coalesce(p_data->>'message','');v_form_name:=trim(coalesce(p_data->>'form',''));v_campaign:=trim(coalesce(p_data->>'campaign',''));v_utm:=coalesce(p_data->'utm','{}');
 if length(v_name) not between 2 and 160 or (mail='' and v_phone='') or (mail<>'' and (length(mail)>254 or mail !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$')) or (v_phone<>'' and v_phone !~ '^\+[1-9][0-9]{7,14}$') or length(v_company)>160 or length(v_city)>100 or length(v_country)>100 or length(v_message)>8000 or length(v_form_name)>100 or length(v_campaign)>300 then raise exception using errcode='P0422',message='Valid bounded contact and enquiry fields required';end if;
 if jsonb_typeof(v_utm) is distinct from 'object' or length(v_utm::text)>1800 or exists(select 1 from jsonb_each(v_utm) e where e.key not in ('utm_source','utm_medium','utm_campaign','utm_term','utm_content') or jsonb_typeof(e.value)<>'string' or length(e.value#>>'{}')>300) then raise exception using errcode='P0422',message='Bounded UTM metadata required';end if;
 if jsonb_typeof(coalesce(p_data->'tags','[]')) is distinct from 'array' or exists(select 1 from jsonb_array_elements(coalesce(p_data->'tags','[]')) t where jsonb_typeof(t)<>'string') then raise exception using errcode='P0422',message='Actual tag labels required';end if;
 select coalesce(array_agg(t#>>'{}'),'{}'::text[]) into v_tags from jsonb_array_elements(coalesce(p_data->'tags','[]')) t;
 if not public.valid_labels(v_tags) then raise exception using errcode='P0422',message='At most 20 actual tags of 1–40 characters required';end if;
 canonical:=jsonb_build_object('name',v_name,'email',mail,'phone',v_phone,'company',v_company,'city',v_city,'country',v_country,'message',v_message,'form',v_form_name,'campaign',v_campaign,'utm',v_utm,'tags',to_jsonb(v_tags));
 v_activity:='API source: '||s.name||E'\nEvent: '||trim(p_event)||E'\nAcquisition: '||(canonical-'name'-'email'-'phone'-'company'-'message')::text||E'\n'||coalesce(nullif(v_message,''),'Enquiry received');
 if length(v_activity)>10000 then raise exception using errcode='P0422',message='Combined enquiry and acquisition exceed the supported timeline budget';end if;
 if p_fingerprint is null or p_fingerprint !~ '^[0-9a-f]{64}$' or p_limit is null or p_limit not between 1 and 1000 then raise exception 'Server origin and bounded intake budget required';end if;
 -- Share the manual/import/website lock: duplicate checks are atomic across channels.
 perform pg_advisory_xact_lock(hashtext('crm-lead-intake'));
 select payload into prior from portal_private.crm_lead_api_receipts where source_id=s.id and event_id=trim(p_event);
 if found then
  if prior is distinct from canonical then raise exception using errcode='P0409',message='Event identity already has different payload';end if;
  return;
 end if;
 delete from portal_private.website_intake_limits where window_started<now()-interval '1 day';
 insert into portal_private.website_intake_limits(fingerprint,attempts) values(p_fingerprint,1) on conflict(fingerprint) do update set attempts=case when website_intake_limits.window_started<=now()-interval '10 minutes' then 1 else website_intake_limits.attempts+1 end,window_started=case when website_intake_limits.window_started<=now()-interval '10 minutes' then now() else website_intake_limits.window_started end returning attempts into n;
 if n>p_limit then raise exception using errcode='P0429',message='Intake limit reached';end if;
 select id into eid from public.crm_leads where email=mail and mail<>'';
 select id into pid from public.crm_leads where crm_leads.phone=v_phone and v_phone<>'';
 if eid is not null and pid is not null and eid<>pid then raise exception using errcode='P0422',message='Contact conflict requires private review';end if;
 lid:=coalesce(eid,pid);
 if lid is null then
  select array_agg(id) into cids from public.companies where (mail<>'' and lower(trim(email))=mail) or (v_phone<>'' and regexp_replace(companies.phone,'[[:space:]().-]','','g')=v_phone);
  if cardinality(cids)>1 then raise exception using errcode='P0422',message='Multiple customer matches require private review';end if;cid:=cids[1];
  insert into public.crm_leads(name,email,phone,company_name,city,country,source,campaign,form_name,utm,message,tags,company_id) values(v_name,mail,v_phone,v_company,v_city,v_country,'API',coalesce(nullif(v_campaign,''),v_utm->>'utm_campaign',''),coalesce(nullif(v_form_name,''),s.name),v_utm,v_message,v_tags,cid) returning id into lid;
 else update public.crm_leads set updated_at=now() where id=lid;end if;
 insert into public.crm_sales_activity(lead_id,kind,body,actor_id) values(lid,'Enquiry',v_activity,null);
 update public.crm_deals set last_activity_at=now() where lead_id=lid;
 insert into portal_private.crm_lead_api_receipts(source_id,event_id,payload,lead_id) values(s.id,trim(p_event),canonical,lid);
 select * into lead from public.crm_leads where id=lid;
 insert into public.portal_reminders(user_id,event_key,title,view)
 select p.id,'api-enquiry:'||s.id||':'||trim(p_event),'API enquiry received',case when lead.status='Assigned' then 'sales_boards' else 'raw_leads' end from public.profiles p
 where p.active and p.role in ('admin','team') and (p.role='admin' or exists(select 1 from public.crm_memberships m join public.crm_roles r on r.id=m.role_id join public.crm_teams t on t.id=m.team_id where m.user_id=p.id and r.active and t.active and r.permissions && array['sales.manage','sales.own']))
 and ((lead.owner_id is not null and p.id=lead.owner_id) or (lead.owner_id is null and (p.role='admin' or exists(select 1 from public.crm_memberships m join public.crm_roles r on r.id=m.role_id join public.crm_teams t on t.id=m.team_id where m.user_id=p.id and r.active and t.active and 'sales.manage'=any(r.permissions)))))
 and coalesce((select enabled from public.portal_reminder_preferences where user_id=p.id),true) on conflict(user_id,event_key) do nothing;
end$$;
revoke all on function portal_private.lead_api_evidence_immutable(),portal_private.lead_api_source_summary(portal_private.crm_lead_api_sources) from public,anon,authenticated,service_role;
revoke all on function public.create_crm_lead_api_source(uuid,text,text),public.revoke_crm_lead_api_source(uuid,integer,text),public.crm_lead_api_source_register(),public.capture_api_crm_lead(text,text,jsonb,text,integer) from public,anon,authenticated,service_role;
grant execute on function public.create_crm_lead_api_source(uuid,text,text),public.revoke_crm_lead_api_source(uuid,integer,text),public.crm_lead_api_source_register() to authenticated;
grant execute on function public.capture_api_crm_lead(text,text,jsonb,text,integer) to service_role;
commit;
