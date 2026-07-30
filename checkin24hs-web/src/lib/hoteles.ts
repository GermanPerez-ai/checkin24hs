import type { Hotel } from '../types';

export const PUYEHUE_RESERVA_URL =
  'https://reservas.puyehue.cl/cgi-bin/paso1.cgi?RESORT=HTP&AGENCIA=CANOPY&LANGUAGE=ES';

export const AGUAS_CALIENTES_RESERVA_URL =
  'https://reservas.puyehue.cl/cgi-bin/paso1.cgi?RESORT=TAC&AGENCIA=CANOPY&LANGUAGE=ES';

export function isHotelTermasPuyehue(hotel: { name?: string | null; slug?: string | null }): boolean {
  const n = (hotel.name || '').toLowerCase();
  const s = (hotel.slug || '').toLowerCase();
  return n.includes('puyehue') || s.includes('puyehue');
}

export function isHotelTermasAguasCalientes(hotel: {
  name?: string | null;
  slug?: string | null;
}): boolean {
  const n = (hotel.name || '').toLowerCase();
  const s = (hotel.slug || '').toLowerCase();
  return (
    n.includes('aguas calientes') ||
    s.includes('aguas-calientes') ||
    s.includes('aguas_calientes') ||
    s.includes('aguascalientes')
  );
}

export function hasReservarCarousel(hotel: {
  name?: string | null;
  slug?: string | null;
}): boolean {
  return isHotelTermasPuyehue(hotel) || isHotelTermasAguasCalientes(hotel);
}

export function getReservaDirectaUrl(hotel: Hotel): string | null {
  if (hotel.url_reserva_directa?.trim()) return hotel.url_reserva_directa.trim();
  if (isHotelTermasPuyehue(hotel)) return PUYEHUE_RESERVA_URL;
  if (isHotelTermasAguasCalientes(hotel)) return AGUAS_CALIENTES_RESERVA_URL;
  return null;
}

/** Prioridad en carrusel Home: Puyehue (0), Aguas Calientes (1), resto (2). */
function carouselSortPriority(hotel: Hotel): number {
  if (isHotelTermasPuyehue(hotel)) return 0;
  if (isHotelTermasAguasCalientes(hotel)) return 1;
  return 2;
}

/** Home: Termas de Puyehue primero; Termas de Aguas Calientes justo al lado. */
export function sortHotelsPuyehueFirst(hotels: Hotel[]): Hotel[] {
  return [...hotels].sort((a, b) => {
    const ap = carouselSortPriority(a);
    const bp = carouselSortPriority(b);
    if (ap !== bp) return ap - bp;
    return (a.name || '').localeCompare(b.name || '', 'es');
  });
}

export function openReservaPopup(url: string): void {
  const width = 1100;
  const height = 800;
  const left = Math.max(0, Math.round((window.screen.width - width) / 2));
  const top = Math.max(0, Math.round((window.screen.height - height) / 2));
  const features = [
    `width=${width}`,
    `height=${height}`,
    `left=${left}`,
    `top=${top}`,
    'scrollbars=yes',
    'resizable=yes',
  ].join(',');
  window.open(url, 'checkin24hs_reserva', features);
}
