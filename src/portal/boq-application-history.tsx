import React,{useState} from 'react';
import type {Row} from './client';
import {csvText,downloadText} from './business-utils';

type Entry={kind:string;receipt:Row};
export function applicationHistoryEntries(offer:Row,applications:Row[],extensions:Row[]):Entry[]{
 return [...applications.map(receipt=>({kind:'New product',receipt})),...extensions.map(receipt=>({kind:'Existing workstream extension',receipt}))]
  .filter(({receipt:r})=>r.offer_id===offer.id&&r.project_id===offer.project_id&&r.source_snapshot?.id===offer.id&&r.source_snapshot?.project_id===offer.project_id&&r.source_snapshot.status==='Accepted'&&r.source_snapshot.consent===true)
  .sort((a,b)=>String(a.receipt.created_at).localeCompare(String(b.receipt.created_at))||a.receipt.id.localeCompare(b.receipt.id));
}
const json=(value:unknown)=>value==null?'':JSON.stringify(value);
export function applicationHistoryRows(entries:Entry[]):unknown[][]{
 const rows:unknown[][]=[['Row type','Application type','Application ID','Offer ID','Offer number','Offer revision','Accepted version','Project ID','Frozen project','Frozen customer','Workstream ID','Product board ID','Template version ID','Template revision','Planning start','Parameters JSON','Planned crew hours','Planned crew days','Applied at','Applied by','Reason','Task key','Template task key','Actual task ID','Task title','Phase','Quantity','Unit','Planned minutes','Crew size','Crew role','Task start','Task deadline','Dependency keys JSON','Actual dependency IDs JSON','Checklist JSON','Tools','Preconditions','Actual phase milestone ID','Accepted source JSON','Reviewed plan JSON','Original workstream baseline JSON','Actual task IDs JSON','Actual milestone IDs JSON']];
 for(const {kind,receipt:r} of entries){
  const s=r.source_snapshot,p=r.plan_snapshot,base=[kind,r.id,r.offer_id,s.number,s.revision,s.version,r.project_id,s.project_title,s.company_name,r.workstream_id,r.board_id,r.request?.template_version||p.template_version,p.revision,p.start_date,json(p.parameters),p.man_hours,p.man_days,r.created_at,r.created_by,r.reason];
  rows.push(['Application',...base,...Array(18).fill(''),json(s),json(p),json(r.baseline_snapshot),json(r.task_ids),json(r.milestone_ids)]);
  for(const t of p.tasks||[])rows.push(['Task',...base,t.key,t.source_task_key||t.key,r.task_ids?.[t.key]||'',t.title,t.phase,t.quantity,t.unit,t.duration_minutes,t.crew,t.crew_role,t.start_date,t.deadline,json(t.depends_on||[]),json((t.depends_on||[]).map((key:string)=>r.task_ids?.[key]||'')),json(t.checklist||[]),t.tools,t.preconditions,r.milestone_ids?.[String(t.phase)]||'',...Array(5).fill('')]);
 }
 return rows;
}

function FrozenTasks({plan,taskIds={},milestoneIds={}}:{plan:Row;taskIds?:Record<string,string>;milestoneIds?:Record<string,string>}){
 return <div className="p-table-scroll"><table className="p-table"><thead><tr><th>Task / identity</th><th>Phase / milestone</th><th>Quantity</th><th>Planned time / crew</th><th>Recorded dates</th><th>Dependencies</th><th>QA / requirements</th></tr></thead><tbody>{(plan.tasks||[]).map((t:Row,i:number)=><tr key={t.key||i}><td>{t.title}<br/>Template key: {t.source_task_key||t.key}<br/>Recorded key: {t.key}{taskIds[t.key]&&<><br/>Task ID: {taskIds[t.key]}</>}</td><td>{t.phase}{milestoneIds[String(t.phase)]&&<><br/>{milestoneIds[String(t.phase)]}</>}</td><td>{t.quantity} {t.unit}</td><td>{t.duration_minutes} minutes · {t.crew} {t.crew_role}</td><td>{t.start_date||'Start not recorded'} – {t.deadline||'Deadline not recorded'}</td><td>{(t.depends_on||[]).map((key:string)=><p key={key}>{key}{taskIds[key]&&<> · {taskIds[key]}</>}</p>)}</td><td>{(t.checklist||[]).join('; ')}<p>{t.tools}</p><p>{t.preconditions}</p></td></tr>)}</tbody></table></div>;
}

export function BoqApplicationHistory({offer,applications,extensions,authorized,busy}:{offer:Row;applications:Row[];extensions:Row[];authorized:boolean;busy:boolean}){
 const [error,setError]=useState('');
 if(!authorized)return null;
 const entries=applicationHistoryEntries(offer,applications,extensions);
 if(!entries.length)return null;
 return <section className="p-no-print"><h4>Frozen workstream application history</h4><p>Recorded planning evidence at application. Current execution and later task revisions are available in Tasks; whole-request fulfilment is recorded separately.</p>
  <button disabled={busy} onClick={()=>{setError('');try{downloadText(`boq-${offer.id}-application-history.csv`,csvText(applicationHistoryRows(entries)));}catch(e:any){setError(e.message||'Application history export failed');}}}>Export workstream application history CSV</button>
  {error&&<p role="alert">{error}</p>}
  {entries.map(({kind,receipt:r})=>{const s=r.source_snapshot,p=r.plan_snapshot;return <details key={`${kind}:${r.id}`}><summary>{kind} · {s.number} revision {s.revision} · {r.created_at}</summary>
   <p>Application {r.id} · Workstream {r.workstream_id} · Applied by {r.created_by}</p><p className="p-pre">Reason: {r.reason}</p>
   <details><summary>Frozen accepted client source</summary><p>{s.project_title} · {s.company_name} · {s.title}</p><p>{s.status} version {s.version} · consent {s.consent?'recorded':'not recorded'} · client {s.decided_by} · {s.decided_at}</p><p>Original quotation {s.baseline_number} revision {s.baseline_revision}</p><p>{s.currency} subtotal {s.subtotal} · tax {s.tax_total} · total {s.total} · WHT {s.wht_total} · net payment {s.receivable}</p><p className="p-pre">{s.terms}</p><pre className="p-pre">{JSON.stringify(s.items,null,2)}</pre></details>
   <h5>Frozen reviewed template and parameters</h5><p>Template {r.request?.template_version||p.template_version} revision {p.revision} · planning start {p.start_date} · {p.man_hours} planned crew hours · {p.man_days} planned crew days</p><pre className="p-pre">{JSON.stringify(p.parameters,null,2)}</pre><FrozenTasks plan={p} taskIds={r.task_ids} milestoneIds={r.milestone_ids}/>
   {r.baseline_snapshot&&<details><summary>Original workstream baseline recorded at extension</summary><p>Workstream {r.baseline_snapshot.id} · template {r.baseline_snapshot.template_version_id}</p><pre className="p-pre">{JSON.stringify(r.baseline_snapshot.parameters,null,2)}</pre><FrozenTasks plan={r.baseline_snapshot.plan||{}}/><details><summary>Complete recorded baseline</summary><pre className="p-pre">{JSON.stringify(r.baseline_snapshot,null,2)}</pre></details></details>}
  </details>;})}
 </section>;
}
