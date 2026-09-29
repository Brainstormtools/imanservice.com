-- Apply once after 004_service_work.sql. Additive workspace upgrade.
begin;
create function public.valid_labels(v text[]) returns boolean language sql immutable set search_path='' as $$select v is not null and cardinality(v)<=20 and not exists(select 1 from unnest(v) x where x is null or length(trim(x)) not between 1 and 40)$$;
alter table public.companies add column email text not null default '' check(length(email)<=254),add column phone text not null default '' check(length(phone)<=60),add column address text not null default '' check(length(address)<=1000),add column website text not null default '' check(length(website)<=300),add column labels text[] not null default '{}' check(public.valid_labels(labels));
alter table public.projects add column start_date date,add column labels text[] not null default '{}' check(public.valid_labels(labels)),add constraint project_dates check(start_date is null or deadline is null or start_date<=deadline);
alter table public.tasks add column start_date date,add column milestone_id uuid references public.milestones on delete set null,add column collaborators uuid[] not null default '{}' check(cardinality(collaborators)<=30),add column labels text[] not null default '{}' check(public.valid_labels(labels)),add constraint task_dates check(start_date is null or deadline is null or start_date<=deadline);
create table public.client_contacts(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies,name text not null check(length(trim(name)) between 1 and 160),email text not null default '' check(length(email)<=254),phone text not null default '' check(length(phone)<=60),position text not null default '' check(length(position)<=160),notes text not null default '' check(length(notes)<=4000),active boolean not null default true,created_at timestamptz not null default now());
alter table public.client_contacts enable row level security;
create policy contact_read on public.client_contacts for select to authenticated using(public.is_staff());
create policy contact_manage on public.client_contacts for all to authenticated using(public.is_admin()) with check(public.is_admin());
revoke all on public.client_contacts from public,anon,authenticated;
grant select,insert,update on public.client_contacts to authenticated;
create function public.workspace_validate() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if tg_table_name='tasks' then
  if new.milestone_id is not null and not exists(select 1 from public.milestones where id=new.milestone_id and project_id=new.project_id) then raise exception 'Milestone must belong to this project'; end if;
  if tg_op='INSERT' or new.collaborators is distinct from old.collaborators then
   if exists(select 1 from unnest(new.collaborators) c where c is null or not exists(select 1 from public.profiles p where p.id=c and p.active and p.role in ('admin','team'))) then raise exception 'Collaborators must be active staff'; end if;
   if cardinality(new.collaborators)<>(select count(distinct c) from unnest(new.collaborators) c) then raise exception 'Duplicate collaborator'; end if;
  end if;
 elsif tg_table_name='milestones' and tg_op='UPDATE' then
  if new.project_id is distinct from old.project_id then raise exception 'Milestone project cannot be changed'; end if;
 elsif tg_table_name='client_contacts' and tg_op='UPDATE' then
  if new.company_id is distinct from old.company_id then raise exception 'Contact company cannot be changed'; end if;
 end if;
 return new;
end $$;
create trigger workspace_task_validate before insert or update on public.tasks for each row execute function public.workspace_validate();
create trigger workspace_milestone_validate before update on public.milestones for each row execute function public.workspace_validate();
create trigger workspace_contact_validate before update on public.client_contacts for each row execute function public.workspace_validate();
create table public.workspace_activity(id uuid primary key default gen_random_uuid(),project_id uuid not null references public.projects on delete cascade,entity text not null,entity_id uuid not null,title text not null,action text not null,actor_id uuid,created_at timestamptz not null default now());
alter table public.workspace_activity enable row level security;
create policy activity_staff on public.workspace_activity for select to authenticated using(public.is_staff());
revoke all on public.workspace_activity from public,anon,authenticated;
grant select on public.workspace_activity to authenticated;
create function public.record_workspace_activity() returns trigger language plpgsql security definer set search_path='' as $$
declare pid uuid;
begin
 if tg_table_name='projects' then pid:=new.id;else pid:=new.project_id;end if;
 if tg_op='UPDATE' and to_jsonb(new)=to_jsonb(old) then return new; end if;
 insert into public.workspace_activity(project_id,entity,entity_id,title,action,actor_id) values(pid,tg_table_name,new.id,new.title,case when tg_op='INSERT' then 'Created' else 'Updated' end,auth.uid());return new;
