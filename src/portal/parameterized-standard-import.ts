import {mapStandardRows,standardImportFields,requiredStandardFields} from './task-standard-import';
export {requiredStandardFields};
export const parameterizedImportFields=[...standardImportFields,'parameters','quantity_parameters','factor_parameter','condition_parameter'];
const keyPattern=/^[a-z][a-z0-9_]{0,39}$/;
export function mapParameterizedStandards(rows:string[][],mapping:Record<string,string>){
 const used=parameterizedImportFields.map(k=>Number(mapping[k]??-1)).filter(n=>n>=0);
 if(new Set(used).size!==used.length||used.some(n=>!Number.isInteger(n)||n>=rows[0]?.length))throw Error('Map fields to distinct source columns');
 const base=mapStandardRows(rows,mapping);
 return base.map((row,i)=>{
  const fail=(message:string):never=>{throw Error(`Row ${i+2}: ${message}`);},cell=(key:string)=>(rows[i+1][Number(mapping[key]??-1)]||'').trim();
  const parse=(key:string,fallback:unknown)=>{const v=cell(key);if(!v)return fallback;if(v.length>50000)fail(`${key} is too large`);try{return JSON.parse(v);}catch{fail(`${key} must be values-only JSON`);}};
  // Existing planning values are JSON numbers; reject conversion that changes the supplied decimal.
  const rational=(value:string)=>{const [mantissa,exp='0']=value.toLowerCase().split('e');const [whole,fraction='']=mantissa.split('.');let n=BigInt(whole+fraction),scale=fraction.length-Number(exp);if(scale<0){n*=10n**BigInt(-scale);scale=0;}return {n,scale};};
  for(const field of ['minutes','fixed_minutes','fixed_quantity']){const original=rational(cell(field)),saved=rational(String(row.task[field as 'minutes']));const scale=Math.max(original.scale,saved.scale);if(original.n*10n**BigInt(scale-original.scale)!==saved.n*10n**BigInt(scale-saved.scale))fail(`${field} loses decimal precision; revise the source value explicitly`);}
  const parameters=parse('parameters',[]) as any;
  if(!Array.isArray(parameters)||parameters.length>30)fail('Use up to 30 actual parameter definitions');
  const keys=new Set<string>();
  // Decimal bounds stay text when supplied as text; fractional JSON numbers must use text to avoid parsing loss.
  const decimal=(v:unknown)=>{if(typeof v==='number'&&(!Number.isSafeInteger(v)||v<0))fail('Use decimal text for fractional parameter bounds/defaults');if(typeof v!=='number'&&typeof v!=='string'||!/^\d+(?:\.\d+)?$/.test(String(v))||String(v).length>200)fail('Parameter bounds/defaults require explicit nonnegative decimals');const s=String(v),[a,b='']=s.split('.');return {n:BigInt(a+b),scale:b.length};};
  const compare=(a:ReturnType<typeof decimal>,b:ReturnType<typeof decimal>)=>{const scale=Math.max(a.scale,b.scale);const x=a.n*10n**BigInt(scale-a.scale),y=b.n*10n**BigInt(scale-b.scale);return x<y?-1:x>y?1:0;};
  for(const p of parameters){
   if(!p||typeof p!=='object'||Array.isArray(p)||Object.keys(p).sort().join(',')!=='default,key,label,max,min'||typeof p.key!=='string'||!keyPattern.test(p.key)||keys.has(p.key)||typeof p.label!=='string'||!p.label.trim()||p.label.length>100)fail('Actual unique parameter keys, labels and exact five fields required');
   keys.add(p.key);const min=decimal(p.min),max=decimal(p.max),def=decimal(p.default),limit=decimal(100000);
   if(compare(min,max)>0||compare(max,limit)>0||compare(def,min)<0||compare(def,max)>0)fail('Parameter bounds must be 0–100000 and include the explicit default');
  }
  const quantity=parse('quantity_parameters',[]) as any;
  if(!Array.isArray(quantity)||quantity.length>30||quantity.some(k=>typeof k!=='string'||!keys.has(k))||new Set(quantity).size!==quantity.length)fail('Quantity references must be unique actual parameter keys');
  const factor=cell('factor_parameter'),condition=cell('condition_parameter');
  if(factor&&!keys.has(factor)||condition&&!keys.has(condition))fail('Factor and inclusion condition must reference actual parameter keys');
  return {...row,parameters,task:{...row.task,quantity_parameters:quantity as string[],factor_parameter:factor,condition_parameter:condition}};
 });
}
