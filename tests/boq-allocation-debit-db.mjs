import {PGlite} from '@electric-sql/pglite';
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {boqAllocationDebitCases} from './helpers/boq-allocation-debit-cases.mjs';
// A fresh local database isolates financial issuance/rollback from unrelated suite fixtures.
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
 for(const name of (await fs.readdir(new URL('../supabase/',import.meta.url))).filter(n=>/^\d{3}_.*\.sql$/.test(n)&&Number(n.slice(0,3))<148&&!n.startsWith('028_')).sort())await pg.exec(await fs.readFile(new URL('../supabase/'+name,import.meta.url),'utf8'));
 const q=async(s,p=[])=>(await pg.query(s,p)).rows,one=async(s,p=[])=>(await q(s,p))[0];
 const user=async(id)=>pg.exec(`reset role;select set_config('request.jwt.claim.sub','${id}',false);select set_config('request.jwt.claim.role','authenticated',false);set role authenticated;`);
 const eq=(a,b,label)=>{assert.deepEqual(a,b,label);passed++;console.log('PASS',label);};
 const deny=async(s,p,label)=>{await assert.rejects(()=>q(s,p));passed++;console.log('PASS',label);};
 await boqAllocationDebitCases({pg,fs,q,one,user,eq,deny});console.log(`${passed} isolated allocation debit database assertions passed`);
}finally{await pg.close();}
