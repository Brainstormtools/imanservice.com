begin;
create table public.client_sites(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies,name text not null check(length(trim(name)) between 1 and 200),address text not null default '' check(length(address)<=2000),contact text not null default '' check(length(contact)<=1000),active boolean not null default true,version integer not null default 1);
alter table public.equipment add column site_id uuid references public.client_sites;
create function public.validate_asset_site() returns trigger language plpgsql security definer set search_path='' as $$begin
 if new.site_id is not null and not exists(select 1 from public.client_sites where id=new.site_id and company_id=new.company_id) then raise exception 'Site must belong to equipment company';end if;return new;end $$;
create trigger equipment_site_check before insert or update on public.equipment for each row execute function public.validate_asset_site();
create table public.it_jobs(id uuid primary key default gen_random_uuid(),kind text not null check(kind in ('Audit','Visit')),site_id uuid not null references public.client_sites,company_id uuid not null references public.companies,project_id uuid references public.projects,task_id uuid references public.tasks,technician_id uuid not null references public.profiles,title text not null check(length(trim(title)) between 1 and 200),scheduled_at timestamptz not null check(isfinite(scheduled_at)),ends_at timestamptz not null check(isfinite(ends_at)),status text not null default 'Scheduled' check(status in ('Scheduled','Submitted','Published','Confirmed','Changes requested','Cancelled')),work text not null default '' check(length(work)<=10000),checklist jsonb not null default '[]',findings jsonb not null default '[]',evidence uuid[] not null default '{}',client_note text not null default '' check(length(client_note)<=2000),version integer not null default 1,check(ends_at>scheduled_at and ends_at<=scheduled_at+interval '7 days'));
create table public.amc_renewals(id uuid primary key default gen_random_uuid(),contract_id uuid not null references public.contracts,company_id uuid not null references public.companies,title text not null check(length(trim(title)) between 1 and 200),start_date date not null,end_date date not null,services text not null default '' check(length(services)<=10000),targets jsonb not null check(public.valid_sla_targets(targets)),price numeric(14,2) not null check(price>=0 and price::text<>'NaN'),currency text not null check(currency ~ '^[A-Z]{3}$'),status text not null default 'Draft' check(status in ('Draft','Published','Accepted','Declined','Activated','Withdrawn')),client_note text not null default '' check(length(client_note)<=2000),new_contract_id uuid unique references public.contracts,version integer not null default 1,check(isfinite(start_date) and isfinite(end_date) and end_date>=start_date));
create unique index amc_one_open_renewal on public.amc_renewals(contract_id) where status in ('Draft','Published','Accepted');
create table public.it_operation_history(id uuid primary key default gen_random_uuid(),record_id uuid not null,company_id uuid not null references public.companies,record_type text not null,actor_id uuid not null default auth.uid() references public.profiles,action text not null,created_at timestamptz not null default now());
create table public.it_job_reports(id uuid primary key default gen_random_uuid(),job_id uuid not null references public.it_jobs,version integer not null,snapshot jsonb not null,created_at timestamptz not null default now(),unique(job_id,version));
create function public.it_job_visible(j public.it_jobs) returns boolean language sql stable security definer set search_path='' as $$select public.is_admin() or (public.is_staff() and j.technician_id=auth.uid()) or (not public.is_staff() and public.can_company(j.company_id) and j.status in ('Published','Confirmed','Changes requested'));$$;
alter table public.client_sites enable row level security;
alter table public.it_jobs enable row level security;
alter table public.amc_renewals enable row level security;
alter table public.it_operation_history enable row level security;
alter table public.it_job_reports enable row level security;
create policy reports_read on public.it_job_reports for select to authenticated using(exists(select 1 from public.it_jobs j where j.id=job_id and public.it_job_visible(j)));
create policy sites_read on public.client_sites for select to authenticated using(public.can_company(company_id));
create policy jobs_read on public.it_jobs for select to authenticated using(public.it_job_visible(it_jobs));
create policy renewals_read on public.amc_renewals for select to authenticated using(public.is_admin() or (not public.is_staff() and public.can_company(company_id) and status<>'Draft'));
create policy it_history_read on public.it_operation_history for select to authenticated using(public.is_admin() or (record_type='Site' and public.can_company(company_id)) or (record_type='Job' and exists(select 1 from public.it_jobs j where j.id=record_id and public.it_job_visible(j))) or (record_type='Renewal' and exists(select 1 from public.amc_renewals r where r.id=record_id and not public.is_staff() and public.can_company(r.company_id) and r.status<>'Draft')));
create function public.save_client_site(p_id uuid,p_version integer,p_company uuid,p_name text,p_address text,p_contact text,p_active boolean) returns uuid language plpgsql security definer set search_path='' as $$declare s public.client_sites;begin
 if not public.is_admin() then raise exception 'Administrator required';end if;
 if p_id is null then insert into public.client_sites(company_id,name,address,contact,active) values(p_company,trim(p_name),p_address,p_contact,p_active) returning * into s;
 else select * into s from public.client_sites where id=p_id for update;if not found or s.version is distinct from p_version or s.company_id is distinct from p_company then raise exception 'Site changed or unavailable';end if;update public.client_sites set name=trim(p_name),address=p_address,contact=p_contact,active=p_active,version=version+1 where id=p_id returning * into s;end if;
 insert into public.it_operation_history(record_id,company_id,record_type,action) values(s.id,s.company_id,'Site','Saved');return s.id;end $$;
