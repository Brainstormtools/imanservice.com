-- User-authorized retained acceptance workspace. No business data or financial terms.
-- Refuse ambiguous configuration; reruns preserve existing test work.
begin;
do $$declare a uuid;c uuid;g uuid;p uuid;b uuid;pm uuid;tl uuid;tech uuid;sa uuid;sm uuid;begin
 select id into a from public.profiles where role='admin' and active order by id limit 1;
 select id into c from public.companies where name='Portal acceptance test customer';
 select id into g from public.crm_teams where name='Portal acceptance test team' and active;
 select id into pm from public.profiles where name='Acceptance Project Manager' and active;
 select id into tl from public.profiles where name='Acceptance Team Lead' and active;
 select id into tech from public.profiles where name='Acceptance Technician' and active;
 select id into sa from public.profiles where name='Acceptance Sales Agent' and active;
 select id into sm from public.profiles where name='Acceptance Sales Manager' and active;
 if a is null or c is null or g is null or pm is null or tl is null or tech is null or sa is null or sm is null then raise exception 'Confirmed acceptance configuration required';end if;
 if not exists(select 1 from portal_private.sales_manager_lead_scopes where user_id=sm and team_id=g) then raise exception 'Isolated sales-manager scope required';end if;
 if (select count(*) from public.profiles where name in ('Acceptance Project Manager','Acceptance Team Lead','Acceptance Technician','Acceptance Sales Agent','Acceptance Sales Manager') and active)<>5 then raise exception 'Ambiguous acceptance profiles';end if;
 perform set_config('request.jwt.claim.sub',a::text,true);
 select id into p from public.projects where company_id=c and title='Portal acceptance test project';
 if p is null then insert into public.projects(company_id,title,description) values(c,'Portal acceptance test project','Synthetic acceptance workspace only. No real service, payment or employment obligation.') returning id into p;end if;
 insert into public.project_assignments(project_id,technician_id,assigned_by) values(p,pm,a),(p,tl,a) on conflict do nothing;
 if not exists(select 1 from public.tasks where project_id=p and title='Acceptance technician workflow') then insert into public.tasks(project_id,title,assignee) values(p,'Acceptance technician workflow',tech);end if;
 select id into b from public.crm_boards where code='portal_acceptance';
 if b is null then insert into public.crm_boards(code,name,color,outcome) values('portal_acceptance','Portal acceptance test board','#64748B','Project') returning id into b;end if;
 perform public.set_sales_board_member(b,sa,true);perform public.set_sales_board_member(b,sm,true);
 if not exists(select 1 from public.crm_leads where email='portal-acceptance@example.test') then insert into public.crm_leads(name,email,source,owner_id) values('Portal acceptance synthetic lead','portal-acceptance@example.test','Isolated acceptance test',sa);end if;
end$$;
commit;