end $$;
create trigger workspace_project_activity after insert or update on public.projects for each row execute function public.record_workspace_activity();
create trigger workspace_task_activity after insert or update on public.tasks for each row execute function public.record_workspace_activity();
create trigger workspace_ticket_activity after insert or update on public.tickets for each row execute function public.record_workspace_activity();
create function public.bulk_update_tasks(p_project uuid,p_ids uuid[],p_patch jsonb) returns integer language plpgsql security definer set search_path='' as $$
declare n integer;
begin
 if not public.is_staff() then raise exception 'Staff access required'; end if;
 if p_ids is null or cardinality(p_ids) not between 1 and 500 or cardinality(p_ids)<>(select count(distinct x) from unnest(p_ids) x) then raise exception 'Select 1 to 500 unique tasks'; end if;
 if p_patch is null or jsonb_typeof(p_patch)<>'object' or p_patch='{}'::jsonb or exists(select 1 from jsonb_object_keys(p_patch) k where k not in ('status','priority','assignee','deadline','milestone_id')) then raise exception 'Unsupported bulk fields'; end if;
 perform id from public.tasks where id=any(p_ids) order by id for update;
 if (select count(*) from public.tasks where id=any(p_ids) and project_id=p_project)<>cardinality(p_ids) then raise exception 'All tasks must belong to this project'; end if;
 update public.tasks set status=case when p_patch?'status' then p_patch->>'status' else status end,priority=case when p_patch?'priority' then p_patch->>'priority' else priority end,assignee=case when p_patch?'assignee' then nullif(p_patch->>'assignee','')::uuid else assignee end,deadline=case when p_patch?'deadline' then nullif(p_patch->>'deadline','')::date else deadline end,milestone_id=case when p_patch?'milestone_id' then nullif(p_patch->>'milestone_id','')::uuid else milestone_id end where id=any(p_ids);
 get diagnostics n=row_count;return n;
end $$;
create table public.workspace_imports(id uuid primary key,kind text not null,author_id uuid not null references public.profiles,payload jsonb not null,row_count integer not null,created_at timestamptz not null default now());
alter table public.workspace_imports enable row level security;
revoke all on public.workspace_imports from public,anon,authenticated;
create function public.import_workspace(p_batch uuid,p_kind text,p_rows jsonb) returns integer language plpgsql security definer set search_path='' as $$
declare prior public.workspace_imports;r jsonb;n integer:=0;ls text[];
begin
 if not public.is_staff() or (p_kind='clients' and not public.is_admin()) then raise exception 'Required staff or administrator access missing'; end if;
 if p_batch is null or p_kind not in ('clients','projects') or p_kind is null or p_rows is null or jsonb_typeof(p_rows)<>'array' then raise exception 'Invalid import'; end if;
 if jsonb_array_length(p_rows) not between 1 and 500 then raise exception 'Import 1 to 500 rows'; end if;
 perform pg_advisory_xact_lock(hashtext(p_batch::text));select * into prior from public.workspace_imports where id=p_batch;
 if found then if prior.author_id=auth.uid() and prior.kind=p_kind and prior.payload=p_rows then return prior.row_count; else raise exception 'Import ID already used'; end if; end if;
 for r in select value from jsonb_array_elements(p_rows) loop
  if jsonb_typeof(r)<>'object' then raise exception 'Invalid row'; end if;
  ls:=array(select trim(x) from unnest(string_to_array(coalesce(r->>'labels',''),',')) x where trim(x)<>'');
  if p_kind='clients' then
   insert into public.companies(name,email,phone,address,website,labels) values(trim(r->>'name'),coalesce(r->>'email',''),coalesce(r->>'phone',''),coalesce(r->>'address',''),coalesce(r->>'website',''),ls);
  else
   insert into public.projects(company_id,title,description,status,start_date,deadline,labels) values((r->>'company_id')::uuid,trim(r->>'title'),coalesce(r->>'description',''),coalesce(nullif(r->>'status',''),'Planning'),nullif(r->>'start_date','')::date,nullif(r->>'deadline','')::date,ls);
  end if;n:=n+1;
 end loop;
 insert into public.workspace_imports values(p_batch,p_kind,auth.uid(),p_rows,n,now());return n;
end $$;
revoke all on function public.workspace_validate(),public.record_workspace_activity(),public.bulk_update_tasks(uuid,uuid[],jsonb),public.import_workspace(uuid,text,jsonb) from public,anon,authenticated;
grant execute on function public.bulk_update_tasks(uuid,uuid[],jsonb),public.import_workspace(uuid,text,jsonb) to authenticated;
create index client_contacts_company on public.client_contacts(company_id);
create index workspace_activity_time on public.workspace_activity(created_at desc);
create index tasks_milestone on public.tasks(milestone_id);
notify pgrst,'reload schema';
commit;
