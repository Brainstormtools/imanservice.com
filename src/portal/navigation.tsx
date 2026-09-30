import React from 'react';

type Item = {view:string; label:string};
type Group = {label:string; items:Item[]};
export function navigationGroups(role?:string):Group[] {
 if(!['admin','team','client'].includes(role||'')) return [];
 const client=role==='client', team=role==='team';
 const item=(view:string,label:string):Item=>({view,label});
 return [
 {label:'Overview',items:[item('dashboard','Dashboard')]},
 {label:'Workspace',items:[...(!client?[item('directory','Clients & contacts')]:[]),item('projects',client?'My projects':'Projects'),item('calendar','My tasks & calendar')]},
 ...(!team?[{label:'Sales & billing',items:[item('estimates',client?'My estimates & proposals':'Estimates & proposals'),item('agreements',client?'My contract documents':'Contract documents'),item('orders',client?'My orders & catalogue':'Orders & catalogue'),item('billing',client?'My invoices & payments':'Invoices & payments')]}]:[]),
 {label:'IT operations',items:[item('sites',client?'My sites':'Client sites'),item('equipment',client?'My IT assets':'IT assets'),item('contracts',client?'My AMC & SLA':'AMC & SLA'),...(!team?[item('renewals','AMC renewals')]:[]),item('visits','Maintenance visits'),item('maintenance','Preventive maintenance'),item('audits','Network audits'),item('support','Support & SLA'),item('reports','Reports')]},
 {label:'My workspace',items:[item('notifications','Notifications'),...(!client?[item('attendance','Attendance')]:[])]},
 ...(role==='admin'?[{label:'Administration',items:[item('clients','Clients & team access')]}]:[])
 ];
}
export function PortalNavigation({role,view,onSelect}:{role?:string;view:string;onSelect:(view:string)=>void}) {
 return <nav aria-label="Portal navigation">{navigationGroups(role).map(group=><section className="p-nav-group" key={group.label} aria-label={group.label}><h2>{group.label}</h2>{group.items.map(item=><button type="button" key={item.view} className={view===item.view?'active':''} aria-current={view===item.view?'page':undefined} onClick={()=>onSelect(item.view)}>{item.label}</button>)}</section>)}</nav>;
}
