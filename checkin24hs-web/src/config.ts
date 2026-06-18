/** Normaliza variables VITE_* (EasyPanel a veces las guarda con comillas). */
export function readEnv(value: string | undefined): string {
  return (value || '').trim().replace(/^["']+|["']+$/g, '');
}

export const COTIZADOR_BASE = readEnv(import.meta.env.VITE_COTIZADOR_URL) || 'https://cotizar.checkin24hs.com';
/** Número WhatsApp con código de país sin +. Por defecto 5492944411580; override con VITE_WHATSAPP_NUMBER en build. */
export const WHATSAPP_NUMBER = readEnv(import.meta.env.VITE_WHATSAPP_NUMBER) || '5492944411580';
export const FLOR_CHATBOT_URL = readEnv(import.meta.env.VITE_FLOR_CHATBOT_URL);
// HTTPS sin puerto para evitar mixed content (web en HTTPS). Traefik enruta flor-api.checkin24hs.com.
export const FLOR_API_URL = readEnv(import.meta.env.VITE_FLOR_API_URL) || 'https://flor-api.checkin24hs.com';
export const SUPABASE_URL = readEnv(import.meta.env.VITE_SUPABASE_URL);
export const SUPABASE_ANON_KEY = readEnv(import.meta.env.VITE_SUPABASE_ANON_KEY);

export function buildCotizadorUrl(params: {
  hotel_id?: string;
  checkin?: string;
  checkout?: string;
  pax?: number;
}): string {
  const url = new URL(COTIZADOR_BASE);
  if (params.hotel_id) url.searchParams.set('hotel_id', params.hotel_id);
  if (params.checkin) url.searchParams.set('checkin', params.checkin);
  if (params.checkout) url.searchParams.set('checkout', params.checkout);
  if (params.pax != null) url.searchParams.set('pax', String(params.pax));
  return url.toString();
}
