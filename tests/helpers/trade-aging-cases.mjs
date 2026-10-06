export async function tradeAgingCases({pg,fs,q,one,user,eq,deny,ids,actors,accounts,po}){
 await pg.exec('reset role');await pg.exec(await fs.readFile(new URL('../../supabase/026_trade_aging.sql',import.meta.url),'utf8'));
 await user(accounts);const initial=(await one('select finance_trade_report() r')).r;
 eq(initial.business_date,(await one("select (now() at time zone 'Asia/Karachi')::date::text d")).d,'Trade aging uses the Pakistan business date');
 const day=initial.business_date;
 await pg.exec('reset role');
 const invoices=[];
 for(const offset of [-91,-90,-61,-60,-31,-30,-1,0,1,7,8,30,31]){
  const id=(await one("insert into invoices(company_id,company_name,number,currency,status,issued_on,due_on,subtotal,total,author_id) values($1,'Aging customer',$2,'PKR','Issued',$3::date-200,$3::date+$4::integer,100,100,$5) returning id",[ids.a,'QA-AGING-'+offset,day,offset,ids.admin])).id;
  invoices.push({id,offset});
 }
 const foreign=(await one("insert into invoices(company_id,company_name,number,currency,status,issued_on,due_on,total,author_id) values($1,'Foreign aging','QA-AGING-USD','USD','Issued',$2::date-2,$2::date-1,123,$3) returning id",[ids.a,day,ids.admin])).id;
 const draft=(await one("insert into invoices(company_id,company_name,number,status,issued_on,due_on,total,author_id) values($1,'Draft customer','QA-AGING-DRAFT','Draft',$2::date-2,$2::date-1,999,$3) returning id",[ids.a,day,ids.admin])).id;
 const inv=invoices[0].id;
 const verified=(await one("insert into payment_claims(invoice_id,amount,reference,paid_on,status,submitted_by,reviewed_by) values($1,20,'QA-AGING-VERIFIED',$2,'Verified',$3,$3) returning id",[inv,day,ids.admin])).id;
 await q("insert into payment_claims(invoice_id,amount,reference,paid_on,status,submitted_by) values($1,25,'QA-AGING-PENDING',$2,'Pending',$3),($1,15,'QA-AGING-REVERSED',$2,'Reversed',$3)",[inv,day,ids.admin]);
 const credit=crypto.randomUUID();await q("insert into credit_notes(id,invoice_id,amount,reason,status,author_id) values($1,$2,10,'Aging credit test','Issued',$3)",[credit,inv,ids.admin]);
 await q("insert into credit_notes(id,invoice_id,amount,reason,status,author_id) values(gen_random_uuid(),$1,5,'Reversed credit test','Reversed',$2)",[inv,ids.admin]);
 const expense=(await one("insert into fin_expenses(payee,voucher,category,description,incurred_on,due_on,amount,evidence,status,created_by,approved_by) values('Aging payee','QA-AGING-EXPENSE','TADA','Aging expense fixture',$1::date-31,$1::date-31,100,'QA private receipt','Approved',$2,$3) returning id",[day,accounts,ids.admin])).id;
 await q("insert into fin_cash_entries(expense_id,kind,direction,amount,paid_on,method,reference,evidence,created_by) values($1,'Expense payment','Out',40,$2,'Cash','QA-AGING-EXP-PAY','QA private payment',$3)",[expense,day,accounts]);
 const expenseReversed=(await one("insert into fin_cash_entries(expense_id,kind,direction,amount,paid_on,method,reference,evidence,created_by,reversed_by,reversed_at,reversal_reason) values($1,'Expense payment','Out',10,$2,'Cash','QA-AGING-EXP-REV','QA private payment',$3,$4,now(),'Reversal test') returning id",[expense,day,accounts,ids.admin])).id;
 const order=await one('select vendor_id from sc_orders where id=$1',[po]);
 const bill=(await one("insert into sc_bills(order_id,vendor_id,vendor_invoice,invoice_date,due_date,quantity,rate,total,evidence,status,created_by,approved_by) values($1,$2,'QA-AGING-BILL',$3::date-1,$3,100,1,100,'QA private supplier evidence','Approved',$4,$5) returning id",[po,order.vendor_id,day,accounts,ids.admin])).id;
 await q("insert into sc_vendor_payments(bill_id,amount,payment_date,method,reference,evidence,created_by) values($1,30,$2,'Cash','QA-AGING-VENDOR-PAY','QA private bank evidence',$3)",[bill,day,accounts]);
 const held=(await one("insert into sc_bills(order_id,vendor_id,vendor_invoice,invoice_date,due_date,quantity,rate,total,evidence,status,created_by) values($1,$2,'QA-AGING-HELD',$3::date-1,$3,99,1,99,'QA held supplier evidence','Held',$4) returning id",[po,order.vendor_id,day,accounts])).id;
 await user(accounts);let report=(await one('select finance_trade_report() r')).r;
 const doc=id=>report.documents.find(r=>r.id===id),pk=report.summary.find(r=>r.currency==='PKR'),before=initial.summary.find(r=>r.currency==='PKR');
 eq(Number(doc(inv).balance),70,'Verified receipts and issued credits reduce trade balance once');
 eq(Number(doc(expense).balance),60,'Unreversed expense cash reduces payable without reversed cash');
 eq(Number(doc(bill).balance),70,'Approved vendor bill uses unreversed vendor payments');
 eq(doc(draft),undefined,'Draft invoice does not enter trade aging');eq(doc(held),undefined,'Held vendor bill does not enter payable aging');
 for(const [offset,bucket] of [[-91,'91+ days'],[-90,'61–90 days'],[-61,'61–90 days'],[-60,'31–60 days'],[-31,'31–60 days'],[-30,'1–30 days'],[-1,'1–30 days'],[0,'Current'],[1,'Current']])eq(doc(invoices.find(i=>i.offset===offset).id).aging_bucket,bucket,'Aging boundary '+offset+' days is exact');
 eq(doc(invoices.find(i=>i.offset===0).id).due_status,'Due today','Due today is current rather than overdue');
 eq(Number(pk.receivable)-Number(before.receivable),1270,'PKR trade total excludes foreign invoice and pending payments');
 eq(Number(pk.payable)-Number(before.payable),130,'Payables total includes approved expense and bill without duplicate cash');
 const usd=report.summary.find(r=>r.currency==='USD'),oldUSD=initial.summary.find(r=>r.currency==='USD');eq(Number(usd.receivable)-Number(oldUSD?.receivable||0),123,'Foreign receivable has a separate currency total');eq(Number(usd.payable),0,'PKR vendor bills never enter USD payable totals');
 for(const [period,amount] of [['Due today',100],['Today through 7 days',300],['Today through 30 days',500]]){
  const now=report.upcoming.find(r=>r.currency==='PKR'&&r.period===period),old=initial.upcoming.find(r=>r.currency==='PKR'&&r.period===period);
  eq(Number(now.receivable)-Number(old.receivable),amount,'Upcoming '+period+' excludes overdue and includes exact end date');
 }
 eq(report.aging.filter(r=>r.currency==='PKR').reduce((n,r)=>n+Number(r.receivable),0),Number(pk.receivable),'Aging receivables reconcile to currency outstanding');
 eq(report.aging.filter(r=>r.currency==='PKR').reduce((n,r)=>n+Number(r.payable),0),Number(pk.payable),'Aging payables reconcile to currency outstanding');
 eq(report.documents.every(r=>!('evidence' in r)&&!('reference' in r)&&!('loan_id' in r)),true,'Trade report excludes payment evidence and loan identifiers');
 await pg.exec('reset role');await q("update payment_claims set status='Reversed' where id=$1",[verified]);await q("update credit_notes set status='Reversed' where id=$1",[credit]);await user(accounts);report=(await one('select finance_trade_report() r')).r;eq(Number(doc(inv).balance),100,'Receipt and credit reversal restore outstanding on refresh');
 await user(ids.team);await deny('select finance_trade_report()',[],'Technician cannot query company trade aging');await user(actors.manager);await deny('select finance_trade_report()',[],'Project manager permission does not grant company trade aging');await user(ids.clientA);await deny('select finance_trade_report()',[],'Client cannot query vendor and expense aging');
 await pg.exec('reset role');await q('update profiles set active=false where id=$1',[accounts]);await user(accounts);await deny('select finance_trade_report()',[],'Disabled Accounts loses trade aging access');await pg.exec('reset role');await q('update profiles set active=true where id=$1',[accounts]);
 await pg.exec("select set_config('request.jwt.claim.sub','',false);set role anon");await deny('select finance_trade_report()',[],'Anonymous trade aging function execution denied');await user(ids.admin);
}
