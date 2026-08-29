/** Ficha modular pública (página detalle hotel). Separada de flor_info. */
export interface FichaWebOpinionCategoria {
  nombre: string;
  puntaje: number;
}

export interface FichaWebCerca {
  lugar: string;
  distancia: string;
}

export interface FichaWeb {
  sobre_propiedad?: string | null;
  servicios?: string[] | null;
  opiniones?: {
    categorias?: FichaWebOpinionCategoria[] | null;
    resumen?: string | null;
  } | null;
  zona?: string | null;
  cerca?: FichaWebCerca[] | null;
  como_desplazarse?: string | null;
  detalles_tecnicos?: {
    alojamiento?: string | null;
    habitaciones?: string | null;
    piscinas?: string | null;
    restaurantes?: string | null;
    aparcamiento?: string | null;
    internet?: string | null;
  } | null;
  politicas?: {
    check_in?: string | null;
    check_out?: string | null;
    mascotas?: string | null;
    ninos?: string | null;
  } | null;
  informacion_importante?: {
    tasas?: string | null;
    iva?: string | null;
    extras?: string | null;
    seguridad?: string | null;
    servicios_especiales?: string | null;
    aviso_legal?: string | null;
  } | null;
}

/** Ficha de paquete/pack (tarjeta overlay + detalle con sidebar). */
export interface FichaPack {
  noches?: number | null;
  destinos_count?: number | null;
  alojamientos_count?: number | null;
  circuitos_count?: number | null;
  precio_por_persona?: number | null;
  moneda?: string | null;
  /** Ej. "En base a 2 adultos y 2 niños" */
  precio_nota?: string | null;
  adultos?: number | null;
  ninos?: number | null;
  /** Pill de ubicación en la tarjeta, ej. "Brasil - Palladium Imbassai" */
  etiqueta_ubicacion?: string | null;
  /** Ej. "Temas Brasil | Circuitos regulares sin aéreo" */
  temas?: string | null;
  /** Texto con viñetas (una por línea) */
  descripcion?: string | null;
  incluye?: string | null;
  excluye?: string | null;
  alojamientos_previstos?: string | null;
  punto_encuentro?: string | null;
  itinerario?: string | null;
  observaciones?: string | null;
}

export interface Hotel {
  id: string;
  name: string;
  slug: string | null;
  description: string | null;
  pais: string | null;
  region: string | null;
  ciudad: string | null;
  location?: string | null;
  coordinates?: unknown;
  google_maps?: string | null;
  imagen_principal: string | null;
  galeria_fotos: string[] | null;
  wifi: boolean;
  desayuno: boolean;
  piscina: boolean;
  estacionamiento: boolean;
  calefaccion: boolean;
  pet_friendly: boolean;
  precio_desde: number | null;
  metodo_venta: 'cotizacion' | 'directa' | null;
  url_reserva_directa: string | null;
  /** hotel = alojamiento; paquete = paquete turístico (legado; preferir los flags) */
  tipo_producto?: 'hotel' | 'paquete' | null;
  /** Si true, aparece en destinos como alojamiento */
  mostrar_como_hotel?: boolean | null;
  /** Si true, aparece en /packs */
  mostrar_como_paquete?: boolean | null;
  /** Si true, aparece en Home → Nuestros elegidos del mes (hoteles) */
  elegido_del_mes?: boolean | null;
  /** Si true, aparece en Home → Nuestros Pack elegidos del mes */
  pack_elegido_del_mes?: boolean | null;
  /** Ficha modular para la web pública */
  ficha_web?: FichaWeb | null;
  /** Datos específicos de pack/paquete */
  ficha_pack?: FichaPack | null;
  puntuacion_num: number | null;
  puntuacion_texto: string | null;
  cantidad_opiniones: number | null;
  rating?: number | null;
  price?: number | null;
  images?: string[] | null;
  status?: string | null;
  created_at?: string;
  updated_at?: string;
}

export interface SliderOferta {
  id: string;
  titulo: string | null;
  texto_boton: string | null;
  imagen_url: string;
  imagen_url_mobile: string | null;
  link_destino: string | null;
  tipo_link: string | null;
  orden: number;
  activo: boolean;
}

export interface Novedad {
  id: string;
  titulo: string;
  resumen: string | null;
  imagen_miniatura: string | null;
  imagen_miniatura_mobile: string | null;
  video_miniatura: string | null;
  fecha_publicacion: string;
  cuerpo_nota: string | null;
  slug: string | null;
  /** Texto exacto del botón en la tarjeta (sin sufijos -2, -3). */
  etiqueta_boton?: string | null;
}

/** Landing de venta en /promo/:slug (mailing Brevo → web). */
export interface LandingPromo {
  id: string;
  slug: string;
  titulo: string;
  subtitulo: string | null;
  hotel_nombre: string | null;
  hotel_id: string | null;
  badge: string | null;
  precio_texto: string | null;
  beneficios: string | null;
  cuerpo: string | null;
  imagen_hero: string | null;
  imagen_hero_mobile: string | null;
  cta_whatsapp: string;
  mensaje_whatsapp: string | null;
  vigencia_hasta: string | null;
  activo: boolean;
  orden: number;
  created_at?: string;
  updated_at?: string;
}

export type TestimonioFuente =
  | 'instagram'
  | 'facebook'
  | 'google'
  | 'whatsapp'
  | 'otro';

export interface Testimonio {
  id: string;
  nombre: string;
  texto: string;
  fuente: TestimonioFuente | string;
  estrellas: number;
  avatar_url?: string | null;
  enlace_url?: string | null;
  activo?: boolean;
  orden?: number;
}

export interface SearchParams {
  pais?: string;
  ciudad?: string;
  checkin?: string;
  checkout?: string;
  pax?: number;
}
