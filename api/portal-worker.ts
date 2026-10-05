import {createClient} from '@supabase/supabase-js';
import {timingSafeEqual} from 'node:crypto';
const safeEqual=(a:string,b:string)=>a.length===b.length&&timingSafeEqual(Buffer.from(a),Buffer.from(b));
// This release intentionally has no outbound notification channels.
export function configuredChannels(_env:NodeJS.ProcessEnv){return [] as string[];}
export async function submitAlert(_channel:string,_destination:string,_id:string,_env:NodeJS.ProcessEnv,_fetcher:typeof fetch=fetch){
 throw new Error('External email, SMS and WhatsApp delivery is excluded');
}
export default async function handler(req:any,res:any){
 res.setHeader('Cache-Control','no-store');
 if(req.method!=='GET'&&req.method!=='POST')return res.status(405).json({error:'GET or POST required'});
 const secret=process.env.CRON_SECRET||'';const authorization=typeof req.headers.authorization==='string'?req.headers.authorization:'';
 if(secret.length<32||!safeEqual(authorization,`Bearer ${secret}`))return res.status(401).json({error:'Unauthorized'});
 if(!process.env.SUPABASE_SERVICE_ROLE_KEY||!process.env.SUPABASE_URL)return res.status(503).json({error:'Server database connection not configured'});
 const db=createClient(process.env.SUPABASE_URL,process.env.SUPABASE_SERVICE_ROLE_KEY,{auth:{persistSession:false,autoRefreshToken:false}});
 const checked=(r:any)=>{if(r.error)throw new Error('Database operation failed');return r.data;};
 try{
  const generated=checked(await db.rpc('generate_maintenance'));
  const reminders=checked(await db.rpc('queue_portal_reminders'));
  return res.status(200).json({generated,reminders,configuredChannels:[]});
 }catch{return res.status(500).json({error:'Worker failed. Check database configuration and notification log.'});}
}
