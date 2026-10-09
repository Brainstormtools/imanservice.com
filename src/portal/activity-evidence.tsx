import React,{useRef,useState} from 'react';
import {db,check,type Row} from './client';
const types:Record<string,string>={pdf:'application/pdf',png:'image/png',jpg:'image/jpeg',jpeg:'image/jpeg',webp:'image/webp',txt:'text/plain',csv:'text/csv',zip:'application/zip',docx:'application/vnd.openxmlformats-officedocument.wordprocessingml.document',xlsx:'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'};
const bucket='activity-evidence';
export function ActivityEvidence({activity,profile,files,busy,onBusy,onRefresh}:{key?:string;activity:Row;profile:Row;files:Row[];busy:boolean;onBusy:(v:boolean)=>void;onRefresh:()=>void}){
 const [error,setError]=useState(''),[notice,setNotice]=useState('');
 const running=useRef(false);
 const pending=useRef<{fingerprint:string;path:string;uploaded:boolean}|null>(null);
 if(!['admin','team'].includes(profile.role))return null;
 const editable=activity.user_id===profile.id&&['Draft','Rejected'].includes(activity.status);
 async function run(fn:()=>Promise<void>){if(busy||running.current)return;running.current=true;onBusy(true);setError('');setNotice('');try{await fn();}catch(e:any){setError(e.message||'Evidence operation failed.');}finally{running.current=false;onBusy(false);}}
 async function upload(e:React.FormEvent<HTMLFormElement>){e.preventDefault();const form=e.currentTarget,file=new FormData(form).get('file') as File;await run(async()=>{
  if(!file?.size)throw new Error('Choose a nonempty file.');const ext=file.name.split('.').pop()?.toLowerCase()||'',mime=types[ext];
  if(!mime||file.size>10485760||file.name.length>160||/[\/\\\x00-\x1f]/.test(file.name))throw new Error('Choose an allowed file up to 10 MB with a filename up to 160 characters.');
  if(file.type&&file.type!==mime)throw new Error('The file type must agree with its extension.');
  const fingerprint=[file.name,file.size,file.lastModified].join(':');
  if(pending.current&&pending.current.fingerprint!==fingerprint){check(await db!.storage.from(bucket).remove([pending.current.path]));pending.current=null;}
  if(!pending.current)pending.current={fingerprint,path:activity.id+'/'+crypto.randomUUID()+'.'+ext,uploaded:false};
  const attempt=pending.current;
  if(!attempt.uploaded){check(await db!.storage.from(bucket).upload(attempt.path,file,{upsert:false,contentType:mime}));attempt.uploaded=true;}
  const result=await db!.rpc('attach_activity_evidence',{p_activity:activity.id,p_version:activity.version,p_path:attempt.path,p_name:file.name});
  if(result.error){
   if(result.error.code){const cleanup=await db!.storage.from(bucket).remove([attempt.path]);if(!cleanup.error)pending.current=null;}
   throw new Error(result.error.message+' Refresh the activity and retry the same file if the result is uncertain.');
  }
  pending.current=null;form.reset();setNotice('Private evidence attached.');onRefresh();
 });}
 return <section aria-label="Activity evidence"><h3>Private activity evidence</h3>{error&&<p role="alert">{error}</p>}{notice&&<p role="status">{notice}</p>}
 {files.map(f=><div key={f.id}><p>{f.name} · {(Number(f.size)/1024).toFixed(1)} KB{f.removed_at?' · Removed: '+f.removal_note:''}</p><button disabled={busy} onClick={()=>run(async()=>{const blob=check(await db!.storage.from(bucket).download(f.path));const url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download=f.name;a.click();setTimeout(()=>URL.revokeObjectURL(url),30000);})}>Download {f.name}</button>{editable&&!f.removed_at&&<form onSubmit={e=>{e.preventDefault();const form=e.currentTarget,note=new FormData(form).get('reason');run(async()=>{check(await db!.rpc('remove_activity_evidence',{p_file:f.id,p_version:activity.version,p_note:note}));setNotice('Evidence removed from the activity; its history is retained.');onRefresh();});}}><label>Removal reason<input name="reason" minLength={3} maxLength={2000} required disabled={busy}/></label><button disabled={busy}>Remove {f.name}</button></form>}</div>)}
 {editable&&<><p>Private to you and authorized reviewers. Up to 10 active files, 20 attachments including removal history, and 10 MB per file.</p><form onSubmit={upload}><label>Evidence file<input name="file" type="file" accept={Object.keys(types).map(x=>'.'+x).join(',')} required disabled={busy}/></label><button disabled={busy||files.filter(f=>!f.removed_at).length>=10||files.length>=20}>Attach evidence file</button></form><form onSubmit={upload}><label>Evidence photo<input name="file" type="file" accept="image/jpeg,image/png" capture="environment" required disabled={busy}/></label><button disabled={busy||files.filter(f=>!f.removed_at).length>=10||files.length>=20}>Attach evidence photo</button></form></>}
 </section>;
}
