import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import styles from './BarceloHeader.module.css';

const FALLBACK_SRC = '/exclusivo-barcelo.png';

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

/** Banner gestionado en Dashboard → Banners del sitio → tipo "Banner Exclusivo Barceló". */
export function BarceloHeader() {
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

  const src =
    (isMobile && banner?.imagen_url_mobile) ||
    banner?.imagen_url ||
    banner?.imagen_url_mobile ||
    FALLBACK_SRC;

  return (
    <section className={styles.section} aria-label="Exclusivo Barceló">
      <div className="container">
        <div className={styles.media}>
          <img src={src} alt="Barceló Hotels & Resorts" className={styles.bg} />
          <div className={styles.overlay} />
        </div>
      </div>
    </section>
  );
}
