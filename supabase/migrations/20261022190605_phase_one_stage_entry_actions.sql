-- Manual actual stage-entry review-task rules, with no seeded recipients or tasks.
create table portal_private.crm_stage_actions(id uuid primary key,board_id uuid not null references public.crm_boards,stage_code text not null,title text not null check(length(trim(title)) between 3 and 200),recipient_id uuid not null references public.profiles,due_days integer not null check(due_days between 0 and 365),active boolean not null default false,version integer not null default 1);
create index crm_stage_action_board on portal_private.crm_stage_actions(board_id,stage_code);
create index crm_stage_action_recipient on portal_private.crm_stage_actions(recipient_id);
create table portal_private.crm_stage_action_history(id uuid primary key default gen_random_uuid(),action_id uuid not null references portal_private.crm_stage_actions,version integer not null,actor_id uuid not null references public.profiles,reason text not null,before_value jsonb,after_value jsonb not null,created_at timestamptz not null default now(),unique(action_id,version));
create index crm_stage_action_history_actor on portal_private.crm_stage_action_history(actor_id);
alter table public.crm_sales_tasks add column assigned_to uuid references public.profiles,add column stage_action_id uuid references portal_private.crm_stage_actions,add column stage_action_board_id uuid references public.crm_boards;
create index crm_sales_task_stage_board on public.crm_sales_tasks(stage_action_board_id);
create policy stage_task_board_scope on public.crm_sales_tasks as restrictive for select to authenticated using(stage_action_id is null or portal_private.board_access(stage_action_board_id));
create index crm_sales_task_assignee on public.crm_sales_tasks(assigned_to);
create index crm_sales_task_stage_action on public.crm_sales_tasks(stage_action_id);
create table portal_private.crm_stage_task_evidence(id uuid primary key default gen_random_uuid(),task_id uuid not null references public.crm_sales_tasks,actor_id uuid references public.profiles,kind text not null check(kind in ('Created','Completed')),evidence jsonb not null,created_at timestamptz not null default now());
create index crm_stage_task_evidence_task on portal_private.crm_stage_task_evidence(task_id);
create index crm_stage_task_evidence_actor on portal_private.crm_stage_task_evidence(actor_id);
do $$declare t text;begin foreach t in array array['crm_stage_actions','crm_stage_action_history','crm_stage_task_evidence'] loop execute format('alter table portal_private.%I enable row level security',t);execute format('revoke all on portal_private.%I from public,anon,authenticated,service_role',t);end loop;end$$;
create trigger crm_stage_action_history_immutable before update or delete on portal_private.crm_stage_action_history for each row execute function portal_private.lead_api_evidence_immutable();
create trigger crm_stage_task_evidence_immutable before update or delete on portal_private.crm_stage_task_evidence for each row execute function portal_private.lead_api_evidence_immutable();
create function portal_private.stage_action_recipient(p_user uuid,p_board uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles p where p.id=p_user and p.active and (p.role='admin' or p.role='team' and exists(select 1 from public.crm_board_memberships m where m.user_id=p.id and m.board_id=p_board) and (portal_private.crm_user_permission(p.id,'sales.manage') or portal_private.crm_user_permission(p.id,'product.own'))));
$$;
revoke all on function portal_private.stage_action_recipient(uuid,uuid) from public,anon,authenticated,service_role;
create function public.save_crm_stage_action(p_id uuid,p_version integer,p_board uuid,p_stage text,p_stage_version integer,p_data jsonb,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare old portal_private.crm_stage_actions;fresh portal_private.crm_stage_actions;recipient uuid;
begin
 perform 1 from public.profiles where id=auth.uid() and active and role='admin' for share;if not found then raise exception 'Active Administrator required';end if;
 if p_id is null or length(trim(coalesce(p_reason,''))) not between 3 and 1000 or p_data is null or jsonb_typeof(p_data)<>'object' or (select count(*) from jsonb_object_keys(p_data))<>4 or not(p_data ?& array['title','recipient_id','due_days','active']) or jsonb_typeof(p_data->'active')<>'boolean' or jsonb_typeof(p_data->'title')<>'string' or jsonb_typeof(p_data->'recipient_id')<>'string' or coalesce(p_data->>'due_days','')!~'^[0-9]{1,3}$' then raise exception 'Actual action, recipient, due interval, active choice and reason required';end if;
 perform pg_advisory_xact_lock(hashtextextended('stage-action:'||p_id::text,0));
 select * into old from portal_private.crm_stage_actions where id=p_id for update;
 perform 1 from public.crm_boards where id=p_board and (active or not(p_data->>'active')::boolean) for share;if not found then raise exception 'Active actual board required';end if;
 perform 1 from public.crm_board_stages where board_id=p_board and code=p_stage and (active or not(p_data->>'active')::boolean) and version=p_stage_version for share;if not found then raise exception 'Stage changed or inactive. Refresh first';end if;
 recipient:=(p_data->>'recipient_id')::uuid;perform 1 from public.profiles where id=recipient for share;
 if (old.id is null or old.recipient_id<>recipient or (p_data->>'active')::boolean) and not portal_private.stage_action_recipient(recipient,p_board) then raise exception 'Actual active board manager or product specialist recipient required';end if;
 if old.id is not null then
  if p_version is null or old.version<>p_version or old.board_id<>p_board or old.stage_code<>p_stage then raise exception 'Action changed or scope differs. Refresh first';end if;
  update portal_private.crm_stage_actions set title=trim(p_data->>'title'),recipient_id=recipient,due_days=(p_data->>'due_days')::integer,active=(p_data->>'active')::boolean,version=version+1 where id=p_id returning * into fresh;
 else
  if p_version is not null or (select count(*) from portal_private.crm_stage_actions where board_id=p_board)>=50 then raise exception 'Action missing or board configuration limit reached';end if;
  insert into portal_private.crm_stage_actions(id,board_id,stage_code,title,recipient_id,due_days,active) values(p_id,p_board,p_stage,trim(p_data->>'title'),recipient,(p_data->>'due_days')::integer,(p_data->>'active')::boolean) returning * into fresh;
 end if;
 insert into portal_private.crm_stage_action_history(action_id,version,actor_id,reason,before_value,after_value) values(p_id,fresh.version,auth.uid(),trim(p_reason),case when old.id is null then null else to_jsonb(old) end,to_jsonb(fresh));
end$$;
create function public.crm_stage_action_register() returns jsonb language plpgsql stable security definer set search_path='' as $$begin
 if not exists(select 1 from public.profiles where id=auth.uid() and active and role='admin') then raise exception 'Active Administrator required';end if;
 return jsonb_build_object('actions',coalesce((select jsonb_agg(to_jsonb(a) order by a.board_id,a.stage_code,a.id) from portal_private.crm_stage_actions a),'[]'::jsonb),'history',coalesce((select jsonb_agg(to_jsonb(h)) from (select * from portal_private.crm_stage_action_history order by created_at desc,id desc limit 100) h),'[]'::jsonb),'recipients',coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'name',p.name,'board_id',b.id)) from public.profiles p cross join public.crm_boards b where b.active and portal_private.stage_action_recipient(p.id,b.id)),'[]'::jsonb));end$$;
