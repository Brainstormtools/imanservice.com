-- APPLIED via native connected migration 20261027230213; CLI unavailable. New handovers only; historical signed scopes unchanged.
create table portal_private.crm_handover_release_receipts(id uuid primary key,handover_id uuid not null unique references public.crm_handovers,actor_id uuid not null references public.profiles,payload jsonb not null,created_at timestamptz not null default now());
create index crm_handover_release_actor on portal_private.crm_handover_release_receipts(actor_id);
create table portal_private.crm_handover_criteria_files(handover_id uuid not null references public.crm_handovers,file_id uuid not null references portal_private.crm_criteria_files,metadata jsonb not null,primary key(handover_id,file_id));
create index crm_handover_criteria_file on portal_private.crm_handover_criteria_files(file_id);
alter table portal_private.crm_handover_release_receipts enable row level security;
alter table portal_private.crm_handover_criteria_files enable row level security;
revoke all on portal_private.crm_handover_release_receipts,portal_private.crm_handover_criteria_files from public,anon,authenticated,service_role;
create trigger crm_handover_release_immutable before update or delete on portal_private.crm_handover_release_receipts for each row execute function portal_private.lead_api_evidence_immutable();
create trigger crm_handover_files_immutable before update or delete on portal_private.crm_handover_criteria_files for each row execute function portal_private.lead_api_evidence_immutable();
create function portal_private.handover_criteria_basis(p_project uuid,p_lock boolean default false) returns jsonb language plpgsql security definer set search_path='' as $$
declare d portal_private.crm_project_criteria_versions;r portal_private.crm_project_criteria_reviews;o portal_private.crm_criteria_observations;e portal_private.crm_criteria_evidence_reviews;i integer;items jsonb:='[]';files jsonb;basis jsonb;blocks jsonb:='[]';
begin
 select v.* into d from portal_private.crm_project_criteria_versions v join portal_private.crm_project_criteria c on c.project_id=v.project_id and c.revision=v.revision where v.project_id=p_project;
 if d.id is null then return jsonb_build_object('ready',true,'blockers','[]'::jsonb,'scope',jsonb_build_object('schema_version',1,'configured',false,'items','[]'::jsonb));end if;
 select * into r from portal_private.crm_project_criteria_reviews where definition_id=d.id order by sequence desc limit 1;
 if r.decision is distinct from 'Approved' then blocks:=blocks||jsonb_build_array('Current criteria wording requires approval');end if;
 for i in 1..jsonb_array_length(d.criteria) loop
  o:=null;e:=null;basis:=null;files:='[]';
  select * into o from portal_private.crm_criteria_observations where definition_id=d.id and position=i order by sequence desc limit 1;
  if o.id is null or o.review_id is distinct from r.id or o.result is distinct from 'Pass' then blocks:=blocks||jsonb_build_array('Criterion '||i||' requires a current observed Pass');end if;
  if o.id is not null then
   select * into e from portal_private.crm_criteria_evidence_reviews where observation_id=o.id order by sequence desc limit 1;
   if e.id is not null then
    if p_lock then perform 1 from storage.objects where bucket_id='crm-criteria-files' and name in(select path from portal_private.crm_criteria_files where id=any(e.file_ids)) order by name for share;end if;
    basis:=portal_private.criteria_evidence_basis(o.id,e.file_ids);
    select coalesce(jsonb_agg(jsonb_build_object('id',f.id,'name',f.name,'size',f.size,'mime',f.mime,'registered_at',f.created_at) order by f.id),'[]') into files from portal_private.crm_criteria_files f where f.observation_id=o.id and f.id=any(e.file_ids);
   end if;
   if e.decision is distinct from 'Approved' or e.source is distinct from basis or exists(select 1 from jsonb_array_elements(coalesce(basis->'files','[]')) f where (f->>'stored_metadata_matches')::boolean is distinct from true) then blocks:=blocks||jsonb_build_array('Criterion '||i||' requires current approved evidence');end if;
  end if;
  items:=items||jsonb_build_array(jsonb_build_object('position',i,'criterion',d.criteria->(i-1),'observation_id',o.id,'result',o.result,'actual',o.actual,'observed_on',o.observed_on,'observer_name',o.observer_name,'evidence_review_id',e.id,'evidence_decision',e.decision,'evidence_reviewed_at',e.created_at,'files',files));
 end loop;
 return jsonb_build_object('ready',jsonb_array_length(blocks)=0,'blockers',blocks,'scope',jsonb_build_object('schema_version',1,'configured',true,'definition_id',d.id,'definition_revision',d.revision,'wording_review_id',r.id,'wording_reviewed_at',r.created_at,'items',items));
