export const standardImportFields=['name','key','phase','title','process','step','unit','minutes','fixed_minutes','fixed_quantity','crew','crew_role','tools','preconditions','checklist'];
export const requiredStandardFields=['name','key','phase','title','unit','minutes','fixed_minutes','fixed_quantity','crew','crew_role'];
export function mapStandardRows(rows:string[][],mapping:Record<string,string>){
 if(rows.length<2||rows.length>101)throw new Error('Use 1–100 standard rows plus headers');
 const used=standardImportFields.map(k=>Number(mapping[k]??-1)).filter(n=>n>=0);
 if(new Set(used).size!==used.length||used.some(n=>!Number.isInteger(n)||n>=rows[0].length)||requiredStandardFields.some(k=>!used.includes(Number(mapping[k]??-1))))throw new Error('Map required fields to distinct source columns');
 const names=new Set<string>(),keys=new Set<string>();
 return rows.slice(1).map((cells,i)=>{
  const fail=(message:string):never=>{throw new Error(`Row ${i+2}: ${message}`);};
  if(cells.length>rows[0].length)fail('Too many columns');
  const v:Record<string,string>=Object.fromEntries(standardImportFields.map(k=>[k,(cells[Number(mapping[k])]||'').trim()]));
  for(const [k,max] of [['name',160],['title',200],['unit',30],['crew_role',100]] as const)if(!v[k]||v[k].length>max)fail(`${k} must contain 1–${max} characters`);
  if(!/^[a-z][a-z0-9_]{0,39}$/.test(v.key))fail('Use a lowercase task key');
  if(names.has(v.name.toLowerCase())||keys.has(v.key))fail('Duplicate standard name or task key');names.add(v.name.toLowerCase());keys.add(v.key);
  if(!/^[0-5]$/.test(v.phase))fail('Phase must be an integer 0–5');
  if(!/^(?:[1-9][0-9]?|100)$/.test(v.crew))fail('Crew must be an integer 1–100');
  for(const k of ['minutes','fixed_minutes','fixed_quantity'])if(!/^\d+(?:\.\d+)?$/.test(v[k])||Number(v[k])>100000)fail(`${k} requires explicit numeric values 0–100000`);
  if(v.tools.length>2000||v.preconditions.length>2000||v.process.length>2000||v.step.length>2000)fail('Text field exceeds 2000 characters');
  const checklist=v.checklist?v.checklist.split(/\r?\n/).map(s=>s.trim()):[];
  if(checklist.length>30||checklist.some(s=>!s||s.length>200))fail('Use up to 30 nonempty checklist lines, 200 characters each');
  return {name:v.name,task:{key:v.key,phase:Number(v.phase),title:v.title,process:v.process,step:v.step,unit:v.unit,minutes:Number(v.minutes),fixed_minutes:Number(v.fixed_minutes),fixed_quantity:Number(v.fixed_quantity),crew:Number(v.crew),crew_role:v.crew_role,tools:v.tools,preconditions:v.preconditions,checklist,quantity_parameters:[],factor_parameter:'',condition_parameter:'',depends_on:[]}};
 });
}
