import React,{useEffect,useRef,useState} from 'react';
import {parseCSV,readXLSX} from './business-utils';
import {surveyBatchFields,surveyBatchInput,parseSurveyBatch} from './survey-batch-csv';
const optional=['notes','method','evidence'];
export function surveyFileRows(rows:string[][]){
 if(rows.length<2||rows.length>101)throw Error('Use headers and 1–100 measurement rows');
 const width=rows[0].length;if(!width||width>20)throw Error('Use 1–20 source columns');
 if(rows.some(r=>r.length>width))throw Error('A measurement row has columns beyond the source headers');
 if(new TextEncoder().encode(JSON.stringify(rows)).length>1000000)throw Error('Decoded survey data must be within 1 MB');
 return rows.map(r=>Array.from({length:width},(_,i)=>r[i]??''));
}
export function mappedSurveyCSV(rows:string[][],mapping:Record<string,string>){
 const checked=surveyFileRows(rows),chosen:number[]=[];
 for(const field of surveyBatchFields){const v=mapping[field];if(v==='blank'&&optional.includes(field))continue;if(!/^(0|[1-9][0-9]*)$/.test(v||'')||Number(v)>=checked[0].length)throw Error('Choose a source column for '+field);chosen.push(Number(v));}
 if(new Set(chosen).size!==chosen.length)throw Error('Map each source column to only one survey field');
 const text=surveyBatchInput(checked.slice(1).map(r=>Object.fromEntries(surveyBatchFields.map(field=>[field,mapping[field]==='blank'?'':r[Number(mapping[field])]]))));
 parseSurveyBatch(text);return text;
}
export async function readSurveyFile(file:{name:string;size:number;arrayBuffer:()=>Promise<ArrayBuffer>}){
 if(file.size>1000000)throw Error('Survey file must be within 1 MB');
 if(!/\.(csv|xlsx)$/i.test(file.name))throw Error('Choose a CSV or XLSX file');
 const bytes=await file.arrayBuffer();if(bytes.byteLength>1000000)throw Error('Survey file must be within 1 MB');
 const rows=/\.xlsx$/i.test(file.name)?await readXLSX(bytes):parseCSV(new TextDecoder('utf-8',{fatal:true}).decode(bytes));
 return surveyFileRows(rows);
}
export function SurveyFileInput({disabled,onInvalidate,onMapped}:{disabled:boolean;onInvalidate:()=>void;onMapped:(text:string)=>void}){
 const [rows,setRows]=useState<string[][]>([]),[source,setSource]=useState(''),[mapping,setMapping]=useState<Record<string,string>>({}),[error,setError]=useState(''),[reading,setReading]=useState(false);const generation=useRef(0);
 useEffect(()=>()=>{generation.current++;},[]);
 return <section><h4>Survey file columns</h4><p>Choose a UTF-8 CSV or values-only XLSX file, within 1 MB and 100 measurement rows. XLSX reads only the first worksheet; formulas, macros and encrypted workbooks are rejected. Use explicit ISO date text (YYYY-MM-DD), decimal values and units. Choose every mapping manually. Optional notes/method/evidence can explicitly be left blank for Draft staging. Unmapped columns are excluded; no values are inferred. File contents stay in this editor until you save the mapped batch; the original file and mapping are not uploaded or archived.</p><label className="p-field">Survey CSV or XLSX file<input type="file" accept=".csv,.xlsx" disabled={disabled||reading} onChange={async e=>{const file=e.target.files?.[0],token=++generation.current;e.target.value='';setRows([]);setMapping({});setSource('');setError('');onInvalidate();if(!file){setReading(false);return;}setReading(true);try{const result=await readSurveyFile(file);if(token===generation.current){setRows(result);setSource(file.name);}}catch(e:any){if(token===generation.current)setError(e.message);}finally{if(token===generation.current)setReading(false);}}}/></label>{reading&&<p role="status">Reading survey file…</p>}{error&&<p role="alert">Survey file unavailable: {error}</p>}{rows.length>0&&<><p>Source: {source} · {rows.length-1} measurement rows · {rows[0].length} source columns</p>{surveyBatchFields.map(field=><label className="p-field" key={field}>Map survey {field}<select value={mapping[field]||''} disabled={disabled||reading} onChange={e=>{setMapping({...mapping,[field]:e.target.value});setError('');onInvalidate();}}><option value="">Choose source column</option>{optional.includes(field)&&<option value="blank">Leave blank</option>}{rows[0].map((header,i)=><option key={i} value={String(i)}>Column {i+1}: {header||'(blank header)'}</option>)}</select></label>)}<details><summary>Inspect ordered source rows</summary><pre className="p-pre">{JSON.stringify(rows,null,2)}</pre></details><button type="button" disabled={disabled||reading||surveyBatchFields.some(f=>!mapping[f])} onClick={()=>{try{const text=mappedSurveyCSV(rows,mapping);setError('');onMapped(text);}catch(e:any){setError(e.message);}}}>Use mapped survey rows</button><button type="button" disabled={disabled||reading} onClick={()=>{generation.current++;setRows([]);setMapping({});setSource('');setError('');onInvalidate();}}>Clear survey file</button></>}</section>;
}
