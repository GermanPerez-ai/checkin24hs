import { useEffect, useRef, useState } from 'react';
import { HotelCard } from './HotelCard';
import type { Hotel } from '../types';
import styles from './AlojamientosCarousel.module.css';

/** Ancho base 320px −20% */
export const HOTEL_CAROUSEL_CARD_WIDTH = 256;
/** Alto aprox. tarjeta grid ~350px −35% */
export const HOTEL_CAROUSEL_CARD_HEIGHT = 228;
const SCROLL_STEP = HOTEL_CAROUSEL_CARD_WIDTH + 16;

const DEV_PREVIEW_IMAGE = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=512&h=320&fit=crop';

function devPreviewHotels(): Hotel[] {
  const base = {
    wifi: true,
    desayuno: true,
    piscina: false,
    estacionamiento: true,
    calefaccion: true,
    pet_friendly: false,
    metodo_venta: 'cotizacion' as const,
    url_reserva_directa: null,
    precio_desde: 85000,
    puntuacion_num: 8.6,
    puntuacion_texto: 'Excelente',
    imagen_principal: DEV_PREVIEW_IMAGE,
    galeria_fotos: null,
    description: null,
    slug: null,
    region: null,
    cantidad_opiniones: null,
  };
  return [
    { ...base, id: 'dev-1', name: 'Corralco Resort', ciudad: 'Lonquimay', pais: 'Chile', slug: 'corralco' },
    { ...base, id: 'dev-2', name: 'Termas de Puyehue', ciudad: 'Puyehue', pais: 'Chile', slug: 'puyehue', imagen_principal: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=512&h=320&fit=crop' },
    { ...base, id: 'dev-3', name: 'Huilo Huilo Resort', ciudad: 'Neltume', pais: 'Chile', slug: 'huilo-huilo', imagen_principal: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=512&h=320&fit=crop' },
    { ...base, id: 'dev-4', name: 'Hotel Patagonia', ciudad: 'Bariloche', pais: 'Argentina', slug: 'patagonia', imagen_principal: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=512&h=320&fit=crop' },
    { ...base, id: 'dev-5', name: 'Montaña Lodge', ciudad: 'San Martín', pais: 'Argentina', slug: 'montana', imagen_principal: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=512&h=320&fit=crop' },
  ];
}

type Props = {
  hotels: Hotel[];
  loading: boolean;
  configError?: boolean;
  fetchError?: string | null;
  emptyMessage?: string;
};

export function AlojamientosCarousel({
  hotels,
  loading,
  configError,
  fetchError,
  emptyMessage,
}: Props) {
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(false);
  const trackRef = useRef<HTMLDivElement>(null);

  const useDevPreview = import.meta.env.DEV && !loading && !fetchError && hotels.length === 0;
  const displayHotels = useDevPreview ? devPreviewHotels() : hotels;

  const updateArrows = () => {
    const el = trackRef.current;
    if (!el) return;
    setCanScrollLeft(el.scrollLeft > 0);
    setCanScrollRight(el.scrollLeft < el.scrollWidth - el.clientWidth - 2);
  };

  useEffect(() => {
    const el = trackRef.current;
    if (!el) return;
    updateArrows();
    el.addEventListener('scroll', updateArrows);
    window.addEventListener('resize', updateArrows);
    return () => {
      el.removeEventListener('scroll', updateArrows);
      window.removeEventListener('resize', updateArrows);
    };
  }, [displayHotels.length]);

  const scroll = (direction: 'left' | 'right') => {
    const el = trackRef.current;
    if (!el) return;
    el.scrollBy({ left: direction === 'left' ? -SCROLL_STEP : SCROLL_STEP, behavior: 'smooth' });
  };

  return (
    <section className={styles.section} data-alojamientos-layout="carousel">
      <div className="container">
        <h2 className={styles.title}>Alojamientos</h2>
        {useDevPreview && (
          <p className={styles.devHint}>Vista previa local — configurá Supabase para hoteles reales</p>
        )}
        {loading ? (
          <p className={styles.status}>Cargando hoteles…</p>
        ) : configError && !useDevPreview ? (
          <p className={styles.status}>
            No está configurada la conexión a la base de datos. El administrador debe definir VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY al construir la web.
          </p>
        ) : fetchError ? (
          <p className={styles.status}>
            {fetchError.toLowerCase().includes('invalid api key') || fetchError.includes('JWT')
              ? 'Error de configuración: la API key de Supabase no es válida o no se definió al construir la web.'
              : `Error al cargar alojamientos: ${fetchError}`}
          </p>
        ) : displayHotels.length === 0 ? (
          emptyMessage ? <p className={styles.status}>{emptyMessage}</p> : null
        ) : (
          <div className={styles.carouselOuter}>
            <button
              type="button"
              className={`${styles.arrowBtn} ${styles.arrowLeft}`}
              onClick={() => scroll('left')}
              disabled={!canScrollLeft}
              aria-label="Anterior"
            >
              ‹
            </button>
            <div className={styles.carouselViewport}>
              <div ref={trackRef} className={styles.carouselTrack} role="list">
                {displayHotels.map((h) => (
                  <div key={h.id} className={styles.cardSlot} role="listitem">
                    <HotelCard hotel={h} variant="carousel" />
                  </div>
                ))}
              </div>
            </div>
            <button
              type="button"
              className={`${styles.arrowBtn} ${styles.arrowRight}`}
              onClick={() => scroll('right')}
              disabled={!canScrollRight}
              aria-label="Siguiente"
            >
              ›
            </button>
          </div>
        )}
      </div>
    </section>
  );
}
