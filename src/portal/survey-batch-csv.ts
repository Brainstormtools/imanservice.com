import {parseCSV} from './business-utils';
export const surveyBatchFields=['title','location','notes','method','evidence','unit','value','measured_on'];
export function parseSurveyBatch(text:string){
 if(new TextEncoder().encode(text).length>1000000)throw Error('CSV must be within 1 MB');
 const csv=parseCSV(text);if(csv.length<2||csv.length>101)throw Error('CSV requires headers and 1–100 measurement rows');
 const headers=csv[0].map(s=>s.trim());if(headers.length!==8||new Set(headers).size!==8||headers.some(h=>!surveyBatchFields.includes(h)))throw Error('Exact eight survey headers required; no unknown or duplicate headers');
 return csv.slice(1).map((cells,n)=>{if(cells.length!==8)throw Error(`Row ${n+1}: exactly eight columns required`);return Object.fromEntries(headers.map((h,i)=>[h,cells[i]]));});
}
// Editor text is not a spreadsheet export: preserve original minus signs and formula-like manual notes.
export function surveyBatchInput(rows:Record<string,string>[]){return [surveyBatchFields,...rows.map(r=>surveyBatchFields.map(k=>r[k]))].map(cells=>cells.map(s=>'"'+String(s??'').replaceAll('"','""')+'"').join(',')).join('\r\n');}
