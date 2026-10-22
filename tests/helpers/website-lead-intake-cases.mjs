export async function websiteLeadIntakeCases({pg,fs,q,one,user,eq,deny,ids}){
 await pg.exec('reset role');
 await pg.exec(await fs.readFile(new URL('../../supabase/migrations/20261022005821_phase_one_website_intake.sql',import.meta.url),'utf8'));
 const call='select capture_website_crm_lead($1,$2,$3,$4,$5,$6,$7,$8)',request=crypto.randomUUID();
 const args=[request,'contact',' Web Customer ','WEB.INTAKE@example.test','+923009991122','QA Company','Website enquiry',JSON.stringify({utm_campaign:'Launch'})];
 await user(ids.admin);await deny(call,args,'Even an authenticated administrator cannot invoke the server-only website intake');
 await pg.exec('reset role;set role anon');await deny(call,args,'Anonymous callers cannot invoke website intake directly');
 await pg.exec('reset role;set role service_role');await q(call,args);
 await deny('select * from portal_private.website_lead_receipts',[],'Service role cannot read private intake receipts directly');
 await pg.exec('reset role');
 const lead=await one("select * from crm_leads where email='web.intake@example.test'");
 eq([lead.name,lead.status,lead.owner_id,lead.source,lead.form_name,lead.campaign],['Web Customer','New',null,'Website','contact','Launch'],'Website intake creates an unassigned New lead with normalized contact and attribution');
 const count=async()=>Number((await one('select count(*) n from crm_sales_activity where lead_id=$1',[lead.id])).n);
 eq(await count(),1,'Initial website enquiry records one activity');
 await pg.exec('set role service_role');await q(call,args);await pg.exec('reset role');eq(await count(),1,'Same request retry does not duplicate enquiry activity');
 await pg.exec('set role service_role');await deny(call,[request,'proposal',...args.slice(2)],'Changed payload cannot reuse an existing request identity');
 await pg.exec('reset role');await q("update crm_leads set owner_id=$1,status='Contacted' where id=$2",[ids.admin,lead.id]);
 await pg.exec('set role service_role');const next=[crypto.randomUUID(),...args.slice(1)];next[6]='Second genuine enquiry';next[7]=JSON.stringify({utm_campaign:'Second'});await q(call,next);
 await pg.exec('reset role');eq(await count(),2,'New request for duplicate contact records a genuine repeat enquiry');
 const after=await one('select * from crm_leads where id=$1',[lead.id]);eq([after.owner_id,after.status,after.campaign],[ids.admin,'Contacted','Launch'],'Repeat contact preserves existing owner, status and original acquisition');
 eq((await one("select body from crm_sales_activity where lead_id=$1 order by created_at desc limit 1",[lead.id])).body.includes('Second'),true,'Repeat enquiry retains its own attribution');
 await pg.exec('set role service_role');await deny(call,[crypto.randomUUID(),...args.slice(1,7),'{"owner":"injected"}'],'Unknown acquisition keys rejected by database');
 await deny(call,[crypto.randomUUID(),...args.slice(1,7),JSON.stringify({utm_campaign:'x'.repeat(301)})],'Overlong UTM values rejected by database');
 await deny(call,[crypto.randomUUID(),'contact','X',...args.slice(3)],'Invalid name rejected by database');
 await pg.exec('reset role');await q("insert into crm_leads(name,email,phone,source) values('Conflict','web.other@example.test','+923009991133','Manual')");
 await pg.exec('set role service_role');await deny(call,[crypto.randomUUID(),'contact',args[2],args[3],'+923009991133',args[5],args[6],args[7]],'Conflicting email and phone contacts never merge');
 await pg.exec('reset role');eq(await count(),2,'Rejected submissions leave no enquiry activity');
 await user(ids.clientA);eq((await q('select * from crm_leads where id=$1',[lead.id])).length,0,'Client cannot read website leads');
 await pg.exec('reset role');

 const limited='select capture_website_crm_lead_v2($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)',fingerprint='a'.repeat(64),first=crypto.randomUUID();
 const limitedArgs=[first,'contact','Rate customer','rate.intake@example.test','+923009991144','','Actual local QA enquiry','{}',fingerprint,2];
 await pg.exec('set role service_role');await q(limited,limitedArgs);await q(limited,limitedArgs);await pg.exec('reset role');
 eq((await one('select attempts from portal_private.website_intake_limits where fingerprint=$1',[fingerprint])).attempts,1,'Identical confirmed retry does not consume another new-enquiry budget');
 eq((await one("select count(*)::int n from portal_reminders where event_key=$1",['website-enquiry:'+first])).n,1,'A new enquiry notifies actual eligible triage accounts once, including unchanged retries');
 eq((await one("select user_id from portal_reminders where event_key=$1",['website-enquiry:'+first])).user_id,ids.admin,'Triage notification uses an actual authorized account, never an invented assignee');
 await pg.exec('set role service_role');await q(limited,[crypto.randomUUID(),...limitedArgs.slice(1)]);
 let error;try{await q(limited,[crypto.randomUUID(),...limitedArgs.slice(1)]);}catch(e){error=e;}
 eq(error?.code,'P0429','Durable per-origin limit returns only the intended rate-limit business rejection');
 await pg.exec('reset role');eq((await one("select count(*)::int n from crm_sales_activity where lead_id=(select id from crm_leads where email='rate.intake@example.test')")).n,2,'Rejected rate-limited request creates no lead activity');
 eq((await one('select attempts from portal_private.website_intake_limits where fingerprint=$1',[fingerprint])).attempts,2,'Rejected transaction does not corrupt the accepted request budget');
 await q("update portal_private.website_intake_limits set window_started=now()-interval '11 minutes' where fingerprint=$1",[fingerprint]);await pg.exec('set role service_role');await q(limited,[crypto.randomUUID(),...limitedArgs.slice(1)]);await pg.exec('reset role');
 eq((await one('select attempts from portal_private.website_intake_limits where fingerprint=$1',[fingerprint])).attempts,1,'New ten-minute window resumes intake without changing actual enquiries');
 await pg.exec('set role service_role');await deny(limited,[crypto.randomUUID(),...limitedArgs.slice(1,8),'invalid',2],'Client-supplied or malformed limiter identity is rejected');await deny('select * from portal_private.website_intake_limits',[],'Service role cannot list private origin fingerprints');await pg.exec('reset role');
 for(const role of ['anon','authenticated'])eq((await one("select has_function_privilege($1,'public.capture_website_crm_lead_v2(uuid,text,text,text,text,text,text,jsonb,text,integer)','execute') ok",[role])).ok,false,'Direct website RPC execution denied '+role);
 eq((await one("select relrowsecurity ok from pg_class where oid='portal_private.website_intake_limits'::regclass")).ok,true,'Private limiter has RLS enabled');
}
