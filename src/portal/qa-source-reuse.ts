import type {Row} from './client';
export function attachQaSource(tasks:Row[],key:string,source:Row,reason:string){
 if(tasks.filter(t=>t.key===key).length!==1||!key)throw new Error('Choose one uniquely keyed actual task.');
 if(!source.active||source.revision!==source.current_revision)throw new Error('Choose a current available QA/SOP version.');
 if(reason.trim().length<3||reason.trim().length>1000)throw new Error('Enter the actual reuse review reason.');
 const copy=JSON.parse(JSON.stringify(tasks)),task=copy.find((t:Row)=>t.key===key),refs=task.qa_sop_sources||[];
 if(refs.length>=10)throw new Error('Use at most ten QA/SOP references per task.');
 if(refs.some((r:Row)=>r.library_id===source.library_id))throw new Error('Remove the previous reference before replacing this library entry.');
 task.qa_sop_sources=[...refs,{version_id:source.id,library_id:source.library_id,revision:source.revision,name:source.name,kind:source.kind,steps:[...source.steps],reason:reason.trim(),confirmed:true}];return copy;
}
