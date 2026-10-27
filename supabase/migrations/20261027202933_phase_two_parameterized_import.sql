-- APPLIED via native connected migration 20261027202933; CLI unavailable. Reviewed parameterized imports, never activation.
create function public.import_crm_parameterized_standards(p_batch uuid,p_source text,p_reason text,p_rows jsonb) returns uuid[] language plpgsql security definer set search_path='' as $$declare receipt public.crm_task_library_imports;hash text;row jsonb;ids uuid[]:='{}';names text[]:='{}';keys text[]:='{}';name text;key text;parameter jsonb;field text;begin
perform 1 from public.profiles where id=auth.uid() and active and role='admin' for share;
if not found or not public.is_admin() then raise exception 'Current active administrator reviews parameterized imports';end if;
if p_batch is null or length(trim(coalesce(p_source,''))) not between 1 and 180 or length(trim(coalesce(p_reason,''))) not between 3 and 2000 or jsonb_typeof(p_rows) is distinct from 'array' then raise exception 'Import batch, source, review reason and rows required';end if;
if jsonb_array_length(p_rows) not between 1 and 100 or length(p_rows::text)>1000000 then raise exception 'Use 1–100 bounded standard rows';end if;
-- Serialize same actor/batch retries before inspecting the immutable receipt.
perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(auth.uid()::text||p_batch::text,0));
hash:=md5(jsonb_build_array('parameterized-v1',trim(p_source),trim(p_reason),p_rows)::text);
select * into receipt from public.crm_task_library_imports where author_id=auth.uid() and batch_id=p_batch;
if found then if receipt.source_hash is distinct from hash then raise exception 'Import batch already used for different reviewed data';end if;return receipt.standard_ids;end if;
for row in select value from jsonb_array_elements(p_rows) loop
if jsonb_typeof(row) is distinct from 'object' then raise exception 'Standard row object required';end if;
name:=trim(coalesce(row->>'name',''));key:=row->'task'->>'key';
if lower(name)=any(names) or key=any(keys) then raise exception 'Duplicate standard name or task key in import';end if;names:=names||lower(name);keys:=keys||key;
-- Dedicated RPC fails closed before this migration; no fallback to the fixed-only import.
if row-'name'-'parameters'-'task'<>'{}'::jsonb or jsonb_typeof(row->'name') is distinct from 'string' or jsonb_typeof(row->'parameters') is distinct from 'array' or jsonb_array_length(row->'parameters')>30 then raise exception 'Only actual name parameters and task allowed';end if;
if (row->'task')-'key'-'phase'-'title'-'process'-'step'-'unit'-'minutes'-'fixed_minutes'-'fixed_quantity'-'crew'-'crew_role'-'tools'-'preconditions'-'quantity_parameters'-'factor_parameter'-'condition_parameter'-'depends_on'-'checklist'<>'{}'::jsonb or row->'task'->'depends_on' is distinct from '[]'::jsonb then raise exception 'New independent standards only; configure template predecessors separately';end if;
for parameter in select value from jsonb_array_elements(row->'parameters') loop
 if jsonb_typeof(parameter) is distinct from 'object' or parameter-'key'-'label'-'min'-'max'-'default'<>'{}'::jsonb or (select count(*) from jsonb_object_keys(parameter))<>5 or jsonb_typeof(parameter->'key') is distinct from 'string' or jsonb_typeof(parameter->'label') is distinct from 'string' then raise exception 'Exact actual parameter key label min max default required';end if;
 foreach field in array array['min','max','default'] loop
  if jsonb_typeof(parameter->field) not in ('number','string') or coalesce(parameter->>field,'') !~ '^[0-9]+(\.[0-9]+)?$' or length(parameter->>field)>200 or jsonb_typeof(parameter->field)='number' and (parameter->>field)::numeric<>trunc((parameter->>field)::numeric) then raise exception 'Explicit decimal text or integer parameter values required';end if;
 end loop;
end loop;
foreach field in array array['phase','minutes','fixed_minutes','fixed_quantity','crew'] loop
 if jsonb_typeof(row->'task'->field) is distinct from 'number' then raise exception 'Explicit numeric task planning values required';end if;
end loop;
foreach field in array array['key','title','process','step','unit','crew_role','tools','preconditions','factor_parameter','condition_parameter'] loop
 if jsonb_typeof(row->'task'->field) is distinct from 'string' then raise exception 'Actual task text fields required';end if;
end loop;
if jsonb_typeof(row->'task'->'quantity_parameters') is distinct from 'array' or jsonb_array_length(row->'task'->'quantity_parameters')>30 or jsonb_array_length(row->'task'->'quantity_parameters')<>(select count(distinct value) from jsonb_array_elements(row->'task'->'quantity_parameters')) then raise exception 'Unique bounded quantity references required';end if;
-- Validate exact numeric ranges/types before the existing validator's integer casts.
if coalesce(row->'task'->>'phase','') !~ '^[0-5]$' or coalesce(row->'task'->>'crew','') !~ '^[1-9][0-9]?$|^100$' then raise exception 'Integer phase and crew required';end if;
ids:=ids||public.save_crm_task_standard(null,null,name,false,row->'parameters',row->'task',trim(p_reason));
end loop;
insert into public.crm_task_library_imports(author_id,batch_id,source_name,reason,source_hash,standard_ids) values(auth.uid(),p_batch,trim(p_source),trim(p_reason),hash,ids);
return ids;end$$;
revoke all on function public.import_crm_parameterized_standards(uuid,text,text,jsonb) from public,anon,service_role;
grant execute on function public.import_crm_parameterized_standards(uuid,text,text,jsonb) to authenticated;
