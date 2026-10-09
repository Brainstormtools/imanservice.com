import type {Row} from './client';
export function changeApplications(change:Row,history:Row[],plans:Row[]){
 const revisions=history.filter(h=>h.change_id===change.id&&h.project_id===change.project_id&&h.change_version===change.version).sort((a,b)=>String(b.created_at).localeCompare(String(a.created_at))||b.revision-a.revision);
 const byTask=new Map(plans.map(p=>[p.task_id,p]));
 const state=(h:Row)=>{const plan=byTask.get(h.task_id);return !plan?'Current plan unavailable':plan.version===h.revision?'Current task revision':plan.version>h.revision?'Superseded task revision':'Current plan unavailable';};
 return {revisions,state,tasks:new Set(revisions.map(h=>h.task_id)).size,current:revisions.filter(h=>state(h)==='Current task revision').length};
}
