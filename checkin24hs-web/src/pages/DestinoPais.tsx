import { useEffect, useMemo, useState } from 'react';
import { useLocation } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import type { Hotel } from '../types';
import {
  DESTINO_PAISES,
  agruparHotelesEnBloques,
  filterHotelsPorPais,
  type PaisSlug,
} from '../data/destinoPaises';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import { AlojamientosCarousel } from '../components/AlojamientosCarousel';
import { WhatsAppCta } from '../components/WhatsAppCta';
import { sortHotelsPuyehueFirst } from '../lib/hoteles';
import styles from './DestinoPais.module.css';

export function DestinoPais() {
  const location = useLocation();
  const slug = location.pathname.replace(/^\//, '') as PaisSlug;
  const config = DESTINO_PAISES[slug];

  const [hotels, setHotels] = useState<Hotel[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!config) return;
    if (!supabase) {
      setLoading(false);
      return;
    }
    let cancelled = false;
    supabase
      .from('hotels')
      .select('*')
      .or('status.eq.active,status.eq.activo,status.eq.Activo,status.is.null')
      .order('name')
      .then(({ data, error }) => {
        if (cancelled) return;
        if (!error && data) {
          const filtrados = filterHotelsPorPais(data as Hotel[], config);
          setHotels(sortHotelsPuyehueFirst(filtrados));
        }
        setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [config, slug]);

  const bloques = useMemo(() => {
    if (!config) return [];
    return agruparHotelesEnBloques(hotels, config.bloques);
  }, [hotels, config]);

  if (!config) {
    return (
      <>
        <Header />
        <main className="container" style={{ padding: '48px 16px' }}>
          <p>Destino no encontrado.</p>
        </main>
        <Footer />
      </>
    );
  }

  return (
    <>
      <Header />
      <main>
        <section className={styles.hero}>
          <img src={config.heroImagen} alt="" className={styles.heroImg} />
          <div className={styles.heroOverlay} />
          <div className={`container ${styles.heroContent}`}>
            <h1 className={styles.heroTitle}>{config.nombre}</h1>
            <p className={styles.heroSubtitle}>{config.heroTitulo}</p>
          </div>
        </section>

        {loading ? (
          <div className="container">
            <p className={styles.loading}>Cargando alojamientos…</p>
          </div>
        ) : bloques.length === 0 ? (
          <div className="container">
            <p className={styles.loading}>Próximamente más opciones en {config.nombre}.</p>
          </div>
        ) : (
          bloques.map((b) => (
            <AlojamientosCarousel
              key={b.titulo}
              title={b.titulo}
              hotels={b.hotels}
              loading={false}
              compact
            />
          ))
        )}

        <WhatsAppCta mensajeProducto={`consulta general sobre ${config.nombre}`} />
        <Footer />
      </main>
    </>
  );
}
