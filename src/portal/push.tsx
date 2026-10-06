import React,{useEffect,useState} from 'react';
import {db,check} from './client';

export async function disableDevicePush(removeAccount=true){
 if(!('serviceWorker' in navigator))return;
 const registration=await navigator.serviceWorker.getRegistration('/portal');if(!registration)return;
 const subscription=await registration.pushManager?.getSubscription();
 if(subscription){try{if(removeAccount&&db)check(await db.rpc('remove_portal_push',{p_endpoint:subscription.endpoint}));}finally{if(!await subscription.unsubscribe())throw new Error('Browser notifications could not be disabled. Disable them in browser settings.');}}
 for(const notification of await registration.getNotifications())notification.close();
}
export async function reconcileDevicePush(userId:string|null){
 if(!('serviceWorker' in navigator))return;
 const registration=await navigator.serviceWorker.getRegistration('/portal');
 const subscription=await registration?.pushManager?.getSubscription();if(!subscription)return;
 if(!userId){await disableDevicePush(false);return;}
 const response=await db!.from('portal_push_subscriptions').select('id,endpoint,expires_at').eq('user_id',userId).eq('endpoint',subscription.endpoint).maybeSingle();
 check(response);if(!response.data||new Date(response.data.expires_at).getTime()<=Date.now())await disableDevicePush(!!response.data);
}
function bytes(key:string){const raw=atob(key.replace(/-/g,'+').replace(/_/g,'/')+'='.repeat((4-key.length%4)%4));return Uint8Array.from(raw,c=>c.charCodeAt(0));}
export function DevicePush({userId,remindersEnabled}:{userId:string;remindersEnabled:boolean}){
 const supported='serviceWorker' in navigator&&'PushManager' in window&&'Notification' in window&&window.isSecureContext;
 const [enabled,setEnabled]=useState(false),[busy,setBusy]=useState(false),[message,setMessage]=useState('');
 useEffect(()=>{let live=true;if(supported)reconcileDevicePush(userId).then(()=>navigator.serviceWorker.getRegistration('/portal')).then(registration=>registration?.pushManager.getSubscription()).then(subscription=>{if(live)setEnabled(!!subscription);}).catch(()=>{if(live)setMessage('Device notification settings could not be checked. Try again.');});return()=>{live=false;};},[userId,supported]);
 async function toggle(){setBusy(true);setMessage('');try{
  if(enabled){await disableDevicePush();setEnabled(false);setMessage('Notifications disabled on this device.');return;}
  if(!remindersEnabled)throw new Error('Enable future portal reminders first.');
  // Browser permission is requested only from this explicit button click.
  const permission=await Notification.requestPermission();if(permission!=='granted')throw new Error(permission==='denied'?'Notifications are blocked. Change this site’s notification permission in browser settings.':'Notifications were not enabled.');
  const response=await fetch('/api/push-config',{cache:'no-store'});if(!response.ok)throw new Error('Device notifications are temporarily unavailable.');const config=await response.json();if(!config.publicKey)throw new Error('Device notifications are awaiting server setup.');
  const registration=await navigator.serviceWorker.getRegistration('/portal');if(!registration?.active)throw new Error('Phone installation is still preparing. Refresh this page and try again.');
  let subscription=await registration.pushManager.getSubscription();if(!subscription)subscription=await registration.pushManager.subscribe({userVisibleOnly:true,applicationServerKey:bytes(config.publicKey)});
  const keys=subscription.toJSON().keys;
  try{check(await db!.rpc('save_portal_push',{p_endpoint:subscription.endpoint,p_p256dh:keys?.p256dh,p_auth:keys?.auth}));}catch(error){await subscription.unsubscribe();throw error;}
  setEnabled(true);setMessage('Notifications enabled for future unread reminders on this device for 30 days. Enable again after expiry.');
 }catch(error:any){setMessage(error.message||'Device notification settings could not be changed.');}finally{setBusy(false);}}
 return <section className="p-panel"><h2>Notifications on this device</h2><p>Opt in to a general reminder to open your portal. Project, customer and salary details are kept out of device notifications.</p>{supported?<button type="button" onClick={toggle} disabled={busy||(!enabled&&!remindersEnabled)}>{busy?'Updating…':enabled?'Disable device notifications':'Enable device notifications'}</button>:<p>Use a browser that supports web push. On iPhone or iPad, add the portal to your Home Screen and open the installed app first.</p>}{!remindersEnabled&&<p>Future portal reminders are switched off.</p>}{message&&<p role="status">{message}</p>}</section>;
}
