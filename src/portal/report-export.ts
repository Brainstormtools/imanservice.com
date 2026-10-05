export type ReportSection={title:string;headers:string[];rows:unknown[][]};
// Loaded only when exporting, so the PDF library does not delay portal startup.
export async function createReportPDF(title:string,context:string,sections:ReportSection[]) {
 const {jsPDF}=await import('jspdf');
 const doc=new jsPDF({orientation:'landscape',unit:'mm',format:'a4'});
 const width=doc.internal.pageSize.getWidth(),height=doc.internal.pageSize.getHeight(),margin=14;
 let y=20;
 const line=(value:string,size=9,bold=false)=>{doc.setFont('helvetica',bold?'bold':'normal');doc.setFontSize(size);const lines=doc.splitTextToSize(value,width-2*margin);for(const l of lines){if(y>height-20){doc.addPage();y=20;}doc.text(l,margin,y);y+=size*.45+1.5;}};
 line('i Man Service',12,true);line(title,18,true);line(context);line(`Generated UTC: ${new Date().toISOString()}`);y+=5;
 for(const section of sections){if(y>height-35){doc.addPage();y=20;}line(section.title,12,true);if(!section.rows.length){line('No records in this scope.');continue;}
 const columnWidth=(width-2*margin)/section.headers.length;
 const drawRow=(values:unknown[],heading=false)=>{doc.setFont('helvetica',heading?'bold':'normal');doc.setFontSize(8);const cells=values.map(v=>doc.splitTextToSize(String(v??'—'),columnWidth-4));const rowHeight=Math.max(...cells.map(c=>c.length))*4+5;if(rowHeight>height-40){
 // Long work records continue as labelled paragraphs across pages.
 values.forEach((v,i)=>line(`${section.headers[i]}: ${String(v??'—')}`,8));y+=3;return;
 }
 if(y+rowHeight>height-18){doc.addPage();y=20;if(!heading)drawRow(section.headers,true);}
 if(heading){doc.setFillColor(235,240,247);doc.rect(margin,y-3,width-2*margin,rowHeight,'F');}
 cells.forEach((cell,i)=>doc.text(cell,margin+i*columnWidth+2,y+1));y+=rowHeight;doc.setDrawColor(220);doc.line(margin,y-3,width-margin,y-3);};
 drawRow(section.headers,true);section.rows.forEach(r=>drawRow(r));y+=6;
 }
 const pages=doc.getNumberOfPages();for(let p=1;p<=pages;p++){doc.setPage(p);doc.setFontSize(8);doc.setFont('helvetica','normal');doc.text(`i Man Service · ${p} / ${pages}`,margin,height-8);}
 return doc;
}
export async function downloadReportPDF(filename:string,title:string,context:string,sections:ReportSection[]) {
 (await createReportPDF(title,context,sections)).save(filename.replace(/[^a-zA-Z0-9._-]/g,'_'));
}