create function public.save_it_job(p_id uuid,p_version integer,p_kind text,p_site uuid,p_project uuid,p_technician uuid,p_title text,p_start timestamptz,p_end timestamptz,p_work text,p_checklist jsonb,p_findings jsonb,p_evidence uuid[],p_task uuid default null) returns uuid language plpgsql security definer set search_path='' as $$
declare j public.it_jobs;s public.client_sites;v jsonb;fid uuid;begin
 if not public.is_staff() then raise exception 'Staff required';end if;
 select * into s from public.client_sites where id=p_site and active;if not found then raise exception 'Active site required';end if;
 if not exists(select 1 from public.profiles where id=p_technician and active and role in ('admin','team')) then raise exception 'Active technician required';end if;
 if p_project is not null and not exists(select 1 from public.projects where id=p_project and company_id=s.company_id) then raise exception 'Project must belong to site company';end if;
 if p_task is not null and not exists(select 1 from public.tasks where id=p_task and project_id=p_project and not internal) then raise exception 'Choose a shared task in the selected project';end if;
 if p_checklist is null or jsonb_typeof(p_checklist)<>'array' or jsonb_array_length(p_checklist)>100 or p_findings is null or jsonb_typeof(p_findings)<>'array' or jsonb_array_length(p_findings)>100 or p_evidence is null or cardinality(p_evidence)>100 then raise exception 'Invalid checklist, findings or evidence';end if;
 for v in select value from jsonb_array_elements(p_checklist) loop
 if jsonb_typeof(v)<>'object' or length(trim(coalesce(v->>'title',''))) not between 1 and 300 or jsonb_typeof(v->'done') is distinct from 'boolean' then raise exception 'Checklist needs title and done flag';end if;end loop;
 for v in select value from jsonb_array_elements(p_findings) loop
 if jsonb_typeof(v)<>'object' or length(trim(coalesce(v->>'title',''))) not between 1 and 300 or coalesce(v->>'severity','') not in ('Low','Medium','High','Critical') or length(trim(coalesce(v->>'recommendation',''))) not between 1 and 2000 then raise exception 'Finding needs title, severity and recommendation';end if;end loop;
 foreach fid in array p_evidence loop
 if not exists(select 1 from public.files f join public.projects p on p.id=f.project_id where f.id=fid and f.project_id=p_project and p.company_id=s.company_id) then raise exception 'Evidence must be a shared file in the selected project';end if;end loop;
 perform pg_advisory_xact_lock(hashtextextended('it-technician:'||p_technician::text,0));
 if p_id is not null then select * into j from public.it_jobs where id=p_id for update;
 if not found or j.company_id is distinct from s.company_id or j.version is distinct from p_version or j.status not in ('Scheduled','Changes requested') or (not public.is_admin() and j.technician_id<>auth.uid()) then raise exception 'Job changed, locked or unavailable';end if;
 if not public.is_admin() and (j.site_id is distinct from p_site or j.project_id is distinct from p_project or j.task_id is distinct from p_task or j.kind is distinct from p_kind or j.technician_id is distinct from p_technician or j.scheduled_at is distinct from p_start or j.ends_at is distinct from p_end) then raise exception 'Only administrator can change allocation or schedule';end if;
 else if not public.is_admin() then raise exception 'Administrator schedules work';end if;end if;
 if exists(select 1 from public.it_jobs x where x.technician_id=p_technician and x.id is distinct from p_id and x.status<>'Cancelled' and tstzrange(x.scheduled_at,x.ends_at,'[)') && tstzrange(p_start,p_end,'[)')) then raise exception 'Technician has overlapping work';end if;
 if p_id is null then insert into public.it_jobs(kind,site_id,company_id,project_id,task_id,technician_id,title,scheduled_at,ends_at,work,checklist,findings,evidence) values(p_kind,p_site,s.company_id,p_project,p_task,p_technician,trim(p_title),p_start,p_end,p_work,p_checklist,p_findings,p_evidence) returning * into j;
 else update public.it_jobs set site_id=p_site,company_id=s.company_id,project_id=p_project,task_id=p_task,technician_id=p_technician,title=trim(p_title),scheduled_at=p_start,ends_at=p_end,work=p_work,checklist=p_checklist,findings=p_findings,evidence=p_evidence,status='Scheduled',version=version+1 where id=p_id returning * into j;end if;
 insert into public.it_operation_history(record_id,company_id,record_type,action) values(j.id,j.company_id,'Job','Saved');return j.id;end $$;
