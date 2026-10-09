export async function tradeIdentityCases({pg,fs,q,one,user,eq,deny,ids}){
 await user(ids.admin);const before=(await one('select finance_trade_report() r')).r;
 await pg.exec('reset role');await pg.exec(await fs.readFile(new URL('../../supabase/041_trade_counterparty_identities.sql',import.meta.url),'utf8'));
 await user(ids.admin);let report=(await one('select finance_trade_report() r')).r;
 eq(report.counterparty_identity_version,1,'Trade report explicitly versions returned account identities');
 for(const field of ['summary','aging','upcoming'])eq(report[field],before[field],'Identity migration preserves existing '+field+' amounts');
 const old=before.documents.map(r=>JSON.stringify(r)).sort(),now=report.documents.map(({counterparty_id,counterparty_type,account_name,...r})=>JSON.stringify(r)).sort();eq(now,old,'Identity migration does not rewrite document names or financial evidence');
 const customer1=crypto.randomUUID(),customer2=crypto.randomUUID(),vendor=crypto.randomUUID(),accounts=crypto.randomUUID(),team=crypto.randomUUID();
 await pg.exec('reset role');await q("insert into auth.users values($1)",[accounts]);await q("insert into profiles(id,name,role) values($1,'Identity QA Accounts','team')",[accounts]);await q("insert into crm_teams(id,name) values($1,'Identity QA team')",[team]);await q("insert into crm_memberships(user_id,role_id,team_id) values($1,'accounts',$2)",[accounts,team]);
 await q("insert into companies(id,name) values($1,'Shared QA name'),($2,'Shared QA name')",[customer1,customer2]);
 await q("insert into sc_vendors(id,name,status,created_by) values($1,'Identity QA vendor','Approved',$2)",[vendor,ids.admin]);
 const day=report.business_date;
 const invoice=async(company,name,number)=>(await one("insert into invoices(company_id,company_name,number,currency,status,issued_on,due_on,total,author_id) values($1,$2,$3,'PKR','Issued',$4::date-1,$4,10,$5) returning id",[company,name,number,day,ids.admin])).id;
 const a=await invoice(customer1,'Old QA invoice name','QA-ID-A'),b=await invoice(customer1,'New QA invoice name','QA-ID-B'),c=await invoice(customer2,'Old QA invoice name','QA-ID-C');
 const expense=async(link,payee,voucher)=>(await one("insert into fin_expenses(payee,vendor_id,voucher,category,description,incurred_on,due_on,amount,evidence,status,created_by,approved_by) values($1,$2,$3,'Other','Identity QA fixture',$4,$4,5,'QA receipt','Approved',$5,$6) returning id",[payee,link,voucher,day,accounts,ids.admin])).id;
 const linked=await expense(vendor,'Old vendor payee label','QA-ID-LINKED'),unlinked=await expense(null,'Identity QA vendor','QA-ID-NAME');
 await user(accounts);report=(await one('select finance_trade_report() r')).r;const doc=id=>report.documents.find(r=>r.id===id);
 eq(doc(a).counterparty_id,customer1,'Customer identity comes from the existing invoice company');eq(doc(b).counterparty_id,customer1,'Renamed invoice snapshots retain one customer account identity');eq(doc(c).counterparty_id,customer2,'Same invoice name cannot merge separate customer identities');eq(doc(a).account_name,'Shared QA name','Account display uses current customer name');eq(doc(a).counterparty,'Old QA invoice name','Original invoice name snapshot remains unchanged');
 eq([doc(linked).counterparty_type,doc(linked).counterparty_id,doc(linked).account_name],['Vendor',vendor,'Identity QA vendor'],'Only explicitly linked expenses receive existing vendor identity');
 eq([doc(unlinked).counterparty_type,doc(unlinked).counterparty_id,doc(unlinked).account_name],['Recorded name',null,'Identity QA vendor'],'Unlinked payee matching vendor name receives no inferred account');
 eq(report.documents.filter(r=>r.kind==='Vendor bill').every(r=>r.counterparty_type==='Vendor'&&r.counterparty_id),true,'Vendor bills return existing vendor identities');
 eq(report.documents.every(r=>!('evidence' in r)&&!('reference' in r)&&!('loan_id' in r)&&!('contact' in r)),true,'Identity report still omits private evidence, loans and contact data');
 await pg.exec('reset role');await q("update companies set name='Renamed QA account' where id=$1",[customer1]);await q("update sc_vendors set name='Renamed QA vendor' where id=$1",[vendor]);await user(accounts);report=(await one('select finance_trade_report() r')).r;
 eq([doc(a).counterparty_id,doc(a).account_name,doc(a).counterparty],[customer1,'Renamed QA account','Old QA invoice name'],'Customer renaming changes display without changing identity or invoice history');
 eq([doc(linked).counterparty_id,doc(linked).account_name,doc(linked).counterparty],[vendor,'Renamed QA vendor','Old vendor payee label'],'Vendor renaming preserves explicit identity and expense payee history');
 await user(ids.clientA);await deny('select finance_trade_report()',[],'Identity report remains denied to clients');await user(ids.team);await deny('select finance_trade_report()',[],'Identity report remains denied to technicians');
 await pg.exec('reset role');await q('update profiles set active=false where id=$1',[accounts]);await user(accounts);await deny('select finance_trade_report()',[],'Disabled Accounts cannot retrieve counterparty identities');await pg.exec('reset role');await q('update profiles set active=true where id=$1',[accounts]);await q('delete from crm_memberships where user_id=$1',[accounts]);await user(accounts);await deny('select finance_trade_report()',[],'Revoked Accounts cannot retrieve counterparty identities');
 await pg.exec("reset role;select set_config('request.jwt.claim.sub','',false);set role anon");await deny('select finance_trade_report()',[],'Anonymous identity report execution remains denied');await user(ids.admin);
}
