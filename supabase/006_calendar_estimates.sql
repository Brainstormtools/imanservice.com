-- Apply once after 005_workspace.sql.
begin;
create table public.calendar_events (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references public.profiles,
 project_id uuid references public.projects, title text not null check(length(trim(title)) between 1 and 200),
 notes text not null default '' check(length(notes)<=4000), starts_at timestamptz not null, ends_at timestamptz not null,
 internal boolean not null default true, reminder_minutes integer not null default 15 check(reminder_minutes between 0 and 10080),
 cancelled boolean not null default false, version integer not null default 1, created_at timestamptz not null default now(),
 check(ends_at>=starts_at),check(ends_at<=starts_at+interval '366 days')
);
alter table public.calendar_events enable row level security;
create policy calendar_read on public.calendar_events for select to authenticated using(
 exists(select 1 from public.profiles where id=auth.uid() and active) and
 ((project_id is null and owner_id=auth.uid()) or (project_id is not null and public.can_project(project_id) and (not internal or public.is_staff()))));
create function public.save_calendar_event(p_id uuid,p_version integer,p_project uuid,p_title text,p_notes text,p_start timestamptz,p_end timestamptz,p_internal boolean,p_reminder integer,p_cancelled boolean) returns uuid language plpgsql security definer set search_path='' as $$
declare e public.calendar_events;
begin
 if not exists(select 1 from public.profiles where id=auth.uid() and active) then raise exception 'Active account required'; end if;
 if p_project is not null and not public.is_staff() then raise exception 'Staff creates project events'; end if;
 if p_project is not null and not public.can_project(p_project) then raise exception 'Project unavailable'; end if;
 if p_id is null then
  insert into public.calendar_events(project_id,title,notes,starts_at,ends_at,internal,reminder_minutes,cancelled) values(p_project,trim(p_title),p_notes,p_start,p_end,case when p_project is null then true else p_internal end,p_reminder,p_cancelled) returning * into e;
 else
  select * into e from public.calendar_events where id=p_id for update;
  if not found or (e.project_id is null and e.owner_id<>auth.uid()) or (e.project_id is not null and not public.is_staff()) then raise exception 'Event unavailable'; end if;
  if e.version is distinct from p_version then raise exception 'Event changed. Refresh before saving.'; end if;
  if e.project_id is distinct from p_project then raise exception 'Event project cannot change'; end if;
  update public.calendar_events set title=trim(p_title),notes=p_notes,starts_at=p_start,ends_at=p_end,internal=case when p_project is null then true else p_internal end,reminder_minutes=p_reminder,cancelled=p_cancelled,version=version+1 where id=e.id;
 end if;
 return e.id;
end $$;

