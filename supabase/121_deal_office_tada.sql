begin;
-- Confirmed interim policy: own Deal activity -> Office/no-project expense.
-- Only the explicitly requested category is added; no business fixtures/assignments.
alter table public.fin_expenses add column reference text not null default '' check(length(reference)<=160);
update public.crm_settings set value=value||'["Pre-sales / Survey"]'::jsonb,version=version+1,updated_at=now()
 where id='expense_categories' and not value @> '["Pre-sales / Survey"]'::jsonb;
create or replace function portal_private.activity_expense_authorized(p public.work_activities) returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and public.is_staff() and p.user_id=auth.uid() and p.link_kind in ('Project','Ticket','Internal','Deal')
 and portal_private.activity_read(p) and portal_private.activity_scope(p.link_kind,p.project_id,p.task_id,p.ticket_id,p.deal_id)
 and portal_private.activity_worker_authorized(p) and portal_private.expense_scope(p.project_id,p.task_id);
$$;
create or replace function public.activity_tada_context(p_activity uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare a public.work_activities;sources jsonb;
begin
 select * into a from public.work_activities where id=p_activity;
 if a.id is null or not coalesce(portal_private.activity_expense_authorized(a),false) then raise exception 'Own activity and current existing expense access required';end if;
 select coalesce(jsonb_agg(to_jsonb(s)||jsonb_build_object('expense',jsonb_build_object('id',e.id,'number',e.number,'status',e.status,'version',e.version,'category',e.category,'amount',e.amount,'voucher',e.voucher,'reference',e.reference),'source_current',a.version=s.activity_version and a.status not in ('Voided','Cancelled')) order by s.created_at,s.id),'[]') into sources
 from public.work_activity_expense_sources s join public.fin_expenses e on e.id=s.expense_id where s.activity_id=a.id and portal_private.expense_read(e.id);
 return jsonb_build_object('activity',jsonb_build_object('id',a.id,'version',a.version,'status',a.status,'project_id',a.project_id,'task_id',a.task_id,'ticket_id',a.ticket_id,'link_kind',a.link_kind,'deal_id',a.deal_id,'location',a.location,'description',a.description,'actual_start',a.actual_start,'actual_end',a.actual_end),'sources',sources);
end$$;
create or replace function public.create_activity_tada_claim(p_id uuid,p_activity uuid,p_version integer,p_data jsonb) returns uuid
language plpgsql security definer set search_path='' as $$
declare a public.work_activities;old public.work_activity_expense_sources;payload jsonb;req jsonb;expense uuid;reason text;
begin
 select * into a from public.work_activities where id=p_activity;
 if a.id is null or not coalesce(portal_private.activity_expense_authorized(a),false) then raise exception 'Own activity and current existing expense access required';end if;
 perform portal_private.activity_open(a.project_id);
 perform pg_advisory_xact_lock(hashtextextended(a.user_id::text,24));
 perform 1 from public.profiles where id=auth.uid() for share;
 perform 1 from public.crm_memberships where user_id=auth.uid() for share;
 perform 1 from public.project_assignments where project_id=a.project_id and technician_id=auth.uid() for share;
 perform 1 from public.tasks where id=a.task_id for share;
 if a.link_kind='Deal' then
  perform 1 from public.crm_deals where id=a.deal_id for share;
  perform 1 from public.crm_product_lines where deal_id=a.deal_id for share;
  perform 1 from public.crm_board_memberships where user_id=auth.uid() for share;
 end if;
 select * into a from public.work_activities where id=p_activity for update;
 if not coalesce(portal_private.activity_expense_authorized(a),false) then raise exception 'Current activity and expense authority required';end if;
 if p_id is null or p_data is null or jsonb_typeof(p_data)<>'object' then raise exception 'Explicit claim request and manually entered expense fields required';end if;
 if exists(select 1 from jsonb_object_keys(p_data) k where k not in ('description','payee','voucher','incurred_on','due_on','amount','evidence','reason') and not (k='reference' and a.link_kind='Deal')) then raise exception 'Only manual expense fields allowed; activity supplies fixed expense scope and category';end if;
 reason:=trim(coalesce(p_data->>'reason',''));
 if length(reason) not between 3 and 2000 then raise exception 'Manual claim creation reason required';end if;
 payload:=jsonb_build_object('project_id',a.project_id,'task_id',a.task_id,'category',case when a.link_kind='Deal' then 'Pre-sales / Survey' else 'TADA' end,'description',trim(p_data->>'description'),'payee',trim(p_data->>'payee'),'voucher',trim(p_data->>'voucher'),'incurred_on',p_data->>'incurred_on','due_on',p_data->>'due_on','amount',(p_data->>'amount')::numeric,'evidence',trim(p_data->>'evidence'));
 if a.link_kind='Deal' then
  if length(trim(coalesce(p_data->>'reference',''))) not between 1 and 160 then raise exception 'Actual Deal number reference required';end if;
  payload:=payload||jsonb_build_object('reference',trim(p_data->>'reference'));
 end if;
 req:=jsonb_build_object('activity_id',a.id,'activity_version',p_version,'data',payload,'reason',reason);
 select * into old from public.work_activity_expense_sources where id=p_id;
 if old.id is not null then
  if old.actor_id=auth.uid() and old.request=req and portal_private.expense_read(old.expense_id) then return old.expense_id;end if;
  raise exception 'Claim request records different content or account';
 end if;
 if a.version is distinct from p_version or a.status in ('Voided','Cancelled') then raise exception 'Exact current non-void activity version required';end if;
 expense:=public.save_finance_expense(null,null,payload);
 if a.link_kind='Deal' then update public.fin_expenses set reference=payload->>'reference' where id=expense;end if;
 insert into public.work_activity_expense_sources(id,activity_id,expense_id,activity_version,source_snapshot,expense_snapshot,request,reason,actor_id)
 select p_id,a.id,e.id,a.version,jsonb_build_object('id',a.id,'user_id',a.user_id,'version',a.version,'status',a.status,'project_id',a.project_id,'task_id',a.task_id,'ticket_id',a.ticket_id,'link_kind',a.link_kind,'deal_id',a.deal_id,'location',a.location,'description',a.description,'actual_start',a.actual_start,'actual_end',a.actual_end),to_jsonb(e),req,reason,auth.uid() from public.fin_expenses e where e.id=expense;
 perform portal_private.finance_audit(expense,null,'Activity source recorded',reason);
 return expense;
end$$;
-- Preserve each source's original category (legacy TADA or Deal Pre-sales / Survey),
-- scope, author and manually supplied Deal reference through ordinary revisions.
create or replace function portal_private.activity_expense_source_guard() returns trigger language plpgsql security definer set search_path='' as $$
declare s public.work_activity_expense_sources;
begin
 select * into s from public.work_activity_expense_sources where expense_id=old.id;
 if s.id is not null and (new.category is distinct from s.expense_snapshot->>'category' or row(new.project_id,new.task_id,new.created_by) is distinct from row(old.project_id,old.task_id,old.created_by) or (s.source_snapshot->>'link_kind'='Deal' and new.reference is distinct from s.expense_snapshot->>'reference')) then raise exception 'Activity-linked expense category, original work scope, author and Deal reference are fixed';end if;
 return new;
end$$;
drop trigger activity_expense_source_guard on public.fin_expenses;
create trigger activity_expense_source_guard before update of category,project_id,task_id,created_by,reference on public.fin_expenses for each row execute function portal_private.activity_expense_source_guard();
revoke all on function portal_private.activity_expense_source_guard() from public,anon,authenticated;
revoke all on function portal_private.activity_expense_authorized(public.work_activities) from public,anon,authenticated;
revoke all on function public.activity_tada_context(uuid),public.create_activity_tada_claim(uuid,uuid,integer,jsonb) from public,anon;
grant execute on function public.activity_tada_context(uuid),public.create_activity_tada_claim(uuid,uuid,integer,jsonb) to authenticated;
notify pgrst,'reload schema';
commit;
