import React,{useEffect,useState} from 'react';

type InstallEvent=Event & {prompt:()=>Promise<void>;userChoice:Promise<{outcome:string}>};

export function PortalPwa(){
 const [install,setInstall]=useState<InstallEvent|null>(null),[installed,setInstalled]=useState(false),[online,setOnline]=useState(navigator.onLine!==false),[message,setMessage]=useState(''),[busy,setBusy]=useState(false);
 useEffect(()=>{
  const manifest=document.createElement('link');manifest.rel='manifest';manifest.href='/portal/manifest.webmanifest';document.head.appendChild(manifest);
  const media=window.matchMedia?.('(display-mode: standalone)');
  const refreshInstalled=()=>setInstalled(media?.matches||(navigator as Navigator & {standalone?:boolean}).standalone===true);
  const offer=(event:Event)=>{event.preventDefault();setInstall(event as InstallEvent);};
  const complete=()=>{setInstall(null);setInstalled(true);};
  const connection=()=>setOnline(navigator.onLine!==false);
  refreshInstalled();window.addEventListener('beforeinstallprompt',offer);window.addEventListener('appinstalled',complete);window.addEventListener('online',connection);window.addEventListener('offline',connection);media?.addEventListener?.('change',refreshInstalled);
  if('serviceWorker' in navigator&&window.isSecureContext)navigator.serviceWorker.register('/portal/sw.js',{scope:'/portal',updateViaCache:'none'}).catch(()=>setMessage('Phone installation is temporarily unavailable. You can keep using the portal in your browser.'));
  return()=>{manifest.remove();window.removeEventListener('beforeinstallprompt',offer);window.removeEventListener('appinstalled',complete);window.removeEventListener('online',connection);window.removeEventListener('offline',connection);media?.removeEventListener?.('change',refreshInstalled);};
 },[]);
 async function installApp(){if(!install)return;setBusy(true);setMessage('');try{await install.prompt();const choice=await install.userChoice;if(choice.outcome==='accepted')setMessage('Follow your browser’s installation steps.');setInstall(null);}catch{setMessage('Installation did not finish. Try your browser’s Install app or Add to Home Screen menu.');}finally{setBusy(false);}}
 return <section className="p-panel" aria-label="Phone access">
  {!online&&<p role="status">You are offline. Reconnect before recording or uploading work. No work is saved offline.</p>}
  {installed?<p className="p-muted">Portal installed on this device.</p>:install?<button type="button" disabled={busy} onClick={installApp}>{busy?'Opening installation…':'Install portal on this device'}</button>:<details><summary>Add portal to your phone</summary><p>On iPhone or iPad, open this page in Safari, choose Share, then Add to Home Screen. On Android, use your browser’s Install app or Add to Home Screen menu.</p></details>}
  {message&&<p role="status">{message}</p>}
 </section>;
}

export function CameraEvidence({upload,busy}:{upload:(event:React.FormEvent<HTMLFormElement>)=>Promise<void>;busy:boolean}){
 return <form className="p-form" onSubmit={upload}><label className="p-field"><span>Take an evidence photo</span><input type="file" name="file" accept="image/jpeg,image/png" capture="environment" required disabled={busy}/></label><p className="p-muted">Use your phone camera or choose a JPG/PNG photo, up to 10 MB. Upload the photo before leaving this project. Technician photos remain private until administrator publication.</p><button className="p-primary" disabled={busy}>{busy?'Uploading…':'Upload evidence photo'}</button></form>;
}
