begin;
-- Return only basic identity for workers already eligible for this project.
create function public.project_allocation_people(p_project uuid) returns table(id uuid,name text,role text,active boolean) language plpgsql stable security definer set search_path='' as $$begin
if not exists(select 1 from public.projects where projects.id=p_project) or not portal_private.execution_manager(p_project) then raise exception 'Assigned project manager access required';end if;
return query select u.id,u.name,u.role,u.active from public.profiles u where u.active and u.role in ('admin','team') and (u.role='admin' or exists(select 1 from public.project_assignments a where a.project_id=p_project and a.technician_id=u.id) or exists(select 1 from public.tasks t where t.project_id=p_project and (t.assignee=u.id or u.id=any(t.collaborators)))) order by u.name,u.id;
end$$;
revoke all on function public.project_allocation_people(uuid) from public,anon;
grant execute on function public.project_allocation_people(uuid) to authenticated;
commit;
