import {createClient} from '@supabase/supabase-js';
import {timingSafeEqual} from 'node:crypto';
const safeEqual=(a:string,b:string)=>a.length===b.length&&timingSafeEqual(Buffer.from(a),Buffer.from(b));
export function configuredChannels(env:NodeJS.ProcessEnv){
 const channels:string[]=[];
 if(env.NOTIFICATIONS_ENABLED!=='true')return channels;
 if(env.RESEND_API_KEY&&env.NOTIFICATION_FROM_EMAIL)channels.push('email');
 if(env.TWILIO_ACCOUNT_SID&&env.TWILIO_AUTH_TOKEN){
  if(env.TWILIO_SMS_FROM)channels.push('sms');
  if(env.TWILIO_WHATSAPP_FROM&&env.TWILIO_WHATSAPP_CONTENT_SID)channels.push('whatsapp');
 }
 return channels;
}
export async function submitAlert(channel:string,destination:string,id:string,env:NodeJS.ProcessEnv,fetcher:typeof fetch=fetch){
 const portal=new URL(env.PORTAL_PUBLIC_URL||'https://www.imanservice.com/portal');
 if(portal.protocol!=='https:')throw new Error('HTTPS portal URL required');
 const text=`i Man Service: You have a service update. Sign in to your portal: ${portal.href}`;
 let url:string,init:RequestInit;
 if(channel==='email'){
  url='https://api.resend.com/emails';init={method:'POST',headers:{Authorization:`Bearer ${env.RESEND_API_KEY}`,'Content-Type':'application/json','Idempotency-Key':`portal-alert-${id}`},body:JSON.stringify({from:env.NOTIFICATION_FROM_EMAIL,to:[destination],subject:'i Man Service portal update',text})};
 }else{
  if(!/^AC[0-9a-f]{32}$/i.test(env.TWILIO_ACCOUNT_SID||''))throw new Error('Invalid Twilio account configuration');
  url=`https://api.twilio.com/2010-04-01/Accounts/${env.TWILIO_ACCOUNT_SID}/Messages.json`;
  const body=new URLSearchParams({To:channel==='whatsapp'?`whatsapp:${destination}`:destination,From:channel==='whatsapp'?env.TWILIO_WHATSAPP_FROM!:env.TWILIO_SMS_FROM!});
  if(channel==='whatsapp'){body.set('ContentSid',env.TWILIO_WHATSAPP_CONTENT_SID!);}else body.set('Body',text);
  init={method:'POST',headers:{Authorization:`Basic ${Buffer.from(`${env.TWILIO_ACCOUNT_SID}:${env.TWILIO_AUTH_TOKEN}`).toString('base64')}`,'Content-Type':'application/x-www-form-urlencoded'},body:body.toString()};
 }
 const response=await fetcher(url,{...init,signal:AbortSignal.timeout(10000)});
 if(!response.ok)return {status:response.status>=500?'Unknown':'Failed',last_error:`Provider returned HTTP ${response.status}. ${response.status>=500?'Reconcile provider logs before resending.':'Check provider configuration or destination.'}`};
 const body=await response.json(); const providerId=body.id||body.sid;
 if(!providerId)return {status:'Unknown',last_error:'Provider response missing message ID; reconcile provider logs.'};
 return {status:'Submitted',provider_id:String(providerId),last_error:null};
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
  checked(await db.rpc('queue_due_alerts'));
  const channels=configuredChannels(process.env);
  const rows=checked(await db.rpc('claim_notifications',{p_channels:channels}))||[];
  let submitted=0;
  // Sequential claims are durable. Unknown outcomes are never automatically resent.
  for(const row of rows){
   let outcome:any;
   try{
    const profile=checked(await db.from('profiles').select('active,role,company_id').eq('id',row.user_id).maybeSingle());
    const pref=checked(await db.from('notification_preferences').select('*').eq('id',row.user_id).maybeSingle());
    const allowed=profile?.active&&!(profile.role==='team'&&['Invoice issued','Payment awaiting review','Payment review updated'].includes(row.event_type))&&pref?.[`${row.channel}_enabled`]&&(profile.role!=='client'||profile.company_id===row.company_id);
    if(!allowed)outcome={status:'Cancelled',last_error:'Recipient access or preference changed'};
    else{
     let destination=pref.phone;
     if(row.channel==='email'){
      const {data,error}=await db.auth.admin.getUserById(row.user_id);
      if(error)throw new Error('Account lookup failed');
      destination=data.user?.email_confirmed_at?data.user.email:null;
     }
     if(!destination)outcome={status:'Failed',last_error:'Verified email or phone is missing'};
     else outcome=await submitAlert(row.channel,destination,row.id,process.env);
    }
   }catch{outcome={status:'Unknown',last_error:'Submission outcome uncertain. Check provider logs before resending.'};}
   checked(await db.from('notifications').update(outcome).eq('id',row.id).eq('status','Processing'));
   if(outcome.status==='Submitted')submitted++;
  }
  return res.status(200).json({generated,processed:rows.length,submitted,configuredChannels:channels});
 }catch{return res.status(500).json({error:'Worker failed. Check database configuration and notification log.'});}
}
