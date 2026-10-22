import {PGlite} from '@electric-sql/pglite';
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {leadFileCases} from './helpers/lead-file-cases.mjs';
// A fresh local database isolates website capture and abuse-limit checks from unrelated suite fixtures.
const pg=new PGlite();let passed=0;
try{
 await pg.exec(`set timezone='UTC';create role anon;create role authenticated;create role service_role bypassrls;
 create schema auth;create schema storage;create function auth.role() returns text language sql stable as $$select nullif(current_setting('request.jwt.claim.role',true),'')$$;
 create table auth.users(id uuid primary key);
 create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
 grant usage on schema auth,storage,public to authenticated,anon;grant execute on function auth.uid() to authenticated,anon;
 create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
 create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text,owner_id text,metadata jsonb);
 alter table storage.objects enable row level security;grant select,insert,update,delete on storage.objects to authenticated;`);
 // 028 is the external pg_net/cron scheduler; it is also excluded from assigned-work tests.
 for(const name of (await fs.readdir(new URL('../supabase/',import.meta.url))).filter(n=>/^\d{3}_.*\.sql$/.test(n)&&Number(n.slice(0,3))<142&&!n.startsWith('028_')).sort())await pg.exec(await fs.readFile(new URL('../supabase/'+name,import.meta.url),'utf8'));
 const q=async(s,p=[])=>(await pg.query(s,p)).rows,one=async(s,p=[])=>(await q(s,p))[0];
 const user=async(id)=>pg.exec(`reset role;select set_config('request.jwt.claim.sub','${id}',false);select set_config('request.jwt.claim.role','authenticated',false);set role authenticated;`);
 const eq=(a,b,label)=>{assert.deepEqual(a,b,label);passed++;console.log('PASS',label);};
 const deny=async(s,p,label)=>{await assert.rejects(()=>q(s,p));passed++;console.log('PASS',label);};
 const ids={admin:crypto.randomUUID(),clientA:crypto.randomUUID(),worker:crypto.randomUUID()},company=crypto.randomUUID();
 await q('insert into auth.users values($1),($2)',[ids.admin,ids.clientA]);await q("insert into companies(id,name) values($1,'QA isolated website company')",[company]);await q("insert into profiles(id,name,role,company_id) values($1,'QA admin','admin',null),($2,'QA client','client',$3)",[ids.admin,ids.clientA,company]);
 await q('insert into auth.users values($1)',[ids.worker]);await q("insert into profiles(id,name,role) values($1,'QA unrelated worker','team')",[ids.worker]);
 await pg.exec(await fs.readFile(new URL('../supabase/migrations/20261022005821_phase_one_website_intake.sql',import.meta.url),'utf8'));
 await pg.exec(await fs.readFile(new URL('../supabase/migrations/20261022103801_phase_one_api_intake.sql',import.meta.url),'utf8'));
 await pg.exec(await fs.readFile(new URL('../supabase/migrations/20261022103855_phase_one_meta_intake.sql',import.meta.url),'utf8'));
 await pg.exec(await fs.readFile(new URL('../supabase/migrations/20261022104422_phase_one_lead_routing.sql',import.meta.url),'utf8'));
 await pg.exec(await fs.readFile(new URL('../supabase/migrations/20261022111906_phase_one_board_fields.sql',import.meta.url),'utf8'));
 await pg.exec(await fs.readFile(new URL('../supabase/migrations/20261022113632_phase_one_board_number_precision.sql',import.meta.url),'utf8'));
 await pg.exec(await fs.readFile(new URL('../supabase/migrations/20261022184714_phase_one_sales_list_actions.sql',import.meta.url),'utf8'));
 await pg.exec(await fs.readFile(new URL('../supabase/migrations/20261022190605_phase_one_stage_entry_actions.sql',import.meta.url),'utf8'));
 await pg.exec(await fs.readFile(new URL('../supabase/migrations/20261022192444_phase_one_product_scope.sql',import.meta.url),'utf8'));
 await pg.exec(await fs.readFile(new URL('../supabase/migrations/20261022191929_phase_one_lead_files.sql',import.meta.url),'utf8'));
 await leadFileCases({pg,q,one,user,eq,deny,ids});console.log(`${passed} isolated lead-file database assertions passed`);
}finally{await pg.close();}
