import React,{useRef,useState} from 'react';
import {db,check,type Row} from './client';
import {csvText,downloadText} from './business-utils';

export function SurveyBatchReview({draft,records,admin,busy,blocked,setBusy,onError,onSaved}:{draft:Row;records:Row[];admin:boolean;busy:boolean;blocked:boolean;setBusy:(v:boolean)=>void;onError:(v:string)=>void;onSaved:()=>void}){
 const [action,setAction]=useState(''),[reason,setReason]=useState('');const attempt=useRef({hash:'',id:''});
 const events=records.filter(r=>r.batch_id===draft.id&&r.project_id===draft.project_id).sort((a,b)=>b.sequence-a.sequence),current=events.find(r=>r.batch_version===draft.version);
 const start=(a:string)=>{setAction(a);setReason('');attempt.current={hash:'',id:''};};
 return <section><h3>Survey batch review</h3><p>Current survey batch v{draft.version}: {current?.action||'Not reviewed'}. Review requires actual method and evidence in every staged row, matching existing survey review requirements. Return records required corrections. Decisions preserve the full ordered batch. Later batch revisions need their own review. Application is a separate action; review does not create or approve registry measurements.</p>
  <button hidden={!admin} disabled={!admin||busy||blocked||current?.action==='Reviewed'} onClick={()=>start('Reviewed')}>Review this survey batch version</button><button hidden={!admin} disabled={!admin||busy||blocked||current?.action==='Returned'} onClick={()=>start('Returned')}>Return this survey batch version</button>
  {admin&&action&&<form className="p-form" onSubmit={async e=>{e.preventDefault();if(busy)return;const args={p_batch:draft.id,p_version:draft.version,p_action:action,p_reason:reason},hash=JSON.stringify(args);if(attempt.current.hash!==hash)attempt.current={hash,id:crypto.randomUUID()};setBusy(true);onError('');try{check(await db!.rpc('review_project_survey_batch',{...args,p_id:attempt.current.id}));setAction('');onSaved();}catch(e:any){onError(e.message);}finally{setBusy(false);}}}>
   <p>{action} · exact survey batch v{draft.version}</p><label className="p-field">Survey batch review reason<textarea required minLength={3} maxLength={2000} value={reason} disabled={busy} onChange={e=>setReason(e.target.value)}/></label><button disabled={busy||reason.trim().length<3}>Confirm survey batch {action.toLowerCase()}</button><button type="button" disabled={busy} onClick={()=>setAction('')}>Close survey batch review</button>
  </form>}
  <button disabled={busy||blocked||!events.length} onClick={()=>{try{downloadText('private-survey-batch-review-history.csv',csvText([['Action ID','Batch ID','Draft version','Action sequence','Action','Actual actor','Recorded time','Reason','Frozen batch JSON','Canonical request JSON'],...events.map(r=>[r.id,r.batch_id,r.batch_version,r.sequence,r.action,r.actor_id,r.created_at,r.reason,JSON.stringify(r.snapshot),JSON.stringify(r.request)])]));}catch(e:any){onError(e.message);}}}>Export survey batch review CSV</button>
  {events.map(r=><details key={r.id}><summary>Survey batch v{r.batch_version} · {r.action} · {r.actor_id} · {r.created_at} · {r.reason}</summary><pre className="p-pre">{JSON.stringify(r.snapshot,null,2)}</pre></details>)}
 </section>;
}
