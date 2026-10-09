import type {Row} from './client';

// These are document-name groups, not inferred account identities.
type Group={counterparty:string;direction:string;kind:string;documents:number;open_documents:number;balance_cents:number;overdue_cents:number;due_today_cents:number;not_due_cents:number};
export function tradeCounterpartySummary(documents:Row[],currency:string){
 const groups=new Map<string,Group>();
 for(const document of documents){
  if(document.currency!==currency)continue;
  const key=JSON.stringify([document.direction,document.kind,document.counterparty]);
  let group=groups.get(key);
  if(!group){group={counterparty:document.counterparty,direction:document.direction,kind:document.kind,documents:0,open_documents:0,balance_cents:0,overdue_cents:0,due_today_cents:0,not_due_cents:0};groups.set(key,group);}
  group.documents++;
  const cents=Math.round(Number(document.balance)*100);
  group.balance_cents+=cents;
  if(cents>0){
   group.open_documents++;
   if(document.due_status==='Overdue')group.overdue_cents+=cents;
   if(document.due_status==='Due today')group.due_today_cents+=cents;
   if(document.due_status==='Not due')group.not_due_cents+=cents;
  }
 }
 return [...groups.values()].map(group=>({...group,balance:group.balance_cents/100,overdue:group.overdue_cents/100,due_today:group.due_today_cents/100,not_due:group.not_due_cents/100})).sort((a,b)=>String(a.counterparty).localeCompare(String(b.counterparty))||String(a.direction).localeCompare(String(b.direction))||String(a.kind).localeCompare(String(b.kind)));
}
