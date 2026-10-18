begin;
create table public.crm_training_rosters(
 id uuid primary key,training_id uuid not null references public.crm_project_training,project_id uuid not null references public.projects,
 training_version integer not null,sequence integer not null,previous_id uuid references public.crm_training_rosters,
 training_snapshot jsonb not null,participants jsonb not null,request jsonb not null,reason text not null,
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(training_id,sequence)
);
create index training_roster_project on public.crm_training_rosters(project_id);
create index training_roster_previous on public.crm_training_rosters(previous_id);
create index training_roster_actor on public.crm_training_rosters(actor_id);
create table public.crm_training_roster_members(
 roster_id uuid not null references public.crm_training_rosters,project_id uuid not null references public.projects,
 profile_id uuid not null references public.profiles,ordinal integer not null check(ordinal between 1 and 100),profile_snapshot jsonb not null,
 primary key(roster_id,profile_id),unique(roster_id,ordinal)
);
create index training_roster_member_project on public.crm_training_roster_members(project_id);
create index training_roster_member_profile on public.crm_training_roster_members(profile_id);
alter table public.crm_training_rosters enable row level security;
alter table public.crm_training_roster_members enable row level security;
revoke all on public.crm_training_rosters,public.crm_training_roster_members from public,anon,authenticated;
grant select on public.crm_training_rosters,public.crm_training_roster_members to authenticated;
create policy training_roster_read on public.crm_training_rosters for select to authenticated using(portal_private.execution_manager(project_id));
create policy training_roster_member_read on public.crm_training_roster_members for select to authenticated using(portal_private.execution_manager(project_id));
create function public.training_participant_candidates(p_training uuid) returns table(id uuid,name text)
language plpgsql stable security definer set search_path='' as $$
declare project uuid;
begin
 select project_id into project from public.crm_project_training where crm_project_training.id=p_training;
 if auth.uid() is null or project is null or not portal_private.execution_manager(project) then raise exception 'Assigned project manager access required';end if;
 return query select u.id,u.name from public.profiles u join public.project_assignments a on a.technician_id=u.id and a.project_id=project where u.active and u.role in ('admin','team') order by u.name,u.id;
end$$;
create function public.save_training_participants(p_id uuid,p_training uuid,p_version integer,p_previous uuid,p_participants uuid[],p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare t public.crm_project_training;old public.crm_training_rosters;retry public.crm_training_rosters;req jsonb;people jsonb;
begin
 select * into t from public.crm_project_training where id=p_training;
 if auth.uid() is null or t.id is null or not portal_private.execution_manager(t.project_id) then raise exception 'Assigned project manager access required';end if;
 perform 1 from public.projects where id=t.project_id for update;
 select * into t from public.crm_project_training where id=p_training for update;
 if p_id is null or p_version is null or p_participants is null or cardinality(p_participants)>100 or array_ndims(p_participants)>1 or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit roster identity/version/participants/manual reason required';end if;
 if exists(select 1 from unnest(p_participants) u where u is null) or (select count(distinct u) from unnest(p_participants) u)<>cardinality(p_participants) then raise exception 'Distinct actual participant accounts required';end if;
 req:=jsonb_build_object('training_id',p_training,'version',p_version,'previous_id',p_previous,'participants',to_jsonb(p_participants),'reason',trim(p_reason));
 select * into retry from public.crm_training_rosters where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=req then return retry.id;end if;
  raise exception 'Roster identity records a different request';
 end if;
 if t.version is distinct from p_version or t.details->>'status' is distinct from 'Draft' then raise exception 'Current Draft training version required';end if;
 select * into old from public.crm_training_rosters where training_id=t.id order by sequence desc limit 1;
 if old.id is distinct from p_previous then raise exception 'Roster changed; refresh latest revision';end if;
 -- Lock selected accounts/assignments while checking live eligibility, without assigning anyone.
 perform 1 from public.profiles where id=any(p_participants) order by id for share;
 perform 1 from public.project_assignments where project_id=t.project_id and technician_id=any(p_participants) order by technician_id for share;
 if (select count(*) from public.profiles u join public.project_assignments a on a.technician_id=u.id and a.project_id=t.project_id where u.id=any(p_participants) and u.active and u.role in ('admin','team'))<>cardinality(p_participants) then raise exception 'Choose active assigned project staff accounts';end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',u.id,'name',u.name,'role',u.role) order by chosen.ordinality),'[]'::jsonb) into people from unnest(p_participants) with ordinality chosen(id,ordinality) join public.profiles u on u.id=chosen.id;
 insert into public.crm_training_rosters(id,training_id,project_id,training_version,sequence,previous_id,training_snapshot,participants,request,reason,actor_id)
 values(p_id,t.id,t.project_id,t.version,coalesce(old.sequence,0)+1,old.id,to_jsonb(t),people,req,trim(p_reason),auth.uid());
 insert into public.crm_training_roster_members(roster_id,project_id,profile_id,ordinal,profile_snapshot)
 select p_id,t.project_id,(value->>'id')::uuid,ordinality::integer,value from jsonb_array_elements(people) with ordinality;
 return p_id;
end$$;
revoke all on function public.training_participant_candidates(uuid),public.save_training_participants(uuid,uuid,integer,uuid,uuid[],text) from public,anon;
grant execute on function public.training_participant_candidates(uuid),public.save_training_participants(uuid,uuid,integer,uuid,uuid[],text) to authenticated;
notify pgrst,'reload schema';
commit;
