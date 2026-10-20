begin;
-- Read projections over immutable issued evidence. No copied balances, skill credit or assignments.
create function portal_private.issued_employee_skills() returns table(employee_id uuid,definition_id uuid,skill text,evidence jsonb) language sql stable security definer set search_path='' as $$
 select c.employee_id,(c.snapshot->'assignment'->'criteria'->>'definition_id')::uuid,c.snapshot->'assignment'->'criteria'->>'skill',
 jsonb_agg(jsonb_build_object('certificate_id',c.id,'issued_at',c.issued_at,'expires_at',c.expires_at,'state',portal_private.competence_certificate_state(c,now())) order by c.issued_at,c.id)
 from public.competence_certificates c join public.profiles p on p.id=c.employee_id
 where p.active and p.role in ('admin','team') and c.issued_at<=now() and c.expires_at>now() and portal_private.competence_certificate_state(c,now()) in ('Current','Renewal due') and c.snapshot->'receipt'->'snapshot'->'result'->>'outcome'='Pass'
 group by c.employee_id,(c.snapshot->'assignment'->'criteria'->>'definition_id')::uuid,c.snapshot->'assignment'->'criteria'->>'skill';
$$;
revoke all on function portal_private.issued_employee_skills() from public,anon,authenticated;
create function public.competence_skill_profiles() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.is_staff() then raise exception 'Current internal staff skill-profile access required';end if;
 return jsonb_build_object('server_time',now(),'profiles',coalesce((select jsonb_agg(jsonb_build_object('employee',jsonb_build_object('id',p.id,'name',p.name),'skills',s.skills) order by p.name,p.id) from public.profiles p join lateral(select coalesce(jsonb_agg(jsonb_build_object('definition_id',s.definition_id,'skill',s.skill,'evidence',s.evidence) order by s.skill,s.definition_id),'[]'::jsonb) skills from portal_private.issued_employee_skills() s where s.employee_id=p.id)s on true where p.active and p.role in ('admin','team') and (p.id=auth.uid() or (portal_private.hr_access() and s.skills<>'[]'::jsonb))),'[]'::jsonb));
end$$;
create function public.project_allocation_skill_suggestions(p_project uuid,p_definition uuid default null,p_skill text default null) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare options jsonb;matches jsonb;
begin
 if auth.uid() is null or not public.is_staff() or p_project is null or not exists(select 1 from public.projects where id=p_project) or not portal_private.execution_manager(p_project) then raise exception 'Current assigned project manager skill-suggestion access required';end if;
 if (p_definition is null)<>(p_skill is null) or (p_skill is not null and length(p_skill) not between 1 and 200) then raise exception 'Explicit matching competency and actual skill label required';end if;
 with eligible as(select p.id,p.name from public.project_allocation_people(p_project) p),skills as(select s.* from portal_private.issued_employee_skills() s join eligible p on p.id=s.employee_id)
 select coalesce((select jsonb_agg(jsonb_build_object('definition_id',s.definition_id,'skill',s.skill) order by s.skill,s.definition_id) from (select distinct definition_id,skill from skills)s),'[]'::jsonb),
 coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'name',p.name,'definition_id',s.definition_id,'skill',s.skill,'evidence',s.evidence) order by p.name,p.id) from eligible p join skills s on s.employee_id=p.id where p_definition is not null and s.definition_id=p_definition and s.skill=p_skill),'[]'::jsonb)
 into options,matches;
 return jsonb_build_object('project_id',p_project,'server_time',now(),'skills',options,'matches',matches);
end$$;
revoke all on function public.competence_skill_profiles(),public.project_allocation_skill_suggestions(uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.competence_skill_profiles(),public.project_allocation_skill_suggestions(uuid,uuid,text) to authenticated;
commit;