create function portal_private.enter_crm_stage_actions() returns trigger language plpgsql security definer set search_path='' as $$
declare a portal_private.crm_stage_actions;task_id uuid;event text;due date;
begin
 if old.stage is not distinct from new.stage then return new;end if;
 for a in select x.* from portal_private.crm_stage_actions x join public.crm_product_lines l on l.board_id=x.board_id and l.deal_id=new.id and l.status='Active' join public.crm_boards b on b.id=x.board_id and b.active join public.crm_board_stages s on s.board_id=x.board_id and s.code=x.stage_code and s.active where x.active and x.stage_code=new.stage order by x.id for share of x loop
  perform 1 from public.profiles where id=a.recipient_id for share;
  perform 1 from public.crm_board_memberships where board_id=a.board_id and user_id=a.recipient_id for share;
  perform 1 from public.crm_memberships where user_id=a.recipient_id order by role_id,team_id for share;
  perform 1 from public.crm_roles order by id for share;
  perform 1 from public.crm_teams where id in(select team_id from public.crm_memberships where user_id=a.recipient_id) order by id for share;
  if not portal_private.stage_action_recipient(a.recipient_id,a.board_id) then raise exception 'Configured stage-task recipient is no longer eligible. Administrator must revise the actual action';end if;
  due:=(now() at time zone 'Asia/Karachi')::date+a.due_days;event:='stage-entry:'||new.id||':'||new.version||':'||a.id;
  insert into public.crm_sales_tasks(deal_id,title,due_on,event_key,assigned_to,stage_action_id,stage_action_board_id) values(new.id,a.title,due,event,a.recipient_id,a.id,a.board_id) returning id into task_id;
  insert into public.portal_reminders(user_id,event_key,title,view,deal_id) select a.recipient_id,event,a.title||': '||new.title,'sales_boards',new.id where coalesce((select enabled from public.portal_reminder_preferences where user_id=a.recipient_id),true) on conflict do nothing;
  insert into portal_private.crm_stage_task_evidence(task_id,actor_id,kind,evidence) values(task_id,auth.uid(),'Created',jsonb_build_object('action',to_jsonb(a),'from_stage',old.stage,'to_stage',new.stage,'deal_version',new.version,'assignee',a.recipient_id,'due_on',due));
  insert into public.crm_sales_activity(deal_id,kind,body,actor_id) values(new.id,'Follow-up','Configured stage review task created: '||a.title,auth.uid());
 end loop;
 return new;
