import React,{useRef,useState} from 'react';
import {db,check,type Row} from './client';
import {csvText,downloadText} from './business-utils';

export function ProjectContractReview({draft,records,busy,blocked,setBusy,onError,onSaved}:{draft:Row;records:Row[];busy:boolean;blocked:boolean;setBusy:(v:boolean)=>void;onError:(v:string)=>void;onSaved:()=>void}){
 const [action,setAction]=useState(''),[reason,setReason]=useState('');const attempt=useRef({hash:'',id:''});
 const events=records.filter(r=>r.draft_id===draft.id&&r.project_id===draft.project_id).sort((a,b)=>b.sequence-a.sequence),current=events.find(r=>r.draft_version===draft.version);
 const start=(a:string)=>{setAction(a);setReason('');attempt.current={hash:'',id:''};};
 return <section><h3>Internal contract proposal review</h3><p>Current wording draft v{draft.version}: {current?.action||'Not reviewed'}. Review freezes this exact private proposal. Return records corrections without deleting earlier reviews. Client publication/decisions use the separate fixed public workflow; operative contract/revenue changes remain pending.</p>
  <button disabled={busy||blocked||current?.action==='Reviewed'} onClick={()=>start('Reviewed')}>Review this contract version</button><button disabled={busy||blocked||current?.action==='Returned'} onClick={()=>start('Returned')}>Return this contract version</button>
  {action&&<form className="p-form" onSubmit={async e=>{e.preventDefault();if(busy)return;const args={p_draft:draft.id,p_version:draft.version,p_action:action,p_reason:reason},hash=JSON.stringify(args);if(attempt.current.hash!==hash)attempt.current={hash,id:crypto.randomUUID()};setBusy(true);onError('');try{check(await db!.rpc('review_project_contract_draft',{...args,p_id:attempt.current.id}));setAction('');onSaved();}catch(e:any){onError(e.message);}finally{setBusy(false);}}}>
   <p>{action} · exact contract wording draft v{draft.version}</p><label className="p-field">Contract review action reason<textarea required minLength={3} maxLength={2000} value={reason} disabled={busy} onChange={e=>setReason(e.target.value)}/></label><button disabled={busy||reason.trim().length<3}>Confirm contract {action.toLowerCase()}</button><button type="button" disabled={busy} onClick={()=>setAction('')}>Close contract review</button>
  </form>}
  <button disabled={busy||blocked||!events.length} onClick={()=>{try{downloadText('private-contract-review-history.csv',csvText([['Action ID','Draft ID','Project ID','Draft version','Action sequence','Action','Actual actor','Recorded time','Reason','Frozen contract proposal JSON','Canonical request JSON'],...events.map(r=>[r.id,r.draft_id,r.project_id,r.draft_version,r.sequence,r.action,r.actor_id,r.created_at,r.reason,JSON.stringify(r.snapshot),JSON.stringify(r.request)])]));}catch(e:any){onError(e.message);}}}>Export private contract review CSV</button>
  {events.map(r=><details key={r.id}><summary>Contract draft v{r.draft_version} · {r.action} · {r.actor_id} · {r.created_at} · {r.reason}</summary><pre className="p-pre">{JSON.stringify(r.snapshot,null,2)}</pre></details>)}
 </section>;
}
