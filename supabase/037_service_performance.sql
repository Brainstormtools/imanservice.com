begin;
create table public.ticket_performance_owners(ticket_id uuid primary key references public.tickets,project_id uuid not null references public.projects,user_id uuid references public.profiles,version integer not null default 1,history jsonb not null default '[]');
create table public.ticket_resolution_history(id uuid primary key default gen_random_uuid(),ticket_id uuid not null references public.tickets,project_id uuid not null references public.projects,user_id uuid references public.profiles,revision integer not null,resolved_at timestamptz not null,resolution_due_at timestamptz,sla_note text not null,recorded_by uuid references public.profiles,created_at timestamptz not null default now(),unique(ticket_id,revision));
create index ticket_resolution_month on public.ticket_resolution_history(user_id,resolved_at,ticket_id);
create table public.service_ratings(id uuid primary key default gen_random_uuid(),signoff_id uuid not null unique references public.service_signoffs,resolution_id uuid not null unique references public.ticket_resolution_history,project_id uuid not null references public.projects,user_id uuid references public.profiles,client_id uuid not null references public.profiles,rating integer not null check(rating between 1 and 5),comment text not null check(length(comment)<=2000),created_at timestamptz not null default now());
create index service_ratings_month on public.service_ratings(user_id,created_at);
alter table public.ticket_performance_owners enable row level security;
alter table public.ticket_resolution_history enable row level security;
alter table public.service_ratings enable row level security;
create policy owner_read on public.ticket_performance_owners for select to authenticated using(public.is_admin() or portal_private.ticket_visible(ticket_id));
create policy resolution_read on public.ticket_resolution_history for select to authenticated using(public.is_admin() or portal_private.ticket_visible(ticket_id));
create policy rating_read on public.service_ratings for select to authenticated using(public.is_admin() or (public.is_staff() and exists(select 1 from public.ticket_resolution_history h where h.id=resolution_id and portal_private.ticket_visible(h.ticket_id))) or (not public.is_staff() and client_id=auth.uid() and public.can_project(project_id)));
revoke all on public.ticket_performance_owners,public.ticket_resolution_history,public.service_ratings from public,anon,authenticated;
grant select on public.ticket_performance_owners,public.ticket_resolution_history,public.service_ratings to authenticated;
create function public.set_ticket_performance_owner(p_ticket uuid,p_owner uuid,p_version integer,p_reason text) returns void language plpgsql security definer set search_path='' as $$declare t public.tickets;o public.ticket_performance_owners;h jsonb;begin
 if not public.is_admin() or length(trim(coalesce(p_reason,''))) not between 3 and 2000 then raise exception 'Administrator and assignment reason required';end if;
 select * into t from public.tickets where id=p_ticket for update;if t.id is null then raise exception 'Ticket unavailable';end if;
 if p_owner is not null and not exists(select 1 from public.profiles u where u.id=p_owner and u.active and u.role in ('admin','team') and (u.role='admin' or exists(select 1 from public.project_assignments a where a.project_id=t.project_id and a.technician_id=u.id) or exists(select 1 from public.tasks k where k.ticket_id=t.id and (k.assignee=u.id or u.id=any(k.collaborators))))) then raise exception 'Owner must already have assigned ticket/project access';end if;
 select * into o from public.ticket_performance_owners where ticket_id=t.id for update;
 if (o.ticket_id is null and p_version is not null) or (o.ticket_id is not null and o.version is distinct from p_version) then raise exception 'Current ownership version required';end if;
 h:=coalesce(o.history,'[]')||jsonb_build_array(jsonb_build_object('user_id',p_owner,'reason',trim(p_reason),'actor_id',auth.uid(),'at',now()));
 insert into public.ticket_performance_owners(ticket_id,project_id,user_id,history) values(t.id,t.project_id,p_owner,h) on conflict(ticket_id) do update set user_id=excluded.user_id,version=ticket_performance_owners.version+1,history=excluded.history;
end$$;
create function portal_private.capture_ticket_resolution() returns trigger language plpgsql security definer set search_path='' as $$begin
 if new.status='Resolved' and old.status<>'Resolved' then
 insert into public.ticket_resolution_history(ticket_id,project_id,user_id,revision,resolved_at,resolution_due_at,sla_note,recorded_by) values(new.id,new.project_id,(select user_id from public.ticket_performance_owners where ticket_id=new.id),coalesce((select max(revision)+1 from public.ticket_resolution_history where ticket_id=new.id),1),new.resolved_at,new.resolution_due_at,new.sla_note,auth.uid());end if;return new;
end$$;
create trigger capture_ticket_resolution after update on public.tickets for each row execute function portal_private.capture_ticket_resolution();
alter table public.service_signoffs add column resolution_id uuid references public.ticket_resolution_history;
create function portal_private.link_signoff_resolution() returns trigger language plpgsql security definer set search_path='' as $$begin
 select id into new.resolution_id from public.ticket_resolution_history where ticket_id=new.ticket_id order by revision desc limit 1;return new;
