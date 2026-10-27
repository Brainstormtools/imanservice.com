import type {Row} from './client';
function decimalIdentity(value:unknown):string|null {
 if(typeof value!=='string'&&typeof value!=='number'||typeof value==='number'&&!Number.isFinite(value))return null;
 const text=String(value);if(text.length>500)return null;
 const m=/^(\d+)(?:\.(\d+))?(?:[eE]([+-]?\d+))?$/.exec(text);if(!m)return null;
 let digits=(m[1]+(m[2]||'')).replace(/^0+/,'')||'0',power=Number(m[3]||0)-(m[2]||'').length;
 if(!Number.isSafeInteger(power)||Math.abs(power)>1000)return null;
 if(digits==='0')return '0';while(digits.endsWith('0')){digits=digits.slice(0,-1);power++;}
 return digits+':'+power;
}
// Copy into an unsaved draft; saved versions and running plans are untouched.
export function reuseTaskStandard(parameters:Row[],tasks:Row[],source:Row,key:string){
 const task=source.tasks.find((t:Row)=>t.key===key);
 if(!task)throw new Error('Choose a saved task standard.');
 if(tasks.some(t=>t.key===key))throw new Error('This task key already exists in the draft. Rename or remove it before copying.');
 const populated=tasks.filter(t=>t.key||t.title);
 if(populated.length>=100)throw new Error('A template can contain at most 100 tasks.');
 if(populated.some(t=>Number(t.phase)>Number(task.phase)))throw new Error('Copy standards in phase order, or remove later-phase tasks first.');
 if((task.depends_on||[]).some((k:string)=>!populated.some(t=>t.key===k)))throw new Error('Copy or create the required predecessor tasks first.');
 const needed=new Set([...(task.quantity_parameters||[]),task.factor_parameter,task.condition_parameter].filter(Boolean));
 const merged=parameters.map(p=>({...p}));
 for(const k of needed){
  const incoming=source.parameters.find((p:Row)=>p.key===k);
  if(!incoming)throw new Error('Saved standard has an unavailable formula parameter.');
  const current=merged.find(p=>p.key===k);
  if(current&&['min','max','default'].some(f=>decimalIdentity(current[f])===null||decimalIdentity(incoming[f])===null||decimalIdentity(current[f])!==decimalIdentity(incoming[f])))throw new Error(`Parameter ${k} conflicts with this draft. Align its range and default before copying.`);
  if(!current)merged.push({...incoming});
 }
 if(merged.length>30)throw new Error('A template can contain at most 30 parameters.');
 return {parameters:merged,tasks:[...populated,JSON.parse(JSON.stringify(task))]};
}
