import React,{useEffect,useRef,useState} from 'react';
import {db,check,type Row} from './client';
import {csvText,downloadText} from './business-utils';
export function CompetenceAssessmentReview({profile,assessment,version}:{profile:Row;assessment:string;version:number}){
 const allowed=profile.active!==false&&['admin','team'].includes(profile.role),scope=JSON.stringify([profile.id,profile.role,profile.active,profile.crm_permissions,assessment,version]);
 const scopeRef=useRef(scope),epoch=useRef(0),attempt=useRef({hash:'',id:''});scopeRef.current=scope;
 const [loaded,setLoaded]=useState<{scope:string;value:Row}|null>(null),[reviewer,setReviewer]=useState(''),[reason,setReason]=useState(''),[busy,setBusy]=useState(false),[error,setError]=useState(''),[notice,setNotice]=useState('');
 useEffect(()=>{epoch.current++;scopeRef.current=scope;setLoaded(null);setReviewer('');setReason('');setBusy(false);setError('');setNotice('');attempt.current={hash:'',id:''};return()=>{epoch.current++;scopeRef.current='';};},[scope]);
 const current=allowed&&loaded?.scope===scope?loaded.value:null;
 async function load(){const generation=epoch.current,valid=()=>scopeRef.current===scope&&epoch.current===generation;setBusy(true);setLoaded(null);setError('');try{const value=check(await db!.rpc('competence_assessment_review_context',{p_assessment:assessment}));if(!valid())return;setLoaded({scope,value});if(attempt.current.id&&value.history.some((h:Row)=>h.id===attempt.current.id)){attempt.current={hash:'',id:''};setReason('');setReviewer('');setNotice('Previous review action confirmed in immutable history.');}}catch(e:any){if(valid())setError(e.message);}finally{if(valid())setBusy(false);}}
 async function write(action:string){if(busy||!current?.receipt)return;const generation=epoch.current,valid=()=>scopeRef.current===scope&&epoch.current===generation;
 const args={p_assessment:assessment,p_receipt:current.receipt.id,p_version:current.assessment_version,p_previous:current.previous_sequence,p_reason:reason,...(action==='Assign'?{p_reviewer:reviewer}:{p_action:action})},hash=JSON.stringify(args);
 if(attempt.current.hash!==hash)attempt.current={hash,id:crypto.randomUUID()};setBusy(true);setError('');setNotice('');
 try{check(await db!.rpc(action==='Assign'?'assign_competence_assessment_reviewer':'review_competence_assessment',{...args,p_id:attempt.current.id}));if(!valid())return;attempt.current={hash:'',id:''};setReason('');setReviewer('');await load();if(valid())setNotice('Review action recorded. The assessment outcome is unchanged; no certificate or employee skill was issued.');}catch(e:any){if(valid()){setLoaded(null);setError(e.message);}}finally{if(valid())setBusy(false);}}
 if(!allowed)return null;
 return <section className="p-panel"><h3>Independent competence review</h3><p>Review confirms the recorded evidence, including a correctly recorded Fail. It does not change Pass/Fail or issue a certificate. HR/Admin explicitly selects an actual Team Lead or PM different from the assessor.</p>
 <button disabled={busy} onClick={load}>{current?'Refresh independent review':'Load independent review'}</button>{busy&&<p role="status">Checking independent review…</p>}{error&&<p role="alert">Review unavailable: {error}. Refresh before continuing.</p>}{notice&&<p role="status">{notice}</p>}
 {current&&<><p>{current.approved_current?'Current independent review approved':'No current independent approval'} · {current.latest_review?.action||'No reviewer assigned'} · assessment version {current.assessment_version} · review sequence {current.previous_sequence}</p>
 {current.receipt&&<p>Exact recorded receipt {current.receipt.id} · outcome {current.receipt.snapshot.result.outcome} · {current.receipt.created_at}</p>}
 {(current.can_assign||current.can_review||current.can_withdraw)&&<form className="p-form" onSubmit={e=>{e.preventDefault();const action=(e.nativeEvent as SubmitEvent).submitter?.getAttribute('value');if(action)void write(action);}}>
 {current.can_assign&&<label className="p-field">Actual independent reviewer<select required disabled={busy} value={reviewer} onChange={e=>setReviewer(e.target.value)}><option value="">Choose actual Team Lead or PM</option>{current.candidates.map((p:Row)=><option key={p.id} value={p.id}>{p.name}</option>)}</select></label>}
 <label className="p-field">Independent review action reason<textarea required minLength={3} maxLength={2000} disabled={busy} value={reason} onChange={e=>setReason(e.target.value)}/></label>
 {current.can_assign&&<button disabled={busy} value="Assign">Assign selected independent reviewer</button>}{current.can_review&&<><button disabled={busy} value="Approve">Approve exact recorded evidence</button><button disabled={busy} value="Return">Return recorded evidence with reason</button></>}{current.can_withdraw&&<button disabled={busy} value="Withdraw">Withdraw review with retained history</button>}
 </form>}
 <p>Returned records remain immutable. HR/Admin can cancel and manually assign a new assessment for corrected observations. Withdraw the existing review before selecting a replacement reviewer.</p>
 <details><summary>Immutable independent review history</summary><pre className="p-pre">{JSON.stringify(current.history,null,2)}</pre></details>
 <button disabled={busy} onClick={()=>{try{downloadText('private-competence-review.csv',csvText([['Assessment ID','Exact recorded receipt JSON','Immutable independent review history JSON'],[assessment,JSON.stringify(current.receipt),JSON.stringify(current.history)]]));}catch(e:any){setLoaded(null);setError(e.message);}}}>Export private independent review CSV</button></>}
 </section>;
}