end$$;
revoke all on function portal_private.enter_crm_stage_actions() from public,anon,authenticated,service_role;
create trigger crm_stage_entry_actions after update of stage on public.crm_deals for each row execute function portal_private.enter_crm_stage_actions();
create or replace function public.complete_crm_sales_task(p_id uuid,p_version integer,p_note text) returns void language plpgsql security definer set search_path='' as $$declare task public.crm_sales_tasks;before_row jsonb;begin
 perform 1 from public.profiles where id=auth.uid() and active and role in ('admin','team') for share;if not found then raise exception 'Active staff account required';end if;
 select * into task from public.crm_sales_tasks where id=p_id for update;
 if not found or not portal_private.deal_access(task.deal_id) or (task.stage_action_id is not null and not portal_private.board_access(task.stage_action_board_id)) or not(case when task.stage_action_id is null then portal_private.deal_edit(task.deal_id) else public.is_admin() or portal_private.crm_permission('sales.manage') or task.assigned_to=auth.uid() end) then raise exception 'Sales task unavailable';end if;
 if task.version is distinct from p_version or task.status<>'Open' then raise exception 'Task changed or already completed';end if;
 if length(trim(coalesce(p_note,''))) not between 3 and 2000 then raise exception 'Completion note required';end if;
 before_row:=to_jsonb(task);update public.crm_sales_tasks set status='Done',note=trim(p_note),version=version+1 where id=p_id;
 insert into public.crm_sales_activity(deal_id,kind,body,actor_id) values(task.deal_id,'Follow-up','Completed sales task: '||trim(p_note),auth.uid());
 if task.stage_action_id is not null then insert into portal_private.crm_stage_task_evidence(task_id,actor_id,kind,evidence) values(p_id,auth.uid(),'Completed',jsonb_build_object('before',before_row,'note',trim(p_note),'version',task.version+1));end if;
end$$;
revoke all on function public.save_crm_stage_action(uuid,integer,uuid,text,integer,jsonb,text),public.crm_stage_action_register(),public.complete_crm_sales_task(uuid,integer,text) from public,anon,service_role;
grant execute on function public.save_crm_stage_action(uuid,integer,uuid,text,integer,jsonb,text),public.crm_stage_action_register(),public.complete_crm_sales_task(uuid,integer,text) to authenticated;
