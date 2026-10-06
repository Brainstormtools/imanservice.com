import webpush from 'web-push';

export function safePushEndpoint(value:string){try{const u=new URL(value);return u.protocol==='https:'&&!u.username&&!u.password&&!u.port&&['fcm.googleapis.com','updates.push.services.mozilla.com','web.push.apple.com'].includes(u.hostname);}catch{return false;}}
export async function deliverPortalPush(db:any,env:Record<string,string|undefined>,send=webpush.sendNotification){
 if(!env.WEB_PUSH_PUBLIC_KEY||!env.WEB_PUSH_PRIVATE_KEY)return {configured:false,sent:0,retry:0,expired:0};
 const claimed=await db.rpc('claim_portal_push');if(claimed.error)throw new Error('Push queue failed');
 const result={configured:true,sent:0,retry:0,expired:0};
 // Four bounded provider requests at a time; the worker is limited to twenty claims.
 const rows=claimed.data||[];
 for(let i=0;i<rows.length;i+=4)await Promise.all(rows.slice(i,i+4).map(async(row:any)=>{
  let outcome:'sent'|'retry'|'expired'='expired';
  if(safePushEndpoint(row.endpoint))try{
   await send({endpoint:row.endpoint,keys:{p256dh:row.p256dh,auth:row.auth}},JSON.stringify({kind:'portal-reminder'}),{TTL:300,timeout:7000,urgency:'normal',vapidDetails:{subject:'https://www.imanservice.com',publicKey:env.WEB_PUSH_PUBLIC_KEY!,privateKey:env.WEB_PUSH_PRIVATE_KEY!}});outcome='sent';
  }catch(error:any){outcome=[400,404,410].includes(error.statusCode)?'expired':'retry';}
  const finished=await db.rpc('finish_portal_push',{p_subscription:row.subscription_id,p_reminder:row.reminder_id,p_lease:row.lease,p_outcome:outcome});if(finished.error)throw new Error('Push acknowledgement failed');result[outcome]++;
 }));
 return result;
}
