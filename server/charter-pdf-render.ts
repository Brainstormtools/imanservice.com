import {jsPDF} from 'jspdf';
import {readFileSync} from 'node:fs';
import {join} from 'node:path';
import {randomBytes} from 'node:crypto';
const fonts:Record<string,string>={};
export function renderCharterPDF(approval:any):Buffer{
 if(!approval?.id||!approval.snapshot?.client_terms||approval.consent!==true)throw Error('Complete immutable approval required');
 const p=approval.snapshot,t=p.client_terms;
 const doc=new jsPDF({unit:'mm',format:'a4',compress:true,putOnlyUsedFonts:true,encryption:{userPassword:'',ownerPassword:randomBytes(24).toString('hex'),userPermissions:['print','copy']}});
 for(const [file,family] of [['DejaVuSans.ttf','Charter'],['NotoNaskhArabic-Regular.ttf','Arabic']]){fonts[file]??=readFileSync(join(process.cwd(),'server/fonts',file)).toString('base64');doc.addFileToVFS(file,fonts[file]);doc.addFont(file,family,'normal');}doc.setFont('Charter','normal');
 doc.setProperties({title:`Approved project charter - ${p.title}`,subject:`Immutable portal approval ${approval.id}`,author:'IMAN',creator:'IMAN portal charter-pdf-v1'});
 const selectFont=(text:string)=>{doc.setFont(/[\u0590-\u08ff\ufb50-\ufeff]/.test(text)?'Arabic':'Charter','normal');return doc.getFont().metadata.cmap.unicode.codeMap;};
 const valid=(text:string)=>{const cmap=selectFont(text);for(const c of text){const n=c.codePointAt(0)!;if(!/[\n\r\t]/.test(c)&&(!cmap[n]||n>65535))throw Error(`PDF font does not support U+${n.toString(16).toUpperCase()}; approval remains saved`);}};
 let y=29;
 const page=()=>{doc.setR2L(false);doc.setFont('Charter','normal');doc.setFillColor(17,43,63);doc.rect(0,0,210,19,'F');doc.setFontSize(10);doc.setTextColor(255,255,255);doc.text('IMAN | PROJECT CHARTER',18,12);doc.setTextColor(25,35,45);y=29;};page();
 const line=(text:string,size=10)=>{if(y>275){doc.addPage();page();}valid(text);const rtl=/[\u0590-\u08ff\ufb50-\ufeff]/.test(text);doc.setFontSize(size);doc.setR2L(false);doc.text(text,rtl?192:18,y,{align:rtl?'right':'left',isInputVisual:false,isOutputVisual:true,isInputRtl:rtl,isOutputRtl:false});y+=size===10?5.4:6.5;};
 const section=(label:string,value:any)=>{const text=String(value??'');for(const p of text.split(/\r?\n/))valid(p);if(y>258){doc.addPage();page();}doc.setR2L(false);doc.setTextColor(17,83,112);line(label,11);doc.setTextColor(25,35,45);doc.setFontSize(10);for(const paragraph of text.replace(/\r\n?/g,'\n').replace(/\t/g,'    ').split('\n')){selectFont(paragraph);const lines=doc.splitTextToSize(paragraph||' ',174);for(const l of lines)line(l);}y+=4;};
 section('PORTAL APPROVAL RECORDED',`${approval.full_name}\nAccount: ${approval.actor_id}\nApproved at: ${approval.created_at}\nRequest IP: ${approval.request_ip}\nAgreement: I agree to this exact published charter\nApproval ID: ${approval.id}`);
 section('Project / client',`${p.project_title}\n${p.company_name}`);section('Charter title',p.title);
 section('Published version',`${t.document_kind} | project publication ${p.publication_sequence} | copy v${p.copy_version} | publication v${approval.publication_version}\nPublication ID: ${approval.publication_id}${t.supersedes_publication_id?`\nPrior publication: ${t.supersedes_publication_id}`:''}`);
 for(const [label,key] of [['Objectives','objectives'],['Scope','scope'],['Product lines','product_lines'],['Deliverables','deliverables'],['Milestones and dates','milestones_dates'],['Contract value','contract_value'],['Payment milestones','payment_milestones'],['Responsibilities','responsibilities'],['Communication','communication']] as const)section(label,p[key]??t[key]);
 if(t.change_summary)section('Change order summary',t.change_summary);if(approval.note)section('Optional approval note',approval.note);
 const pages=doc.getNumberOfPages();for(let i=1;i<=pages;i++){doc.setPage(i);doc.setR2L(false);doc.setFont('Charter','normal');doc.setFontSize(7);doc.setTextColor(90,100,110);doc.text(`Approval ${approval.id}`,18,287);doc.text(`Page ${i} of ${pages}`,192,287,{align:'right'});}
 return Buffer.from(doc.output('arraybuffer'));
}
