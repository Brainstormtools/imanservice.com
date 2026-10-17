begin;
create table public.crm_project_communication_reviews(
 id uuid primary key,plan_id uuid not null references public.crm_project_communication_drafts,project_id uuid not null references public.projects,
 plan_version integer not null,sequence integer not null,action text not null check(action in ('Reviewed','Returned')),
 snapshot jsonb not null,charter_snapshot jsonb not null,request jsonb not null,reason text not null,
 actor_id uuid not null references public.profiles,created_at timestamptz not null default now(),unique(plan_id,sequence)
);
create index communication_review_project on public.crm_project_communication_reviews(project_id);
create index communication_review_actor on public.crm_project_communication_reviews(actor_id);
alter table public.crm_project_communication_reviews enable row level security;
revoke all on public.crm_project_communication_reviews from public,anon,authenticated;
grant select on public.crm_project_communication_reviews to authenticated;
create policy communication_review_read on public.crm_project_communication_reviews for select to authenticated using(portal_private.execution_manager(project_id));
create function public.review_project_communication_draft(p_id uuid,p_plan uuid,p_version integer,p_action text,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare d public.crm_project_communication_drafts;c public.crm_project_charters;retry public.crm_project_communication_reviews;prior public.crm_project_communication_reviews;req jsonb;next_sequence integer;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Active administrator required to review communication plans';end if;
 select * into d from public.crm_project_communication_drafts where id=p_plan;
 if d.id is null then raise exception 'Existing communication draft required';end if;
 -- Same project-first order as charter/draft saves serializes concurrent source changes and decisions.
 perform 1 from public.projects where id=d.project_id for update;
 select * into d from public.crm_project_communication_drafts where id=p_plan for update;
 if p_id is null or p_version is null or p_action is null or p_action not in ('Reviewed','Returned') or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Explicit identity/version/action/manual reason required';end if;
 req:=jsonb_build_object('plan_id',p_plan,'version',p_version,'action',p_action,'reason',trim(p_reason));
 select * into retry from public.crm_project_communication_reviews where id=p_id;
 if retry.id is not null then
  if retry.actor_id=auth.uid() and retry.request=req then return retry.id;end if;
  raise exception 'Decision identity records a different request';
 end if;
 if d.version is distinct from p_version then raise exception 'Communication draft changed; refresh version';end if;
 select * into c from public.crm_project_charters where id=d.charter_id for share;
 if c.id is null or c.project_id is distinct from d.project_id then raise exception 'Existing source charter required';end if;
 -- Return documents corrections even after source change/archive. Review requires exact current source evidence.
 if p_action='Reviewed' and (c.details->>'status' is distinct from 'Reviewed' or d.charter_version is distinct from c.version or d.source_snapshot is distinct from to_jsonb(c)) then raise exception 'Refresh draft from exact current Reviewed charter before communication review';end if;
 select * into prior from public.crm_project_communication_reviews where plan_id=d.id and plan_version=d.version order by sequence desc limit 1;
 if prior.action=p_action then raise exception 'This communication version already has that review state';end if;
 select coalesce(max(sequence),0)+1 into next_sequence from public.crm_project_communication_reviews where plan_id=d.id;
 insert into public.crm_project_communication_reviews(id,plan_id,project_id,plan_version,sequence,action,snapshot,charter_snapshot,request,reason,actor_id)
 values(p_id,d.id,d.project_id,d.version,next_sequence,p_action,to_jsonb(d),to_jsonb(c),req,trim(p_reason),auth.uid());
 return p_id;
end$$;
revoke all on function public.review_project_communication_draft(uuid,uuid,integer,text,text) from public,anon;
grant execute on function public.review_project_communication_draft(uuid,uuid,integer,text,text) to authenticated;
notify pgrst,'reload schema';
commit;
