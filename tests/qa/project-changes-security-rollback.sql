begin;
do $$declare a uuid;c uuid:=gen_random_uuid();p uuid:=gen_random_uuid();m uuid:=gen_random_uuid();g uuid:=gen_random_uuid();l uuid:=gen_random_uuid();d jsonb:='{"title":"QA request","proposed_scope":"QA proposed scope","justification":"QA need","cost_impact":"QA cost assessment","schedule_impact":"QA schedule assessment","evidence":"QA reference","status":"Draft","decision_note":""}';begin
select id into a from profiles where active and role='admin' order by id limit 1;
perform set_config('request.jwt.claim.sub',a::text,true);
insert into companies(id,name) values(c,'QA change register company');
insert into projects(id,company_id,title) values(p,c,'QA change register project');
insert into auth.users(id) values(m);insert into profiles(id,name,role) values(m,'QA manager','team');
insert into crm_teams(id,name) values(g,'QA change register team');
insert into crm_memberships(user_id,role_id,team_id) values(m,'project_manager',g);
insert into project_assignments(project_id,technician_id) values(p,m);
perform set_config('request.jwt.claim.sub',m::text,true);execute 'set local role authenticated';
perform save_project_change(l,null,p,d,'QA request reason');
perform save_project_change(l,null,p,d,'QA request reason');
if (select count(*) from crm_project_changes_history where change_id=l)<>1 then raise exception 'retry';end if;

begin update crm_project_changes set version=99 where id=l;raise exception 'allowed';exception when insufficient_privilege then null;end;
begin delete from crm_project_changes_history where change_id=l;raise exception 'allowed';exception when insufficient_privilege then null;end;
execute 'reset role';delete from project_assignments where project_id=p and technician_id=m;execute 'set local role authenticated';
if exists(select 1 from crm_project_changes where id=l) or exists(select 1 from crm_project_changes_history where change_id=l) then raise exception 'revoked read';end if;
begin perform save_project_change(gen_random_uuid(),null,p,d,'QA revoked create');raise exception 'allowed';exception when others then if sqlerrm<>'Assigned project manager access required' then raise;end if;end;
execute 'reset role';
if has_function_privilege('anon','public.save_project_change(uuid,integer,uuid,jsonb,text)','EXECUTE') then raise exception 'anon';end if;
end$$;
select true as passed,6 as assertions,true as fixtures_rollback;
rollback;
