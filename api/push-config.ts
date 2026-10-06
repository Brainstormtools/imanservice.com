export default function handler(req:any,res:any){
 res.setHeader('Cache-Control','no-store');
 if(req.method!=='GET')return res.status(405).json({error:'GET required'});
 const key=process.env.WEB_PUSH_PUBLIC_KEY||'';
 return res.status(200).json({publicKey:/^[A-Za-z0-9_-]{87}$/.test(key)?key:null});
}
