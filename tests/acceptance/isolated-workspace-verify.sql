-- Read-only authenticated role assertions; rolled back after checking.
begin;
do $$declare r record;p integer;t integer;b integer;l integer;c integer;n integer:=0;begin
 for r in select id,name from public.profiles where name in ('Acceptance Project Manager','Acceptance Team Lead','Acceptance Technician','Acceptance Customer','Acceptance Sales Agent','Acceptance Sales Manager') loop
  perform set_config('request.jwt.claim.sub',r.id::text,true);execute 'set local role authenticated';
  select count(*) into p from public.projects;select count(*) into t from public.tasks;
  select count(*) into b from public.crm_boards;select count(*) into l from public.crm_leads;select count(*) into c from public.companies;
  if r.name in ('Acceptance Sales Agent','Acceptance Sales Manager') then
   if p<>0 or t<>0 or b<>1 or l<>1 or c<>0 then raise exception 'Sales isolation failed: %, project %, task %, board %, lead %, company %',r.name,p,t,b,l,c;end if;
   if exists(select 1 from public.crm_boards where code<>'portal_acceptance') or exists(select 1 from public.crm_leads where email<>'portal-acceptance@example.test') then raise exception 'Sales business record visible';end if;
  else
   if p<>1 or t<>1 or b<>0 or l<>0 or c<>1 then raise exception 'Work isolation failed: %, project %, task %, board %, lead %, company %',r.name,p,t,b,l,c;end if;
   if exists(select 1 from public.projects where title<>'Portal acceptance test project') or exists(select 1 from public.tasks where title<>'Acceptance technician workflow') or exists(select 1 from public.companies where name<>'Portal acceptance test customer') then raise exception 'Work business record visible';end if;
  end if;
  if exists(select 1 from public.crm_deals) then raise exception 'Unexpected deal visibility';end if;
  n:=n+1;execute 'reset role';
 end loop;
 if n<>6 then raise exception 'Six role profiles required';end if;
end$$;
rollback;
select 'Six roles passed count, exact-record and deal visibility assertions (18 grouped assertions)' result;
