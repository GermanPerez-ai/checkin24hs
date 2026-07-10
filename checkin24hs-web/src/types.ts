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
  /** hotel = alojamiento; paquete = paquete turístico */
  tipo_producto?: 'hotel' | 'paquete' | null;
  /** Si true, aparece en Home → Nuestros elegidos del mes */
  elegido_del_mes?: boolean | null;
  /** Ficha modular para la web pública */
  ficha_web?: FichaWeb | null;
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

export interface SearchParams {
  pais?: string;
  ciudad?: string;
  checkin?: string;
  checkout?: string;
  pax?: number;
}