create function public.it_job_action(p_id uuid,p_version integer,p_action text,p_note text default '') returns uuid language plpgsql security definer set search_path='' as $$declare j public.it_jobs;next_status text;begin
 select * into j from public.it_jobs where id=p_id for update;
 if not found or not public.it_job_visible(j) or j.version is distinct from p_version then raise exception 'Job changed or unavailable';end if;
 if p_note is null or length(p_note)>2000 then raise exception 'Note too long';end if;
 if p_action='Submit' and public.is_staff() and (public.is_admin() or j.technician_id=auth.uid()) and j.status in ('Scheduled','Changes requested') then
 if length(trim(j.work))<3 or exists(select 1 from jsonb_array_elements(j.checklist) c where c->>'done'<>'true') then raise exception 'Complete checklist and work record first';end if;next_status:='Submitted';
 elsif p_action='Publish' and public.is_admin() and j.status='Submitted' then
 if exists(select 1 from unnest(j.evidence) e where not exists(select 1 from public.files f where f.id=e and f.project_id=j.project_id)) then raise exception 'Evidence is no longer shared';end if;insert into public.it_job_reports(job_id,version,snapshot) values(j.id,j.version+1,to_jsonb(j));next_status:='Published';
 elsif p_action in ('Confirm','Request changes') and not public.is_staff() and public.can_company(j.company_id) and j.status='Published' then
 if p_action='Request changes' and length(trim(p_note))<3 then raise exception 'Explain required changes';end if;next_status:=case when p_action='Confirm' then 'Confirmed' else 'Changes requested' end;
 elsif p_action='Cancel' and public.is_admin() and j.status in ('Scheduled','Changes requested','Submitted') and length(trim(p_note))>=3 then next_status:='Cancelled';
 else raise exception 'Action not permitted';end if;
 update public.it_jobs set status=next_status,client_note=case when p_action in ('Confirm','Request changes') then p_note else client_note end,version=version+1 where id=p_id;
 insert into public.it_operation_history(record_id,company_id,record_type,action) values(j.id,j.company_id,'Job',p_action||case when p_note<>'' then ': '||p_note else '' end);return j.id;end $$;
