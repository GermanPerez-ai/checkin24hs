import type { FichaPack, Hotel } from '../types';

export function getHotelImageUrl(h: Hotel): string {
  if (h.imagen_principal) return h.imagen_principal;
  const galeria = h.galeria_fotos;
  if (Array.isArray(galeria) && galeria.length) return galeria[0];
  if (h.images && Array.isArray(h.images) && h.images.length) return h.images[0];
  return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800';
}

export function getHotelSlug(h: Hotel): string {
  return h.slug || h.id;
}

export function getFichaPack(h: Hotel): FichaPack {
  const raw = h.ficha_pack;
  return raw && typeof raw === 'object' ? raw : {};
}

export function linesFromText(v: string | null | undefined): string[] {
  if (!v) return [];
  return String(v)
    .split(/\r?\n/)
    .map((s) => s.replace(/^[\s•\-\*]+/, '').trim())
    .filter(Boolean);
}

export function formatPackPrice(precio: number | null | undefined, moneda?: string | null): string {
  if (precio == null || !Number.isFinite(Number(precio))) return '';
  const n = Number(precio);
  const cur = (moneda || 'USD').toUpperCase();
  if (cur === 'USD' || cur === 'US$' || cur === 'U$S') {
    return `US$${n.toLocaleString('en-US', { maximumFractionDigits: 0 })}`;
  }
  if (cur === 'ARS' || cur === '$') {
    return `$${n.toLocaleString('es-AR', { maximumFractionDigits: 0 })}`;
  }
  return `${cur} ${n.toLocaleString('es-AR', { maximumFractionDigits: 0 })}`;
}

export function getPackPrecio(h: Hotel): number | null {
  const fp = getFichaPack(h);
  if (fp.precio_por_persona != null && Number.isFinite(Number(fp.precio_por_persona))) {
    return Number(fp.precio_por_persona);
  }
  if (h.precio_desde != null) return Number(h.precio_desde);
  if (h.price != null) return Number(h.price);
  return null;
}

export function getPackEtiquetaUbicacion(h: Hotel): string {
  const fp = getFichaPack(h);
  if (fp.etiqueta_ubicacion?.trim()) return fp.etiqueta_ubicacion.trim();
  const pais = (h.pais || '').trim();
  if (pais && h.name) return `${pais} - ${h.name}`;
  return h.location || h.name || '';
}
