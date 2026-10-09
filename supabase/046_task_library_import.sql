begin;
create table public.crm_task_library_imports(author_id uuid not null references public.profiles,batch_id uuid not null,source_name text not null,reason text not null,source_hash text not null,standard_ids uuid[] not null,created_at timestamptz not null default now(),primary key(author_id,batch_id));
alter table public.crm_task_library_imports enable row level security;
revoke all on public.crm_task_library_imports from public,anon,authenticated;
grant select on public.crm_task_library_imports to authenticated;
create policy task_library_import_read on public.crm_task_library_imports for select to authenticated using(public.is_admin());
create function public.import_crm_task_standards(p_batch uuid,p_source text,p_reason text,p_rows jsonb) returns uuid[] language plpgsql security definer set search_path='' as $$declare receipt public.crm_task_library_imports;hash text;row jsonb;ids uuid[]:='{}';names text[]:='{}';keys text[]:='{}';name text;key text;begin
if not public.is_admin() then raise exception 'Administrator reviews task-library imports';end if;
if p_batch is null or length(trim(coalesce(p_source,''))) not between 1 and 180 or length(trim(coalesce(p_reason,''))) not between 3 and 2000 or jsonb_typeof(p_rows) is distinct from 'array' then raise exception 'Import batch, source, review reason and rows required';end if;
if jsonb_array_length(p_rows) not between 1 and 100 or length(p_rows::text)>1000000 then raise exception 'Use 1–100 bounded standard rows';end if;
-- Serialize same actor/batch retries before inspecting the immutable receipt.
perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(auth.uid()::text||p_batch::text,0));
hash:=md5(jsonb_build_array(trim(p_source),trim(p_reason),p_rows)::text);
select * into receipt from public.crm_task_library_imports where author_id=auth.uid() and batch_id=p_batch;
if found then if receipt.source_hash is distinct from hash then raise exception 'Import batch already used for different reviewed data';end if;return receipt.standard_ids;end if;
for row in select value from jsonb_array_elements(p_rows) loop
if jsonb_typeof(row) is distinct from 'object' then raise exception 'Standard row object required';end if;
name:=trim(coalesce(row->>'name',''));key:=row->'task'->>'key';
if lower(name)=any(names) or key=any(keys) then raise exception 'Duplicate standard name or task key in import';end if;names:=names||lower(name);keys:=keys||key;
-- Import cannot supply IDs, existing versions, activation or formula parameters.
if row-'name'-'task'<>'{}'::jsonb or (row->'task')-'key'-'phase'-'title'-'process'-'step'-'unit'-'minutes'-'fixed_minutes'-'fixed_quantity'-'crew'-'crew_role'-'tools'-'preconditions'-'quantity_parameters'-'factor_parameter'-'condition_parameter'-'depends_on'-'checklist'<>'{}'::jsonb or row->'task'->'quantity_parameters' is distinct from '[]'::jsonb or row->'task'->'depends_on' is distinct from '[]'::jsonb or coalesce(row->'task'->>'factor_parameter','')<>'' or coalesce(row->'task'->>'condition_parameter','')<>'' then raise exception 'Import new fixed standards only; formulas require manual review';end if;
-- Validate exact numeric ranges/types before the existing validator's integer casts.
if coalesce(row->'task'->>'phase','') !~ '^[0-5]$' or coalesce(row->'task'->>'crew','') !~ '^[1-9][0-9]?$|^100$' then raise exception 'Integer phase and crew required';end if;
ids:=ids||public.save_crm_task_standard(null,null,name,false,'[]',row->'task',trim(p_reason));
end loop;
insert into public.crm_task_library_imports(author_id,batch_id,source_name,reason,source_hash,standard_ids) values(auth.uid(),p_batch,trim(p_source),trim(p_reason),hash,ids);
return ids;end$$;
revoke all on function public.import_crm_task_standards(uuid,text,text,jsonb) from public,anon;
grant execute on function public.import_crm_task_standards(uuid,text,text,jsonb) to authenticated;
commit;