end$$;
create trigger link_signoff_resolution before insert on public.service_signoffs for each row execute function portal_private.link_signoff_resolution();
create function public.rate_service_signoff(p_signoff uuid,p_rating integer,p_comment text) returns uuid language plpgsql security definer set search_path='' as $$declare s public.service_signoffs;t public.tickets;h public.ticket_resolution_history;r public.service_ratings;begin
 select * into s from public.service_signoffs where id=p_signoff;
 if s.id is null or not exists(select 1 from public.profiles u where u.id=auth.uid() and u.active and u.role='client') or not public.can_project(s.project_id) or s.decided_by is distinct from auth.uid() then raise exception 'Own accepted client sign-off required';end if;
 select * into t from public.tickets where id=s.ticket_id for update;select * into s from public.service_signoffs where id=p_signoff for update;
 select * into h from public.ticket_resolution_history where id=s.resolution_id;
 if s.status<>'Accepted' or t.status<>'Resolved' or h.id is null or h.id is distinct from (select id from public.ticket_resolution_history where ticket_id=t.id order by revision desc limit 1) or h.resolved_at is distinct from t.resolved_at or p_rating is null or p_rating not between 1 and 5 or length(coalesce(p_comment,''))>2000 then raise exception 'Current accepted resolution and rating 1–5 required';end if;
 select * into r from public.service_ratings where resolution_id=h.id;
 if r.id is not null then if r.signoff_id=s.id and r.client_id=auth.uid() and r.rating=p_rating and r.comment=coalesce(p_comment,'') then return r.id;end if;raise exception 'A resolution rating is permanent';end if;
 insert into public.service_ratings(signoff_id,resolution_id,project_id,user_id,client_id,rating,comment) values(s.id,h.id,s.project_id,h.user_id,auth.uid(),p_rating,coalesce(p_comment,'')) returning id into r.id;return r.id;
end$$;
do $$declare definition text;begin
 select pg_get_functiondef('public.save_hr_policy(jsonb)'::regprocedure) into definition;
 if position('''on_time_task'')' in definition)=0 then raise exception 'KPI validator changed';end if;
 definition:=replace(definition,'''on_time_task'')','''on_time_task'',''ticket_sla'',''customer_rating'')');execute definition;
end$$;
alter function portal_private.hr_month(uuid,date) rename to hr_month_before_service_performance;
create function portal_private.hr_month(p_user uuid,p_month date) returns jsonb language plpgsql stable security definer set search_path='' as $$declare data jsonb;resolutions jsonb;ratings jsonb;total integer;missing integer;within_sla integer;average_rating numeric;rating_count integer;metrics jsonb;score numeric:=0;coverage numeric:=0;w record;band jsonb;bonus numeric;basic numeric;begin
 data:=portal_private.hr_month_before_service_performance(p_user,p_month);
 select coalesce(jsonb_agg(to_jsonb(h) order by ticket_id),'[]') into resolutions from (select distinct on(ticket_id) * from public.ticket_resolution_history where user_id=p_user and (resolved_at at time zone 'Asia/Karachi')::date>=p_month and (resolved_at at time zone 'Asia/Karachi')::date<p_month+interval '1 month' order by ticket_id,revision desc) h;
 select count(*),count(*) filter(where x->>'resolution_due_at' is null),count(*) filter(where (x->>'resolved_at')::timestamptz<=(x->>'resolution_due_at')::timestamptz) into total,missing,within_sla from jsonb_array_elements(resolutions) x;
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'resolution_id',resolution_id,'rating',rating,'created_at',created_at) order by id),'[]'),avg(rating),count(*) into ratings,average_rating,rating_count from public.service_ratings where user_id=p_user and (created_at at time zone 'Asia/Karachi')::date>=p_month and (created_at at time zone 'Asia/Karachi')::date<p_month+interval '1 month';
 metrics:=(data->'metrics')||jsonb_build_object('ticket_sla',case when total>0 and missing=0 then round(within_sla::numeric/total*100,2) end,'customer_rating',round(average_rating/5*100,2));
 for w in select key,(value#>>'{}')::numeric weight from jsonb_each(data->'policy'->'weights') loop if metrics->>w.key is not null then score:=score+w.weight*(metrics->>w.key)::numeric/100;coverage:=coverage+w.weight;end if;end loop;
 if coverage<>100 then score:=null;end if;select x into band from jsonb_array_elements(data->'policy'->'bonus_slabs') x where (x->>'score')::numeric<=score order by (x->>'score')::numeric desc limit 1;
 basic:=(data->>'salary')::numeric;bonus:=case when score is null then null when band is null then 0 when band->>'mode'='Salary percent' then round(basic*(band->>'amount')::numeric/100,2) else (band->>'amount')::numeric end;
 return data||jsonb_build_object('metrics',metrics,'score',round(score,2),'coverage',coverage,'bonus',bonus,'bonus_basis',jsonb_build_object('band',band,'salary_base',basic,'base_description','Prorated basic salary before deductions; excludes overtime and TADA'),'gross_salary_summary',basic+(data->>'overtime_pay')::numeric+bonus,'projected_net_before_manual_deductions',basic+(data->>'overtime_pay')::numeric+bonus-coalesce((data->>'automatic_deductions')::numeric,0),'service_resolution_sources',resolutions,'service_rating_sources',ratings,'service_resolved',total,'service_sla_missing',missing,'service_rating_average',round(average_rating,2),'service_rating_count',rating_count,'service_performance_note','SLA uses the latest captured resolution per ticket in this resolution month and the owner recorded at resolution. Existing contract clocks are 24/7; waiting-on-client pause rules remain pending. CSAT uses ratings submitted this month: average 1–5 divided by 5 × 100. Unrated work is not scored as zero. Legacy resolutions are not reconstructed. Unassigned resolutions have no employee attribution.');
end$$;
revoke all on function public.set_ticket_performance_owner(uuid,uuid,integer,text),public.rate_service_signoff(uuid,integer,text) from public,anon;
grant execute on function public.set_ticket_performance_owner(uuid,uuid,integer,text),public.rate_service_signoff(uuid,integer,text) to authenticated;
revoke all on function portal_private.capture_ticket_resolution(),portal_private.link_signoff_resolution(),portal_private.hr_month(uuid,date),portal_private.hr_month_before_service_performance(uuid,date) from public,anon,authenticated;
commit;
