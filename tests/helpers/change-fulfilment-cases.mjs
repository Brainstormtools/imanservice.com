export async function changeFulfilmentCases({pg,fs,q,one,user,eq,deny,ids}) {
 await pg.exec('reset role');await pg.exec(await fs.readFile(new URL('../../supabase/059_change_fulfilment.sql',import.meta.url),'utf8'));
 const project=(await one("insert into projects(company_id,title) values($1,'QA fulfilment project') returning id",[ids.a])).id;
 const manager=crypto.randomUUID(),other=crypto.randomUUID(),change=crypto.randomUUID(),first=crypto.randomUUID();
 for(const u of [manager,other]) {await q('insert into auth.users(id) values($1)',[u]);await q("insert into profiles(id,name,role) values($1,'QA assessment staff','team')",[u]);}
 const team=(await one("insert into crm_teams(name) values('QA fulfilment team') returning id")).id;
 await q("insert into crm_memberships(user_id,role_id,team_id) values($1,'project_manager',$2)",[manager,team]);await q('insert into project_assignments(project_id,technician_id) values($1,$2)',[project,manager]);
 const draft={title:'QA scope assessment',proposed_scope:'QA entire approved scope',justification:'QA explicit need',cost_impact:'QA internal assessment only',schedule_impact:'QA internal timing only',evidence:'QA decision evidence',status:'Draft',decision_note:''};
 await user(manager);await q('select save_project_change($1,null,$2,$3,$4)',[change,project,JSON.stringify(draft),'QA draft']);
 await q('select save_project_change($1,1,$2,$3,$4)',[change,project,JSON.stringify({...draft,status:'Submitted'}),'QA submit']);
 const sql='select record_change_fulfilment($1,$2,$3,$4,$5,$6,$7,$8,$9)',args=(id=first,version=3,previous=null,status='Partially fulfilled')=>[id,change,version,previous,status,'QA scope coverage','QA remaining work','QA evidence reference','QA assessment reason'];
 await deny(sql,args(),'Manager cannot record assessment');await user(ids.admin);
 await deny(sql,args(),'Submitted decision cannot be assessed');
 await q('select save_project_change($1,2,$2,$3,$4)',[change,project,JSON.stringify({...draft,status:'Approved',decision_note:'QA internal decision'}),'QA approve']);
 for(const [index,value] of [[0,null],[2,null],[2,2],[4,null],[4,'Unknown'],[5,' '],[6,''],[7,'x'],[8,''],[5,'x'.repeat(4001)],[6,'x'.repeat(4001)],[7,'x'.repeat(4001)],[8,'x'.repeat(2001)]]) {const a=args();a[index]=value;await deny(sql,a,'Malformed or stale assessment denied '+index);}
 await deny(sql,[first,crypto.randomUUID(),3,null,'Fulfilled','QA scope','QA none','QA ref','QA reason'],'Unknown request denied');
 await deny(sql,args(first,3,crypto.randomUUID()),'Fabricated prior denied');await q(sql,args());await q(sql,args());
 const record=await one('select * from crm_change_fulfilment where id=$1',[first]);
 eq(record.actor_id,ids.admin,'Assessment attributes authenticated administrator');eq(record.revision,1,'First assessment starts revision one');eq(record.decision_snapshot.details.proposed_scope,draft.proposed_scope,'Server freezes actual approved scope');eq(record.decision_snapshot.details.status,'Approved','Server freezes decision status');eq(record.application_snapshot.length,0,'No linked tasks does not infer planning fulfilment');eq((await q('select * from crm_change_fulfilment where change_id=$1',[change])).length,1,'Exact retry creates no duplicate assessment');
 const changed=args();changed[7]='Different evidence';await deny(sql,changed,'Changed retry denied');
 await deny(sql,args(crypto.randomUUID(),3,null),'Stale previous assessment denied');
 const second=crypto.randomUUID();await q(sql,args(second,3,first,'Fulfilled'));
 const latest=await one('select * from crm_change_fulfilment where id=$1',[second]);eq(latest.revision,2,'Correction appends next revision');eq(latest.previous_id,first,'Correction retains preceding assessment');eq((await one('select status from crm_change_fulfilment where id=$1',[first])).status,'Partially fulfilled','Prior assessment remains unchanged');
 await q(sql,args());eq((await q('select * from crm_change_fulfilment where change_id=$1',[change])).length,2,'Delayed exact retry returns original without changing current assessment');
 await deny('update crm_change_fulfilment set status=$1 where id=$2',['Not fulfilled',second],'Direct assessment update denied');await deny('delete from crm_change_fulfilment where id=$1',[first],'Direct history deletion denied');await deny('insert into crm_change_fulfilment select * from crm_change_fulfilment where id=$1',[first],'Direct insert denied');
 await user(manager);eq((await q('select * from crm_change_fulfilment where change_id=$1',[change])).length,2,'Assigned manager reads assessment history');await deny(sql,args(crypto.randomUUID(),3,second),'Manager cannot append correction');
 for(const u of [ids.clientA,other]) {await user(u);eq((await q('select * from crm_change_fulfilment where change_id=$1',[change])).length,0,'Client or unassigned staff cannot read assessments');await deny(sql,args(),'Client or unassigned staff cannot write assessments');}
 await pg.exec('reset role');await q('delete from project_assignments where project_id=$1 and technician_id=$2',[project,manager]);await user(manager);eq((await q('select * from crm_change_fulfilment where change_id=$1',[change])).length,0,'Revoked manager loses history');
 await pg.exec('reset role');await q('update profiles set active=false where id=$1',[ids.admin]);await user(ids.admin);await deny(sql,args(),'Disabled administrator cannot retry or assess');eq((await q('select * from crm_change_fulfilment where change_id=$1',[change])).length,0,'Disabled administrator loses history');await pg.exec('reset role');await q('update profiles set active=true where id=$1',[ids.admin]);

 const linked=await one('select h.change_id,h.change_version,h.task_id,h.revision,h.id,h.proposal_id,p.version current_version from crm_task_plan_history h join crm_task_plans p on p.task_id=h.task_id where h.change_id is not null order by h.created_at desc limit 1');
 const snapshotID=crypto.randomUUID();await user(ids.admin);await q(sql,[snapshotID,linked.change_id,linked.change_version,null,'Not fulfilled','QA scope not yet verified','QA verification remains pending','QA planning evidence only','QA explicit assessment']);
 const frozen=(await one('select application_snapshot from crm_change_fulfilment where id=$1',[snapshotID])).application_snapshot;
 const matching=frozen.find(h=>h.history_id===linked.id);eq(matching.task_id,linked.task_id,'Server captures actual linked task identity');eq(matching.revision,linked.revision,'Server captures linked planning revision');eq(matching.current_plan_version,linked.current_version,'Server captures current plan version at assessment');eq(matching.proposal_id,linked.proposal_id,'Server captures proposal linkage without inferred fulfilment');
 await pg.exec('reset role');await q('update crm_task_plans set version=version+1 where task_id=$1',[linked.task_id]);await user(ids.admin);eq((await one('select application_snapshot from crm_change_fulfilment where id=$1',[snapshotID])).application_snapshot,frozen,'Later plan changes leave assessment snapshot immutable');
 eq((await one("select has_function_privilege('anon','public.record_change_fulfilment(uuid,uuid,integer,uuid,text,text,text,text,text)','execute') allowed")).allowed,false,'Anonymous assessment execution denied');
 eq((await one('select version from crm_project_changes where id=$1',[change])).version,3,'Assessments do not mutate frozen change decision');eq((await one('select count(*)::int n from tasks where project_id=$1',[project])).n,0,'Assessment creates no executable work');
}
