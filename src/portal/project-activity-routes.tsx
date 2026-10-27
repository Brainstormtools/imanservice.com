import {useEffect,useRef,useState} from 'react';
import {db,check,type Row} from './client';
import {csvText,downloadText} from './business-utils';
export function ProjectActivityRoutes({profile}:{profile:Row}){
 const allowed=profile.active!==false&&(profile.role==='admin'||profile.role==='team'&&profile.crm_permissions?.includes('project.own'));
 return allowed?<Evidence key={JSON.stringify([profile.id,profile.role,profile.crm_permissions])}/>:null;
}
function Evidence(){
 const [projects,setProjects]=useState<Row[]>([]),[project,setProject]=useState(''),[data,setData]=useState<Row|null>(null),[busy,setBusy]=useState(false),[error,setError]=useState('');
 const epoch=useRef(0),mounted=useRef(true),running=useRef(false);
 useEffect(()=>{mounted.current=true;return()=>{mounted.current=false;epoch.current++;};},[]);
 async function load(id:string|null){
  if(running.current)return;const n=++epoch.current;running.current=true;setBusy(true);setError('');setData(null);
  if(!id){setProjects([]);setProject('');}
  try{
   const result=check(await db!.rpc('project_activity_route_context',{p_project:id}));
   if(!mounted.current||n!==epoch.current)return;
   if(id){if(result.project?.id!==id||!Array.isArray(result.activities))throw Error('Actual activity project changed; reload evidence.');setData(result);}
   else setProjects(result.projects);
  }catch(e:any){if(mounted.current&&n===epoch.current){setData(null);setProjects([]);setError(e.message);}}
  finally{if(mounted.current&&n===epoch.current){running.current=false;setBusy(false);}}
 }
 return <section className="p-panel"><h2>Recorded activity route evidence</h2>
 <p>Original route references captured for newly recorded task-linked work. Reference currency is measured at recording, not at the entered work date. Draft, submitted, approved and voided activities retain their separate work status. Missing or stale references do not prove installed work or client acceptance.</p>
 {error&&<p role="alert">{error}</p>}
 <button type="button" disabled={busy} onClick={()=>void load(null)}>Load activity evidence projects</button>
 {projects.length>0&&<label className="p-field">Actual activity evidence project<select disabled={busy} value={project} onChange={e=>{setProject(e.target.value);setData(null);if(e.target.value)void load(e.target.value);}}><option value="">Choose actual project</option>{projects.map(p=><option key={p.id} value={p.id}>{p.title}</option>)}</select></label>}
 {project&&<button type="button" disabled={busy} onClick={()=>void load(project)}>Refresh activity route evidence</button>}
 {data&&<><p>{data.project.title} · {data.project.status}</p>{data.activities.length===0&&<p>No actual task-linked activity records.</p>}
 {data.activities.map((a:Row)=><details key={a.activity_id}><summary>{a.basis?.task_source?.task?.title||a.task_id} · {a.activity_status} · {a.capture_state}</summary>
 <p>Activity {a.activity_id} · Worker {a.worker_id} · Current interval {a.actual_start} → {a.actual_end}</p>
 {a.basis?<><p>Recorded by {a.basis.recorded_by||'Not available'} · Server capture {a.basis.captured_at}</p><p>Task basis at recording: {a.basis.task_source.task.title} · {a.basis.task_source.task.status}</p>
 {a.basis.planning_reference&&<p>Original reference {a.basis.reference_id} · {a.basis.planning_reference.action} · {a.basis.planning_reference.route_source.details.code} v{a.basis.planning_reference.route_source.revision} · {a.basis.planning_reference.route_source.details.length||'Length not recorded'} {a.basis.planning_reference.route_source.details.unit}</p>}
 <details><summary>Frozen source evidence</summary><pre>{JSON.stringify(a.basis,null,2)}</pre></details></>:<p>No route evidence was captured for this historical record. A current planning link is not substituted.</p>}
 </details>)}
 {data.activities.length>0&&<button type="button" disabled={busy} onClick={()=>downloadText('activity-route-evidence.csv',csvText([['Project','Activity','Task','Worker','Current activity status','Current start','Current end','Capture state','Frozen evidence'],...data.activities.map((a:Row)=>[data.project.title,a.activity_id,a.task_id,a.worker_id,a.activity_status,a.actual_start,a.actual_end,a.capture_state,a.basis?JSON.stringify(a.basis):''])]))}>Export activity route evidence CSV</button>}
 </>}
 </section>;
}
