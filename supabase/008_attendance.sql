begin;
create table public.attendance_entries(
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles,
 checked_in timestamptz not null default now(), checked_out timestamptz,
 version integer not null default 1, voided boolean not null default false,
 check(isfinite(checked_in)), check(checked_out is null or (isfinite(checked_out) and checked_out>checked_in and checked_out<=checked_in+interval '48 hours'))
);
create unique index attendance_one_open on public.attendance_entries(user_id) where checked_out is null and not voided;
create table public.attendance_history(
 id uuid primary key default gen_random_uuid(),entry_id uuid not null references public.attendance_entries,
 actor_id uuid not null default auth.uid() references public.profiles, action text not null,
 reason text not null default '' check(length(reason)<=2000),before_value jsonb,after_value jsonb,created_at timestamptz not null default now()
);
alter table public.attendance_entries enable row level security;
alter table public.attendance_history enable row level security;
create policy attendance_read on public.attendance_entries for select to authenticated using(public.is_admin() or (public.is_staff() and user_id=auth.uid()));
create policy attendance_history_read on public.attendance_history for select to authenticated using(exists(select 1 from public.attendance_entries a where a.id=entry_id and (public.is_admin() or (public.is_staff() and a.user_id=auth.uid()))));
create function public.attendance_clock(p_action text,p_id uuid default null,p_version integer default null) returns uuid language plpgsql security definer set search_path='' as $$
declare a public.attendance_entries;
begin
 if not public.is_staff() then raise exception 'Active staff access required';end if;
 perform pg_advisory_xact_lock(hashtextextended('attendance:'||auth.uid()::text,0));
 if p_action='in' then
  select * into a from public.attendance_entries where user_id=auth.uid() and checked_out is null and not voided;
  if found then return a.id;end if;
  insert into public.attendance_entries(user_id) values(auth.uid()) returning * into a;
  insert into public.attendance_history(entry_id,action,after_value) values(a.id,'Check in',to_jsonb(a));
 elsif p_action='out' then
  select * into a from public.attendance_entries where id=p_id and user_id=auth.uid() and not voided for update;
  if not found then raise exception 'Attendance unavailable';end if;
  if a.checked_out is not null then return a.id;end if;
  if a.version is distinct from p_version then raise exception 'Attendance changed. Refresh first.';end if;
  if now()<=a.checked_in or now()>a.checked_in+interval '48 hours' then raise exception 'Ask an administrator to correct this attendance entry';end if;
  update public.attendance_entries set checked_out=now(),version=version+1 where id=a.id;
  insert into public.attendance_history(entry_id,action,before_value,after_value) select a.id,'Check out',to_jsonb(a),to_jsonb(e) from public.attendance_entries e where e.id=a.id;
 else raise exception 'Choose check in or check out';end if;
 return a.id;
end $$;
create function public.correct_attendance(p_id uuid,p_version integer,p_user uuid,p_in timestamptz,p_out timestamptz,p_void boolean,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare a public.attendance_entries;b jsonb;
begin
 if not public.is_admin() then raise exception 'Administrator access required';end if;
 if length(trim(coalesce(p_reason,'')))<3 or length(p_reason)>2000 then raise exception 'Enter a correction reason (3–2000 characters)';end if;
 if p_in is null or not isfinite(p_in) or p_in>now() or (p_out is not null and (not isfinite(p_out) or p_out>now() or p_out<=p_in or p_out>p_in+interval '48 hours')) then raise exception 'Use valid past timestamps and a duration of at most 48 hours';end if;
 if not exists(select 1 from public.profiles where id=p_user and role in ('admin','team')) then raise exception 'Staff member required';end if;
 perform pg_advisory_xact_lock(hashtextextended('attendance:'||p_user::text,0));
 if p_id is not null then
  select * into a from public.attendance_entries where id=p_id for update;
  if not found or a.user_id<>p_user or a.version is distinct from p_version then raise exception 'Attendance changed or unavailable. Refresh first.';end if;
  b:=to_jsonb(a);
 end if;
 if not p_void and exists(select 1 from public.attendance_entries e where e.user_id=p_user and not e.voided and e.id is distinct from p_id and tstzrange(e.checked_in,e.checked_out,'[)') && tstzrange(p_in,p_out,'[)')) then raise exception 'Attendance overlaps another entry';end if;
 if p_id is null then
  insert into public.attendance_entries(user_id,checked_in,checked_out,voided) values(p_user,p_in,p_out,p_void) returning * into a;
 else
  update public.attendance_entries set checked_in=p_in,checked_out=p_out,voided=p_void,version=version+1 where id=p_id returning * into a;
 end if;
 insert into public.attendance_history(entry_id,action,reason,before_value,after_value) values(a.id,case when p_void then 'Voided' else 'Admin correction' end,p_reason,b,to_jsonb(a));
 return a.id;
end $$;
revoke all on public.attendance_entries,public.attendance_history from anon,authenticated;
grant select on public.attendance_entries,public.attendance_history to authenticated;
revoke all on function public.attendance_clock(text,uuid,integer),public.correct_attendance(uuid,integer,uuid,timestamptz,timestamptz,boolean,text) from public,anon;
grant execute on function public.attendance_clock(text,uuid,integer),public.correct_attendance(uuid,integer,uuid,timestamptz,timestamptz,boolean,text) to authenticated;
commit;
