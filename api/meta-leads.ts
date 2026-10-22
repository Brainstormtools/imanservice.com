import {createClient} from '@supabase/supabase-js';
import {IntakeError} from '../server/website-lead-intake.js';
import {metaConfiguration,rawMetaBody,retrieveMetaLead,safeEqual,signedMetaEvents} from '../server/meta-lead-intake.js';
export const config={api:{bodyParser:false}};
export default async function handler(req:any,res:any){
 res.setHeader('Cache-Control','no-store');res.setHeader('X-Content-Type-Options','nosniff');
 if(!['GET','POST'].includes(req.method)){res.setHeader('Allow','GET, POST');return res.status(405).json({accepted:false});}
 try{
  const c=metaConfiguration(process.env);
  if(req.method==='GET'){
   const q=req.query||{};if(q['hub.mode']!=='subscribe'||typeof q['hub.verify_token']!=='string'||!safeEqual(q['hub.verify_token'],c.verify)||typeof q['hub.challenge']!=='string'||q['hub.challenge'].length>200)return res.status(403).json({accepted:false});
   res.setHeader('Content-Type','text/plain; charset=utf-8');return res.status(200).send(q['hub.challenge']);
  }
  const events=signedMetaEvents(await rawMetaBody(req),req.headers?.['x-hub-signature-256'],c.secret);
  if(!process.env.SUPABASE_URL||!process.env.SUPABASE_SERVICE_ROLE_KEY)throw new IntakeError(503,'Meta intake is temporarily unavailable.');
  if(events.some(e=>!c.pages[e.page]))throw new IntakeError(503,'A webhook page is not connected.');
  const db=createClient(process.env.SUPABASE_URL,process.env.SUPABASE_SERVICE_ROLE_KEY,{auth:{persistSession:false,autoRefreshToken:false}});
  // Four bounded workers keep the largest accepted batch within the function budget.
  let next=0;const results=await Promise.allSettled(Array.from({length:Math.min(events.length,4)},async()=>{while(next<events.length){const event=events[next++],{data,provider}=await retrieveMetaLead(event,c);const {error}=await db.rpc('capture_meta_crm_lead',{p_page:event.page,p_event:event.lead,p_data:data,p_provider:provider});if(error)throw new IntakeError(503,'Meta receipt could not be confirmed.');}}));
  if(results.some(r=>r.status==='rejected'))throw new IntakeError(503,'Some Meta receipts could not be confirmed. Retry the batch.');
  return res.status(200).json({accepted:true});
 }catch(error){return res.status(error instanceof IntakeError?error.status:503).json({accepted:false,message:error instanceof IntakeError?error.message:'Meta receipt could not be confirmed.'});}
}