end$$;
revoke all on function portal_private.handover_criteria_basis(uuid,boolean) from public,anon,authenticated,service_role;
create function public.handover_criteria_preview(p_project uuid) returns jsonb language plpgsql security definer set search_path='' as $$begin
 if not public.is_admin() or not exists(select 1 from public.projects where id=p_project) then raise exception 'Actual project and current active Admin required';end if;
 return jsonb_build_object('project_id',p_project,'active_handover',(select jsonb_build_object('id',id,'status',status) from public.crm_handovers where project_id=p_project and status in ('Awaiting signatures','Signed','Closed') order by revision desc limit 1))||portal_private.handover_criteria_basis(p_project);
end$$;
revoke all on function public.handover_criteria_preview(uuid) from public,anon,service_role;
grant execute on function public.handover_criteria_preview(uuid) to authenticated;
create function portal_private.release_handover_core(p_request uuid,p_project uuid,p_summary text,p_contractor uuid,p_consultant uuid,p_client uuid,p_basis jsonb,p_confirm boolean) returns uuid language plpgsql security definer set search_path='' as $$declare p public.projects;h uuid;payload jsonb;rev integer;c jsonb;request jsonb;receipt portal_private.crm_handover_release_receipts;item jsonb;file jsonb;begin
perform 1 from public.profiles where id=auth.uid() and active and role='admin' for share;if not found or not public.is_admin() then raise exception 'Current active Administrator release required';end if;
select * into p from public.projects where id=p_project for update;if not found or p_request is null then raise exception 'Actual project and request required';end if;
request:=jsonb_build_array(p_project,p_summary,p_contractor,p_consultant,p_client,p_basis,p_confirm);
select * into receipt from portal_private.crm_handover_release_receipts where id=p_request;
if found then if receipt.actor_id<>auth.uid() or receipt.payload is distinct from request then raise exception 'Handover retry meaning or actor changed';end if;return receipt.handover_id;end if;
if p.status='Completed' then raise exception 'Active project required';end if;
c:=portal_private.handover_criteria_basis(p.id,true);
if not (c->>'ready')::boolean or p_confirm is distinct from true or p_basis is distinct from c->'scope' then raise exception 'Current approved Pass criteria/evidence and exact reviewed handover scope required';end if;
perform 1 from public.profiles where id in(p_contractor,p_consultant,p_client) order by id for share;
perform 1 from public.project_assignments where project_id=p.id and technician_id in(p_contractor,p_consultant,p_client) order by technician_id for share;
perform portal_private.handover_ready(p_project);
if not portal_private.handover_signer_eligible(p_project,p_contractor,'Contractor') or not portal_private.handover_signer_eligible(p_project,p_consultant,'Consultant') or not portal_private.handover_signer_eligible(p_project,p_client,'Client') then raise exception 'Choose eligible active project signers';end if;
select coalesce(max(revision),0)+1 into rev from public.crm_handovers where project_id=p_project;
payload:=jsonb_build_object('project_id',p.id,'project',p.title,'company',(select name from public.companies where id=p.company_id),'summary',trim(p_summary),'revision',rev,'phases',coalesce((select jsonb_agg(jsonb_build_object('phase',phase,'summary',summary,'reviewed_at',reviewed_at,'evidence',evidence) order by phase) from public.crm_phases where project_id=p.id),'[]'::jsonb),'nodes',coalesce((select jsonb_agg(jsonb_build_object('device',n.device_id,'discipline',n.discipline,'location',n.location,'checks',(select jsonb_agg(jsonb_build_object('step',c.step,'result',c.result,'checked_by',c.checked_name,'reviewed_by',c.reviewed_name,'reviewed_at',c.reviewed_at) order by c.step) from public.crm_node_checks c where c.node_id=n.id)) order by n.device_id) from public.crm_nodes n where n.project_id=p.id),'[]'::jsonb),'punch',coalesce((select jsonb_agg(jsonb_build_object('title',title,'location',location,'priority',priority,'closed_at',closed_at) order by id) from public.crm_punch_items where project_id=p.id),'[]'::jsonb));
payload:=payload||jsonb_build_object('criteria_scope',c->'scope');
insert into public.crm_handovers(project_id,revision,summary,contractor_id,consultant_id,client_id,snapshot,snapshot_hash,created_by) values(p.id,rev,trim(p_summary),p_contractor,p_consultant,p_client,payload,encode(sha256(convert_to(payload::text,'UTF8')),'hex'),auth.uid()) returning id into h;
insert into public.crm_execution_history(project_id,kind,record_id,action,snapshot,actor_id) values(p.id,'Handover',h::text,'Released',payload,auth.uid());
insert into public.portal_reminders(user_id,event_key,title,view,project_id) select u,'handover:'||h::text,'Handover signature requested: '||p.title,'handover',p.id from unnest(array[p_contractor,p_consultant,p_client]) u where coalesce((select enabled from public.portal_reminder_preferences where user_id=u),true) on conflict do nothing;
for item in select value from jsonb_array_elements(c->'scope'->'items') loop
 for file in select value from jsonb_array_elements(item->'files') loop insert into portal_private.crm_handover_criteria_files values(h,(file->>'id')::uuid,file);end loop;end loop;
