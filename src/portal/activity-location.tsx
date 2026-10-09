import React,{useEffect,useState} from 'react';
import {type Row} from './client';
import {workspaceRows} from './workspace';
export function ActivityLocation({profile,value='',companyId,projectRequired=false,readOnly=false,label='Site / location'}:{profile:Row;value?:string;companyId?:string;projectRequired?:boolean;readOnly?:boolean;label?:string}){
 const [sites,setSites]=useState<Row[]>([]),[location,setLocation]=useState(value),[error,setError]=useState('');
 useEffect(()=>{let live=true;setSites([]);setError('');if(!['admin','team'].includes(profile.role)||readOnly)return;workspaceRows('client_sites').then(rows=>{if(live)setSites(rows);}).catch(e=>{if(live)setError(e.message);});return()=>{live=false;};},[profile.id,profile.role,readOnly]);
 useEffect(()=>setLocation(value),[value,companyId]);
 if(!['admin','team'].includes(profile.role))return null;
 const available=sites.filter(s=>s.active!==false&&(!projectRequired||!!companyId)&&(!companyId||s.company_id===companyId));
 return <>{!readOnly&&<label className="p-field">Saved site lookup (optional)<select aria-label="Saved site lookup" defaultValue="" onChange={e=>{const site=available.find(s=>s.id===e.target.value);if(site)setLocation([site.name,site.address].filter(Boolean).join(' · ').slice(0,300));}}><option value="">Choose an accessible site…</option>{available.map(s=><option key={s.id} value={s.id}>{s.name}</option>)}</select></label>}{error&&<p role="alert">Saved sites could not load: {error}. You can enter the location below.</p>}<label className="p-field">{label}<input name="location" value={location} onChange={e=>setLocation(e.target.value)} readOnly={readOnly} maxLength={300} required/></label>{!readOnly&&<p>Choose an accessible active site or enter another location. The saved record retains the entered location if site details later change.</p>}</>;
}