create sequence public.estimate_numbers;
create table public.estimates (
 id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies,
 number text not null unique default ('EST-'||lpad(nextval('public.estimate_numbers')::text,6,'0')),
 kind text not null check(kind in ('Estimate','Proposal')),title text not null check(length(trim(title)) between 1 and 200),
 company_name text not null, currency text not null check(currency ~ '^[A-Z]{3}$'),valid_until date not null,
 scope text not null default '' check(length(scope)<=10000),terms text not null default '' check(length(terms)<=10000),
 items jsonb not null, subtotal numeric(14,2) not null,tax_total numeric(14,2) not null,total numeric(14,2) not null check(total>=0),
 status text not null default 'Draft' check(status in ('Draft','Published','Accepted','Declined','Withdrawn','Superseded')),
 version integer not null default 1, revision integer not null default 1,previous_id uuid unique references public.estimates,
 published_at timestamptz,decided_at timestamptz,decided_by uuid references public.profiles,decision_note text not null default '' check(length(decision_note)<=2000),
 project_id uuid references public.projects,invoice_id uuid references public.invoices,
 author_id uuid not null default auth.uid() references public.profiles,created_at timestamptz not null default now()
);
create table public.estimate_history(id uuid primary key default gen_random_uuid(),estimate_id uuid not null references public.estimates,action text not null,actor_id uuid not null default auth.uid() references public.profiles,created_at timestamptz not null default now());
alter table public.estimates enable row level security;
alter table public.estimate_history enable row level security;
create function public.can_estimate(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$
 select public.is_admin() or exists(select 1 from public.estimates e join public.profiles p on p.company_id=e.company_id where e.id=p_id and e.published_at is not null and p.id=auth.uid() and p.active and p.role='client');
$$;
create policy estimate_read on public.estimates for select to authenticated using(public.can_estimate(id));
create policy estimate_history_read on public.estimate_history for select to authenticated using(public.can_estimate(estimate_id));
create function public.save_estimate(p_id uuid,p_version integer,p_company uuid,p_kind text,p_title text,p_currency text,p_valid date,p_scope text,p_terms text,p_items jsonb) returns uuid language plpgsql security definer set search_path='' as $$
declare e public.estimates; cname text; r jsonb; q numeric(10,3); price numeric(12,2); rate numeric(5,2); n numeric(14,2); t numeric(14,2); net_sum numeric(14,2):=0; taxes numeric(14,2):=0; lines jsonb:='[]';
begin
 if not public.is_admin() then raise exception 'Administrator access required'; end if;
 if jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items) not between 1 and 100 then raise exception 'Use 1 to 100 lines'; end if;
 select name into cname from public.companies where id=p_company;
 if cname is null then raise exception 'Company unavailable'; end if;
 for r in select value from jsonb_array_elements(p_items) loop
  q:=(r->>'quantity')::numeric;price:=(r->>'unit_price')::numeric;rate:=(r->>'tax_percent')::numeric;
  if q is null or q<=0 or q>100000 or price is null or price<0 or rate is null or rate<0 or rate>100 or q::text='NaN' or price::text='NaN' or rate::text='NaN' or length(trim(coalesce(r->>'description',''))) not between 1 and 500 then raise exception 'Invalid line quantity, price, tax or description'; end if;
  n:=round(q*price,2);t:=round(n*rate/100,2);net_sum:=net_sum+n;taxes:=taxes+t;
  lines:=lines||jsonb_build_array(jsonb_build_object('description',trim(r->>'description'),'quantity',q,'unit_price',price,'tax_percent',rate,'net',n,'tax',t));
 end loop;
 if p_id is null then
  insert into public.estimates(company_id,company_name,kind,title,currency,valid_until,scope,terms,items,subtotal,tax_total,total) values(p_company,cname,p_kind,trim(p_title),upper(p_currency),p_valid,p_scope,p_terms,lines,net_sum,taxes,net_sum+taxes) returning * into e;
 else
  select * into e from public.estimates where id=p_id for update;
  if not found or e.status<>'Draft' or e.company_id<>p_company then raise exception 'Only drafts can be edited; company cannot change'; end if;
  if e.version is distinct from p_version then raise exception 'Estimate changed. Refresh before saving.'; end if;
  update public.estimates set company_name=cname,kind=p_kind,title=trim(p_title),currency=upper(p_currency),valid_until=p_valid,scope=p_scope,terms=p_terms,items=lines,subtotal=net_sum,tax_total=taxes,total=net_sum+taxes,version=version+1 where id=e.id;
 end if;
 insert into public.estimate_history(estimate_id,action) values(e.id,'Draft saved');
 return e.id;
