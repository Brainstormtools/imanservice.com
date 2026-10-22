import {createHmac,timingSafeEqual} from 'node:crypto';
import {IntakeError,internationalPhone} from './website-lead-intake.js';

const id=/^[0-9]{1,40}$/;
const providerId=(v:unknown)=>typeof v==='string'&&id.test(v)||typeof v==='number'&&Number.isSafeInteger(v)&&v>=0;
const fields=['full_name','first_name','last_name','email','phone_number','company_name','city','country'];
export function metaConfiguration(env:NodeJS.ProcessEnv){
 if(!env.META_APP_SECRET||!env.META_WEBHOOK_VERIFY_TOKEN||!/^v[0-9]{1,3}\.0$/.test(env.META_GRAPH_API_VERSION||''))throw new IntakeError(503,'Meta intake is not configured.');
 let pages:any;try{pages=JSON.parse(env.META_LEAD_PAGES_JSON||'');}catch{throw new IntakeError(503,'Meta intake is not configured.');}
 if(!pages||typeof pages!=='object'||Array.isArray(pages)||Object.keys(pages).length===0||Object.keys(pages).length>100)throw new IntakeError(503,'Meta intake is not configured.');
 for(const [page,config]of Object.entries(pages) as [string,any][]){
  if(!id.test(page)||!config||typeof config.accessToken!=='string'||!config.accessToken||config.accessToken.length>4096||/[\r\n]/.test(config.accessToken))throw new IntakeError(503,'Meta intake is not configured.');
  if(config.fieldMap!==undefined&&(!config.fieldMap||typeof config.fieldMap!=='object'||Array.isArray(config.fieldMap)||Object.entries(config.fieldMap).some(([key,value])=>!fields.includes(key)||typeof value!=='string'||value.length<1||value.length>100)))throw new IntakeError(503,'Meta intake is not configured.');
  if(config.formNames!==undefined&&(!config.formNames||typeof config.formNames!=='object'||Array.isArray(config.formNames)||Object.entries(config.formNames).some(([key,value])=>!id.test(key)||typeof value!=='string'||!value.trim()||value.length>100)))throw new IntakeError(503,'Meta intake is not configured.');
 }
 return {secret:env.META_APP_SECRET,verify:env.META_WEBHOOK_VERIFY_TOKEN,version:env.META_GRAPH_API_VERSION!,pages};
}
export function safeEqual(a:string,b:string){const left=Buffer.from(a),right=Buffer.from(b);return left.length===right.length&&timingSafeEqual(left,right);}
export async function rawMetaBody(req:any){
 let bytes:Buffer;
 if(Buffer.isBuffer(req.body))bytes=req.body;
 else if(typeof req.body==='string')bytes=Buffer.from(req.body);
 else if(req.body!==undefined)throw new IntakeError(400,'Original request bytes required.');
 else{const chunks:Buffer[]=[];let size=0;for await(const chunk of req){const b=Buffer.from(chunk);size+=b.length;if(size>131072)throw new IntakeError(413,'Webhook batch is too large.');chunks.push(b);}bytes=Buffer.concat(chunks);}
 if(bytes.length>131072)throw new IntakeError(413,'Webhook batch is too large.');return bytes;
}
export function signedMetaEvents(bytes:Buffer,signature:unknown,secret:string){
 if(typeof signature!=='string'||!/^sha256=[0-9a-f]{64}$/.test(signature)||!safeEqual(signature.slice(7),createHmac('sha256',secret).update(bytes).digest('hex')))throw new IntakeError(401,'Invalid webhook signature.');
 let data:any;try{data=JSON.parse(bytes.toString('utf8'));}catch{throw new IntakeError(400,'Invalid webhook JSON.');}
 if(data?.object!=='page'||!Array.isArray(data.entry))throw new IntakeError(400,'Page lead webhook required.');
 if(data.entry.length>20)throw new IntakeError(413,'Webhook batch is too large.');
 const events:{page:string;lead:string;form:string;ad:string;adgroup:string}[]=[];
 for(const entry of data.entry){
  if(!entry||!providerId(entry.id)||!Array.isArray(entry.changes))throw new IntakeError(400,'Invalid webhook entry.');
  if(entry.changes.length>20)throw new IntakeError(413,'Webhook batch is too large.');
  for(const change of entry.changes){
   if(change?.field!=='leadgen')continue;
   const v=change.value;if(!v||!providerId(v.leadgen_id)||v.page_id!==undefined&&String(v.page_id)!==String(entry.id))throw new IntakeError(400,'Invalid lead identity.');
   for(const key of ['form_id','ad_id','adgroup_id'])if(v[key]!==undefined&&!providerId(v[key]))throw new IntakeError(400,'Invalid acquisition identity.');
   events.push({page:String(entry.id),lead:String(v.leadgen_id),form:String(v.form_id||''),ad:String(v.ad_id||''),adgroup:String(v.adgroup_id||'')});
  }
 }
 if(events.length>20)throw new IntakeError(413,'Webhook batch is too large.');
 return [...new Map(events.map(e=>[e.page+':'+e.lead,e])).values()];
}
export async function retrieveMetaLead(event:ReturnType<typeof signedMetaEvents>[number],configuration:ReturnType<typeof metaConfiguration>,fetcher:typeof fetch=fetch){
 const page=configuration.pages[event.page];if(!page)throw new IntakeError(503,'A webhook page is not connected.');
 const url=new URL(`https://graph.facebook.com/${configuration.version}/${event.lead}`);
 url.searchParams.set('fields','id,created_time,field_data,form_id,ad_id,adset_id,campaign_id,campaign_name,platform');
 url.searchParams.set('appsecret_proof',createHmac('sha256',configuration.secret).update(page.accessToken).digest('hex'));
 let response:Response;try{response=await fetcher(url,{headers:{Authorization:'Bearer '+page.accessToken},signal:AbortSignal.timeout(8000),redirect:'error'});}catch{throw new IntakeError(503,'Meta lead retrieval could not be confirmed.');}
 if(!response.ok)throw new IntakeError(503,'Meta lead retrieval could not be confirmed.');
 let text='';if(!response.body)throw new IntakeError(503,'Meta lead retrieval could not be confirmed.');
 const reader=response.body.getReader();let size=0;const chunks:Uint8Array[]=[];
 try{while(true){const {done,value}=await reader.read();if(done)break;size+=value.byteLength;if(size>65536){await reader.cancel();throw Error('size');}chunks.push(value);}text=Buffer.concat(chunks).toString('utf8');}catch{throw new IntakeError(503,'Meta lead retrieval could not be confirmed.');}finally{reader.releaseLock();}
 let lead:any;try{lead=JSON.parse(text);}catch{throw new IntakeError(503,'Meta lead retrieval could not be confirmed.');}
 if(!providerId(lead?.id)||String(lead?.id)!==event.lead||!Array.isArray(lead.field_data)||lead.field_data.length>100||lead.form_id!==undefined&&String(lead.form_id)!==event.form&&event.form!==''||lead.ad_id!==undefined&&event.ad!==''&&String(lead.ad_id)!==event.ad)throw new IntakeError(503,'Meta lead identity could not be confirmed.');
 for(const key of ['form_id','ad_id','adset_id','campaign_id'])if(lead[key]!==undefined&&!providerId(lead[key]))throw new IntakeError(503,'Meta acquisition identity could not be confirmed.');
 for(const [key,max]of [['campaign_name',300],['platform',100],['created_time',100]] as const)if(lead[key]!==undefined&&(typeof lead[key]!=='string'||lead[key].length>max))throw new IntakeError(503,'Meta acquisition fields could not be confirmed.');
 const actual:Record<string,string[]>=Object.create(null);
 for(const field of lead.field_data){if(typeof field?.name!=='string'||field.name.length<1||field.name.length>100||!Array.isArray(field.values)||field.values.length>20||field.values.some((v:any)=>typeof v!=='string'||v.length>8000)||Object.hasOwn(actual,field.name))throw new IntakeError(503,'Meta lead fields could not be confirmed.');Object.defineProperty(actual,field.name,{value:field.values,enumerable:true});}
 const value=(key:string)=>{const values=actual[page.fieldMap?.[key]||key];return values?.length===1?values[0].trim():'';};
 const name=value('full_name')||[value('first_name'),value('last_name')].filter(Boolean).join(' '),rawPhone=value('phone_number');
 const formId=event.form||String(lead.form_id||'');
 const data={name,email:value('email').toLowerCase(),phone:internationalPhone(rawPhone),company:value('company_name'),city:value('city'),country:value('country'),form:page.formNames?.[formId]||formId,campaign:lead.campaign_name||String(lead.campaign_id||''),message:rawPhone&&!internationalPhone(rawPhone)?'Original phone (country code not inferred): '+rawPhone:''};
 // Only explicit provider identities and original field values; no tokens, guessed campaign or platform.
 const provider={page_id:event.page,lead_id:event.lead,form_id:formId,ad_id:event.ad||String(lead.ad_id||''),adgroup_id:event.adgroup,adset_id:String(lead.adset_id||''),campaign_id:String(lead.campaign_id||''),campaign_name:lead.campaign_name||'',platform:lead.platform||'',created_time:lead.created_time||'',field_data:actual};
 if(Buffer.byteLength(JSON.stringify({data,provider}))>60000)throw new IntakeError(503,'Meta lead fields exceed the supported receipt size.');
 return {data,provider};
}
