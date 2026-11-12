import type { Hotel } from '../types';
import {
  BARCELO_DESTACADOS,
  BARCELO_KEYWORDS,
  BARCELO_MARCAS,
  BARCELO_PAISES,
  BARCELO_ZONAS,
  type FlagCode,
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

const PAISES_GENERICOS = new Set(['caribe', 'internacional', 'internacionales']);

const PAISES_POR_ALIAS = new Map<string, (typeof BARCELO_PAISES)[number]>();
for (const p of BARCELO_PAISES) {
  PAISES_POR_ALIAS.set(p.id.replace(/-/g, ' '), p);
  PAISES_POR_ALIAS.set(normalizarTexto(p.label), p);
  for (const a of p.aliases) PAISES_POR_ALIAS.set(normalizarTexto(a), p);
}

const NOMBRES_PAIS = new Set(PAISES_POR_ALIAS.keys());

export type PaisHotel = {
  id: string;
  label: string;
  flag?: FlagCode;
};

/** País real del hotel (no usa "Caribe"/"Internacional" como país). */
export function paisDeHotel(h: Hotel): PaisHotel {
  const pais = normalizarTexto(h.pais);
  const region = normalizarTexto(h.region);
  if (pais && !PAISES_GENERICOS.has(pais)) {
    const known = PAISES_POR_ALIAS.get(pais);
    if (known) return { id: known.id, label: known.label, flag: known.flag };
    return { id: pais.replace(/\s+/g, '-') || 'otros', label: (h.pais || '').trim() || 'Otros' };
  }
  if (region && NOMBRES_PAIS.has(region)) {
    const known = PAISES_POR_ALIAS.get(region)!;
    return { id: known.id, label: known.label, flag: known.flag };
  }
  const resto = normalizarTexto([h.ciudad, h.location, h.name].filter(Boolean).join(' '));
  for (const p of BARCELO_PAISES) {
    const claves = [normalizarTexto(p.label), ...p.aliases.map(normalizarTexto)];
    if (claves.some((c) => c && resto.includes(c))) {
      return { id: p.id, label: p.label, flag: p.flag };
    }
  }
  return { id: 'otros', label: (h.pais || h.region || '').trim() || 'Otros destinos' };
}

export type ZonaHotel = { id: string; label: string };

function zonaPorTexto(texto: string, paisId?: string): ZonaHotel | null {
  const n = normalizarTexto(texto);
  if (!n) return null;
  const zonas = paisId ? BARCELO_ZONAS.filter((z) => z.paisId === paisId) : BARCELO_ZONAS;
  for (const z of zonas) {
    if (z.match.some((m) => n.includes(normalizarTexto(m)))) {
      return { id: z.id, label: z.label };
    }
  }
  return null;
}

/**
 * Destino/zona (Punta Cana, Cancún, etc.). Prioriza ciudad y región del
 * catálogo; si faltan o la región es un país, se infiere del nombre o location.
 */
export function zonaDeHotel(h: Hotel): ZonaHotel {
  const pais = paisDeHotel(h);
  const ciudad = (h.ciudad || '').trim();
  const region = (h.region || '').trim();
  const regionNorm = normalizarTexto(region);
  if (ciudad) {
    const z = zonaPorTexto(ciudad, pais.id);
    if (z) return z;
  }
  if (region && !NOMBRES_PAIS.has(regionNorm) && !PAISES_GENERICOS.has(regionNorm)) {
    const z = zonaPorTexto(region, pais.id);
    if (z) return z;
    return { id: regionNorm.replace(/\s+/g, '-') || 'otros', label: region };
  }
  // El nombre va antes que location: varias fichas de Riviera Maya mencionan
  // "Chetumal-Cancún" en la dirección y no deben caer en Cancún.
  const porNombre = zonaPorTexto(h.name, pais.id);
  if (porNombre) return porNombre;
  const porDireccion = zonaPorTexto(h.location || '', pais.id);
  if (porDireccion) return porDireccion;
  if (ciudad) return { id: normalizarTexto(ciudad).replace(/\s+/g, '-') || 'otros', label: ciudad };
  return { id: pais.id, label: pais.label };
}

/** Texto de tarjeta: "México · Playa del Carmen". */
export function etiquetaUbicacion(h: Hotel): { label: string; flag?: FlagCode } {
  const pais = paisDeHotel(h);
  const zona = zonaDeHotel(h);
  const label =
    zona.label && normalizarTexto(zona.label) !== normalizarTexto(pais.label)
      ? `${pais.label} · ${zona.label}`
      : pais.label;
  return { label, flag: pais.flag };
}

export function rankPais(h: Hotel): number {
  const idx = BARCELO_PAISES.findIndex((p) => p.id === paisDeHotel(h).id);
  return idx === -1 ? BARCELO_PAISES.length : idx;
}

export function rankZona(h: Hotel): number {
  const zona = zonaDeHotel(h);
  const idx = BARCELO_ZONAS.findIndex((z) => z.id === zona.id);
  return idx === -1 ? BARCELO_ZONAS.length : idx;
}

/** País (popularidad AR) → destino (popularidad) → shortlist → nombre. */
export function ordenarBarcelo(hotels: Hotel[]): Hotel[] {
  return [...hotels].sort((a, b) => {
    const pa = rankPais(a);
    const pb = rankPais(b);
    if (pa !== pb) return pa - pb;
    const za = rankZona(a);
    const zb = rankZona(b);
    if (za !== zb) return za - zb;
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

export type PaisGrupoBarcelo = {
  id: string;
  label: string;
  flag?: FlagCode;
  destinos: DestinoBarcelo[];
};

/** Destino del hotel según zona resuelta (Punta Cana, Cancún, …). */
export function destinoDeHotel(h: Hotel): { id: string; label: string } {
  const zona = zonaDeHotel(h);
  return { id: zona.id, label: zona.label };
}

/**
 * Agrupa por destino. Los hoteles ya deben venir ordenados (ordenarBarcelo):
 * el orden de los destinos sigue al de países y zonas.
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

/** Agrupa por país y, dentro, por destino. Requiere hoteles ya ordenados. */
export function agruparPorPais(hotelsOrdenados: Hotel[]): PaisGrupoBarcelo[] {
  const map = new Map<string, PaisGrupoBarcelo>();
  for (const h of hotelsOrdenados) {
    const pais = paisDeHotel(h);
    let g = map.get(pais.id);
    if (!g) {
      g = { id: pais.id, label: pais.label, flag: pais.flag, destinos: [] };
      map.set(pais.id, g);
    }
    const dest = destinoDeHotel(h);
    let d = g.destinos.find((x) => x.id === dest.id);
    if (!d) {
      d = { id: dest.id, label: dest.label, hotels: [] };
      g.destinos.push(d);
    }
    d.hotels.push(h);
  }
  return [...map.values()];
}
