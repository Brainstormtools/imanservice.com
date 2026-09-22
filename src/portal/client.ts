import { createClient } from '@supabase/supabase-js';
const env = (import.meta as any).env;
export const configured = Boolean(env.VITE_SUPABASE_URL && env.VITE_SUPABASE_ANON_KEY);
export const db = configured ? createClient(env.VITE_SUPABASE_URL, env.VITE_SUPABASE_ANON_KEY) : null;
export type Row = { id: string; [key: string]: any };
export function check<T>(result: { data?: T; error: any }): T {
  if (result.error) throw result.error;
  return result.data;
}
