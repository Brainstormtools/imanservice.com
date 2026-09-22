-- Run once in a new Supabase project. No service-role key is used in the browser.
begin;
create table public.companies (id uuid primary key default gen_random_uuid(), name text not null check(length(name) between 1 and 160));
create table public.profiles (
 id uuid primary key references auth.users on delete cascade,
 name text not null check(length(name) between 1 and 160),
 role text not null check(role in ('admin','team','client')),
 company_id uuid references public.companies,
 active boolean not null default true,
 check (role <> 'client' or company_id is not null)
);
create table public.projects (
 id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies,
 title text not null check(length(title) between 1 and 200), description text not null default '',
 status text not null default 'Planning' check(status in ('Planning','In progress','On hold','Completed')),
 deadline date, created_at timestamptz not null default now()
);
create function public.is_staff() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.profiles where id=auth.uid() and active and role in ('admin','team'));
$$;
create function public.is_admin() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.profiles where id=auth.uid() and active and role='admin');
$$;
create function public.can_project(pid uuid) returns boolean language sql stable security definer set search_path = '' as $$
 select public.is_staff() or exists(select 1 from public.projects p join public.profiles u on u.company_id=p.company_id where p.id=pid and u.id=auth.uid() and u.active and u.role='client');
$$;
create table public.tasks (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects on delete cascade,
 title text not null check(length(title) between 1 and 300), assignee uuid references public.profiles,
 status text not null default 'To do' check(status in ('To do','In progress','Done')),
 deadline date, internal boolean not null default false, created_at timestamptz not null default now()
);
create table public.milestones (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects on delete cascade,
 title text not null check(length(title) between 1 and 300), deadline date,
 status text not null default 'Upcoming' check(status in ('Upcoming','In progress','Completed')),
 created_at timestamptz not null default now()
);
create table public.tickets (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects on delete cascade,
 title text not null check(length(title) between 1 and 200), description text not null check(length(description) between 1 and 10000),
 priority text not null check(priority in ('Low','Normal','High','Urgent')),
 status text not null default 'Open' check(status in ('Open','In progress','Waiting on client','Resolved')),
 author_id uuid not null default auth.uid() references public.profiles, created_at timestamptz not null default now()
);
create table public.messages (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects on delete cascade,
 ticket_id uuid references public.tickets on delete cascade,
 body text not null check(length(body) between 1 and 10000), internal boolean not null default false,
 author_id uuid not null default auth.uid() references public.profiles, created_at timestamptz not null default now()
);
create table public.files (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects on delete cascade,
 name text not null check(length(name) between 1 and 255), path text not null unique,
 size bigint not null check(size between 1 and 10485760), deliverable boolean not null default false,
 author_id uuid not null default auth.uid() references public.profiles, created_at timestamptz not null default now(),
 check (split_part(path,'/',1)=project_id::text)
);
create table public.approvals (
 id uuid primary key default gen_random_uuid(), file_id uuid not null references public.files on delete cascade,
 decision text not null check(decision in ('Approved','Changes requested')), note text not null default '' check(length(note)<=10000),
 author_id uuid not null default auth.uid() references public.profiles, created_at timestamptz not null default now()
);
-- Functions bypass only profile/project RLS to avoid recursive policies. They do not accept a user ID.
revoke all on function public.is_staff(),public.is_admin(),public.can_project(uuid) from public, anon;
grant execute on function public.is_staff(),public.is_admin(),public.can_project(uuid) to authenticated;

alter table public.companies enable row level security;
alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.tasks enable row level security;
alter table public.milestones enable row level security;
alter table public.tickets enable row level security;
alter table public.messages enable row level security;
alter table public.files enable row level security;
alter table public.approvals enable row level security;

