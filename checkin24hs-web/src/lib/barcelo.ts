import type { Hotel } from '../types';
import {
  BARCELO_DESTACADOS,
  BARCELO_KEYWORDS,
  BARCELO_MARCAS,
  type PerfilBarcelo,
} from '../data/barceloLanding';

/** Minúsculas, sin acentos, espacios simples. */
export function normalizarTexto(s: string | null | undefined): string {
  return String(s || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9ñ]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Hotel del grupo Barceló: flag del Dashboard o nombre de una marca del grupo. */
export function esHotelGrupoBarcelo(h: Hotel): boolean {
  if (h.grupo_barcelo) return true;
  const n = normalizarTexto(h.name);
  return BARCELO_MARCAS.some((m) => n.startsWith(m));
}

/** Posición en el orden destacado (Excel). Los no listados van después. */
export function rankDestacado(h: Hotel): number {
  const n = normalizarTexto(h.name);
  const idx = BARCELO_DESTACADOS.findIndex((d) => d.match.some((m) => n.includes(normalizarTexto(m))));
  return idx === -1 ? BARCELO_DESTACADOS.length : idx;
}

export function ordenarBarcelo(hotels: Hotel[]): Hotel[] {
  return [...hotels].sort((a, b) => {
    const ra = rankDestacado(a);
    const rb = rankDestacado(b);
    if (ra !== rb) return ra - rb;
    return (a.name || '').localeCompare(b.name || '', 'es');
  });
}

function textoHotel(h: Hotel): string {
  let ficha = '';
  try {
    ficha = h.ficha_web ? JSON.stringify(h.ficha_web) : '';
  } catch {
    ficha = '';
  }
  return normalizarTexto([h.name, h.description, ficha].filter(Boolean).join(' '));
}

function contieneAlguna(texto: string, claves: string[]): boolean {
  return claves.some((k) => texto.includes(normalizarTexto(k)));
}

/** Perfiles que respaldan los datos reales del hotel (nombre + ficha_web + descripción). */
export function perfilesHotel(h: Hotel): Set<PerfilBarcelo> {
  const texto = textoHotel(h);
  const perfiles = new Set<PerfilBarcelo>();
  const soloAdultos = contieneAlguna(texto, BARCELO_KEYWORDS.soloAdultos);
  if (soloAdultos) {
    perfiles.add('solo-adultos');
    perfiles.add('parejas');
  } else if (contieneAlguna(texto, BARCELO_KEYWORDS.familias)) {
    perfiles.add('familias');
  }
  if (contieneAlguna(texto, BARCELO_KEYWORDS.parejas)) perfiles.add('parejas');
  return perfiles;
}

export type DestinoBarcelo = {
  /** Clave estable para filtros y URL */
  id: string;
  label: string;
  hotels: Hotel[];
};

const PAISES_GENERICOS = new Set(['caribe', 'internacional', 'internacionales']);

/** Destino del hotel según los campos del catálogo: región > ciudad > país. */
export function destinoDeHotel(h: Hotel): { id: string; label: string } {
  const region = (h.region || '').trim();
  const ciudad = (h.ciudad || '').trim();
  const pais = (h.pais || '').trim();
  const lugar = region || ciudad || pais || 'Otros destinos';
  const paisValido = pais && !PAISES_GENERICOS.has(normalizarTexto(pais));
  const label =
    paisValido && normalizarTexto(pais) !== normalizarTexto(lugar) ? `${lugar}, ${pais}` : lugar;
  return { id: normalizarTexto(lugar).replace(/\s+/g, '-') || 'otros', label };
}

/**
 * Agrupa por destino. Los hoteles ya deben venir ordenados (ordenarBarcelo):
 * el orden de los destinos sigue al mejor hotel destacado de cada uno.
 */
export function agruparPorDestino(hotelsOrdenados: Hotel[]): DestinoBarcelo[] {
  const map = new Map<string, DestinoBarcelo>();
  for (const h of hotelsOrdenados) {
    const d = destinoDeHotel(h);
    const g = map.get(d.id);
    if (g) g.hotels.push(h);
    else map.set(d.id, { id: d.id, label: d.label, hotels: [h] });
  }
  return [...map.values()];
}
