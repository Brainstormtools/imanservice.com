-- Optional project CSAT with explicit ownership and immutable closure attribution.
begin;
create table public.project_performance_owners(project_id uuid primary key references public.projects,user_id uuid references public.profiles,version integer not null default 1,history jsonb not null default '[]');
create table public.handover_performance_basis(id uuid primary key default gen_random_uuid(),handover_id uuid not null unique references public.crm_handovers,project_id uuid not null references public.projects,user_id uuid references public.profiles,closed_at timestamptz not null,snapshot_hash text not null);
create table public.handover_ratings(id uuid primary key default gen_random_uuid(),handover_id uuid not null unique references public.crm_handovers,project_id uuid not null references public.projects,basis_id uuid references public.handover_performance_basis,user_id uuid references public.profiles,client_id uuid not null references public.profiles,rating integer not null check(rating between 1 and 5),comment text not null check(length(comment)<=2000),snapshot_hash text not null,created_at timestamptz not null default now());
create index handover_ratings_month on public.handover_ratings(user_id,created_at);
create index handover_ratings_project on public.handover_ratings(project_id);
alter table public.project_performance_owners enable row level security;
alter table public.handover_performance_basis enable row level security;
alter table public.handover_ratings enable row level security;
create policy project_performance_read on public.project_performance_owners for select to authenticated using(public.is_staff() and public.can_project(project_id));
create policy handover_basis_read on public.handover_performance_basis for select to authenticated using(public.is_staff() and portal_private.handover_read(handover_id));
create policy handover_rating_read on public.handover_ratings for select to authenticated using((public.is_staff() and portal_private.handover_read(handover_id)) or (client_id=auth.uid() and public.can_project(project_id)));
revoke all on public.project_performance_owners,public.handover_performance_basis,public.handover_ratings from public,anon,authenticated;
grant select on public.project_performance_owners,public.handover_performance_basis,public.handover_ratings to authenticated;
create function public.set_project_performance_owner(p_project uuid,p_owner uuid,p_version integer,p_reason text) returns void language plpgsql security definer set search_path='' as $$declare o public.project_performance_owners;h jsonb;begin
 if not public.is_admin() or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Administrator and assignment reason required';end if;
 perform 1 from public.projects where id=p_project and status<>'Completed' for update;if not found then raise exception 'Open project required; closed ownership is fixed';end if;
 if p_owner is not null and not exists(select 1 from public.profiles u where u.id=p_owner and u.active and u.role in ('admin','team') and (u.role='admin' or exists(select 1 from public.project_assignments a where a.project_id=p_project and a.technician_id=u.id))) then raise exception 'Owner must already have assigned project access';end if;
 select * into o from public.project_performance_owners where project_id=p_project for update;
 if (o.project_id is null and p_version is not null) or (o.project_id is not null and o.version is distinct from p_version) then raise exception 'Current ownership version required';end if;
 h:=coalesce(o.history,'[]')||jsonb_build_array(jsonb_build_object('user_id',p_owner,'reason',trim(p_reason),'actor_id',auth.uid(),'at',now()));
 insert into public.project_performance_owners(project_id,user_id,history) values(p_project,p_owner,h) on conflict(project_id) do update set user_id=excluded.user_id,version=project_performance_owners.version+1,history=excluded.history;
end$$;
create function portal_private.capture_handover_performance() returns trigger language plpgsql security definer set search_path='' as $$declare owner uuid;begin
 if new.status='Closed' and old.status<>'Closed' then
 select user_id into owner from public.project_performance_owners where project_id=new.project_id;
 if owner is not null and not portal_private.handover_signer_eligible(new.project_id,owner,'Contractor') then raise exception 'Performance owner lost assigned access; clear or replace before closure';end if;
 insert into public.handover_performance_basis(handover_id,project_id,user_id,closed_at,snapshot_hash) values(new.id,new.project_id,owner,new.closed_at,new.snapshot_hash);
 end if;return new;
