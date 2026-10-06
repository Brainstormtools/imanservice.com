import {createClient} from '@supabase/supabase-js';
import {deliverPortalPush} from './delivery.ts';

export async function handlePush(req,create=createClient,deliver=deliverPortalPush,env=Deno.env){
 const headers={'Content-Type':'application/json','Cache-Control':'no-store'};
 const reply=(status,data)=>new Response(JSON.stringify(data),{status,headers});
 if(req.method!=='POST')return reply(405,{error:'POST required'});
 const authorization=req.headers.get('Authorization')||'';
 if(!/^Bearer [A-Za-z0-9_-]{43}$/.test(authorization))return reply(401,{error:'Unauthorized'});
 const db=create(env.get('SUPABASE_URL'),env.get('SUPABASE_SERVICE_ROLE_KEY'),{auth:{persistSession:false,autoRefreshToken:false}});
 try{
  // Custom authentication happens before claims or any provider request.
  const config=await db.rpc('portal_push_worker_config',{p_secret:authorization.slice(7)});
  if(config.error)throw new Error('Configuration unavailable');
  if(!config.data)return reply(401,{error:'Unauthorized'});
  const result=await deliver(db,{WEB_PUSH_PUBLIC_KEY:config.data.publicKey,WEB_PUSH_PRIVATE_KEY:config.data.privateKey});
  return reply(200,result);
 }catch{return reply(500,{error:'Push worker failed'});}
}
if(typeof Deno!=='undefined')Deno.serve(req=>handlePush(req));
