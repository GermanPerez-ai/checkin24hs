import { useEffect, useState } from 'react';
import { useSearchParams, useLocation } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import type { Hotel } from '../types';
import { Header } from '../components/Header';
import { SliderOfertas } from '../components/SliderOfertas';
import { HotelCard } from '../components/HotelCard';
import { Destinos } from '../components/Destinos';
import { Novedades } from '../components/Novedades';
import { SobreNosotros } from '../components/SobreNosotros';
import { Footer } from '../components/Footer';
import { useFlorContext } from '../context/FlorContext';
import styles from './Home.module.css';

export function Home() {
  const [hotels, setHotels] = useState<Hotel[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchParams] = useSearchParams();
  const location = useLocation();
  const { setContext } = useFlorContext();

  // Scroll al ancla cuando la URL tiene #novedades, #destinos o #sobre-nosotros
  useEffect(() => {
    const hash = location.hash?.replace('#', '') || (typeof window !== 'undefined' ? window.location.hash?.replace('#', '') : '');
    if (!hash) return;
    const scroll = () => {
      const el = document.getElementById(hash);
      if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    };
    scroll();
    const t1 = setTimeout(scroll, 400);
    const t2 = setTimeout(scroll, 1000);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, [location.pathname, location.hash]);

  useEffect(() => {
    const onHashChange = () => {
      const hash = window.location.hash?.replace('#', '');
      if (!hash) return;
      const el = document.getElementById(hash);
      if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    };
    window.addEventListener('hashchange', onHashChange);
    return () => window.removeEventListener('hashchange', onHashChange);
  }, []);

  const pais = searchParams.get('pais') || '';
  const ciudad = searchParams.get('ciudad') || '';

  useEffect(() => {
    setContext(undefined);
  }, [setContext]);

  const [configError, setConfigError] = useState(false);
  const [fetchError, setFetchError] = useState<string | null>(null);

  useEffect(() => {
    if (!supabase) {
      setConfigError(true);
      setLoading(false);
      return;
    }
    setConfigError(false);
    setFetchError(null);
    let cancelled = false;
    let q = supabase
      .from('hotels')
      .select('*')
      .or('status.eq.active,status.eq.activo,status.eq.Activo,status.is.null')
      .order('name');

    if (pais) q = q.eq('pais', pais);
    if (ciudad) q = q.eq('ciudad', ciudad);

    void Promise.resolve(q).then(({ data, error }) => {
      if (cancelled) return;
      if (error) {
        setFetchError(error.message || 'Error al cargar');
      } else if (data) {
        setHotels((data as Hotel[]) || []);
      }
      setLoading(false);
    }).catch((err: unknown) => {
      if (cancelled) return;
      const message = err && typeof err === 'object' && 'message' in err ? String((err as { message: unknown }).message) : '';
      const name = err && typeof err === 'object' && 'name' in err ? (err as { name: string }).name : '';
      if (name === 'AbortError' || message.toLowerCase().includes('abort')) {
        setLoading(false);
        return;
      }
      setFetchError(message || 'Error al cargar');
      setLoading(false);
    });

    return () => { cancelled = true; };
  }, [pais, ciudad]);

  return (
    <>
      <Header />
      <main>
        <SliderOfertas />
        <Novedades />
        <section className={styles.hoteles}>
          <div className="container">
            <h2 className={styles.sectionTitle}>Alojamientos</h2>
            {loading ? (
              <p className={styles.loading}>Cargando hoteles…</p>
            ) : configError ? (
              <p className={styles.empty}>
                No está configurada la conexión a la base de datos. El administrador debe definir VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY al construir la web.
              </p>
            ) : fetchError ? (
              <p className={styles.empty}>
                {fetchError.toLowerCase().includes('invalid api key') || fetchError.includes('JWT')
                  ? 'Error de configuración: la API key de Supabase no es válida o no se definió al construir la web. En EasyPanel, configurá los Build Args VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY y volvé a hacer Deploy.'
                  : `Error al cargar alojamientos: ${fetchError}. Revisa permisos en Supabase (RLS) o que la tabla hotels exista.`}
              </p>
            ) : hotels.length === 0 ? (
              <p className={styles.empty}>
                {pais || ciudad
                  ? 'No hay alojamientos para los filtros seleccionados. Prueba otra ciudad o país.'
                  : 'No hay alojamientos en la base de datos. Revisa en Supabase que la tabla "hotels" tenga filas y que los roles anon tengan permiso SELECT (RLS).'}
              </p>
            ) : (
              <div className={styles.grid}>
                {hotels.map((h) => (
                  <HotelCard key={h.id} hotel={h} />
                ))}
              </div>
            )}
          </div>
        </section>
        <Destinos />
        <SobreNosotros />
        <Footer />
      </main>
    </>
  );
}
