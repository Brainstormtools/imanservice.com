import React, {useRef, useState} from 'react';
import {db, check, type Row} from './client';
import {csvText, downloadText} from './business-utils';

export function fulfilmentHistory(change: Row, rows: Row[]) {
 return rows.filter(r => r.change_id === change.id && r.project_id === change.project_id && r.change_version === change.version).sort((a,b) => b.revision-a.revision);
}

export function ChangeFulfilment({change, rows, admin, busy, setBusy, onSaved}: {
 change: Row; rows: Row[]; admin: boolean; busy: boolean; setBusy: (value: boolean) => void; onSaved: () => void;
}) {
 const history=fulfilmentHistory(change,rows), latest=history[0];
 const [editing,setEditing]=useState(false),[error,setError]=useState('');
 const attempt=useRef({hash:'',id:''});
 return <div><h3>Whole-request fulfilment assessment</h3>
  <p>{latest ? `Recorded assessment: ${latest.status} · revision ${latest.revision}` : 'Whole-request fulfilment: Not assessed.'} This is an administrator’s evidence-backed assessment of the approved scope. Linked planning revisions alone do not establish fulfilment. It does not approve commercial changes, certify executed work or replace client sign-off.</p>
  {admin&&change.details.status==='Approved'&&<button disabled={busy} onClick={()=>{setEditing(true);setError('');attempt.current={hash:'',id:''};}}>Record fulfilment assessment</button>}
  <button disabled={busy||!history.length||!!error} onClick={()=>downloadText('change-fulfilment-history.csv',csvText([
   ['Assessment ID','Change ID','Project ID','Decision revision','Assessment revision','Previous assessment ID','Recorded status','Scope coverage','Remaining work / limitations','Evidence reference','Reason','Actor ID','Recorded at','Frozen decision','Linked planning snapshot'],
   ...history.map(r=>[r.id,r.change_id,r.project_id,r.change_version,r.revision,r.previous_id||'',r.status,r.coverage,r.remaining_work,r.evidence,r.reason,r.actor_id,r.created_at,JSON.stringify(r.decision_snapshot),JSON.stringify(r.application_snapshot)])
  ]))}>Export fulfilment history CSV</button>
  {error&&<p role="alert">{error}</p>}
  {editing&&admin&&<form className="p-form" onSubmit={async e=>{
   e.preventDefault();if(busy)return;const f=new FormData(e.currentTarget);
   const args={p_change:change.id,p_change_version:change.version,p_previous:latest?.id||null,p_status:String(f.get('status')),p_coverage:String(f.get('coverage')),p_remaining_work:String(f.get('remaining_work')),p_evidence:String(f.get('evidence')),p_reason:String(f.get('reason'))};
   const hash=JSON.stringify(args);if(attempt.current.hash!==hash)attempt.current={hash,id:crypto.randomUUID()};
   setBusy(true);setError('');
   try {check(await db!.rpc('record_change_fulfilment',{...args,p_id:attempt.current.id}));setEditing(false);attempt.current={hash:'',id:''};onSaved();}
   catch(e:any){setError(e.message);}finally{setBusy(false);}
  }}>
   <p>Approved decision v{change.version} · previous assessment {latest?.revision||'none'}. A new record preserves every earlier assessment. All fields require explicit recorded information.</p>
   <label className="p-field">Recorded fulfilment status<select name="status" required disabled={busy} defaultValue=""><option value="">Choose assessment</option>{['Not fulfilled','Partially fulfilled','Fulfilled'].map(s=><option key={s}>{s}</option>)}</select></label>
   {([['coverage','Scope coverage against the approved request'],['remaining_work','Remaining work / limitations (explicitly record none when applicable)'],['evidence','Evidence reference'],['reason','Assessment / correction reason']] as const).map(([name,label])=><label className="p-field" key={name}>{label}<textarea name={name} required minLength={3} maxLength={name==='reason'?2000:4000} disabled={busy}/></label>)}
   <button disabled={busy}>Save fulfilment assessment</button><button type="button" disabled={busy} onClick={()=>{setEditing(false);setError('');}}>Close assessment editor</button>
  </form>}
  {history.map(r=><article key={r.id}><h4>Assessment revision {r.revision} · {r.status}</h4><p>{r.actor_id} · {r.created_at} · {r.reason}</p><p>Scope coverage: {r.coverage}</p><p>Remaining work / limitations: {r.remaining_work}</p><p>Evidence reference: {r.evidence}</p><details><summary>Frozen decision and linked planning evidence at assessment</summary><p>{r.decision_snapshot.details.title} · {r.decision_snapshot.details.proposed_scope} · decision v{r.change_version}</p>{r.application_snapshot.length===0?<p>No linked task planning revisions recorded at assessment.</p>:r.application_snapshot.map((h:Row)=><p key={h.history_id}>Task {h.task_id} · revision {h.revision} · current plan version at assessment {h.current_plan_version??'unavailable'} · proposal {h.proposal_id||'not linked'} · {h.actor_id} · {h.created_at} · {h.reason}</p>)}</details></article>)}
 </div>;
}
