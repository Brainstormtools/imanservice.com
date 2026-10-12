import React,{useRef,useState} from 'react';
import {db,check,type Row} from './client';
import {csvText,downloadText} from './business-utils';

export function ProjectBudgetReview({draft,records,busy,blocked,setBusy,onError,onSaved}:{draft:Row;records:Row[];busy:boolean;blocked:boolean;setBusy:(v:boolean)=>void;onError:(v:string)=>void;onSaved:()=>void}){
 const [action,setAction]=useState(''),[reason,setReason]=useState('');
 const attempt=useRef({hash:'',id:''});
 const events=records.filter(r=>r.draft_id===draft.id&&r.project_id===draft.project_id).sort((a,b)=>b.sequence-a.sequence);
 const current=events.find(r=>r.draft_version===draft.version),released=events.find(r=>r.action==='Released');
 const start=(a:string)=>{setAction(a);setReason('');attempt.current={hash:'',id:''};};
 return <div>
  <p>Current cost draft v{draft.version}: {current?.action||'Not reviewed'}. Latest archived release: {released?`v${released.draft_version} · ${released.snapshot.currency} ${released.snapshot.total_cost}`:'None'}.</p>
  <p>A release archives the reviewed costs. Finance, funding and procurement still use the original budget until consumer integration is implemented.</p>
  {current?.action!=='Released'&&<>
   <button disabled={busy||blocked||current?.action==='Reviewed'} onClick={()=>start('Reviewed')}>Review this budget version</button>
   <button disabled={busy||blocked||current?.action==='Returned'} onClick={()=>start('Returned')}>Return this budget version</button>
   <button disabled={busy||blocked||current?.action!=='Reviewed'} onClick={()=>start('Released')}>Release reviewed cost snapshot</button>
  </>}
  {action&&<form className="p-form" onSubmit={async e=>{
   e.preventDefault();if(busy)return;
   const args={p_draft:draft.id,p_version:draft.version,p_action:action,p_review:action==='Released'?current?.id:null,p_reason:reason},hash=JSON.stringify(args);
   if(attempt.current.hash!==hash)attempt.current={hash,id:crypto.randomUUID()};
   setBusy(true);onError('');
   try{check(await db!.rpc('review_project_budget_draft',{...args,p_id:attempt.current.id}));setAction('');onSaved();}
   catch(e:any){onError(e.message);}finally{setBusy(false);}
  }}>
   <p>{action} · exact cost draft v{draft.version} · {draft.currency} {draft.total_cost}</p>
   <label className="p-field">Budget review action reason<textarea required minLength={3} maxLength={2000} value={reason} disabled={busy} onChange={e=>setReason(e.target.value)}/></label>
   <button disabled={busy||reason.trim().length<3}>Confirm budget {action.toLowerCase()}</button>
   <button type="button" disabled={busy} onClick={()=>setAction('')}>Close budget review</button>
  </form>}
  <button disabled={busy||blocked||!events.length} onClick={()=>{
   try{downloadText('private-budget-review-history.csv',csvText([['Action ID','Draft ID','Project ID','Draft version','Action sequence','Action','Reviewed action ID','Actual actor','Recorded time','Reason','Frozen budget JSON'],...events.map(r=>[r.id,r.draft_id,r.project_id,r.draft_version,r.sequence,r.action,r.review_id||'',r.actor_id,r.created_at,r.reason,JSON.stringify(r.snapshot)])]));}
   catch(e:any){onError(e.message);}
  }}>Export private budget review CSV</button>
  {events.map(r=><details key={r.id}><summary>Budget v{r.draft_version} · {r.action} · {r.actor_id} · {r.created_at} · {r.reason}</summary><p>Recorded review reference: {r.review_id||'None'}</p><pre className="p-pre">{JSON.stringify(r.snapshot,null,2)}</pre></details>)}
 </div>;
}
