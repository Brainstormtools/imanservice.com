import type {Row} from './client';

type Group={counterparty:string;direction:string;reference:string;identity:boolean;kinds:Set<string>;documents:number;open_documents:number;balance_cents:number;overdue_cents:number;due_today_cents:number;not_due_cents:number};
// Use only explicit database identities. Legacy/unlinked names never become accounts.
export function tradeCounterpartySummary(documents:Row[],currency:string,useIdentities=false){
 const groups=new Map<string,Group>();
 for(const document of documents){
  if(document.currency!==currency)continue;
  const identity=useIdentities&&['Customer','Vendor'].includes(document.counterparty_type)&&typeof document.counterparty_id==='string'&&document.counterparty_id.length>0;
  const key=JSON.stringify(identity?[document.direction,document.counterparty_type,document.counterparty_id]:[document.direction,document.kind,document.counterparty]);
  let group=groups.get(key);
  if(!group){group={counterparty:identity?document.account_name:document.counterparty,direction:document.direction,reference:identity?document.counterparty_type+' account '+document.counterparty_id:'Recorded name',identity,kinds:new Set(),documents:0,open_documents:0,balance_cents:0,overdue_cents:0,due_today_cents:0,not_due_cents:0};groups.set(key,group);}
  group.kinds.add(document.kind);
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
 return [...groups.values()].map(({kinds,...group})=>({...group,kind:[...kinds].sort().join(' / '),balance:group.balance_cents/100,overdue:group.overdue_cents/100,due_today:group.due_today_cents/100,not_due:group.not_due_cents/100})).sort((a,b)=>a.counterparty.localeCompare(b.counterparty)||a.direction.localeCompare(b.direction)||a.kind.localeCompare(b.kind)||a.reference.localeCompare(b.reference));
}
