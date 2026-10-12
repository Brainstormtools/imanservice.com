const origins=new Set(['https://www.imanservice.com','https://imanservice.com']);
const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
export function accountHandler(db:any,url:string){return async(req:Request)=>{
 const origin=req.headers.get('Origin')||'',headers={'Content-Type':'application/json','Cache-Control':'no-store',...(origins.has(origin)?{'Access-Control-Allow-Origin':origin,'Vary':'Origin'}:{}),'Access-Control-Allow-Headers':'authorization,apikey,content-type,x-client-info','Access-Control-Allow-Methods':'POST,OPTIONS'};
 const reply=(status:number,body:any)=>new Response(JSON.stringify(body),{status,headers});
 if(origin&&!origins.has(origin))return reply(403,{error:'Portal origin required'});
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers});if(req.method!=='POST')return reply(405,{error:'POST required'});
 const token=req.headers.get('Authorization')?.match(/^Bearer (\S+)$/)?.[1];if(!token)return reply(401,{error:'Sign in required'});
 try{
  const auth=await db.auth.getUser(token);if(auth.error||!auth.data?.user)return reply(401,{error:'Sign in required'});const actor=auth.data.user.id;
  const profile=await db.from('profiles').select('id,role,active').eq('id',actor).maybeSingle();if(profile.error||profile.data?.role!=='admin'||!profile.data.active)return reply(403,{error:'Active administrator required'});
  if(Number(req.headers.get('Content-Length')||0)>4096)return reply(413,{error:'Account request too large'});const raw=await req.text();if(raw.length>4096)return reply(413,{error:'Account request too large'});let b:any;try{b=JSON.parse(raw);}catch{return reply(400,{error:'Valid account request required'});}let target:string;
  if(b.action==='create'){
   if(!uuid.test(b.request_id||''))return reply(400,{error:'Valid request ID required'});
   const reserved=await db.rpc('reserve_portal_account',{p_actor:actor,p_id:b.request_id,p_details:b.details});if(reserved.error)return reply(400,{error:'Check name, email, role, company and staff membership. A retry must keep the same details.'});const request=Array.isArray(reserved.data)?reserved.data[0]:reserved.data;if(!request?.target_id)return reply(500,{error:'Account reservation unavailable'});target=request.target_id;
   let existing=await db.auth.admin.getUserById(target);
   if(!existing.data?.user){const created=await db.auth.admin.createUser({id:target,email:request.details.email,email_confirm:false,app_metadata:{portal_request:b.request_id}});if(created.error){existing=await db.auth.admin.getUserById(target);if(!existing.data?.user)return reply(409,{error:'Account could not be created. The email may already belong to another account. Existing accounts are never reassigned by creation.'});}else existing=created;}
   if(existing.data.user.id!==target||existing.data.user.app_metadata?.portal_request!==b.request_id||existing.data.user.email?.toLowerCase()!==request.details.email)return reply(409,{error:'Authentication account does not match this request'});
   const complete=await db.rpc('complete_portal_account',{p_actor:actor,p_id:b.request_id});if(complete.error)return reply(409,{error:'Account setup is pending. Retry the same request; no existing account was reassigned.'});
  }else if(b.action==='password_link'&&uuid.test(b.user_id||'')){target=b.user_id;}else return reply(400,{error:'Valid account action required'});
  const active=await db.from('profiles').select('id,active').eq('id',target).maybeSingle();if(active.error||!active.data?.active)return reply(400,{error:'Enable the existing account before issuing a password link'});
  const user=await db.auth.admin.getUserById(target);if(user.error||!user.data?.user?.email)return reply(400,{error:'Account email unavailable'});
  // Generate only: no inviteUserByEmail/resetPasswordForEmail and no message delivery.
  const link=await db.auth.admin.generateLink({type:'recovery',email:user.data.user.email,options:{redirectTo:'https://www.imanservice.com/portal'}});
  if(link.error||link.data?.user?.id!==target)return reply(502,{error:'Account saved, but password link unavailable. Retry from the existing account.'});
  const action=new URL(link.data.properties.action_link);if(action.origin!==new URL(url).origin||action.pathname!=='/auth/v1/verify')return reply(502,{error:'Password link unavailable'});
  const audit=await db.rpc('record_portal_password_link',{p_actor:actor,p_user:target});if(audit.error)return reply(403,{error:'Access changed; password link not released'});
  return reply(200,{user_id:target,email:user.data.user.email,password_link:action.href});
 }catch{return reply(500,{error:'Account service unavailable. Retry without changing the request.'});}
};}
