type Pool={id:string;project_id:string;outstanding:unknown};
type Booking={id:string;issue_id:string;project_id:string;status:string;starts_at:string;ends_at:string;quantity:unknown};
export function toolAvailability(pool:Pool,bookings:Booking[],start:number,end:number){
 const unavailable={known:false,peak:null,spare:null,toolHours:null,bookings:null};
 const capacity=Number(pool.outstanding);
 if(!pool.id||!pool.project_id||(typeof pool.outstanding==='string'&&!pool.outstanding.trim())||pool.outstanding===null||pool.outstanding===undefined||pool.outstanding===''||!Number.isFinite(capacity)||capacity<0||!Number.isFinite(start)||!Number.isFinite(end)||end<=start)return unavailable;
 const seen=new Map<string,string>(),events=new Map<number,number>();let hours=0,count=0;
 for(const b of bookings){
  if(b.issue_id!==pool.id||b.status==='Cancelled')continue;
  const from=Date.parse(b.starts_at),to=Date.parse(b.ends_at),quantity=Number(b.quantity);
  if(!b.id||b.project_id!==pool.project_id||b.status!=='Reserved'||!Number.isFinite(from)||!Number.isFinite(to)||to<=from||!Number.isInteger(quantity)||quantity<1)return unavailable;
  const signature=JSON.stringify([b.project_id,b.status,from,to,quantity]),prior=seen.get(b.id);
  if(prior!==undefined){if(prior!==signature)return unavailable;continue;}seen.set(b.id,signature);
  const a=Math.max(start,from),z=Math.min(end,to);if(z<=a)continue;
  count++;hours+=(z-a)*quantity/3600000;events.set(a,(events.get(a)||0)+quantity);events.set(z,(events.get(z)||0)-quantity);
 }
 let active=0,peak=0;for(const [,delta] of [...events].sort((a,b)=>a[0]-b[0])){active+=delta;peak=Math.max(peak,active);}
 // A negative spare value exposes inconsistent/currently overcommitted data; never hide it as zero.
 return {known:true,peak,spare:capacity-peak,toolHours:hours,bookings:count};
}
