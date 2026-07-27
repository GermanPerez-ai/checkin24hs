import { useEffect, useMemo, useState } from 'react';
import { supabase } from '../lib/supabase';
import type { Hotel } from '../types';
import { PACKS_DESTINO, esPaquete } from '../data/destinoPaises';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import { AlojamientosCarousel } from '../components/AlojamientosCarousel';
import { WhatsAppCta } from '../components/WhatsAppCta';
import styles from './DestinoPais.module.css';

export function Packs() {
  const [hotels, setHotels] = useState<Hotel[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
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
          setHotels((data as Hotel[]).filter(esPaquete));
        }
        setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const porPais = useMemo(() => {
    const map = new Map<string, Hotel[]>();
    for (const h of hotels) {
      const key = (h.pais || 'Otros').trim() || 'Otros';
      if (!map.has(key)) map.set(key, []);
      map.get(key)!.push(h);
    }
    return Array.from(map.entries()).sort(([a], [b]) => a.localeCompare(b, 'es'));
  }, [hotels]);

  return (
    <>
      <Header />
      <main>
        <section className={styles.hero}>
          <img src={PACKS_DESTINO.heroImagen} alt="" className={styles.heroImg} />
          <div className={styles.heroOverlay} />
          <div className={`container ${styles.heroContent}`}>
            <h1 className={styles.heroTitle}>{PACKS_DESTINO.nombre}</h1>
            <p className={styles.heroSubtitle}>{PACKS_DESTINO.heroTitulo}</p>
          </div>
        </section>

        {loading ? (
          <div className="container">
            <p className={styles.loading}>Cargando packs…</p>
          </div>
        ) : porPais.length === 0 ? (
          <div className="container">
            <p className={styles.loading}>Próximamente más packs y escapadas.</p>
          </div>
        ) : (
          porPais.map(([pais, items]) => (
            <AlojamientosCarousel
              key={pais}
              title={`Packs en ${pais}`}
              hotels={items}
              loading={false}
              compact
              cardVariant="pack"
            />
          ))
        )}

        <WhatsAppCta mensajeProducto="consulta general sobre packs y paquetes" />
        <Footer />
      </main>
    </>
  );
}
