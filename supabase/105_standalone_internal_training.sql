begin;
create table public.crm_internal_training(
 id uuid primary key,training_type text not null default 'Internal' check(training_type='Internal'),
 title text not null,objective text not null,facilitator_id uuid not null references public.profiles,facilitator_snapshot jsonb not null,
 version integer not null default 1,status text not null default 'Draft' check(status='Draft'),reason text not null,
 created_by uuid not null references public.profiles,created_at timestamptz not null default now()
);
create index internal_training_facilitator on public.crm_internal_training(facilitator_id);
create index internal_training_creator on public.crm_internal_training(created_by);
create table public.crm_internal_training_history(
 id uuid primary key,training_id uuid not null references public.crm_internal_training,revision integer not null,
 before_record jsonb,after_record jsonb not null,request jsonb not null,reason text not null,actor_id uuid not null references public.profiles,
 created_at timestamptz not null default now(),unique(training_id,revision)
);
create index internal_training_history_actor on public.crm_internal_training_history(actor_id);
alter table public.crm_internal_training enable row level security;
alter table public.crm_internal_training_history enable row level security;
revoke all on public.crm_internal_training,public.crm_internal_training_history from public,anon,authenticated;
grant select on public.crm_internal_training,public.crm_internal_training_history to authenticated;
create policy internal_training_read on public.crm_internal_training for select to authenticated using(portal_private.hr_access() or (created_by=auth.uid() and portal_private.crm_permission('team.own')));
create policy internal_training_history_read on public.crm_internal_training_history for select to authenticated using(exists(select 1 from public.crm_internal_training t where t.id=training_id and (portal_private.hr_access() or (t.created_by=auth.uid() and portal_private.crm_permission('team.own')))));
create function portal_private.internal_training_facilitator(p_user uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles u where u.id=p_user and u.active and u.role in ('admin','team') and (portal_private.hr_access() or u.id=auth.uid() or portal_private.hr_supervisor(u.id,(now() at time zone 'Asia/Karachi')::date,'Lead')));
$$;
revoke all on function portal_private.internal_training_facilitator(uuid) from public,anon,authenticated;
create function public.internal_training_facilitators() returns table(id uuid,name text) language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not (portal_private.hr_access() or portal_private.crm_permission('team.own')) then raise exception 'HR or team lead access required';end if;
 return query select u.id,u.name from public.profiles u where portal_private.internal_training_facilitator(u.id) order by u.name,u.id;
end$$;
create function public.save_internal_training(p_request uuid,p_id uuid,p_version integer,p_title text,p_objective text,p_facilitator uuid,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare old public.crm_internal_training;saved public.crm_internal_training;retry public.crm_internal_training_history;req jsonb;person jsonb;
begin
 if auth.uid() is null or not (portal_private.hr_access() or portal_private.crm_permission('team.own')) then raise exception 'HR or team lead access required';end if;
 if p_request is null or p_id is null or p_facilitator is null or length(trim(coalesce(p_title,''))) not between 3 and 160 or length(trim(coalesce(p_objective,''))) not between 3 and 4000 or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit identity/title/objective/facilitator/manual reason required';end if;
 perform pg_advisory_xact_lock(hashtextextended('internal-training:'||p_id::text,0));
 select * into old from public.crm_internal_training where id=p_id for update;
 if old.id is not null and not (portal_private.hr_access() or old.created_by=auth.uid()) then raise exception 'Only HR or the creating team lead may revise this draft';end if;
 req:=jsonb_build_object('id',p_id,'version',p_version,'title',trim(p_title),'objective',trim(p_objective),'facilitator_id',p_facilitator,'reason',trim(p_reason));
 select * into retry from public.crm_internal_training_history where id=p_request;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=req then return retry.training_id;end if;
  raise exception 'Request identity records a different session revision';
 end if;
 if old.id is null and p_version is not null or old.id is not null and old.version is distinct from p_version then raise exception 'Current Internal training version required';end if;
 select jsonb_build_object('id',u.id,'name',u.name,'role',u.role) into person from public.profiles u where u.id=p_facilitator and portal_private.internal_training_facilitator(u.id) for share;
 if person is null then raise exception 'Choose an eligible active staff facilitator';end if;
 if old.id is null then
  insert into public.crm_internal_training(id,title,objective,facilitator_id,facilitator_snapshot,reason,created_by) values(p_id,trim(p_title),trim(p_objective),p_facilitator,person,trim(p_reason),auth.uid()) returning * into saved;
 else
  update public.crm_internal_training set title=trim(p_title),objective=trim(p_objective),facilitator_id=p_facilitator,facilitator_snapshot=person,reason=trim(p_reason),version=version+1 where id=p_id returning * into saved;
 end if;
 insert into public.crm_internal_training_history(id,training_id,revision,before_record,after_record,request,reason,actor_id)
 values(p_request,saved.id,saved.version,case when old.id is null then null else to_jsonb(old) end,to_jsonb(saved),req,trim(p_reason),auth.uid());
 return saved.id;
end$$;
revoke all on function public.internal_training_facilitators(),public.save_internal_training(uuid,uuid,integer,text,text,uuid,text) from public,anon;
grant execute on function public.internal_training_facilitators(),public.save_internal_training(uuid,uuid,integer,text,text,uuid,text) to authenticated;
notify pgrst,'reload schema';
commit;
