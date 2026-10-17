import {createHash} from 'node:crypto';
import {renderCharterPDF} from './charter-pdf-render.js';
const checked=(r:any)=>{if(r.error)throw Error('Approval evidence unavailable');return r.data;};
export async function charterPDF(client:any,approvalId:string,token:string,generate=true,render=renderCharterPDF){
 const args={p_approval:approvalId,p_gateway_token:token};let source=checked(await client.rpc('charter_approval_pdf_source',args));
 if(!source?.approval||source.approval.id!==approvalId)throw Error('Exact saved approval required');
 if(!source.document){
  if(!generate)throw Error('PDF not archived yet');
  const bytes=render(source.approval);
  checked(await client.rpc('archive_charter_approval_pdf',{...args,p_receipt_hash:source.receipt_hash,p_pdf_base64:bytes.toString('base64')}));
  // Always read the winning immutable archive: concurrent valid renderings may differ in encryption metadata.
  source=checked(await client.rpc('charter_approval_pdf_source',args));
 }
 const document=source?.document;if(!document?.base64||document.receipt_hash!==source.receipt_hash)throw Error('PDF approval binding failed');
 const bytes=Buffer.from(document.base64,'base64');if(createHash('sha256').update(bytes).digest('hex')!==document.sha256)throw Error('PDF integrity check failed');
 return {bytes,sha256:document.sha256,created_at:document.created_at};
}
