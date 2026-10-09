begin;
-- A legacy locked summary treated the full month as employed. Adding explicit
-- dates is safe only when every day in that locked month remains employed.
do $$declare definition text;begin
 select pg_get_functiondef('public.save_hr_employment(uuid,date,date,integer,text)'::regprocedure) into definition;
 if position('old.user_id is null or ((x::date>=old.starts_on' in definition)=0 then raise exception 'Employment lock source changed';end if;
 definition:=replace(definition,'(old.user_id is null or ((x::date>=old.starts_on and (old.ends_on is null or x::date<=old.ends_on)) is distinct from (x::date>=p_start and (p_end is null or x::date<=p_end))))','((case when old.user_id is null then true else x::date>=old.starts_on and (old.ends_on is null or x::date<=old.ends_on) end) is distinct from (x::date>=p_start and (p_end is null or x::date<=p_end)))');
 if position('old.user_id is null or ((x::date>=old.starts_on' in definition)>0 then raise exception 'Employment lock replacement failed';end if;execute definition;
end$$;
commit;
