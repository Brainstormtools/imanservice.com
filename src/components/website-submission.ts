// Retain one identity for an unchanged retry; editing the payload starts a new enquiry.
export function websiteSubmission(previous:{payload:string;requestId:string}|null, payload:unknown){
 const serialized=JSON.stringify(payload);
 return previous?.payload===serialized?previous:{payload:serialized,requestId:crypto.randomUUID()};
}
export function websiteAcquisition(){
 const query=new URLSearchParams(window.location.search);
 return Object.fromEntries(['utm_source','utm_medium','utm_campaign','utm_term','utm_content'].flatMap(key=>query.has(key)?[[key,query.get(key)!.slice(0,300)]]:[]));
}
