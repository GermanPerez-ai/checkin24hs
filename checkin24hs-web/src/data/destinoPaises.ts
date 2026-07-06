/** Bloques de destino por país para páginas /chile, /argentina, /internacionales */

export type PaisSlug = 'chile' | 'argentina' | 'internacionales';

export type DestinoBloque = {
  titulo: string;
  /** Coincide con hotel.ciudad o hotel.region (insensible a mayúsculas) */
  match: string[];
};

export type PaisDestinoConfig = {
  slug: PaisSlug;
  nombre: string;
  heroTitulo: string;
  heroImagen: string;
  /** Valores de hotel.pais para filtrar (internacionales = excluir Chile y Argentina) */
  paisesIncluidos?: string[];
  excluirPaises?: string[];
  bloques: DestinoBloque[];
};

export const DESTINO_PAISES: Record<PaisSlug, PaisDestinoConfig> = {
  chile: {
    slug: 'chile',
    nombre: 'Chile',
    heroTitulo: 'Patagonia y cordillera chilena',
    heroImagen: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=1600&h=600&fit=crop',
    paisesIncluidos: ['Chile', 'chile', 'CHILE'],
    bloques: [
      { titulo: 'Puyehue y Los Lagos', match: ['Puyehue', 'Osorno', 'Puerto Varas'] },
      { titulo: 'Corralco y Lonquimay', match: ['Lonquimay', 'Corralco'] },
      { titulo: 'Huilo Huilo', match: ['Neltume', 'Huilo', 'Huilo-Huilo'] },
      { titulo: 'Santiago y centro', match: ['Santiago', 'Valparaíso', 'Valparaiso'] },
    ],
  },
  argentina: {
    slug: 'argentina',
    nombre: 'Argentina',
    heroTitulo: 'Patagonia argentina y más allá',
    heroImagen: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=1600&h=600&fit=crop',
    paisesIncluidos: ['Argentina', 'argentina', 'ARGENTINA'],
    bloques: [
      { titulo: 'Bariloche', match: ['Bariloche', 'San Carlos de Bariloche'] },
      { titulo: 'Villa La Angostura', match: ['Villa La Angostura', 'Angostura'] },
      { titulo: 'San Martín de los Andes', match: ['San Martín', 'San Martin', 'San Martín de los Andes'] },
      { titulo: 'Mendoza', match: ['Mendoza'] },
      { titulo: 'Buenos Aires', match: ['Buenos Aires', 'CABA', 'Capital Federal'] },
    ],
  },
  internacionales: {
    slug: 'internacionales',
    nombre: 'Internacionales',
    heroTitulo: 'Caribe, Brasil y el mundo',
    heroImagen: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1600&h=600&fit=crop',
    excluirPaises: ['Chile', 'chile', 'Argentina', 'argentina'],
    bloques: [
      { titulo: 'Caribe', match: ['Caribe', 'Punta Cana', 'Cancún', 'Cancun', 'Riviera Maya', 'Aruba', 'Jamaica'] },
      { titulo: 'Brasil', match: ['Brasil', 'Brazil', 'Río', 'Rio', 'Florianópolis', 'Buzios', 'Búzios'] },
      { titulo: 'Otros destinos', match: [] },
    ],
  },
};

export const SELECTOR_DESTINOS = [
  {
    slug: 'chile' as PaisSlug,
    label: 'CHILE',
    imagen: DESTINO_PAISES.chile.heroImagen,
    resumen: 'Patagonia, termas y cordillera',
  },
  {
    slug: 'argentina' as PaisSlug,
    label: 'ARGENTINA',
    imagen: DESTINO_PAISES.argentina.heroImagen,
    resumen: 'Bariloche, Mendoza y más',
  },
  {
    slug: 'internacionales' as PaisSlug,
    label: 'INTERNACIONALES',
    imagen: DESTINO_PAISES.internacionales.heroImagen,
    resumen: 'Caribe, Brasil y el mundo',
  },
];

function norm(s: string) {
  return s.trim().toLowerCase();
}

export function hotelMatchesBloque(hotel: { ciudad?: string | null; region?: string | null; pais?: string | null }, bloque: DestinoBloque): boolean {
  if (bloque.match.length === 0) return false;
  const hay = [hotel.ciudad, hotel.region, hotel.pais].filter(Boolean).map((x) => norm(String(x)));
  return bloque.match.some((m) => hay.some((h) => h.includes(norm(m)) || norm(m).includes(h)));
}

export function filterHotelsPorPais<T extends { pais?: string | null }>(hotels: T[], config: PaisDestinoConfig): T[] {
  if (config.paisesIncluidos?.length) {
    const set = new Set(config.paisesIncluidos.map(norm));
    return hotels.filter((h) => h.pais && set.has(norm(h.pais)));
  }
  if (config.excluirPaises?.length) {
    const excl = new Set(config.excluirPaises.map(norm));
    return hotels.filter((h) => !h.pais || !excl.has(norm(h.pais)));
  }
  return hotels;
}

export function agruparHotelesEnBloques<T extends { ciudad?: string | null; region?: string | null; pais?: string | null }>(
  hotels: T[],
  bloques: DestinoBloque[]
): { titulo: string; hotels: T[] }[] {
  const usados = new Set<T>();
  const out: { titulo: string; hotels: T[] }[] = [];

  for (const bloque of bloques) {
    if (bloque.match.length === 0) continue;
    const grupo = hotels.filter((h) => !usados.has(h) && hotelMatchesBloque(h, bloque));
    grupo.forEach((h) => usados.add(h));
    if (grupo.length > 0) out.push({ titulo: bloque.titulo, hotels: grupo });
  }

  const otros = hotels.filter((h) => !usados.has(h));
  const otrosBloque = bloques.find((b) => b.match.length === 0);
  if (otros.length > 0 && otrosBloque) {
    out.push({ titulo: otrosBloque.titulo, hotels: otros });
  }

  return out;
}
