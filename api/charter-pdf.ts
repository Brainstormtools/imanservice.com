import {createClient} from '@supabase/supabase-js';
import {charterPDF} from '../server/charter-pdf-service.js';
const uuid=(v:unknown)=>typeof v==='string'&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);
export function pdfHandler(env:NodeJS.ProcessEnv=process.env,factory:typeof createClient=createClient,archive=charterPDF){return async(req:any,res:any)=>{
 res.setHeader('Cache-Control','private, no-store');res.setHeader('X-Content-Type-Options','nosniff');
 if(req.method!=='POST'){res.setHeader('Allow','POST');return res.status(405).json({error:'POST required'});}
 const authorization=req.headers?.authorization;if(typeof authorization!=='string'||!/^Bearer [^\s]+$/.test(authorization))return res.status(401).json({error:'Signed-in project access required'});
 const url=env.VITE_SUPABASE_URL,key=env.VITE_SUPABASE_ANON_KEY,token=env.CHARTER_APPROVAL_GATEWAY_TOKEN;if(env.VERCEL!=='1'||!url||!key||!token)return res.status(503).json({error:'PDF endpoint is not configured'});
 let b=req.body;try{if(typeof b==='string')b=JSON.parse(b);}catch{return res.status(400).json({error:'Invalid PDF request'});}
 if(!b||typeof b!=='object'||Object.keys(b).sort().join(',')!=='action,approval_id'||!uuid(b.approval_id)||!['generate','download'].includes(b.action))return res.status(400).json({error:'Exact saved approval and PDF action required'});
 try{
  const client=factory(url,key,{auth:{persistSession:false,autoRefreshToken:false},global:{headers:{Authorization:authorization}}});const auth=await client.auth.getUser(authorization.slice(7));if(auth.error||!auth.data.user)return res.status(401).json({error:'Signed-in project access required'});
  const pdf=await archive(client,b.approval_id,token,b.action==='generate');
  if(b.action==='generate')return res.status(200).json({status:'Archived',sha256:pdf.sha256,created_at:pdf.created_at});
  res.setHeader('Content-Type','application/pdf');res.setHeader('Content-Disposition',`attachment; filename="approved-charter-${b.approval_id}.pdf"`);res.setHeader('X-Document-SHA256',pdf.sha256);return res.status(200).send(pdf.bytes);
 }catch{console.error('Charter PDF access or generation failed');return res.status(409).json({error:'PDF unavailable. Refresh your access, then retry generation or download; the approval remains saved.'});}
};}
export default pdfHandler();
