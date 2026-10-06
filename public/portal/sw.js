/* Keep privileged pages, API responses, credentials and evidence out of Cache Storage. */
const CACHE='iman-portal-shell-v1';
const OFFLINE='/portal/offline.html';
const SAFE=[OFFLINE,'/portal/icons/icon-192.png','/portal/icons/icon-512.png'];
self.addEventListener('install',event=>event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(SAFE))));
self.addEventListener('activate',event=>event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(key=>key.startsWith('iman-portal-shell-')&&key!==CACHE).map(key=>caches.delete(key)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',event=>{
 const request=event.request,url=new URL(request.url);
 if(request.method!=='GET'||url.origin!==self.location.origin)return;
 if(request.mode==='navigate'&&(url.pathname==='/portal'||url.pathname.startsWith('/portal/'))){
  event.respondWith(fetch(request).catch(()=>caches.match(OFFLINE).then(response=>response||new Response('Reconnect to use your portal.',{status:503,headers:{'Content-Type':'text/plain'}}))));return;
 }
 if(SAFE.includes(url.pathname)&&!url.search)event.respondWith(caches.match(url.pathname).then(response=>response||fetch(request)));
});
self.addEventListener('push',event=>{
 // Always show generic text. Never trust payload text, links or account details.
 event.waitUntil(self.registration.showNotification('i Man Service Portal',{body:'You have a portal reminder. Sign in to review your updates.',icon:'/portal/icons/icon-192.png',badge:'/portal/icons/icon-192.png',tag:'iman-portal-reminder',data:{url:'/portal?view=notifications'}}));
});
self.addEventListener('notificationclick',event=>{
 event.notification.close();
 const url=new URL('/portal?view=notifications',self.location.origin).href;
 event.waitUntil(self.clients.matchAll({type:'window',includeUncontrolled:true}).then(async clients=>{
  for(const client of clients){const current=new URL(client.url);if(current.origin===self.location.origin&&(current.pathname==='/portal'||current.pathname.startsWith('/portal/'))){await client.navigate(url);return client.focus();}}
  return self.clients.openWindow(url);
 }));
});
