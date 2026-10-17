import {charterPDF} from '../server/charter-pdf-service.js';
import {createClient} from '@supabase/supabase-js';
import {isIP} from 'node:net';
export const uuid=(v:unknown)=>typeof v==='string'&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);
// Vercel overwrites this platform header; never accept IP/account/time from JSON or generic proxy headers.
// https://vercel.com/docs/headers/request-headers#x-vercel-forwarded-for
export function approvalHandler(env:NodeJS.ProcessEnv=process.env,clientFactory:typeof createClient=createClient,archive=charterPDF){return async(req:any,res:any)=>{
 res.setHeader('Cache-Control','private, no-store');res.setHeader('X-Content-Type-Options','nosniff');
 if(req.method!=='POST'){res.setHeader('Allow','POST');return res.status(405).json({error:'POST required'});}
 const authorization=req.headers?.authorization;
 if(typeof authorization!=='string'||!/^Bearer [^\s]+$/.test(authorization))return res.status(401).json({error:'Signed-in client required'});
 const url=env.VITE_SUPABASE_URL,key=env.VITE_SUPABASE_ANON_KEY,secret=env.CHARTER_APPROVAL_GATEWAY_TOKEN;
 if(env.VERCEL!=='1'||!url||!key||!secret||secret.length<32)return res.status(503).json({error:'Approval endpoint is not configured'});
 const ip=req.headers?.['x-vercel-forwarded-for'];if(typeof ip!=='string'||!isIP(ip))return res.status(503).json({error:'Trusted request IP unavailable'});
 let b=req.body;try{if(typeof b==='string'){if(Buffer.byteLength(b)>12000)throw Error();b=JSON.parse(b);}}catch{return res.status(400).json({error:'Invalid approval request'});}
 if(!b||typeof b!=='object'||Array.isArray(b)||Object.keys(b).sort().join(',')!=='consent,full_name,id,note,publication_id,version'||!uuid(b.id)||!uuid(b.publication_id)||!Number.isInteger(b.version)||b.version<1||b.consent!==true||typeof b.full_name!=='string'||b.full_name.trim().length<3||b.full_name.trim().length>160||typeof b.note!=='string'||b.note.trim().length>2000)return res.status(400).json({error:'Exact publication, agreement and actual full name required'});
 try{
  const client=clientFactory(url,key,{auth:{persistSession:false,autoRefreshToken:false},global:{headers:{Authorization:authorization}}});
  const {data,error}=await client.auth.getUser(authorization.slice(7));if(error||!data.user)return res.status(401).json({error:'Signed-in client required'});
  const result=await client.rpc('approve_client_charter',{p_id:b.id,p_publication:b.publication_id,p_version:b.version,p_consent:true,p_full_name:b.full_name,p_note:b.note,p_request_ip:ip,p_gateway_token:secret});
  if(result.error)return res.status(409).json({error:'Approval was not saved. Refresh the charter and check your signing authority/version before retrying.'});
  try{const pdf=await archive(client,result.data,secret);return res.status(200).json({id:result.data,pdf_status:'Archived',sha256:pdf.sha256});}catch{console.error('Charter approval saved; PDF generation pending retry');return res.status(200).json({id:result.data,pdf_status:'Pending generation'});}
 }catch{console.error('Charter approval endpoint failed');return res.status(503).json({error:'Approval unavailable; retry the unchanged request after refreshing access'});}
};}
export default approvalHandler();
