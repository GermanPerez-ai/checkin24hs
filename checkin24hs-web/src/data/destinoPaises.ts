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
    /** Una sección/carrusel por región (mismo valor que hotels.region en el dashboard) */
    bloques: [
      { titulo: 'Hoteles en Puerto Varas', match: ['Puerto Varas'] },
      { titulo: 'Hoteles en Pucón', match: ['Pucón', 'Pucon'] },
      { titulo: 'Hoteles en Villarica', match: ['Villarica', 'Villarrica'] },
      { titulo: 'Hoteles en Valdivia', match: ['Valdivia'] },
      { titulo: 'Hoteles en Puyehue', match: ['Puyehue'] },
      { titulo: 'Hoteles en Viña del Mar', match: ['Viña del Mar', 'Vina del Mar'] },
      { titulo: 'Hoteles en Santiago', match: ['Santiago'] },
      { titulo: 'Otros destinos en Chile', match: [] },
    ],
  },
  argentina: {
    slug: 'argentina',
    nombre: 'Argentina',
    heroTitulo: 'Patagonia argentina y más allá',
    heroImagen: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=1600&h=600&fit=crop',
    paisesIncluidos: ['Argentina', 'argentina', 'ARGENTINA'],
    /** Una sección/carrusel por región (mismo valor que hotels.region en el dashboard) */
    bloques: [
      { titulo: 'Hoteles en Bariloche', match: ['Bariloche'] },
      { titulo: 'Hoteles en Buenos Aires', match: ['Buenos Aires'] },
      { titulo: 'Hoteles en Costa Argentina', match: ['Costa Argentina'] },
      { titulo: 'Hoteles en Norte Argentino', match: ['Norte Argentino'] },
      { titulo: 'Hoteles en Mendoza', match: ['Mendoza'] },
      { titulo: 'Otros destinos en Argentina', match: [] },
    ],
  },
  internacionales: {
    slug: 'internacionales',
    nombre: 'Internacionales',
    heroTitulo: 'Caribe, México, Brasil y el mundo',
    heroImagen: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1600&h=600&fit=crop',
    /** Incluye pais = Internacional y cualquier país que no sea Chile/Argentina */
    excluirPaises: ['Chile', 'chile', 'Argentina', 'argentina'],
    bloques: [
      { titulo: 'Hoteles en Aruba', match: ['Aruba'] },
      { titulo: 'Hoteles en República Dominicana', match: ['República Dominicana', 'Republica Dominicana'] },
      { titulo: 'Hoteles en Cuba', match: ['Cuba'] },
      { titulo: 'Hoteles en Puerto Rico', match: ['Puerto Rico'] },
      { titulo: 'Hoteles en Cancún', match: ['Cancún', 'Cancun'] },
      { titulo: 'Hoteles en Playa del Carmen', match: ['Playa del Carmen'] },
      { titulo: 'Hoteles en Tulum', match: ['Tulum'] },
      { titulo: 'Hoteles en Isla de Cozumel', match: ['Isla de Cozumel', 'Cozumel'] },
      { titulo: 'Hoteles en Los Cabos', match: ['Los Cabos'] },
      { titulo: 'Hoteles en Puerto Vallarta', match: ['Puerto Vallarta'] },
      { titulo: 'Hoteles en Riviera Nayarit', match: ['Riviera Nayarit'] },
      { titulo: 'Hoteles en Río de Janeiro', match: ['Río de Janeiro (Región Sudeste)', 'Río de Janeiro', 'Rio de Janeiro'] },
      { titulo: 'Hoteles en Recife', match: ['Recife (Región Nordeste)', 'Recife'] },
      { titulo: 'Hoteles en Florianópolis', match: ['Florianópolis (Región Sur)', 'Florianópolis', 'Florianopolis'] },
      { titulo: 'Hoteles en Fortaleza', match: ['Fortaleza (Región Nordeste)', 'Fortaleza'] },
      { titulo: 'Hoteles en Costa Rica', match: ['Costa Rica'] },
      { titulo: 'Hoteles en Panamá', match: ['Panamá', 'Panama'] },
      { titulo: 'Hoteles en Hawái', match: ['Hawái', 'Hawai', 'Hawaii'] },
      { titulo: 'Hoteles en Florida', match: ['Florida'] },
      { titulo: 'Otros destinos internacionales', match: [] },
    ],
  },
};

