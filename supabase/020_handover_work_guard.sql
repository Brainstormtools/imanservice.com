begin;
-- Check both sides of reassignment, so moving a task out cannot evade its signed scope lock.
create or replace function portal_private.handover_work_guard() returns trigger language plpgsql security definer set search_path='' as $$declare row_data jsonb;pid uuid;begin
for row_data in select value from jsonb_array_elements(case when tg_op='UPDATE' then jsonb_build_array(to_jsonb(old),to_jsonb(new)) when tg_op='DELETE' then jsonb_build_array(to_jsonb(old)) else jsonb_build_array(to_jsonb(new)) end) loop
pid:=null;
if tg_table_name in ('tasks','task_completions','crm_nodes','crm_phases','crm_punch_items') then pid:=(row_data->>'project_id')::uuid;
elsif tg_table_name='task_items' then select project_id into pid from public.tasks where id=(row_data->>'task_id')::uuid;
elsif tg_table_name='crm_node_checks' then select project_id into pid from public.crm_nodes where id=(row_data->>'node_id')::uuid;end if;
if exists(select 1 from public.crm_handovers where project_id=pid and status in ('Awaiting signatures','Signed','Closed')) then raise exception 'Released handover locks execution; cancel the revision before changes';end if;
end loop;
if tg_op='DELETE' then return old;end if;return new;end$$;
revoke all on function portal_private.handover_work_guard() from public,anon,authenticated;
commit;
