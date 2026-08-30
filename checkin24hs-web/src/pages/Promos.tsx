import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { promoVigente } from '../lib/promos';
import { supabase } from '../lib/supabase';
import type { LandingPromo } from '../types';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import styles from './Promos.module.css';

export function Promos() {
  const [promos, setPromos] = useState<LandingPromo[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!supabase) {
      setLoading(false);
      return;
    }
    let cancelled = false;
    void supabase
      .from('landing_promos')
      .select('*')
      .eq('activo', true)
      .order('orden', { ascending: true })
      .order('created_at', { ascending: false })
      .then(({ data }) => {
        if (cancelled) return;
        const list = ((data as LandingPromo[]) || []).filter(promoVigente);
        setPromos(list);
        setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <>
      <Header />
      <main className={styles.main}>
        <div className={`container ${styles.wrap}`}>
          <p className={styles.brand}>Checkin24hs</p>
          <h1 className={styles.title}>Promos vigentes</h1>
          <p className={styles.lead}>
            Ofertas especiales de hoteles. Elegí una, consultá por WhatsApp o dejá tu email para enterarte de las próximas.
          </p>

          {loading && <p className={styles.state}>Cargando…</p>}

          {!loading && promos.length === 0 && (
            <p className={styles.state}>
              No hay promos activas por ahora. Seguí a Checkin24hs o escribinos por WhatsApp.
            </p>
          )}

          <ul className={styles.grid}>
            {promos.map((p) => (
              <li key={p.id} className={styles.item}>
                <Link to={`/promo/${encodeURIComponent(p.slug)}`} className={styles.card}>
                  <div className={styles.thumb}>
                    {p.video_hero ? (
                      <video
                        className={styles.thumbMedia}
                        src={p.video_hero}
                        poster={p.imagen_hero || undefined}
                        muted
                        loop
                        playsInline
                        autoPlay
                        aria-hidden
                      />
                    ) : p.imagen_hero ? (
                      <img
                        className={styles.thumbMedia}
                        src={p.imagen_hero}
                        alt=""
                      />
                    ) : null}
                  </div>
                  <div className={styles.cardBody}>
                    {p.badge && <span className={styles.badge}>{p.badge}</span>}
                    <h2 className={styles.cardTitle}>{p.titulo}</h2>
                    {p.hotel_nombre && (
                      <p className={styles.hotel}>{p.hotel_nombre}</p>
                    )}
                    {p.precio_texto && (
                      <p className={styles.price}>{p.precio_texto}</p>
                    )}
                    <span className={styles.cta}>Ver oferta →</span>
                  </div>
                </Link>
              </li>
            ))}
          </ul>
        </div>
      </main>
      <Footer />
    </>
  );
}