create policy company_read on public.companies for select to authenticated using(public.is_staff() or id=(select company_id from public.profiles where id=auth.uid()));
create policy company_manage on public.companies for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy profile_read on public.profiles for select to authenticated using(id=auth.uid() or public.is_staff());
-- Role/company changes are admin-only. Users cannot promote themselves or change tenant.
create policy profile_manage on public.profiles for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy project_read on public.projects for select to authenticated using(public.can_project(id));
create policy project_manage on public.projects for all to authenticated using(public.is_staff()) with check(public.is_staff());
create policy task_read on public.tasks for select to authenticated using(public.can_project(project_id) and (not internal or public.is_staff()));
create policy task_manage on public.tasks for all to authenticated using(public.is_staff()) with check(public.is_staff());
create policy milestone_read on public.milestones for select to authenticated using(public.can_project(project_id));
create policy milestone_manage on public.milestones for all to authenticated using(public.is_staff()) with check(public.is_staff());
create policy ticket_read on public.tickets for select to authenticated using(public.can_project(project_id));
create policy ticket_create on public.tickets for insert to authenticated with check(public.can_project(project_id) and author_id=auth.uid() and status='Open');
create policy ticket_update on public.tickets for update to authenticated using(public.is_staff()) with check(public.is_staff());
create policy message_read on public.messages for select to authenticated using(public.can_project(project_id) and (not internal or public.is_staff()));
create policy message_create on public.messages for insert to authenticated with check(
 public.can_project(project_id) and author_id=auth.uid() and (not internal or public.is_staff())
 and (ticket_id is null or exists(select 1 from public.tickets t where t.id=ticket_id and t.project_id=messages.project_id))
);
create policy file_read on public.files for select to authenticated using(public.can_project(project_id));
create policy file_create on public.files for insert to authenticated with check(
 public.can_project(project_id) and author_id=auth.uid() and (not deliverable or public.is_staff())
 and exists(select 1 from storage.objects o where o.bucket_id='project-files' and o.name=path and o.owner_id=auth.uid()::text)
);
create policy approval_read on public.approvals for select to authenticated using(exists(select 1 from public.files f where f.id=file_id and public.can_project(f.project_id)));
create policy approval_create on public.approvals for insert to authenticated with check(
 author_id=auth.uid() and exists(select 1 from public.profiles u where u.id=auth.uid() and u.active and u.role='client')
 and exists(select 1 from public.files f where f.id=file_id and f.deliverable and public.can_project(f.project_id))
);
-- No client UPDATE/DELETE on files, messages or approval history. Each revision is a new upload.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values(
 'project-files','project-files',false,10485760,
 array['application/pdf','image/png','image/jpeg','text/plain','text/csv','application/zip','application/vnd.openxmlformats-officedocument.wordprocessingml.document','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
);
-- Regex-safe text comparison avoids invalid UUID casts from hostile paths.
create policy object_read on storage.objects for select to authenticated using(
 bucket_id='project-files' and exists(select 1 from public.projects p where p.id::text=split_part(storage.objects.name,'/',1) and public.can_project(p.id))
);
create policy object_upload on storage.objects for insert to authenticated with check(
 bucket_id='project-files' and owner_id=auth.uid()::text
 and exists(select 1 from public.projects p where p.id::text=split_part(storage.objects.name,'/',1) and public.can_project(p.id))
);
-- Allows cleanup of an upload whose metadata save failed; finalized files cannot be deleted here.
create policy object_cleanup on storage.objects for delete to authenticated using(
 bucket_id='project-files' and owner_id=auth.uid()::text
 and not exists(select 1 from public.files f where f.path=storage.objects.name)
);
create index projects_company on public.projects(company_id);
create index tasks_project on public.tasks(project_id);
create index milestones_project on public.milestones(project_id);
create index tickets_project on public.tickets(project_id);
create index messages_project on public.messages(project_id,ticket_id,created_at);
create index files_project on public.files(project_id);
create index approvals_file on public.approvals(file_id,created_at);
revoke all on public.companies,public.profiles,public.projects,public.tasks,public.milestones,public.tickets,public.messages,public.files,public.approvals from anon;
grant select,insert,update,delete on public.companies,public.profiles,public.projects,public.tasks,public.milestones,public.tickets,public.messages,public.files,public.approvals to authenticated;
commit;
