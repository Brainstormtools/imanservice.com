/** Date-only project schedule measures; no completion timestamp is inferred. */
export function projectScheduleDate(now=new Date()) {
 return new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Karachi',year:'numeric',month:'2-digit',day:'2-digit'}).format(now);
}
function dateTime(value:unknown):number|null {
 if(typeof value!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(value))return null;
 const time=Date.parse(`${value}T00:00:00Z`);
 return Number.isFinite(time)&&new Date(time).toISOString().slice(0,10)===value?time:null;
}
export function projectDeadlineStatus(project:Record<string,unknown>,asOf:string):string {
 if(project.status==='Completed')return 'Completed';
 if(!project.deadline)return 'No deadline';
 const due=dateTime(project.deadline),today=dateTime(asOf);
 if(due===null||today===null)return 'Invalid date';
 const days=(today-due)/86400000;
 return days>0?`${days} ${days===1?'day':'days'} overdue`:days===0?'Due today':'Not due';
}
export function projectDueThisWeek(project:Record<string,unknown>,asOf:string):boolean {
 if(project.status==='Completed')return false;
 const due=dateTime(project.deadline),today=dateTime(asOf);
 if(due===null||today===null)return false;
 const monday=today-((new Date(today).getUTCDay()+6)%7)*86400000;
 return due>=monday&&due<monday+7*86400000;
}
