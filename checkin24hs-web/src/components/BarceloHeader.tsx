import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import styles from './BarceloHeader.module.css';

const FALLBACK_SRC = '/exclusivo-barcelo.png';

/** Ruta de la landing exclusiva Barceló (ver pages/Barcelo.tsx). */
export const BARCELO_LANDING_PATH = '/barcelo';

type BarceloBanner = {
  imagen_url: string | null;
  imagen_url_mobile: string | null;
};

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

/**
 * Imagen del banner gestionado en Dashboard → Banners del sitio → tipo
 * "Banner Exclusivo Barceló" (slider_ofertas.tipo_link = 'barcelo'), con
 * fallback a /exclusivo-barcelo.png. Se reutiliza en la landing /barcelo.
 */
export function useBarceloBannerSrc(): string {
  const [banner, setBanner] = useState<BarceloBanner | null>(null);
  const isMobile = useIsMobile();

  useEffect(() => {
    if (!supabase) return;
    let cancelled = false;
    void supabase
      .from('slider_ofertas')
      .select('imagen_url, imagen_url_mobile')
      .eq('tipo_link', 'barcelo')
      .eq('activo', true)
      .order('orden', { ascending: true })
      .limit(1)
      .then(({ data }) => {
        if (!cancelled) setBanner((data && data[0]) || null);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const desktop = (banner?.imagen_url || '').trim();
  const mobile = (banner?.imagen_url_mobile || '').trim();
  return (isMobile && mobile) || desktop || mobile || FALLBACK_SRC;
}

/** Banner Barceló de la Home: al hacer clic abre la landing exclusiva /barcelo. */
export function BarceloHeader() {
  const src = useBarceloBannerSrc();

  return (
    <section className={styles.section} aria-label="Exclusivo Barceló">
      <div className="container">
        <Link
          to={BARCELO_LANDING_PATH}
          className={styles.media}
          aria-label="Ver hoteles Exclusivo Barceló"
        >
          <img src={src} alt="Barceló Hotels & Resorts" className={styles.bg} />
          <span className={styles.overlay} aria-hidden />
          <span className={styles.cta}>Ver hoteles Barceló</span>
          <p className={styles.legend}>
            <span className={styles.stars} aria-hidden>★★★</span>
            {' '}Exclusivo Checkin24hs{' '}
            <span className={styles.stars} aria-hidden>★★★</span>
          </p>
        </Link>
      </div>
    </section>
  );
}
