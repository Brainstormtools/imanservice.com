import {createClient} from '@supabase/supabase-js';
import {accountHandler} from './handler.ts';
const url=Deno.env.get('SUPABASE_URL'),key=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
Deno.serve(accountHandler(createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}}),url));
