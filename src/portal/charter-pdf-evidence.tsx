import React,{useState} from 'react';
import {db,check,type Row} from './client';
export function CharterPDFEvidence({approval,onSaved}:{approval:Row;onSaved:()=>void}){
 const [busy,setBusy]=useState(false),[error,setError]=useState('');
 const run=async(action:string)=>{if(busy)return;setBusy(true);setError('');try{
  const session=check(await db!.auth.getSession());if(!session?.session?.access_token)throw Error('Sign in again to access this approval PDF');
  const response=await fetch('/api/charter-pdf',{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${session.session.access_token}`},body:JSON.stringify({approval_id:approval.id,action})});
  if(!response.ok){const data=await response.json();throw Error(data.error||'PDF unavailable');}
  if(action==='generate'){onSaved();return;}
  const bytes=await response.arrayBuffer(),hash=[...new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))].map(b=>b.toString(16).padStart(2,'0')).join('');
  if(hash!==response.headers.get('X-Document-SHA256')||hash!==approval.pdf?.sha256)throw Error('PDF integrity check failed; refresh the approval');
  const url=URL.createObjectURL(new Blob([bytes],{type:'application/pdf'})),a=document.createElement('a');a.href=url;a.download=`approved-charter-${approval.id}.pdf`;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
 }catch(e:any){setError(e.message);}finally{setBusy(false);}};
 return <section><p>{approval.pdf?`Locked approval PDF saved · ${approval.pdf.created_at} · SHA-256 ${approval.pdf.sha256}`:'PDF not saved yet. Retry generation below; your approval is already recorded.'}</p>{error&&<p role="alert">{error}</p>}{approval.pdf?<button disabled={busy} onClick={()=>run('download')}>Download locked approval PDF</button>:<button disabled={busy} onClick={()=>run('generate')}>Generate approval PDF</button>}</section>;
}
