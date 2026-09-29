export function csvText(rows:unknown[][]){return '\ufeff'+rows.map(row=>row.map(value=>{let s=String(value??'');if(/^[\s]*[=+\-@]/.test(s))s="'"+s;return '"'+s.replace(/"/g,'""')+'"';}).join(',')).join('\r\n');}
export function downloadText(name:string,text:string,type='text/csv;charset=utf-8'){const url=URL.createObjectURL(new Blob([text],{type}));const a=document.createElement('a');a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);}
export function parseCSV(text:string):string[][]{
 text=text.replace(/^\ufeff/,'');const rows:string[][]=[];let row:string[]=[],cell='',quoted=false,closed=false;
 for(let i=0;i<text.length;i++){
  const c=text[i];if(quoted){if(c==='"'){if(text[i+1]==='"'){cell+='"';i++;}else{quoted=false;closed=true;}}else cell+=c;}
  else if(c==='"'){if(cell||closed)throw new Error('Unexpected quote in CSV');quoted=true;}
  else if(c===','||c==='\n'||c==='\r'){row.push(cell);cell='';closed=false;if(c!==','){if(c==='\r'&&text[i+1]==='\n')i++;rows.push(row);row=[];}}
  else{if(closed)throw new Error('Unexpected text after closing quote');cell+=c;}
 }
 if(quoted)throw new Error('Unclosed CSV quote');if(cell||row.length||closed){row.push(cell);rows.push(row);}return rows.filter(r=>r.some(c=>c.trim()));
}
export const importHeaders=['title','priority','status','assignee_id','deadline','internal'];
export function validateImport(rows:string[][],members:any[]){
 if(rows.length<2)throw new Error('File must contain headers and at least one task');
 const headers=rows[0].map(x=>x.trim().toLowerCase());
 if(!headers.includes('title')||new Set(headers).size!==headers.length||headers.some(h=>!importHeaders.includes(h)))throw new Error('Use the template headers: '+importHeaders.join(', '));
 if(rows.length>501)throw new Error('Maximum 500 tasks per import');
 const errors:string[]=[];
 const data=rows.slice(1).map((cells,index)=>{
  const v:any=Object.fromEntries(headers.map((h,i)=>[h,(cells[i]||'').trim()]));v.priority||='Normal';v.status||='To do';v.internal||='false';
  const add=(s:string)=>errors.push(`Row ${index+2}: ${s}`);
  if(cells.length>headers.length)add('Too many columns');if(!v.title||v.title.length>300)add('Title must contain 1 to 300 characters');
  if(!['Low','Normal','High','Urgent'].includes(v.priority))add('Invalid priority');if(!['To do','In progress','Done'].includes(v.status))add('Invalid status');
  if(v.assignee_id&&!members.some(m=>m.id===v.assignee_id&&m.active&&m.role!=='client'))add('Assignee must be an active staff user ID');
  if(v.deadline&&(!/^\d{4}-\d{2}-\d{2}$/.test(v.deadline)||!Number.isFinite(Date.parse(v.deadline))||new Date(v.deadline).toISOString().slice(0,10)!==v.deadline))add('Deadline must be a valid YYYY-MM-DD date');
  if(!['true','false'].includes(v.internal.toLowerCase()))add('Internal must be true or false');v.internal=v.internal.toLowerCase()==='true';return v;
 });return {data,errors};
}
// XLSX is a ZIP of XML documents. Read only worksheet values; reject formulas/macros.
export async function readXLSX(buffer:ArrayBuffer):Promise<string[][]>{
 const view=new DataView(buffer),bytes=new Uint8Array(buffer),decode=new TextDecoder();let eocd=-1;
 for(let i=bytes.length-22;i>=Math.max(0,bytes.length-65557);i--)if(view.getUint32(i,true)===0x06054b50){eocd=i;break;}
 if(eocd<0)throw new Error('Invalid XLSX archive');const count=view.getUint16(eocd+10,true);let cursor=view.getUint32(eocd+16,true),total=0;
 if(count>2000)throw new Error('Workbook has too many entries');const entries=new Map<string,{start:number;size:number;method:number;raw:number}>();
 for(let n=0;n<count;n++){
  if(cursor+46>bytes.length||view.getUint32(cursor,true)!==0x02014b50)throw new Error('Invalid ZIP index');
  const flags=view.getUint16(cursor+8,true),method=view.getUint16(cursor+10,true),size=view.getUint32(cursor+20,true),raw=view.getUint32(cursor+24,true),len=view.getUint16(cursor+28,true),extra=view.getUint16(cursor+30,true),comment=view.getUint16(cursor+32,true),start=view.getUint32(cursor+42,true);
  const name=decode.decode(bytes.slice(cursor+46,cursor+46+len));total+=raw;
  if(flags&1||total>20*1024*1024||raw>10*1024*1024||entries.has(name))throw new Error('Encrypted, duplicate or oversized workbook entries are not supported');
  entries.set(name,{start,size,method,raw});cursor+=46+len+extra+comment;
 }
 if([...entries.keys()].some(n=>/vbaProject/i.test(n)))throw new Error('Macro workbooks are not supported');
 async function xml(name:string){
  const e=entries.get(name);if(!e)throw new Error('Missing workbook component: '+name);if(e.start+30>bytes.length||view.getUint32(e.start,true)!==0x04034b50)throw new Error('Invalid ZIP entry');
  const start=e.start+30+view.getUint16(e.start+26,true)+view.getUint16(e.start+28,true);if(start+e.size>bytes.length)throw new Error('Truncated workbook');let data=bytes.slice(start,start+e.size);
  if(e.method===8){const reader=new Blob([data]).stream().pipeThrough(new DecompressionStream('deflate-raw')).getReader();const chunks:Uint8Array[]=[];let size=0;for(;;){const r=await reader.read();if(r.done)break;size+=r.value.length;if(size>e.raw||size>10*1024*1024){await reader.cancel();throw new Error('Workbook expands beyond limits');}chunks.push(r.value);}data=new Uint8Array(size);let offset=0;for(const chunk of chunks){data.set(chunk,offset);offset+=chunk.length;}}
  else if(e.method!==0)throw new Error('Unsupported workbook compression');
  if(data.length!==e.raw)throw new Error('Invalid workbook size');const text=decode.decode(data);if(/<!DOCTYPE|<!ENTITY/i.test(text))throw new Error('Unsafe XML');const doc=new DOMParser().parseFromString(text,'application/xml');if(doc.querySelector('parsererror'))throw new Error('Invalid workbook XML');return doc;
 }
 const workbook=await xml('xl/workbook.xml'),rels=await xml('xl/_rels/workbook.xml.rels');const sheet=workbook.getElementsByTagName('sheet')[0];if(!sheet)throw new Error('No worksheets');const rid=sheet.getAttribute('r:id');const rel=Array.from(rels.getElementsByTagName('Relationship')).find(r=>r.getAttribute('Id')===rid);const target=rel?.getAttribute('Target')||'';
 if(rel?.getAttribute('TargetMode')==='External'||target.includes('..'))throw new Error('External workbook links are not supported');
 const path=target.startsWith('/')?target.slice(1):'xl/'+target;const sheetDoc=await xml(path);if(sheetDoc.getElementsByTagName('f').length)throw new Error('Replace formulas with values before importing');
 const shared=entries.has('xl/sharedStrings.xml')?Array.from((await xml('xl/sharedStrings.xml')).getElementsByTagName('si')).map(s=>Array.from(s.getElementsByTagName('t')).map(t=>t.textContent||'').join('')):[];
 const rows:string[][]=[];for(const row of Array.from(sheetDoc.getElementsByTagName('row'))){const values:string[]=[];for(const cell of Array.from(row.getElementsByTagName('c'))){const ref=cell.getAttribute('r')||'';const letters=ref.match(/^[A-Z]+/)?.[0];if(!letters)throw new Error('Invalid cell reference');let column=0;for(const c of letters)column=column*26+c.charCodeAt(0)-64;if(column>20)throw new Error('Use the six template columns only');let value=cell.getElementsByTagName('v')[0]?.textContent||'';if(cell.getAttribute('t')==='s')value=shared[Number(value)]??'';if(cell.getAttribute('t')==='inlineStr')value=Array.from(cell.getElementsByTagName('t')).map(t=>t.textContent||'').join('');if(cell.getAttribute('t')==='e')throw new Error('Workbook contains an error cell');values[column-1]=value;}if(values.some(v=>v?.trim()))rows.push(Array.from({length:values.length},(_,i)=>values[i]||''));if(rows.length>501)throw new Error('Maximum 500 tasks');}
 return rows;
}
export function reportRows(tickets:any[],from:string,to:string,company:string,projects:any[],now:number){
 const ids=new Set(projects.filter(p=>!company||p.company_id===company).map(p=>p.id));
 return tickets.filter(t=>ids.has(t.project_id)&&(!from||t.created_at.slice(0,10)>=from)&&(!to||t.created_at.slice(0,10)<=to)).map(t=>{
  const response=!t.response_due_at?'Not measured':t.first_response_at?(Date.parse(t.first_response_at)<=Date.parse(t.response_due_at)?'Met':'Missed'):t.status==='Resolved'?'Closed without reply':Date.parse(t.response_due_at)<now?'Overdue':'Pending';
  const resolution=!t.resolution_due_at?'Not measured':t.resolved_at?(Date.parse(t.resolved_at)<=Date.parse(t.resolution_due_at)?'Met':'Missed'):Date.parse(t.resolution_due_at)<now?'Overdue':'Pending';
  return {...t,response_result:response,resolution_result:resolution};
 });
}
