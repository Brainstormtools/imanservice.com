import React from 'react';

type Item = {view:string; label:string};
type Group = {label:string; items:Item[]};
export function navigationGroups(role?:string,permissions:string[]=[]):Group[] {
 if(!['admin','team','client'].includes(role||'')) return [];
 const client=role==='client', team=role==='team';
 const item=(view:string,label:string):Item=>({view,label});
 return [
 {label:'Overview',items:[item('dashboard','Dashboard')]},
 {label:'Workspace',items:[...(role==='admin'?[item('directory','Clients & contacts')]:[]),...((role==='admin'||permissions.includes('customer.read'))?[item('customer_history','Customer history')]:[]),item('projects',client?'My projects':team?'Assigned projects':'Projects'),item('calendar','My tasks & calendar')]},
 ...((role==='admin'||permissions.some(p=>['sales.manage','sales.own','product.own'].includes(p)))?[{label:'Sales CRM',items:[...((role==='admin'||permissions.some(p=>['sales.manage','sales.own'].includes(p)))?[item('raw_leads','Raw Lead Board')]:[]),item('sales_boards','Product sales boards')]}]:[]),
 ...(!team?[{label:'Sales & billing',items:[item('estimates',client?'My estimates & proposals':'Estimates & proposals'),item('agreements',client?'My contract documents':'Contract documents'),item('orders',client?'My orders & catalogue':'Orders & catalogue'),item('billing',client?'My invoices & payments':'Invoices & payments')]}]:[]),
 {label:'IT operations',items:[item('sites',client?'My sites':team?'Assigned sites':'Client sites'),item('equipment',client?'My IT assets':team?'Related IT assets':'IT assets'),item('contracts',client?'My AMC & SLA':'AMC & SLA'),...(!team?[item('renewals','AMC renewals')]:[]),item('visits','Maintenance visits'),item('maintenance','Preventive maintenance'),item('audits','Network audits'),item('support','Support & SLA'),item('reports','Reports')]},
 {label:'My workspace',items:[item('notifications','Notifications'),...(!client?[item('attendance','Attendance')]:[])]},
 ...(role==='admin'?[{label:'Administration',items:[item('clients','Clients & team access'),item('configuration','CRM configuration'),item('sales_configuration','Sales board configuration')]}]:[])
 ];
}
export function PortalNavigation({role,permissions=[],view,onSelect}:{role?:string;permissions?:string[];view:string;onSelect:(view:string)=>void}) {
 return <nav aria-label="Portal navigation">{navigationGroups(role,permissions).map(group=><section className="p-nav-group" key={group.label} aria-label={group.label}><h2>{group.label}</h2>{group.items.map(item=><button type="button" key={item.view} className={view===item.view?'active':''} aria-current={view===item.view?'page':undefined} onClick={()=>onSelect(item.view)}>{item.label}</button>)}</section>)}</nav>;
}