create function public.save_amc_renewal(p_id uuid,p_version integer,p_contract uuid,p_title text,p_start date,p_end date,p_services text,p_targets jsonb,p_price numeric,p_currency text) returns uuid language plpgsql security definer set search_path='' as $$declare r public.amc_renewals;c public.contracts;begin
 if not public.is_admin() then raise exception 'Administrator required';end if;
 select * into c from public.contracts where id=p_contract for update;if not found or p_start<=c.end_date then raise exception 'Renewal must start after previous contract ends';end if;
 if p_id is not null then select * into r from public.amc_renewals where id=p_id for update;if not found or r.status<>'Draft' or r.version is distinct from p_version or r.contract_id<>p_contract then raise exception 'Renewal changed or locked';end if;
 update public.amc_renewals set title=trim(p_title),start_date=p_start,end_date=p_end,services=p_services,targets=p_targets,price=p_price,currency=upper(p_currency),version=version+1 where id=p_id returning * into r;
 else insert into public.amc_renewals(contract_id,company_id,title,start_date,end_date,services,targets,price,currency) values(p_contract,c.company_id,trim(p_title),p_start,p_end,p_services,p_targets,p_price,upper(p_currency)) returning * into r;end if;
 insert into public.it_operation_history(record_id,company_id,record_type,action) values(r.id,r.company_id,'Renewal','Saved');return r.id;end $$;
create function public.amc_renewal_action(p_id uuid,p_version integer,p_action text,p_note text default '') returns uuid language plpgsql security definer set search_path='' as $$declare r public.amc_renewals;c public.contracts;n uuid;next_status text;begin
 select * into r from public.amc_renewals where id=p_id for update;
 if not found then raise exception 'Renewal unavailable';end if;
 if p_action='Activate' and public.is_admin() and r.status='Activated' then return r.new_contract_id;end if;
 if r.version is distinct from p_version or not (public.is_admin() or (not public.is_staff() and public.can_company(r.company_id) and r.status<>'Draft')) then raise exception 'Renewal changed or unavailable';end if;
 if p_note is null or length(p_note)>2000 then raise exception 'Note too long';end if;
 if p_action='Publish' and public.is_admin() and r.status='Draft' then next_status:='Published';
 elsif p_action in ('Accept','Decline') and not public.is_staff() and public.can_company(r.company_id) and r.status='Published' then next_status:=case when p_action='Accept' then 'Accepted' else 'Declined' end;
 elsif p_action='Withdraw' and public.is_admin() and r.status in ('Draft','Published') and length(trim(p_note))>=3 then next_status:='Withdrawn';
 elsif p_action='Activate' and public.is_admin() and r.status='Accepted' then
 select * into c from public.contracts where id=r.contract_id for update;
 if c.status='Cancelled' or r.start_date<=c.end_date or exists(select 1 from public.amc_renewals x where x.contract_id=r.contract_id and x.status='Activated') then raise exception 'Original contract changed, cancelled or already renewed';end if;
 insert into public.contracts(company_id,title,status,start_date,end_date,services,targets) values(r.company_id,r.title,'Active',r.start_date,r.end_date,r.services,r.targets) returning id into n;
 next_status:='Activated';
 else raise exception 'Action not permitted';end if;
 update public.amc_renewals set status=next_status,new_contract_id=coalesce(n,new_contract_id),client_note=case when p_action in ('Accept','Decline') then p_note else client_note end,version=version+1 where id=p_id;
 insert into public.it_operation_history(record_id,company_id,record_type,action) values(r.id,r.company_id,'Renewal',p_action||case when p_note<>'' then ': '||p_note else '' end);return coalesce(n,r.id);end $$;
revoke all on public.client_sites,public.it_jobs,public.amc_renewals,public.it_operation_history,public.it_job_reports from anon,authenticated;
grant select on public.client_sites,public.it_jobs,public.amc_renewals,public.it_operation_history,public.it_job_reports to authenticated;
revoke all on function public.save_client_site(uuid,integer,uuid,text,text,text,boolean),public.save_it_job(uuid,integer,text,uuid,uuid,uuid,text,timestamptz,timestamptz,text,jsonb,jsonb,uuid[],uuid),public.it_job_action(uuid,integer,text,text),public.save_amc_renewal(uuid,integer,uuid,text,date,date,text,jsonb,numeric,text),public.amc_renewal_action(uuid,integer,text,text) from public,anon;
grant execute on function public.save_client_site(uuid,integer,uuid,text,text,text,boolean),public.save_it_job(uuid,integer,text,uuid,uuid,uuid,text,timestamptz,timestamptz,text,jsonb,jsonb,uuid[],uuid),public.it_job_action(uuid,integer,text,text),public.save_amc_renewal(uuid,integer,uuid,text,date,date,text,jsonb,numeric,text),public.amc_renewal_action(uuid,integer,text,text) to authenticated;
commit;
