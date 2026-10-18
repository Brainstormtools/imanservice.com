begin;
-- Invoker access deliberately preserves every existing source/receipt/review/
-- confirmation/storage row policy. This read endpoint grants no new row access.
create function public.training_receipt_history(p_kind text,p_source uuid) returns setof jsonb
language plpgsql stable security invoker set search_path='' as $$
declare v_source_version integer;v_source_status text;
begin
 if auth.uid() is null or p_kind is null or p_kind not in ('Project','Internal') or p_source is null then raise exception 'Actual training source and current coordinator access required';end if;
 if p_kind='Project' then
  select t.version,t.details->>'status' into v_source_version,v_source_status from public.crm_project_training t where t.id=p_source;
 else
  select t.version,t.status into v_source_version,v_source_status from public.crm_internal_training t where t.id=p_source;
 end if;
 if not found then raise exception 'Training source unavailable in current coordinator scope';end if;
 return query
 with registers as (
 select r.*,r.source_version=v_source_version and v_source_status='Draft'
 and not exists(select 1 from public.crm_training_attendee_registers n where n.source_kind=r.source_kind and n.source_id=r.source_id and n.sequence>r.sequence)
 and (p_kind='Internal' or (d.training_version=v_source_version and not exists(select 1 from public.crm_training_session_definitions n where n.training_id=p_source and n.sequence>d.sequence))) current_register
 from public.crm_training_attendee_registers r left join public.crm_training_session_definitions d on d.id=r.project_definition_id
 where (p_kind='Project' and r.source_kind='Project' and d.training_id=p_source) or (p_kind='Internal' and r.source_kind='Internal' and r.internal_training_id=p_source)
 )
 select to_jsonb(r)||jsonb_build_object('attendance',(
 select coalesce(jsonb_agg(to_jsonb(a)||jsonb_build_object(
 'current',r.current_register and not exists(select 1 from public.crm_training_attendance n where n.register_id=r.id and n.sequence>a.sequence),
 'proof',(select coalesce(jsonb_agg(to_jsonb(e)||jsonb_build_object('stored_metadata_matches',exists(select 1 from storage.objects o where o.bucket_id='training-evidence' and o.name=e.path and o.owner_id=e.actor_id::text and o.metadata->>'size'=e.size::text and o.metadata->>'mimetype'=e.mime)) order by e.created_at,e.id),'[]') from public.crm_training_evidence e where e.attendance_id=a.id),
 'client_submissions',(select coalesce(jsonb_agg(to_jsonb(s)||jsonb_build_object('decisions',(select coalesce(jsonb_agg(to_jsonb(d) order by d.sequence),'[]') from public.crm_client_training_decisions d where d.submission_id=s.id),'confirmations',(select coalesce(jsonb_agg(to_jsonb(c) order by c.created_at,c.id),'[]') from public.crm_client_training_confirmations c where c.submission_id=s.id)) order by s.sequence),'[]') from public.crm_client_training_submissions s where s.attendance_id=a.id),
 'internal_submissions',(select coalesce(jsonb_agg(to_jsonb(s)||jsonb_build_object('decisions',(select coalesce(jsonb_agg(to_jsonb(d) order by d.sequence),'[]') from public.crm_internal_training_decisions d where d.submission_id=s.id)) order by s.sequence),'[]') from public.crm_internal_training_submissions s where s.attendance_id=a.id)
 ) order by a.sequence),'[]') from public.crm_training_attendance a where a.register_id=r.id
 )) from registers r order by r.created_at,r.id;
end$$;
revoke all on function public.training_receipt_history(text,uuid) from public,anon;
grant execute on function public.training_receipt_history(text,uuid) to authenticated;
notify pgrst,'reload schema';
commit;