end $$;
create function public.estimate_action(p_id uuid,p_version integer,p_action text,p_note text default '') returns uuid language plpgsql security definer set search_path='' as $$
declare e public.estimates; result uuid;
begin
 select * into e from public.estimates where id=p_id for update;
 if not found or not public.can_estimate(p_id) then raise exception 'Estimate unavailable'; end if;
 if e.version is distinct from p_version then raise exception 'Estimate changed. Refresh before continuing.'; end if;
 result:=e.id;
 if p_action in ('accept','decline') then
  if not exists(select 1 from public.profiles where id=auth.uid() and active and role='client' and company_id=e.company_id) then raise exception 'Client decision required'; end if;
  if e.status<>'Published' or e.valid_until<(now() at time zone 'UTC')::date then raise exception 'Estimate is not open for a decision'; end if;
  update public.estimates set status=case p_action when 'accept' then 'Accepted' else 'Declined' end,decided_at=now(),decided_by=auth.uid(),decision_note=p_note,version=version+1 where id=e.id;
 elsif public.is_admin() then
  if p_action='publish' and e.status='Draft' and e.total>0 and e.valid_until>=(now() at time zone 'UTC')::date then
   update public.estimates set status='Published',published_at=now(),version=version+1 where id=e.id;
  elsif p_action='withdraw' and e.status='Published' then
   update public.estimates set status='Withdrawn',version=version+1 where id=e.id;
  elsif p_action='revise' and e.status in ('Published','Declined','Withdrawn') then
   insert into public.estimates(company_id,company_name,kind,title,currency,valid_until,scope,terms,items,subtotal,tax_total,total,revision,previous_id) values(e.company_id,e.company_name,e.kind,e.title,e.currency,greatest(e.valid_until,(now() at time zone 'UTC')::date),e.scope,e.terms,e.items,e.subtotal,e.tax_total,e.total,e.revision+1,e.id) returning id into result;
   update public.estimates set status='Superseded',version=version+1 where id=e.id;
   insert into public.estimate_history(estimate_id,action) values(result,'Revision created');
  else raise exception 'Action unavailable for this state'; end if;
 else raise exception 'Administrator access required'; end if;
 insert into public.estimate_history(estimate_id,action) values(e.id,p_action);
 return result;
end $$;
create function public.convert_estimate(p_id uuid,p_target text,p_due date default null) returns uuid language plpgsql security definer set search_path='' as $$
declare e public.estimates; result uuid;
begin
 if not public.is_admin() then raise exception 'Administrator access required'; end if;
 select * into e from public.estimates where id=p_id for update;
 if not found or e.status<>'Accepted' then raise exception 'Accepted estimate required'; end if;
 if p_target='project' then
  if e.project_id is not null then return e.project_id; end if;
  insert into public.projects(company_id,title,description,status) values(e.company_id,e.title,e.scope,'Planning') returning id into result;
  update public.estimates set project_id=result,version=version+1 where id=e.id;
 elsif p_target='invoice' then
  if e.invoice_id is not null then return e.invoice_id; end if;
  result:=public.save_invoice(null,e.company_id,e.currency,(now() at time zone 'UTC')::date,p_due,'From '||e.number||' revision '||e.revision||E'\n'||left(e.terms,3500),'',e.items);
  update public.estimates set invoice_id=result,version=version+1 where id=e.id;
 else raise exception 'Choose project or invoice'; end if;
 insert into public.estimate_history(estimate_id,action) values(e.id,'Converted to '||p_target);
 return result;
end $$;
revoke all on public.calendar_events,public.estimates,public.estimate_history from anon,authenticated;
grant select on public.calendar_events,public.estimates,public.estimate_history to authenticated;
revoke all on sequence public.estimate_numbers from anon,authenticated;
revoke all on function public.save_calendar_event(uuid,integer,uuid,text,text,timestamptz,timestamptz,boolean,integer,boolean),public.can_estimate(uuid),public.save_estimate(uuid,integer,uuid,text,text,text,date,text,text,jsonb),public.estimate_action(uuid,integer,text,text),public.convert_estimate(uuid,text,date) from public,anon,authenticated;
grant execute on function public.save_calendar_event(uuid,integer,uuid,text,text,timestamptz,timestamptz,boolean,integer,boolean),public.can_estimate(uuid),public.save_estimate(uuid,integer,uuid,text,text,text,date,text,text,jsonb),public.estimate_action(uuid,integer,text,text),public.convert_estimate(uuid,text,date) to authenticated;
create index calendar_project_time on public.calendar_events(project_id,starts_at);
create index calendar_owner on public.calendar_events(owner_id);
create index estimates_company on public.estimates(company_id);
create index estimate_history_parent on public.estimate_history(estimate_id);
notify pgrst,'reload schema';
commit;
