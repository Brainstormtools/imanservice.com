import {createHmac} from 'node:crypto';
import {createClient} from '@supabase/supabase-js';

export class IntakeError extends Error {
 constructor(public status:number, message:string){super(message);}
}
export const MAX_INTAKE_BYTES=32*1024;
export async function readIntakeBody(req:any){
 let body=req.body;
 if(body===undefined){
  const chunks:Buffer[]=[];let size=0;
  for await(const chunk of req){const b=Buffer.from(chunk);size+=b.length;if(size>MAX_INTAKE_BYTES)throw new IntakeError(413,'Request is too large.');chunks.push(b);}
  body=Buffer.concat(chunks).toString('utf8');
 }
 if(Buffer.isBuffer(body))body=body.toString('utf8');
 if(Buffer.byteLength(typeof body==='string'?body:JSON.stringify(body??{}))>MAX_INTAKE_BYTES)throw new IntakeError(413,'Request is too large.');
 if(typeof body==='string'){try{body=JSON.parse(body);}catch{throw new IntakeError(400,'Invalid JSON payload.');}}
 if(!body||typeof body!=='object'||Array.isArray(body))throw new IntakeError(400,'JSON object required.');
 return body;
}

// A country code cannot safely be inferred from a local number. Email remains required
// by the website forms, so the original phone is retained in the enquiry if ambiguous.
export function internationalPhone(value:string){const phone=value.replace(/[\s().-]/g,'');return /^\+[1-9][0-9]{7,14}$/.test(phone)?phone:'';}
export function acquisition(body:any){
 const result:Record<string,string>={};
 for(const key of ['utm_source','utm_medium','utm_campaign','utm_term','utm_content']){
  const value=body.acquisition?.[key];
  if(value!==undefined){if(typeof value!=='string'||value.length>300)throw new IntakeError(422,'Invalid campaign metadata.');result[key]=value.trim();}
 }
 if(JSON.stringify(result).length>1800)throw new IntakeError(422,'Campaign metadata is too large.');
 return result;
}
export async function recordWebsiteLead(form:'contact'|'proposal', body:any, lead:{name:string;email:string;phone:string;company:string;message:string}, request:any, env:NodeJS.ProcessEnv=process.env, factory:typeof createClient=createClient){
 if(typeof body.requestId!=='string'||!/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(body.requestId))throw new IntakeError(422,'A valid submission identity is required. Please reload the form.');
 const utm=acquisition(body);
 if(lead.message.length>8000 || lead.email.length>254)throw new IntakeError(422,'Please shorten the enquiry details and use a valid email address.');
 if(!env.SUPABASE_URL||!env.SUPABASE_SERVICE_ROLE_KEY)throw new IntakeError(503,'Enquiry recording is temporarily unavailable. Please retry or call +92 314 9020008.');
 try {
 const db=factory(env.SUPABASE_URL,env.SUPABASE_SERVICE_ROLE_KEY,{auth:{persistSession:false,autoRefreshToken:false}});
 const forwarded=request?.headers?.['x-forwarded-for'];
 const address=typeof forwarded==='string'?forwarded.split(',')[0].trim():request?.socket?.remoteAddress||'unknown';
 const fingerprint=createHmac('sha256',env.SUPABASE_SERVICE_ROLE_KEY).update(address).digest('hex');
 const configuredLimit=Number(env.WEBSITE_INTAKE_WINDOW_LIMIT||20);
 const limit=Number.isInteger(configuredLimit)&&configuredLimit>=1&&configuredLimit<=100?configuredLimit:20;
 const {error}=await db.rpc('capture_website_crm_lead_v2',{p_request:body.requestId,p_form:form,p_name:lead.name,p_email:lead.email.toLowerCase(),p_phone:internationalPhone(lead.phone),p_company:lead.company,p_message:lead.message,p_utm:utm,p_fingerprint:fingerprint,p_limit:limit});
 // Never disclose whether a contact exists or return database/provider errors publicly.
 if(error?.code==='P0429')throw new IntakeError(429,'Too many enquiries. Please wait a few minutes before submitting another.');
 if(error)throw error;
 } catch(error) {
  if(error instanceof IntakeError)throw error;
  throw new IntakeError(503,'Enquiry recording could not be confirmed. Retry the same submission or call +92 314 9020008.');
 }
}
