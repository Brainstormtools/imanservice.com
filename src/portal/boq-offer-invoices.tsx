import React from 'react';
import type {Row} from './client';

export function BoqOfferInvoice({offer,invoice,admin,busy,run}:{offer:Row;invoice?:Row;admin:boolean;busy:boolean;run:(name:string,args:Record<string,unknown>)=>Promise<void>}){
 if(offer.status!=='Accepted')return null;
 return <section className="p-no-print">
  {invoice&&<p>Linked invoice {invoice.invoice_number} · {invoice.invoice_status} · {invoice.currency} {Number(invoice.total).toFixed(2)} · issued {invoice.issued_on} · due {invoice.due_on}. View issued invoices in Invoices.</p>}
  {admin&&(!invoice||invoice.invoice_status==='Draft')&&<form className="p-form" onSubmit={e=>{
   e.preventDefault();const f=new FormData(e.currentTarget);
   if(invoice)void run('revise_boq_invoice_details',{p_invoice:invoice.invoice_id,p_version:invoice.details_version,p_due:String(f.get('due_on')),p_bank:String(f.get('bank')),p_reason:String(f.get('reason'))});
   else void run('create_boq_offer_invoice',{p_offer:offer.id,p_version:offer.version,p_issue:String(f.get('issued_on')),p_due:String(f.get('due_on')),p_bank:String(f.get('bank')),p_reason:String(f.get('reason'))});
  }}>
   <h4>{invoice?'Revise draft payment details':'Create invoice draft from accepted BOQ'}</h4>
   <p>Accepted gross amounts and tax are fixed. The invoice uses summary tax buckets; the accepted offer retains the itemized scope and complete terms. WHT does not create a receipt or credit. Issue or void separately in Invoices.</p>
   {!invoice&&<label className="p-field">Invoice date<input name="issued_on" type="date" required disabled={busy}/></label>}
   <label className="p-field">Due date<input name="due_on" type="date" required defaultValue={invoice?.due_on||''} disabled={busy}/></label>
   <label className="p-field">Actual bank transfer instructions<textarea name="bank" required minLength={3} maxLength={4000} disabled={busy}/></label>
   <label className="p-field">Internal invoice reason<textarea name="reason" required minLength={3} maxLength={2000} disabled={busy}/></label>
   <button disabled={busy}>{invoice?'Save draft payment details':'Create accepted BOQ invoice draft'}</button>
  </form>}
 </section>;
}