end$$;
create trigger capture_handover_performance after update on public.crm_handovers for each row execute function portal_private.capture_handover_performance();
create function public.rate_crm_handover(p_handover uuid,p_rating integer,p_comment text) returns uuid language plpgsql security definer set search_path='' as $$declare h public.crm_handovers;p public.projects;b public.handover_performance_basis;r public.handover_ratings;begin
 select * into h from public.crm_handovers where id=p_handover;
 if h.id is null or not exists(select 1 from public.profiles where id=auth.uid() and active and role='client') or h.client_id is distinct from auth.uid() or not public.can_project(h.project_id) then raise exception 'Own signed client handover required';end if;
 select * into p from public.projects where id=h.project_id for update;select * into h from public.crm_handovers where id=p_handover for update;
 if h.status<>'Closed' or p.status<>'Completed' or p.handover_id is distinct from h.id or not exists(select 1 from public.crm_handover_documents where handover_id=h.id) or not exists(select 1 from public.crm_handover_signatures where handover_id=h.id and party='Client' and signer_id=auth.uid() and snapshot_hash=h.snapshot_hash) or p_rating is null or p_rating not between 1 and 5 or length(coalesce(p_comment,''))>2000 then raise exception 'Archived signed handover and rating 1–5 required';end if;
 select * into r from public.handover_ratings where handover_id=h.id;
 if r.id is not null then if r.client_id=auth.uid() and r.rating=p_rating and r.comment=coalesce(p_comment,'') then return r.id;end if;raise exception 'A handover rating is permanent';end if;
 select * into b from public.handover_performance_basis where handover_id=h.id;
 insert into public.handover_ratings(handover_id,project_id,basis_id,user_id,client_id,rating,comment,snapshot_hash) values(h.id,h.project_id,b.id,b.user_id,auth.uid(),p_rating,coalesce(p_comment,''),h.snapshot_hash) returning id into r.id;return r.id;
end$$;
alter function portal_private.hr_month(uuid,date) rename to hr_month_before_handover_ratings;
create function portal_private.hr_month(p_user uuid,p_month date) returns jsonb language plpgsql stable security definer set search_path='' as $$declare data jsonb;ratings jsonb;average_rating numeric;rating_count integer;project_average numeric;project_count integer;metrics jsonb;score numeric:=0;coverage numeric:=0;w record;band jsonb;bonus numeric;basic numeric;begin
 data:=portal_private.hr_month_before_handover_ratings(p_user,p_month);
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'handover_id',handover_id,'basis_id',basis_id,'rating',rating,'created_at',created_at) order by id),'[]'),avg(rating),count(*) into ratings,project_average,project_count from public.handover_ratings where user_id=p_user and (created_at at time zone 'Asia/Karachi')::date>=p_month and (created_at at time zone 'Asia/Karachi')::date<p_month+interval '1 month';
 -- Combine individual values, not rounded source averages; each client rating counts once.
 select avg(rating),count(*) into average_rating,rating_count from (select rating,created_at from public.service_ratings where user_id=p_user union all select rating,created_at from public.handover_ratings where user_id=p_user) all_ratings where (created_at at time zone 'Asia/Karachi')::date>=p_month and (created_at at time zone 'Asia/Karachi')::date<p_month+interval '1 month';
 metrics:=(data->'metrics')||jsonb_build_object('customer_rating',round(average_rating/5*100,2));
 for w in select key,(value#>>'{}')::numeric weight from jsonb_each(data->'policy'->'weights') loop if metrics->>w.key is not null then score:=score+w.weight*(metrics->>w.key)::numeric/100;coverage:=coverage+w.weight;end if;end loop;
 if coverage<>100 then score:=null;end if;select x into band from jsonb_array_elements(data->'policy'->'bonus_slabs') x where (x->>'score')::numeric<=score order by (x->>'score')::numeric desc limit 1;
 basic:=(data->>'salary')::numeric;bonus:=case when score is null then null when band is null then 0 when band->>'mode'='Salary percent' then round(basic*(band->>'amount')::numeric/100,2) else (band->>'amount')::numeric end;
 return data||jsonb_build_object('metrics',metrics,'score',round(score,2),'coverage',coverage,'bonus',bonus,'bonus_basis',jsonb_build_object('band',band,'salary_base',basic,'base_description','Prorated basic salary before deductions; excludes overtime and TADA'),'gross_salary_summary',basic+(data->>'overtime_pay')::numeric+bonus,'projected_net_before_manual_deductions',basic+(data->>'overtime_pay')::numeric+bonus-coalesce((data->>'automatic_deductions')::numeric,0),'project_rating_sources',ratings,'project_rating_average',round(project_average,2),'project_rating_count',project_count,'customer_rating_average',round(average_rating,2),'customer_rating_count',rating_count,'customer_rating_note','Customer rating combines individual ticket-service and project-handover ratings submitted this Pakistan calendar month: average 1–5 / 5 × 100. Project ownership is explicitly configured before closure and captured at archive. No legacy ownership is reconstructed. Unrated or unattributed work is not employee credit. Saved locked summaries remain unchanged.');
end$$;
revoke all on function public.set_project_performance_owner(uuid,uuid,integer,text),public.rate_crm_handover(uuid,integer,text) from public,anon;
grant execute on function public.set_project_performance_owner(uuid,uuid,integer,text),public.rate_crm_handover(uuid,integer,text) to authenticated;
revoke all on function portal_private.capture_handover_performance(),portal_private.hr_month(uuid,date),portal_private.hr_month_before_handover_ratings(uuid,date) from public,anon,authenticated;
commit;
