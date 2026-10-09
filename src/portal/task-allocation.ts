type Schedule={id:string;task_id?:string;user_id:string;status:string;planned_start:string;planned_end:string};
export function taskAllocation(taskId:string,crew:unknown,duration:unknown,schedules:Schedule[]){
 const selected=schedules.filter(s=>s.task_id===taskId&&s.status==='Scheduled');const unique=[...new Map(selected.map(s=>[s.id,s])).values()];
 const events:{at:number;delta:number;worker:string}[]=[];let minutes=0;const workers=new Set<string>();
 for(const s of unique){const start=Date.parse(s.planned_start),end=Date.parse(s.planned_end);if(!s.user_id||!Number.isFinite(start)||!Number.isFinite(end)||end<=start)return {known:false,workers:[],schedules:unique,workerHours:null,plannedHours:null,peak:null};minutes+=(end-start)/60000;workers.add(s.user_id);events.push({at:start,delta:1,worker:s.user_id},{at:end,delta:-1,worker:s.user_id});}
 events.sort((a,b)=>a.at-b.at||a.delta-b.delta);const active=new Map<string,number>();let peak=0;for(const e of events){const count=(active.get(e.worker)||0)+e.delta;if(count===0)active.delete(e.worker);else active.set(e.worker,count);peak=Math.max(peak,active.size);}
 const c=Number(crew),d=Number(duration);if(!Number.isInteger(c)||c<1||!Number.isFinite(d)||d<=0)return {known:false,workers:[...workers],schedules:unique,workerHours:null,plannedHours:null,peak:null};
 return {known:true,workers:[...workers],schedules:unique,workerHours:minutes/60,plannedHours:c*d/60,peak};
}
