begin;
create table public.crm_client_charter_publications(
 id uuid primary key,copy_id uuid not null references public.crm_client_charter_drafts,project_id uuid not null references public.projects,
 company_id uuid not null references public.companies,copy_version integer not null,project_title text not null,company_name text not null,
 title text not null,objectives text not null,scope text not null,deliverables text not null,communication text not null,
 status text not null default 'Published' check(status in ('Published','Withdrawn')),version integer not null default 1,
 published_at timestamptz not null default now(),withdrawn_at timestamptz,unique(copy_id,copy_version)
);
create unique index client_charter_publication_open on public.crm_client_charter_publications(copy_id) where status='Published';
create index client_charter_publication_project on public.crm_client_charter_publications(project_id);
create index client_charter_publication_company on public.crm_client_charter_publications(company_id);
create table public.crm_client_charter_publication_history(
 id uuid primary key,publication_id uuid not null references public.crm_client_charter_publications,copy_id uuid not null references public.crm_client_charter_drafts,
 project_id uuid not null references public.projects,review_id uuid references public.crm_client_charter_reviews,
 action text not null check(action in ('Published','Withdrawn')),private_snapshot jsonb not null,before_record jsonb,after_record jsonb not null,
 request jsonb not null,reason text not null,actor_id uuid not null references public.profiles,created_at timestamptz not null default now()
);
create index client_charter_pub_history_parent on public.crm_client_charter_publication_history(publication_id);
create index client_charter_pub_history_copy on public.crm_client_charter_publication_history(copy_id);
create index client_charter_pub_history_project on public.crm_client_charter_publication_history(project_id);
create index client_charter_pub_history_review on public.crm_client_charter_publication_history(review_id);
create index client_charter_pub_history_actor on public.crm_client_charter_publication_history(actor_id);
alter table public.crm_client_charter_publications enable row level security;
alter table public.crm_client_charter_publication_history enable row level security;
revoke all on public.crm_client_charter_publications,public.crm_client_charter_publication_history from public,anon,authenticated;
grant select on public.crm_client_charter_publications,public.crm_client_charter_publication_history to authenticated;
create policy client_charter_publication_read on public.crm_client_charter_publications for select to authenticated using(public.is_admin() or exists(select 1 from public.profiles u join public.projects p on p.id=crm_client_charter_publications.project_id where u.id=auth.uid() and u.active and u.role='client' and u.company_id=crm_client_charter_publications.company_id and p.company_id=crm_client_charter_publications.company_id));
create policy client_charter_publication_history_read on public.crm_client_charter_publication_history for select to authenticated using(public.is_admin());
create function public.publish_client_charter_copy(p_id uuid,p_copy uuid,p_version integer,p_review uuid,p_company uuid,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare d public.crm_client_charter_drafts;c public.crm_project_charters;p public.projects;r public.crm_client_charter_reviews;
 retry public.crm_client_charter_publication_history;saved public.crm_client_charter_publications;req jsonb;client_name text;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator publishes reviewed client charter copies';end if;
 select * into d from public.crm_client_charter_drafts where id=p_copy;
 select * into p from public.projects where id=d.project_id for update;
 if p.id is null then raise exception 'Existing project required';end if;
 select * into d from public.crm_client_charter_drafts where id=p_copy for update;
 if p_id is null or p_version is null or p_review is null or p_company is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit publication identity/version/review/destination/manual reason required';end if;
 req:=jsonb_build_object('copy_id',p_copy,'version',p_version,'review_id',p_review,'company_id',p_company,'reason',trim(p_reason));
 select * into retry from public.crm_client_charter_publication_history where id=p_id;
 if retry.id is not null then
  if retry.action='Published' and retry.actor_id=auth.uid() and retry.request=req then return retry.publication_id;end if;
  raise exception 'Publication identity records a different request';
 end if;
 if p.company_id is distinct from p_company then raise exception 'Project client changed; refresh destination';end if;
 select name into client_name from public.companies where id=p_company for share;
 if not found then raise exception 'Existing project client required';end if;
 select * into c from public.crm_project_charters where id=d.charter_id for share;
 select * into r from public.crm_client_charter_reviews where copy_id=d.id and copy_version=d.version order by sequence desc limit 1;
 if d.version is distinct from p_version or r.id is null or r.id is distinct from p_review or r.action is distinct from 'Reviewed' or r.snapshot is distinct from to_jsonb(d) or c.id is null or c.details->>'status' is distinct from 'Reviewed' or d.source_snapshot is distinct from to_jsonb(c) then raise exception 'Exact current Reviewed copy and unchanged Reviewed charter required';end if;
 if exists(select 1 from public.crm_client_charter_publications where copy_id=d.id and (copy_version=d.version or status='Published')) then raise exception 'Version already published or open publication requires explicit withdrawal';end if;
 -- Only the five manually written client fields are exposed. Full source/review/request/reason/actor remain private.
 insert into public.crm_client_charter_publications(id,copy_id,project_id,company_id,copy_version,project_title,company_name,title,objectives,scope,deliverables,communication)
 values(p_id,d.id,d.project_id,p_company,d.version,p.title,client_name,d.details->>'title',d.details->>'objectives',d.details->>'scope',d.details->>'deliverables',d.details->>'communication') returning * into saved;
 insert into public.crm_client_charter_publication_history(id,publication_id,copy_id,project_id,review_id,action,private_snapshot,after_record,request,reason,actor_id)
 values(p_id,saved.id,d.id,d.project_id,r.id,'Published',to_jsonb(r),to_jsonb(saved),req,trim(p_reason),auth.uid());
 return saved.id;
end$$;
create function public.withdraw_client_charter_publication(p_id uuid,p_publication uuid,p_version integer,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare old public.crm_client_charter_publications;saved public.crm_client_charter_publications;retry public.crm_client_charter_publication_history;req jsonb;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator withdraws client charter publications';end if;
 select * into old from public.crm_client_charter_publications where id=p_publication;
 perform 1 from public.projects where id=old.project_id for update;if not found then raise exception 'Existing publication required';end if;
 select * into old from public.crm_client_charter_publications where id=p_publication for update;
 if p_id is null or p_version is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit withdrawal identity/version/manual reason required';end if;
 req:=jsonb_build_object('publication_id',p_publication,'version',p_version,'reason',trim(p_reason));
 select * into retry from public.crm_client_charter_publication_history where id=p_id;
 if retry.id is not null then
  if retry.action='Withdrawn' and retry.actor_id=auth.uid() and retry.request=req then return retry.publication_id;end if;
  raise exception 'Withdrawal identity records a different request';
 end if;
 if old.version is distinct from p_version or old.status is distinct from 'Published' then raise exception 'Exact open publication required';end if;
 update public.crm_client_charter_publications set status='Withdrawn',version=version+1,withdrawn_at=now() where id=old.id returning * into saved;
 insert into public.crm_client_charter_publication_history(id,publication_id,copy_id,project_id,action,private_snapshot,before_record,after_record,request,reason,actor_id)
 values(p_id,old.id,old.copy_id,old.project_id,'Withdrawn','{}',to_jsonb(old),to_jsonb(saved),req,trim(p_reason),auth.uid());
 return old.id;
end$$;
revoke all on function public.publish_client_charter_copy(uuid,uuid,integer,uuid,uuid,text),public.withdraw_client_charter_publication(uuid,uuid,integer,text) from public,anon;
grant execute on function public.publish_client_charter_copy(uuid,uuid,integer,uuid,uuid,text),public.withdraw_client_charter_publication(uuid,uuid,integer,text) to authenticated;
notify pgrst,'reload schema';
commit;
