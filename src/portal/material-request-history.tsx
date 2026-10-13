import React from 'react';
import type {Row} from './client';
import {MaterialRequestReceipt} from './mapping-material-request';

export function MaterialRequestHistory({projectId,offerId,receipts,busy,blocked,onError}:{projectId:string;offerId:string;receipts:Row[];busy:boolean;blocked:boolean;onError:(v:string)=>void}){
 const scoped=receipts.filter(r=>r.project_id===projectId&&r.offer_id===offerId).sort((a,b)=>String(b.created_at).localeCompare(String(a.created_at))||String(a.id).localeCompare(String(b.id)));
 if(!scoped.length)return null;
 return <section><h3>Additional material request history</h3><p>Frozen creation evidence for this accepted offer, including requests from older cost releases or mapping revisions. This history does not report current supply status or create another request.</p>{scoped.map(receipt=><div key={receipt.id}><MaterialRequestReceipt receipt={receipt} busy={busy} blocked={blocked} onError={onError}/></div>)}</section>;
}
