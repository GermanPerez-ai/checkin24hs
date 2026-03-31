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
