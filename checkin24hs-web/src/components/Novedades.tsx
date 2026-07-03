import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import type { Novedad } from '../types';
import styles from './Novedades.module.css';

function formatDate(s: string) {
  try {
    return new Date(s).toLocaleDateString('es-AR', { day: 'numeric', month: 'short', year: 'numeric' });
  } catch {
    return s;
  }
}

function useIsMobile() {
  const [isMobile, setIsMobile] = useState(
    typeof window !== 'undefined' && window.innerWidth < 768
  );
  useEffect(() => {
    const onResize = () => setIsMobile(window.innerWidth < 768);
    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, []);
  return isMobile;
}

const CARD_WIDTH = 216; // 200px card + 16px gap, para scrollBy

export function Novedades() {
  const [items, setItems] = useState<Novedad[]>([]);
  const [loading, setLoading] = useState(true);
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(false);
  const trackRef = useRef<HTMLDivElement>(null);
  const isMobile = useIsMobile();

  useEffect(() => {
    if (!supabase) {
      setLoading(false);
      return;
    }
    supabase
      .from('novedades')
      .select('id, titulo, resumen, imagen_miniatura, imagen_miniatura_mobile, video_miniatura, fecha_publicacion, slug, etiqueta_boton')
      .order('fecha_publicacion', { ascending: false })
      .then(({ data, error }) => {
        if (!error && data) setItems(data as Novedad[]);
        setLoading(false);
      });
  }, []);

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
  }, [items.length]);

  const scroll = (direction: 'left' | 'right') => {
    const el = trackRef.current;
    if (!el) return;
    const delta = direction === 'left' ? -CARD_WIDTH : CARD_WIDTH;
    el.scrollBy({ left: delta, behavior: 'smooth' });
  };

  if (loading) {
    return (
      <section id="novedades" className={styles.section}>
        <div className="container">
          <h2 className={styles.title}>Novedades</h2>
        </div>
      </section>
    );
  }

  return (
    <section id="novedades" className={styles.section} data-novedades-layout="carousel">
      {/* carrusel horizontal — layout interno, no visible en UI */}
      <div className="container">
        <h2 className={styles.title}>Novedades</h2>
        {items.length > 0 && (
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
              <div
                ref={trackRef}
                className={styles.carouselTrack}
                role="list"
              >
              {items.map((n) => (
                <Link
                  key={n.id}
                  to={`/novedad/${n.slug || n.id}`}
                  className={styles.cardLink}
                  role="listitem"
                >
                  <article className={styles.card}>
                    {n.video_miniatura ? (
                      <video
                        src={n.video_miniatura}
                        className={styles.img}
                        muted
                        loop
                        playsInline
                        autoPlay
                        aria-hidden
                      />
                    ) : (n.imagen_miniatura || n.imagen_miniatura_mobile) ? (
                      <img
                        src={
                          isMobile && n.imagen_miniatura_mobile
                            ? n.imagen_miniatura_mobile
                            : (n.imagen_miniatura || n.imagen_miniatura_mobile) ?? ''
                        }
                        alt=""
                        className={styles.img}
                      />
                    ) : null}
                    <div className={styles.body}>
                      <div className={styles.bodyText}>
                        <time dateTime={n.fecha_publicacion} className={styles.date}>
                          {formatDate(n.fecha_publicacion)}
                        </time>
                        <h3 className={styles.cardTitle}>{n.titulo}</h3>
                        {n.resumen && <p className={styles.resumen}>{n.resumen}</p>}
                      </div>
                      <span className={styles.cardBtn} aria-hidden>
                        {n.etiqueta_boton != null && String(n.etiqueta_boton).trim() !== ''
                          ? String(n.etiqueta_boton).trim()
                          : 'Ver más'}
                      </span>
                    </div>
                  </article>
                </Link>
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
