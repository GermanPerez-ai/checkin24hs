import { createClient } from '@supabase/supabase-js';
import { SUPABASE_ANON_KEY, SUPABASE_URL } from '../config';

function isValidSupabaseUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return parsed.protocol === 'http:' || parsed.protocol === 'https:';
  } catch {
    return false;
  }
}

const hasConfig =
  !!SUPABASE_URL &&
  !!SUPABASE_ANON_KEY &&
  isValidSupabaseUrl(SUPABASE_URL) &&
  !SUPABASE_ANON_KEY.includes('PEGA_AQUI') &&
  !SUPABASE_ANON_KEY.includes('tu_anon_key');

if (!hasConfig) {
  console.warn('Checkin24hs Web: Configura VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY al construir la web.');
}

export const supabase = hasConfig ? createClient(SUPABASE_URL, SUPABASE_ANON_KEY) : null;
