import React,{useEffect,useRef,useState} from 'react';
import {db,check,type Row} from './client';
import {csvText,downloadText} from './business-utils';
const scope=(p:Row)=>JSON.stringify([p.id,p.role,p.active,p.company_id,p.crm_permissions]);
export function BoqCreditPosting({preparation,canPost,busy,onPost}:{preparation:Row;canPost:boolean;busy:boolean;onPost:(args:Record<string,unknown>)=>void}){
 if(preparation.review?.outcome!=='Approved')return null;
 if(preparation.snapshot.kind!=='Credit note'||preparation.snapshot.manual_wht)return <p>Debit-note and manual WHT posting remain a separate increment.</p>;
 return <Posting key={JSON.stringify([preparation.id,preparation.review.id])} preparation={preparation} canPost={canPost} parentBusy={busy} onPost={onPost}/>;
}
function Posting({preparation,canPost,parentBusy,onPost}:{key?:string;preparation:Row;canPost:boolean;parentBusy:boolean;onPost:(args:Record<string,unknown>)=>void}){
 const [preview,setPreview]=useState<any>(null),[busy,setBusy]=useState(false),[error,setError]=useState('');const live=useRef(true),seq=useRef(0),attempt=useRef({hash:'',id:''});
 useEffect(()=>{live.current=true;return()=>{live.current=false;seq.current++;};},[]);
 const load=async()=>{const n=++seq.current;setPreview(null);setError('');setBusy(true);try{const p=check(await db!.rpc('preview_boq_credit_posting',{p_preparation:preparation.id,p_review:preparation.review.id}));if(live.current&&seq.current===n)setPreview(p);}catch(e:any){if(live.current&&seq.current===n)setError(e.message);}finally{if(live.current&&seq.current===n)setBusy(false);}};
 const blocked=busy||parentBusy;
 return <section className="p-panel"><h5>Approved credit-note posting</h5><p>Posting issues a separate immutable credit note. It reduces the original unpaid balance first; excess becomes same-company PKR client credit for automatic settlement of later issued invoices. No cash refund or WHT reversal is made.</p><button disabled={blocked} onClick={load}>Load credit posting preview or receipt</button>{error&&<p role="alert">{error}</p>}
 {preview?.posting?<p>Issued {preview.posting.number} · gross PKR {preview.posting.gross} · original balance reduction {preview.posting.invoice_balance_reduction} · client credit {preview.posting.client_credit} · actual account {preview.posting.issued_by} · server time {preview.posting.issued_at}. The posting is immutable.</p>:preview&&<><p>Gross PKR {preview.gross} · original unpaid before {preview.unpaid_before} · balance reduction {preview.invoice_balance_reduction} · client credit carried {preview.client_credit}. Verified receipts {preview.verified_paid}; pending claims must be resolved.</p>{canPost&&<form className="p-form" onSubmit={e=>{e.preventDefault();if(blocked)return;const f=new FormData(e.currentTarget);if(f.get('checked')!=='on')return;const args={p_preparation:preparation.id,p_review:preparation.review.id,p_expected:preview,p_reason:String(f.get('reason'))},hash=JSON.stringify(args);if(attempt.current.hash!==hash)attempt.current={hash,id:crypto.randomUUID()};onPost({...args,p_id:attempt.current.id});}}><label className="p-field">Client-visible credit-note reason<textarea name="reason" required minLength={3} maxLength={2000} disabled={blocked}/></label><label className="p-check"><input name="checked" type="checkbox" required disabled={blocked}/>I checked this exact approved invoice-line/tax evidence, current balance and client-credit split. Issue the separate credit note; do not alter the original invoice or transfer cash.</label><button disabled={blocked}>Issue approved BOQ credit note</button></form>}</>}
 </section>;
}
export function ClientCreditLedger({profile,blocked=false}:{profile?:Row;blocked?:boolean}){
 return profile?.id&&profile.active!==false&&['admin','team','client'].includes(profile.role)&&!blocked?<Ledger key={scope(profile)}/>:null;
}
function Ledger(){
 const [data,setData]=useState<any>(null),[busy,setBusy]=useState(false),[error,setError]=useState('');const live=useRef(true),seq=useRef(0);
 useEffect(()=>{live.current=true;return()=>{live.current=false;seq.current++;};},[]);
 const load=async()=>{const n=++seq.current;setData(null);setError('');setBusy(true);try{const d=check(await db!.rpc('boq_client_credit_ledger'));if(live.current&&seq.current===n)setData(d);}catch(e:any){if(live.current&&seq.current===n)setError(e.message);}finally{if(live.current&&seq.current===n)setBusy(false);}};
 return <section className="p-panel"><h3>Issued BOQ credit notes & client credit</h3><p>Available client credit is separate from invoice balances and cash. Later same-company PKR invoices use available credit automatically when issued. Applications are settlements, not additional tax credit notes. Cash refunds, debit-note issuance and manual WHT posting remain separate.</p><button disabled={busy} onClick={load}>Load issued credits and applications</button>{error&&<p role="alert">{error}</p>}{data&&<>
 <button disabled={busy} onClick={()=>{try{downloadText('boq-client-credit-ledger.csv',csvText([['Kind','Evidence JSON'],...data.balances.map((r:any)=>['Available client credit',JSON.stringify(r)]),...data.documents.map((r:any)=>['Issued credit note',JSON.stringify(r)]),...data.applications.map((r:any)=>['Client credit settlement application',JSON.stringify(r)])]));}catch(e:any){setData(null);setError(e.message);}}}>Export issued client-credit ledger CSV</button>
 {!data.balances.length&&<p>No issued BOQ client-credit evidence in your current scope.</p>}{data.balances.map((b:any)=><p key={b.company_id}>{b.company} · PKR client credit created {b.created} · available {b.available}</p>)}
 {data.documents.map((d:any)=><article className="p-panel" key={d.id}><h4>{d.number} · issued credit note · PKR {d.gross}</h4><p>Original invoice {d.invoice_number} · change order {d.change_id} · {d.client_title}</p><p>{d.reason} · net {d.net} · tax {d.tax} · balance reduction {d.balance_reduction} · client credit created {d.client_credit}</p>{d.lines.map((l:any)=><p key={l.item_id}>{l.description} · net {l.net} · original tax {l.tax_percent}% · tax {l.tax} · gross {l.gross}</p>)}<p>Actual issuing account {d.issued_by} · server time {d.issued_at}</p></article>)}
 {data.applications.map((a:any)=><p key={a.id}>{a.number} · PKR {a.amount} applied from {a.source_number} to {a.invoice_number} · actual account {a.applied_by} · server time {a.applied_at}. {a.purpose}</p>)}
 </>}
 </section>;
}
