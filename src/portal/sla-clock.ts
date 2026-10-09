// A waiting ticket uses its server-recorded pause entry, never the browser clock.
export function slaClock(ticket:any,now=Date.now()){
 return ticket.sla_paused_at?Date.parse(ticket.sla_paused_at):now;
}
export function slaOverdue(ticket:any,now=Date.now()){
 const clock=slaClock(ticket,now);
 return ticket.status!=='Resolved'&&((ticket.response_due_at&&!ticket.first_response_at&&Date.parse(ticket.response_due_at)<clock)||(ticket.resolution_due_at&&Date.parse(ticket.resolution_due_at)<clock));
}