insert into portal_private.crm_handover_release_receipts(id,handover_id,actor_id,payload) values(p_request,h,auth.uid(),request);
return h;end$$;
revoke all on function portal_private.release_handover_core(uuid,uuid,text,uuid,uuid,uuid,jsonb,boolean) from public,anon,authenticated,service_role;
create or replace function public.create_crm_handover(p_project uuid,p_summary text,p_contractor uuid,p_consultant uuid,p_client uuid) returns uuid language plpgsql security definer set search_path='' as $$declare c jsonb;begin
 if not public.is_admin() then raise exception 'Current active Administrator required';end if;
 c:=portal_private.handover_criteria_basis(p_project);
 if (c->'scope'->>'configured')::boolean then raise exception 'Use explicit reviewed criteria handover release';end if;
 return portal_private.release_handover_core(gen_random_uuid(),p_project,p_summary,p_contractor,p_consultant,p_client,c->'scope',true);
end$$;
create function public.release_crm_handover(p_request uuid,p_project uuid,p_summary text,p_contractor uuid,p_consultant uuid,p_client uuid,p_basis jsonb,p_confirm boolean) returns uuid language sql security definer set search_path='' as $$select portal_private.release_handover_core(p_request,p_project,p_summary,p_contractor,p_consultant,p_client,p_basis,p_confirm);$$;
revoke all on function public.release_crm_handover(uuid,uuid,text,uuid,uuid,uuid,jsonb,boolean) from public,anon,service_role;
grant execute on function public.release_crm_handover(uuid,uuid,text,uuid,uuid,uuid,jsonb,boolean) to authenticated;
create function portal_private.assert_handover_criteria(p_handover uuid) returns void language plpgsql security definer set search_path='' as $$declare h public.crm_handovers;c jsonb;begin
 select * into h from public.crm_handovers where id=p_handover;
 if not(h.snapshot ? 'criteria_scope') then return;end if;
 perform 1 from public.projects where id=h.project_id and status<>'Completed' for update;if not found then raise exception 'Open handover project required';end if;
 c:=portal_private.handover_criteria_basis(h.project_id,true);
 if h.snapshot->'criteria_scope'->>'schema_version' is distinct from '1' or not(c->>'ready')::boolean or h.snapshot->'criteria_scope' is distinct from c->'scope' then raise exception 'Handover criteria or approved evidence changed; cancel and release a new reviewed revision';end if;
