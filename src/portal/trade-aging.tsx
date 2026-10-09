import React,{useEffect,useState} from 'react';
import {db,check,type Row} from './client';
import {csvText,downloadText} from './business-utils';
import {downloadReportPDF} from './report-export';
import {tradeCounterpartySummary} from './trade-counterparty-summary';

const money=(value:unknown)=>Number(value||0).toLocaleString('en-PK',{minimumFractionDigits:2,maximumFractionDigits:2});
const table=(headers:string[],rows:unknown[][])=><div className="p-table-scroll"><table className="p-table"><thead><tr>{headers.map(h=><th key={h}>{h}</th>)}</tr></thead><tbody>{rows.map((r,i)=><tr key={i}>{r.map((v,j)=><td key={j}>{String(v??'')}</td>)}</tr>)}</tbody></table></div>;

export function TradeAging({profile}:{profile:Row}){
 const allowed=profile.role==='admin'||profile.role==='team'&&profile.crm_permissions?.includes('finance.manage');
 const [report,setReport]=useState<Row|null>(null),[currency,setCurrency]=useState('PKR'),[direction,setDirection]=useState('Both'),[status,setStatus]=useState('Outstanding'),[error,setError]=useState(''),[refresh,setRefresh]=useState(0),[busy,setBusy]=useState(false);
 useEffect(()=>{let live=true;setReport(null);setError('');if(allowed)Promise.resolve(db!.rpc('finance_trade_report')).then(check).then(r=>{if(live)setReport(r);}).catch(e=>{if(live)setError(e.message);});return()=>{live=false;};},[profile.id,allowed,refresh]);
 if(!allowed)return <p>Accounts access is required.</p>;
 const summary=report?.summary?.find((r:Row)=>r.currency===currency);
 const aging=(report?.aging||[]).filter((r:Row)=>r.currency===currency),upcoming=(report?.upcoming||[]).filter((r:Row)=>r.currency===currency);
 const documents=(report?.documents||[]).filter((r:Row)=>r.currency===currency&&(direction==='Both'||r.direction===direction)&&(status==='All records'||(status==='Outstanding'?Number(r.balance)>0:r.due_status===status)));
 const summaryRows=summary?[['Outstanding receivable',money(summary.receivable)],['Outstanding payable',money(summary.payable)],['Overdue receivable',money(summary.overdue_receivable)],['Overdue payable',money(summary.overdue_payable)],['Net trade position',money(summary.net_position)],['Open customer invoices',String(summary.open_receivables)],['Open bills / expenses',String(summary.open_payables)]]:[];
 const detailHeaders=['Document / type','Counterparty','Due','Amount','Paid','Credits','Balance','Due status'];
 const detailRows=documents.map((r:Row)=>[r.number+' · '+r.direction+' · '+r.kind,r.counterparty,r.due_on,money(r.amount),money(r.paid),money(r.credits),money(r.balance),r.due_status+' · '+r.days_overdue+' days overdue']);
 const identities=report?.counterparty_identity_version===1;
 const counterpartyTitle=identities?'Account / name totals':'Recorded-name totals';
 const counterpartyBasis=identities?'Customer and linked vendor totals use existing account identities and current account names. Vendor bills and linked expenses combine for that vendor; unlinked expenses remain exact recorded-name groups. Document names stay unchanged. No receivable/payable netting. These totals follow the document filters.':'Groups use exact recorded names, direction and document type. Names are not verified account identities; renamed records remain separate. No receivable/payable netting. These totals follow the document filters.';
 const counterpartyHeaders=[identities?'Account / name / type':'Recorded name / type','Open / total documents','Outstanding '+currency,'Overdue '+currency,'Due today '+currency,'Not due '+currency];
 const counterpartyRows=tradeCounterpartySummary(documents,currency,identities).map(r=>[r.counterparty+' · '+r.direction+' · '+r.kind+(identities?' · '+r.reference:''),r.open_documents+' / '+r.documents,money(r.balance),money(r.overdue),money(r.due_today),money(r.not_due)]);
 const sections=[{title:'Currency totals (all eligible records)',headers:['Metric',currency],rows:summaryRows},
  {title:'Aging by days overdue',headers:['Bucket','Receivable '+currency,'Payable '+currency],rows:aging.map((r:Row)=>[r.bucket,money(r.receivable),money(r.payable)])},
  {title:'Upcoming due schedule (overlapping windows)',headers:['Period','Receivable '+currency,'Payable '+currency],rows:upcoming.map((r:Row)=>[r.period,money(r.receivable),money(r.payable)])},
  {title:'Documents · '+direction+' · '+status,headers:detailHeaders,rows:detailRows},
  {title:counterpartyTitle+' · '+direction+' · '+status,headers:counterpartyHeaders,rows:counterpartyRows},
  {title:'Report basis',headers:['Note'],rows:[[report?.note||''],[counterpartyBasis]]}];
 return <section className="p-panel"><h2>Receivables & payables</h2>{error&&<p role="alert" className="p-error">{error}</p>}{!report&&!error&&<p role="status">Loading trade balances…</p>}<button disabled={busy||!report&&!error} onClick={()=>setRefresh(refresh+1)}>Refresh trade balances</button>{report&&<><p>As of {report.business_date} · Asia/Karachi · {report.note}</p><div className="p-form"><label className="p-field">Trade currency<select value={currency} onChange={e=>setCurrency(e.target.value)}>{report.summary.map((r:Row)=><option key={r.currency}>{r.currency}</option>)}</select></label><label className="p-field">Document direction<select value={direction} onChange={e=>setDirection(e.target.value)}>{['Both','Receivable','Payable'].map(s=><option key={s}>{s}</option>)}</select></label><label className="p-field">Document due status<select value={status} onChange={e=>setStatus(e.target.value)}>{['Outstanding','Overdue','Due today','Not due','Settled','All records'].map(s=><option key={s}>{s}</option>)}</select></label></div>
 <div className="p-toolbar"><button disabled={busy} onClick={()=>downloadText('trade-balances-'+currency+'.csv',csvText([['Business date',report.business_date],['Currency',currency],['Direction filter',direction],['Due status filter',status],['Report basis',report.note],...sections.flatMap(s=>[[s.title],s.headers,...s.rows])]))}>Export trade CSV</button><button disabled={busy} onClick={async()=>{setBusy(true);setError('');try{await downloadReportPDF('trade-balances-'+currency+'.pdf','Receivables & payables',report.business_date+' · Asia/Karachi · '+currency+' · '+direction+' · '+status,sections);}catch(e:any){setError(e.message);}finally{setBusy(false);}}}>Export trade PDF</button></div>
 <h3>Currency totals</h3><p>Document filters apply to the detail list and counterparty totals. Currency totals include all eligible records.</p>{table(['Metric',currency],summaryRows)}<h3>Aging</h3>{table(['Days overdue','Receivable '+currency,'Payable '+currency],sections[1].rows)}<h3>Upcoming due amounts</h3><p>These windows include today and overlap.</p>{table(sections[2].headers,sections[2].rows)}<h3>{counterpartyTitle} · {counterpartyRows.length} groups</h3><p>{counterpartyBasis}</p>{table(counterpartyHeaders,counterpartyRows)}<h3>Document detail · {documents.length} records</h3>{table(detailHeaders,detailRows)}{!documents.length&&<p>No documents match these filters.</p>}</>}</section>;
}
