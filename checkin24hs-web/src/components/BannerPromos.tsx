import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import styles from './BannerPromos.module.css';

type PromosBanner = {
  imagen_url: string | null;
  imagen_url_mobile: string | null;
  texto_boton: string | null;
  titulo: string | null;
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
      .select('imagen_url, imagen_url_mobile, texto_boton, titulo')
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

  const title = banner.titulo?.trim() || 'Más ofertas vigentes';
  const btn = banner.texto_boton?.trim() || 'Ofertas';

  return (
    <section className={styles.section} aria-label="Banner de Promos">
      <div className="container">
        <div
          className={styles.media}
          style={{ backgroundImage: `url(${src})` }}
        >
          <div className={styles.overlay} />
          <div className={styles.inner}>
            <p className={styles.label}>Checkin24hs</p>
            <h2 className={styles.title}>{title}</h2>
            <Link to="/promos" className={styles.btn}>
              {btn}
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}
