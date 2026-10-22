import {createClient} from '@supabase/supabase-js';
import {createHmac} from 'node:crypto';
import {IntakeError,readIntakeBody} from '../server/website-lead-intake.js';
const fields=['name','email','phone','company','city','country','message','form','campaign','utm','tags'];
export default async function handler(req:any,res:any){
 res.setHeader('Cache-Control','no-store');res.setHeader('X-Content-Type-Options','nosniff');
 if(req.method!=='POST'){res.setHeader('Allow','POST');return res.status(405).json({accepted:false,message:'POST JSON required.'});}
 const authorization=req.headers?.authorization,match=typeof authorization==='string'?/^Bearer (iman_lead_[0-9a-f]{64})$/.exec(authorization):null;
 if(!match)return res.status(401).json({accepted:false,message:'A valid intake API key is required.'});
 const event=req.headers?.['idempotency-key'];
 if(typeof event!=='string'||event.trim().length<1||event.trim().length>200||/[\x00-\x1f\x7f]/.test(event))return res.status(400).json({accepted:false,message:'A stable Idempotency-Key of 1–200 characters is required.'});
 if(typeof req.headers?.['content-type']!=='string'||!/^application\/json(?:\s*;|\s*$)/i.test(req.headers['content-type']))return res.status(415).json({accepted:false,message:'Content-Type application/json required.'});
 try{
  const body=await readIntakeBody(req),payload=Object.fromEntries(fields.filter(k=>body[k]!==undefined).map(k=>[k,body[k]]));
  if(!process.env.SUPABASE_URL||!process.env.SUPABASE_SERVICE_ROLE_KEY)throw new IntakeError(503,'Lead intake is temporarily unavailable. Retry the same event later.');
  const key=match[1],fingerprint=createHmac('sha256',process.env.SUPABASE_SERVICE_ROLE_KEY).update('api-source:'+key).digest('hex'),configured=Number(process.env.CRM_LEAD_API_WINDOW_LIMIT||100),limit=Number.isInteger(configured)&&configured>=1&&configured<=1000?configured:100;
  const db=createClient(process.env.SUPABASE_URL,process.env.SUPABASE_SERVICE_ROLE_KEY,{auth:{persistSession:false,autoRefreshToken:false}});
  const {error}=await db.rpc('capture_api_crm_lead',{p_key:key,p_event:event.trim(),p_data:payload,p_fingerprint:fingerprint,p_limit:limit});
  if(error){const known:Record<string,[number,string]>={P0401:[401,'Invalid or revoked intake API key.'],P0409:[409,'That Idempotency-Key already has different enquiry data.'],P0422:[422,'Check the enquiry fields and use an international phone number or valid email.'],P0429:[429,'Source intake limit reached. Retry this event later.']};const mapped=known[error.code];if(mapped)return res.status(mapped[0]).json({accepted:false,message:mapped[1]});throw new Error('Unconfirmed database receipt');}
  return res.status(202).json({accepted:true,requestId:event.trim()});
 }catch(error){if(error instanceof IntakeError)return res.status(error.status).json({accepted:false,message:error.message});return res.status(503).json({accepted:false,message:'Lead intake could not be confirmed. Retry the same event later.'});}
}