end$$;
create function portal_private.handover_criteria_signature_guard() returns trigger language plpgsql security definer set search_path='' as $$declare h public.crm_handovers;begin
 select * into h from public.crm_handovers where id=new.handover_id;
 if h.snapshot ? 'criteria_scope' then
  perform 1 from public.profiles where id=auth.uid() and active for share;
  if not found then raise exception 'Current active actual signer required';end if;
  perform 1 from public.project_assignments where project_id=h.project_id and technician_id=auth.uid() for share;
  if new.signer_id is distinct from auth.uid() or new.signer_id is distinct from (case new.party when 'Contractor' then h.contractor_id when 'Consultant' then h.consultant_id when 'Client' then h.client_id end) or new.snapshot_hash is distinct from h.snapshot_hash or h.status<>'Awaiting signatures' or not portal_private.handover_signer_eligible(h.project_id,auth.uid(),new.party) then raise exception 'Current actual eligible signer required';end if;
  perform portal_private.assert_handover_criteria(h.id);
 end if;return new;
end$$;
create function portal_private.handover_criteria_archive_guard() returns trigger language plpgsql security definer set search_path='' as $$begin
 if exists(select 1 from public.crm_handovers where id=new.handover_id and snapshot ? 'criteria_scope') then
  perform 1 from public.profiles where id=auth.uid() and active and role='admin' for share;
  if not found or not public.is_admin() then raise exception 'Current active Admin archive required';end if;
  perform portal_private.assert_handover_criteria(new.handover_id);
 end if;return new;
end$$;
revoke all on function portal_private.assert_handover_criteria(uuid),portal_private.handover_criteria_signature_guard(),portal_private.handover_criteria_archive_guard() from public,anon,authenticated,service_role;
create trigger handover_current_criteria_sign before insert on public.crm_handover_signatures for each row execute function portal_private.handover_criteria_signature_guard();
create trigger handover_current_criteria_archive before insert on public.crm_handover_documents for each row execute function portal_private.handover_criteria_archive_guard();
create function portal_private.handover_criteria_file_read(p_path text) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from portal_private.crm_criteria_files f join portal_private.crm_handover_criteria_files l on l.file_id=f.id join public.crm_handovers h on h.id=l.handover_id join portal_private.crm_criteria_observations o on o.id=f.observation_id where f.path=p_path and h.project_id=o.project_id and portal_private.handover_read(h.id) and l.metadata=jsonb_build_object('id',f.id,'name',f.name,'size',f.size,'mime',f.mime,'registered_at',f.created_at));
$$;
revoke all on function portal_private.handover_criteria_file_read(text) from public,anon,authenticated,service_role;
create or replace function portal_private.criteria_file_read(p_path text,p_owner text) returns boolean language sql stable security definer set search_path='' as $$
 select (exists(select 1 from portal_private.crm_criteria_observations o where o.id::text=split_part(p_path,'/',1) and portal_private.project_criteria_access(o.project_id)) and (p_owner=auth.uid()::text or exists(select 1 from portal_private.crm_criteria_files where path=p_path))) or portal_private.handover_criteria_file_read(p_path);
$$;
create function public.handover_criteria_file(p_handover uuid,p_file uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$declare f portal_private.crm_criteria_files;begin
 if not portal_private.handover_read(p_handover) then raise exception 'Current handover access required';end if;
 select x.* into f from portal_private.crm_criteria_files x join portal_private.crm_handover_criteria_files l on l.file_id=x.id and l.handover_id=p_handover where x.id=p_file;
 if not found or not portal_private.handover_criteria_file_read(f.path) then raise exception 'Only exact handover-selected evidence is available';end if;
 return jsonb_build_object('id',f.id,'path',f.path,'name',f.name,'size',f.size,'mime',f.mime);
end$$;
revoke all on function public.handover_criteria_file(uuid,uuid) from public,anon,service_role;
grant execute on function public.handover_criteria_file(uuid,uuid) to authenticated;
