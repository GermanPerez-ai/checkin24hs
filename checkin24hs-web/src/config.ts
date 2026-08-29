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

/** WhatsApp con mensaje prellenado: SOLO nombre del producto (sin pax/fechas). */
export function buildWhatsAppConsultaUrl(
  tituloProducto?: string,
  tipo: 'hotel' | 'pack' | 'general' | 'promo' = 'hotel'
): string {
  const number = String(WHATSAPP_NUMBER || '').replace(/\D/g, '');
  const name = String(tituloProducto || '')
    .trim()
    // No filtrar a WhatsApp cantidades de ficha (ej. "En base a 3 adultos")
    .replace(/\s+/g, ' ');
  const isGeneric = !name || /^consulta general/i.test(name) || /^hola,\s*tengo una consulta/i.test(name);
  let text = 'Hola, tengo una consulta desde checkin24hs.com';
  if (!isGeneric) {
    if (tipo === 'pack') {
      text = `Hola, tengo una consulta desde checkin24hs.com, quiero más info del pack ${name}`;
    } else if (tipo === 'promo') {
      text = name.startsWith('Hola')
        ? name
        : `Hola, vi la promo en checkin24hs.com y quiero info: ${name}`;
    } else if (tipo === 'general') {
      text = `Hola, tengo una consulta desde checkin24hs.com, sobre: ${name}`;
    } else {
      text = `Hola, tengo una consulta desde checkin24hs.com, quiero más info del hotel ${name}`;
    }
  }
  // encodeURIComponent: espacios → %20, acentos y comas correctos en cualquier dispositivo
  return `https://wa.me/${number}?text=${encodeURIComponent(text)}`;
}

/** WhatsApp con texto libre (landings de promo). */
export function buildWhatsAppTextUrl(mensaje: string): string {
  const number = String(WHATSAPP_NUMBER || '').replace(/\D/g, '');
  const text = String(mensaje || '').trim() || 'Hola, tengo una consulta desde checkin24hs.com';
  return `https://wa.me/${number}?text=${encodeURIComponent(text)}`;
}
