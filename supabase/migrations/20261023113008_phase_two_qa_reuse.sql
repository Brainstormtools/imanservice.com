-- UNAPPLIED. Explicit reviewed references in new template versions only.
create function portal_private.freeze_template_qa_sources() returns trigger language plpgsql security definer set search_path='' as $$
declare task jsonb;source jsonb;refs jsonb;tasks jsonb:='[]';v portal_private.crm_qa_library_versions;lib portal_private.crm_qa_library;seen uuid[];begin
 for task in select value from jsonb_array_elements(new.tasks) loop
  refs:='[]';seen:='{}';
  if task ? 'qa_sop_sources' then
   perform 1 from public.profiles where id=auth.uid() and active and role='admin' for share;if not found then raise exception 'Current Admin review required for QA/SOP reuse';end if;
   if jsonb_typeof(task->'qa_sop_sources') is distinct from 'array' or jsonb_array_length(task->'qa_sop_sources')>10 then raise exception 'Use at most ten explicit QA/SOP references per task';end if;
   -- Same order as master revision writes; locks prevent retirement/revision during this save.
   perform 1 from portal_private.crm_qa_library where id in(select (r->>'library_id')::uuid from jsonb_array_elements(task->'qa_sop_sources') r) order by id for share;
   for source in select value from jsonb_array_elements(task->'qa_sop_sources') loop
    select * into v from portal_private.crm_qa_library_versions where id=(source->>'version_id')::uuid;
    if not found then raise exception 'Actual reviewed QA/SOP version required';end if;
    select * into lib from portal_private.crm_qa_library where id=v.library_id;
    if source->'confirmed' is distinct from 'true'::jsonb or not v.active or lib.revision<>v.revision or v.library_id=any(seen) or source->>'library_id' is distinct from v.library_id::text or source->'revision' is distinct from to_jsonb(v.revision) or source->>'name' is distinct from v.name or source->>'kind' is distinct from v.kind or source->'steps' is distinct from v.steps or length(trim(coalesce(source->>'reason',''))) not between 3 and 1000 then raise exception 'QA/SOP source changed, retired, duplicated or lacks actual review reason';end if;
    seen:=seen||v.library_id;
    refs:=refs||jsonb_build_array(jsonb_build_object('version_id',v.id,'library_id',v.library_id,'revision',v.revision,'name',v.name,'kind',v.kind,'steps',v.steps,'reason',trim(source->>'reason'),'confirmed',true,'selected_by',auth.uid(),'selected_at',now()));
   end loop;
   task:=jsonb_set(task,'{qa_sop_sources}',refs);
  end if;
  tasks:=tasks||jsonb_build_array(task);
 end loop;
 new.tasks:=tasks;return new;
end$$;
revoke all on function portal_private.freeze_template_qa_sources() from public,anon,authenticated;
create trigger freeze_template_qa_sources before insert on public.crm_template_versions for each row execute function portal_private.freeze_template_qa_sources();
create function portal_private.preserve_template_qa_sources() returns trigger language plpgsql security definer set search_path='' as $$begin
 if exists(select 1 from jsonb_array_elements(old.tasks)t where t ? 'qa_sop_sources' and t->'qa_sop_sources'<>'[]'::jsonb) then raise exception 'Saved QA/SOP source evidence is immutable; create a new template version';end if;
 if tg_op='DELETE' then return old;else return new;end if;
end$$;
revoke all on function portal_private.preserve_template_qa_sources() from public,anon,authenticated;
create trigger preserve_template_qa_sources before update or delete on public.crm_template_versions for each row execute function portal_private.preserve_template_qa_sources();

-- Dedicated entry point makes the new UI fail closed until this migration is released.
create function public.save_crm_project_template_qa(p_id uuid,p_version integer,p_board uuid,p_name text,p_active boolean,p_parameters jsonb,p_tasks jsonb) returns uuid language plpgsql security invoker set search_path='' as $$begin
 if not exists(select 1 from public.profiles where id=auth.uid() and active and role='admin') then raise exception 'Current Admin access required';end if;
 return public.save_crm_project_template(p_id,p_version,p_board,p_name,p_active,p_parameters,p_tasks);
end$$;
revoke all on function public.save_crm_project_template_qa(uuid,integer,uuid,text,boolean,jsonb,jsonb) from public,anon;
grant execute on function public.save_crm_project_template_qa(uuid,integer,uuid,text,boolean,jsonb,jsonb) to authenticated;
