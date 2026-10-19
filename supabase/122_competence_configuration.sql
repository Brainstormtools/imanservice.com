begin;
-- Manual administrator setup only. No criteria, people, certificates or skills seeded.
create table public.competence_definition_revisions(
 id uuid primary key,definition_id uuid not null,revision integer not null check(revision>0),
 title text not null check(length(title) between 3 and 200),skill text not null check(length(skill) between 1 and 200),
 checklist jsonb not null check(jsonb_typeof(checklist)='array' and jsonb_array_length(checklist) between 1 and 100),
 quiz_enabled boolean not null,pass_mark numeric not null check(pass_mark between 0 and 100),
 validity_months integer not null check(validity_months between 1 and 1200),warning_days integer check(warning_days between 1 and 36500),
 active boolean not null,request jsonb not null,reason text not null check(length(reason) between 3 and 2000),
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(definition_id,revision)
);
create index competence_definition_actor on public.competence_definition_revisions(actor_id);
create table public.competence_assessor_designations(
 id uuid primary key,user_id uuid not null references public.profiles,revision integer not null check(revision>0),
 designation text not null check(designation in ('Site Engineer','Senior technician')),active boolean not null,
 request jsonb not null,reason text not null check(length(reason) between 3 and 2000),
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(user_id,revision)
);
create index competence_assessor_actor on public.competence_assessor_designations(actor_id);
alter table public.competence_definition_revisions enable row level security;
alter table public.competence_assessor_designations enable row level security;
revoke all on public.competence_definition_revisions,public.competence_assessor_designations from public,anon,authenticated;
grant select on public.competence_definition_revisions,public.competence_assessor_designations to authenticated;
create policy competence_definition_admin_read on public.competence_definition_revisions for select to authenticated using(public.is_admin());
create policy competence_assessor_admin_read on public.competence_assessor_designations for select to authenticated using(public.is_admin());
create function portal_private.competence_configuration_immutable() returns trigger language plpgsql set search_path='' as $$
begin raise exception 'Competence configuration history is immutable';end$$;
create trigger competence_definition_immutable before update or delete on public.competence_definition_revisions for each row execute function portal_private.competence_configuration_immutable();
create trigger competence_assessor_immutable before update or delete on public.competence_assessor_designations for each row execute function portal_private.competence_configuration_immutable();
revoke all on function portal_private.competence_configuration_immutable() from public,anon,authenticated;
create function public.competence_configuration_context() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator competence configuration access required';end if;
 return jsonb_build_object(
 'definitions',coalesce((select jsonb_agg(to_jsonb(d) order by d.created_at,d.definition_id) from (select distinct on(definition_id) * from public.competence_definition_revisions order by definition_id,revision desc)d),'[]'::jsonb),
 'definition_history',coalesce((select jsonb_agg(to_jsonb(d) order by d.definition_id,d.revision) from public.competence_definition_revisions d),'[]'::jsonb),
 'assessors',coalesce((select jsonb_agg(to_jsonb(d) order by d.user_id) from (select distinct on(user_id) * from public.competence_assessor_designations order by user_id,revision desc)d),'[]'::jsonb),
 'assessor_history',coalesce((select jsonb_agg(to_jsonb(d) order by d.user_id,d.revision) from public.competence_assessor_designations d),'[]'::jsonb),
 'people',coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'name',p.name,'active',p.active,'role',p.role) order by p.name,p.id) from public.profiles p where (p.active and p.role in ('admin','team')) or exists(select 1 from public.competence_assessor_designations d where d.user_id=p.id)),'[]'::jsonb));
