begin;
create table public.crm_training_session_definitions(
 id uuid primary key,training_id uuid not null references public.crm_project_training,project_id uuid not null references public.projects,
 training_version integer not null,sequence integer not null,previous_id uuid references public.crm_training_session_definitions,
 training_type text not null check(training_type in ('Client','Internal')),facilitator_id uuid not null references public.profiles,
 facilitator_snapshot jsonb not null,training_snapshot jsonb not null,request jsonb not null,reason text not null,
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(training_id,sequence)
);
create index training_session_project on public.crm_training_session_definitions(project_id);
create index training_session_previous on public.crm_training_session_definitions(previous_id);
create index training_session_facilitator on public.crm_training_session_definitions(facilitator_id);
create index training_session_actor on public.crm_training_session_definitions(actor_id);
alter table public.crm_training_session_definitions enable row level security;
revoke all on public.crm_training_session_definitions from public,anon,authenticated;
grant select on public.crm_training_session_definitions to authenticated;
create policy training_session_read on public.crm_training_session_definitions for select to authenticated using(portal_private.execution_manager(project_id));
create function public.save_training_session_definition(p_id uuid,p_training uuid,p_version integer,p_previous uuid,p_type text,p_facilitator uuid,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare t public.crm_project_training;old public.crm_training_session_definitions;retry public.crm_training_session_definitions;req jsonb;person jsonb;
begin
 select * into t from public.crm_project_training where id=p_training;
 if auth.uid() is null or t.id is null or not portal_private.execution_manager(t.project_id) then raise exception 'Assigned project manager access required';end if;
 perform 1 from public.projects where id=t.project_id for update;
 select * into t from public.crm_project_training where id=p_training for update;
 if p_id is null or p_version is null or p_type is null or p_type not in ('Client','Internal') or p_facilitator is null or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit session identity/version/type/facilitator/manual reason required';end if;
 req:=jsonb_build_object('training_id',p_training,'version',p_version,'previous_id',p_previous,'type',p_type,'facilitator_id',p_facilitator,'reason',trim(p_reason));
 select * into retry from public.crm_training_session_definitions where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=req then return retry.id;end if;
  raise exception 'Session identity records a different request';
 end if;
 if t.version is distinct from p_version or t.details->>'status' is distinct from 'Draft' then raise exception 'Current Draft training version required';end if;
 select * into old from public.crm_training_session_definitions where training_id=t.id order by sequence desc limit 1;
 if old.id is distinct from p_previous then raise exception 'Session definition changed; refresh latest revision';end if;
 select jsonb_build_object('id',u.id,'name',u.name,'role',u.role) into person from public.profiles u join public.project_assignments a on a.technician_id=u.id and a.project_id=t.project_id where u.id=p_facilitator and u.active and u.role in ('admin','team') for share of u,a;
 if person is null then raise exception 'Choose an active assigned staff facilitator account';end if;
 insert into public.crm_training_session_definitions(id,training_id,project_id,training_version,sequence,previous_id,training_type,facilitator_id,facilitator_snapshot,training_snapshot,request,reason,actor_id)
 values(p_id,t.id,t.project_id,t.version,coalesce(old.sequence,0)+1,old.id,p_type,p_facilitator,person,to_jsonb(t),req,trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.save_training_session_definition(uuid,uuid,integer,uuid,text,uuid,text) from public,anon;
grant execute on function public.save_training_session_definition(uuid,uuid,integer,uuid,text,uuid,text) to authenticated;
notify pgrst,'reload schema';
commit;
