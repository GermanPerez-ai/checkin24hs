import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import styles from './BannerPromos.module.css';

type PromosBanner = {
  imagen_url: string | null;
  imagen_url_mobile: string | null;
  texto_boton: string | null;
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

/** Banner gestionado en Dashboard → Banners del sitio → tipo "Banner de Promos". */
export function BannerPromos() {
  const [banner, setBanner] = useState<PromosBanner | null>(null);
  const isMobile = useIsMobile();

  useEffect(() => {
    if (!supabase) return;
    let cancelled = false;
    void supabase
      .from('slider_ofertas')
      .select('imagen_url, imagen_url_mobile, texto_boton')
      .eq('tipo_link', 'promos')
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

  if (!banner) return null;

  const src =
    (isMobile && banner.imagen_url_mobile) ||
    banner.imagen_url ||
    banner.imagen_url_mobile ||
    '';
  if (!src) return null;

  const btn = banner.texto_boton?.trim() || 'Ofertas';

  return (
    <section className={styles.section} aria-label="Promos">
      <div className="container">
        <Link
          to="/promos"
          className={styles.media}
          style={{ backgroundImage: `url(${src})` }}
        >
          <span className={styles.overlay} aria-hidden />
          <span className={styles.btn}>{btn}</span>
        </Link>
      </div>
    </section>
  );
}