end$$;
create function public.save_competence_definition(p_id uuid,p_definition uuid,p_previous integer,p_data jsonb,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare old public.competence_definition_revisions;req jsonb;latest integer;step jsonb;mark numeric;months integer;warning integer;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator competence configuration access required';end if;
 perform 1 from public.profiles where id=auth.uid() for share;
 if not public.is_admin() then raise exception 'Current administrator authority required';end if;
 if p_id is null or p_definition is null or p_previous is null or p_previous<0 or p_data is null or jsonb_typeof(p_data)<>'object' or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit definition, previous revision, actual criteria and reason required';end if;
 if exists(select 1 from jsonb_object_keys(p_data) k where k not in ('title','skill','checklist','quiz_enabled','pass_mark','validity_months','warning_days','active')) then raise exception 'Only explicit competence definition fields allowed';end if;
 req:=jsonb_build_object('definition_id',p_definition,'previous',p_previous,'data',p_data,'reason',trim(p_reason));
 perform pg_advisory_xact_lock(hashtextextended(p_definition::text,122));
 select * into old from public.competence_definition_revisions where id=p_id;
 if old.id is not null then
  if old.actor_id=auth.uid() and old.request=req then return old.id;end if;
  raise exception 'Definition request records different content or account';
 end if;
 select coalesce(max(revision),0) into latest from public.competence_definition_revisions where definition_id=p_definition;
 if latest<>p_previous then raise exception 'Exact current competence definition revision required';end if;
 if jsonb_typeof(p_data->'title') is distinct from 'string' or length(trim(p_data->>'title')) not between 3 and 200 or jsonb_typeof(p_data->'skill') is distinct from 'string' or length(trim(p_data->>'skill')) not between 1 and 200 or jsonb_typeof(p_data->'quiz_enabled') is distinct from 'boolean' or jsonb_typeof(p_data->'active') is distinct from 'boolean' then raise exception 'Actual title, skill, explicit quiz choice and active/inactive choice required';end if;
 if jsonb_typeof(p_data->'checklist') is distinct from 'array' then raise exception 'Actual practical checklist required';end if;
 if jsonb_array_length(p_data->'checklist') not between 1 and 100 then raise exception 'Checklist requires 1 to 100 actual steps';end if;
 for step in select value from jsonb_array_elements(p_data->'checklist') loop
  if jsonb_typeof(step)<>'object' then raise exception 'Actual checklist step required';end if;
  if exists(select 1 from jsonb_object_keys(step) k where k not in ('id','label','mandatory')) or jsonb_typeof(step->'id') is distinct from 'string' or jsonb_typeof(step->'label') is distinct from 'string' or length(trim(step->>'label')) not between 1 and 1000 or jsonb_typeof(step->'mandatory') is distinct from 'boolean' then raise exception 'Checklist requires unique step ID, actual label and explicit mandatory choice';end if;
  perform (step->>'id')::uuid;
 end loop;
 if exists(select 1 from jsonb_array_elements(p_data->'checklist') s group by (s->>'id')::uuid having count(*)>1) then raise exception 'Checklist step IDs must be unique';end if;
 if jsonb_typeof(coalesce(p_data->'pass_mark','70'::jsonb))<>'number' or jsonb_typeof(coalesce(p_data->'validity_months','12'::jsonb))<>'number' then raise exception 'Numeric pass mark and whole-month validity required';end if;
 mark:=coalesce(p_data->>'pass_mark','70')::numeric;
 if (p_data->>'validity_months')::numeric is not null and (p_data->>'validity_months')::numeric<>trunc((p_data->>'validity_months')::numeric) then raise exception 'Whole-month validity required';end if;
 months:=(coalesce(p_data->>'validity_months','12')::numeric)::integer;
 if mark not between 0 and 100 or months not between 1 and 1200 then raise exception 'Pass mark 0 to 100 and validity 1 to 1200 months required';end if;
 if p_data->'warning_days' is not null and p_data->'warning_days'<>'null'::jsonb then
  if jsonb_typeof(p_data->'warning_days')<>'number' or (p_data->>'warning_days')::numeric<>trunc((p_data->>'warning_days')::numeric) then raise exception 'Explicit whole-day warning lead time required';end if;
  warning:=((p_data->>'warning_days')::numeric)::integer;
  if warning not between 1 and 36500 then raise exception 'Positive warning lead time required';end if;
 end if;
 insert into public.competence_definition_revisions(id,definition_id,revision,title,skill,checklist,quiz_enabled,pass_mark,validity_months,warning_days,active,request,reason,actor_id)
 values(p_id,p_definition,latest+1,trim(p_data->>'title'),trim(p_data->>'skill'),p_data->'checklist',(p_data->>'quiz_enabled')::boolean,mark,months,warning,(p_data->>'active')::boolean,req,trim(p_reason),auth.uid());
 return p_id;
end$$;
create function public.set_competence_assessor(p_id uuid,p_user uuid,p_previous integer,p_designation text,p_active boolean,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare old public.competence_assessor_designations;req jsonb;latest integer;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator competence configuration access required';end if;
 perform 1 from public.profiles where id in(auth.uid(),p_user) order by id for share;
 if not public.is_admin() then raise exception 'Current administrator authority required';end if;
 if p_id is null or p_user is null or p_previous is null or p_previous<0 or p_active is null or p_designation is null or p_designation not in ('Site Engineer','Senior technician') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Actual account, designation, explicit grant/revoke choice, previous revision and reason required';end if;
 if not exists(select 1 from public.profiles where id=p_user) or (p_active and not exists(select 1 from public.profiles where id=p_user and active and role in ('admin','team'))) then raise exception 'Current actual active internal staff required for assessor designation';end if;
 req:=jsonb_build_object('user_id',p_user,'previous',p_previous,'designation',p_designation,'active',p_active,'reason',trim(p_reason));
 perform pg_advisory_xact_lock(hashtextextended(p_user::text,123));
 select * into old from public.competence_assessor_designations where id=p_id;
 if old.id is not null then
  if old.actor_id=auth.uid() and old.request=req then return old.id;end if;
  raise exception 'Assessor request records different content or account';
 end if;
 select coalesce(max(revision),0) into latest from public.competence_assessor_designations where user_id=p_user;
 if latest<>p_previous then raise exception 'Exact current assessor designation revision required';end if;
 if latest=0 and not p_active then raise exception 'No assessor designation exists to revoke';end if;
 insert into public.competence_assessor_designations(id,user_id,revision,designation,active,request,reason,actor_id) values(p_id,p_user,latest+1,p_designation,p_active,req,trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.competence_configuration_context(),public.save_competence_definition(uuid,uuid,integer,jsonb,text),public.set_competence_assessor(uuid,uuid,integer,text,boolean,text) from public,anon;
grant execute on function public.competence_configuration_context(),public.save_competence_definition(uuid,uuid,integer,jsonb,text),public.set_competence_assessor(uuid,uuid,integer,text,boolean,text) to authenticated;
notify pgrst,'reload schema';
commit;
