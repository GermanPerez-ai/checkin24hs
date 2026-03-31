import { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import type { Novedad } from '../types';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import styles from './NovedadDetail.module.css';

function formatDate(s: string) {
  try {
    return new Date(s).toLocaleDateString('es-AR', { day: 'numeric', month: 'long', year: 'numeric' });
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

export function NovedadDetail() {
  const { slugOrId } = useParams<{ slugOrId: string }>();
  const [novedad, setNovedad] = useState<Novedad | null>(null);
  const [loading, setLoading] = useState(true);
  const isMobile = useIsMobile();

  useEffect(() => {
    if (!slugOrId || !supabase) {
      setLoading(false);
      return;
    }
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(slugOrId);
    let q = supabase.from('novedades').select('*');
    q = isUuid ? q.eq('id', slugOrId) : q.eq('slug', slugOrId);
    q.maybeSingle()
      .then(({ data, error }) => {
        if (error && error.code !== 'PGRST116') {
          setLoading(false);
          return;
        }
        setNovedad((data as Novedad) || null);
        setLoading(false);
      });
  }, [slugOrId]);

  if (loading) {
    return (
      <>
        <Header />
        <main className={styles.main}><p>Cargando…</p></main>
        <Footer />
      </>
    );
  }

  if (!novedad) {
    return (
      <>
        <Header />
        <main className={styles.main}>
          <p>Novedad no encontrada.</p>
          <Link to="/#novedades" className={styles.backLink}>← Volver a Novedades</Link>
        </main>
        <Footer />
      </>
    );
  }

  return (
    <>
      <Header />
      <main className={styles.main}>
        <article className={styles.article}>
          <Link to="/#novedades" className={styles.backLink}>← Volver a Novedades</Link>
          {(novedad.imagen_miniatura || novedad.imagen_miniatura_mobile) && (
            <img
              src={
                isMobile && novedad.imagen_miniatura_mobile
                  ? novedad.imagen_miniatura_mobile
                  : (novedad.imagen_miniatura || novedad.imagen_miniatura_mobile) ?? ''
              }
              alt=""
              className={styles.heroImg}
            />
          )}
          <div className={styles.body}>
            <time dateTime={novedad.fecha_publicacion} className={styles.date}>
              {formatDate(novedad.fecha_publicacion)}
            </time>
            <h1 className={styles.title}>{novedad.titulo}</h1>
            {novedad.resumen && <p className={styles.resumen}>{novedad.resumen}</p>}
            {novedad.cuerpo_nota ? (
              <div
                className={styles.cuerpo}
                dangerouslySetInnerHTML={{
                  /* Permite HTML para botones "Cotizar" / "Chat con Flor IA" que configure el admin */
                  __html: novedad.cuerpo_nota.replace(/\n/g, '<br />'),
                }}
              />
            ) : (
              novedad.resumen && <p className={styles.cuerpo}>{novedad.resumen}</p>
            )}
          </div>
        </article>
      </main>
      <Footer />
    </>
  );
}
