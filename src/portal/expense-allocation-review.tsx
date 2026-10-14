import React,{useRef,useState} from 'react';
import {db,check,type Row} from './client';
import {csvText,downloadText} from './business-utils';

export function ExpenseAllocationReview({draft,records,busy,blocked,setBusy,onError,onSaved}:{draft:Row;records:Row[];busy:boolean;blocked:boolean;setBusy:(v:boolean)=>void;onError:(v:string)=>void;onSaved:()=>void}){
 const [action,setAction]=useState(''),[reason,setReason]=useState('');const attempt=useRef({hash:'',id:''});
 const events=records.filter(r=>r.allocation_id===draft.id&&r.project_id===draft.project_id).sort((a,b)=>b.sequence-a.sequence),current=events.find(r=>r.allocation_version===draft.version);
 const start=(a:string)=>{setAction(a);setReason('');attempt.current={hash:'',id:''};};
 return <section><h3>Private expense allocation review</h3><p>Current allocation draft v{draft.version}: {current?.action||'Not reviewed'}. Review requires the current Approved source version and product identities, including a refreshed draft after cash-only version changes. Return can record corrections to stale source evidence. Decisions preserve actual source and allocation snapshots; product-cost application remains pending.</p>
  <button disabled={busy||blocked||current?.action==='Reviewed'} onClick={()=>start('Reviewed')}>Review this allocation version</button><button disabled={busy||blocked||current?.action==='Returned'} onClick={()=>start('Returned')}>Return this allocation version</button>
  {action&&<form className="p-form" onSubmit={async e=>{e.preventDefault();if(busy)return;const args={p_allocation:draft.id,p_version:draft.version,p_action:action,p_reason:reason},hash=JSON.stringify(args);if(attempt.current.hash!==hash)attempt.current={hash,id:crypto.randomUUID()};setBusy(true);onError('');try{check(await db!.rpc('review_expense_product_allocation',{...args,p_id:attempt.current.id}));setAction('');onSaved();}catch(e:any){onError(e.message);}finally{setBusy(false);}}}>
   <p>{action} · exact allocation draft v{draft.version}</p><label className="p-field">Expense allocation review reason<textarea required minLength={3} maxLength={2000} value={reason} disabled={busy} onChange={e=>setReason(e.target.value)}/></label><button disabled={busy||reason.trim().length<3}>Confirm allocation {action.toLowerCase()}</button><button type="button" disabled={busy} onClick={()=>setAction('')}>Close allocation review</button>
  </form>}
  <button disabled={busy||blocked||!events.length} onClick={()=>{try{downloadText('private-expense-allocation-review-history.csv',csvText([['Action ID','Draft ID','Project ID','Draft version','Action sequence','Action','Actual actor','Recorded time','Reason','Frozen allocation JSON','Current expense at action JSON','Canonical request JSON'],...events.map(r=>[r.id,r.allocation_id,r.project_id,r.allocation_version,r.sequence,r.action,r.actor_id,r.created_at,r.reason,JSON.stringify(r.snapshot),JSON.stringify(r.expense_snapshot),JSON.stringify(r.request)])]));}catch(e:any){onError(e.message);}}}>Export expense allocation review CSV</button>
  {events.map(r=><details key={r.id}><summary>Allocation draft v{r.allocation_version} · {r.action} · {r.actor_id} · {r.created_at} · {r.reason}</summary><pre className="p-pre">{JSON.stringify(r.snapshot,null,2)}</pre><pre className="p-pre">{JSON.stringify(r.expense_snapshot,null,2)}</pre></details>)}
 </section>;
}