export const SELECTOR_DESTINOS = [
  {
    slug: 'argentina',
    label: 'ARGENTINA',
    imagen: DESTINO_PAISES.argentina.heroImagen,
    resumen: 'Bariloche, Mendoza y más',
  },
  {
    slug: 'chile',
    label: 'CHILE',
    imagen: DESTINO_PAISES.chile.heroImagen,
    resumen: 'Patagonia, termas y cordillera',
  },
  {
    slug: 'internacionales',
    label: 'INTERNACIONALES',
    imagen: DESTINO_PAISES.internacionales.heroImagen,
    resumen: 'Caribe, México, Brasil y el mundo',
  },
  {
    slug: 'packs',
    label: 'PACKS',
    imagen: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=1600&h=600&fit=crop',
    resumen: 'Paquetes y escapadas armadas',
  },
] as const;

export const PACKS_DESTINO = {
  slug: 'packs' as const,
  nombre: 'Packs',
  heroTitulo: 'Paquetes y escapadas armadas para vos',
  heroImagen: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=1600&h=600&fit=crop',
};

/** Solo alojamientos (excluye packs puros) en páginas de país */
export function esAlojamiento<T extends {
  tipo_producto?: string | null;
  mostrar_como_hotel?: boolean | null;
}>(h: T): boolean {
  if (h.mostrar_como_hotel === true) return true;
  if (h.mostrar_como_hotel === false) return false;
  return (h.tipo_producto || 'hotel') !== 'paquete';
}

export function esPaquete<T extends {
  tipo_producto?: string | null;
  mostrar_como_paquete?: boolean | null;
}>(h: T): boolean {
  if (h.mostrar_como_paquete === true) return true;
  if (h.mostrar_como_paquete === false) return false;
  return h.tipo_producto === 'paquete';
}

function norm(s: string) {
  return s.trim().toLowerCase();
}

export function hotelMatchesBloque(hotel: { ciudad?: string | null; region?: string | null; pais?: string | null }, bloque: DestinoBloque): boolean {
  if (bloque.match.length === 0) return false;
  const region = hotel.region ? norm(hotel.region) : '';
  // Prioridad: región exacta del dashboard (ej. "Bariloche", "Costa Argentina")
  if (region && bloque.match.some((m) => region === norm(m))) return true;
  const hay = [hotel.ciudad, hotel.region, hotel.pais].filter(Boolean).map((x) => norm(String(x)));
  return bloque.match.some((m) => hay.some((h) => h.includes(norm(m)) || norm(m).includes(h)));
}

export function filterHotelsPorPais<T extends {
  pais?: string | null;
  tipo_producto?: string | null;
  mostrar_como_hotel?: boolean | null;
}>(
  hotels: T[],
  config: PaisDestinoConfig
): T[] {
  // En páginas de país solo se muestran alojamientos (no packs puros)
  const base = hotels.filter(esAlojamiento);
  if (config.slug === 'internacionales') {
    const excl = new Set((config.excluirPaises || ['Chile', 'Argentina']).map(norm));
    return base.filter((h) => {
      const p = h.pais ? norm(h.pais) : '';
      if (!p) return false;
      if (p === 'internacional') return true;
      return !excl.has(p);
    });
  }
  if (config.paisesIncluidos?.length) {
    const set = new Set(config.paisesIncluidos.map(norm));
    return base.filter((h) => h.pais && set.has(norm(h.pais)));
  }
  if (config.excluirPaises?.length) {
    const excl = new Set(config.excluirPaises.map(norm));
    return base.filter((h) => !h.pais || !excl.has(norm(h.pais)));
  }
  return base;
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
