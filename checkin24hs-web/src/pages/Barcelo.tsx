import { useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import type { Hotel } from '../types';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import { HotelCard } from '../components/HotelCard';
import { WhatsAppCta } from '../components/WhatsAppCta';
import { useFlorContext } from '../context/FlorContext';
import { esAlojamiento } from '../data/destinoPaises';
import { BARCELO_PERFILES, type PerfilBarcelo } from '../data/barceloLanding';
import { CountryFlag } from '../components/CountryFlag';
import {
  agruparPorDestino,
  agruparPorPais,
  destinoDeHotel,
  etiquetaUbicacion,
  esHotelGrupoBarcelo,
  ordenarBarcelo,
  perfilesHotel,
} from '../lib/barcelo';
import { useBarceloBannerSrc } from '../components/BarceloHeader';
import { srcSeccion, useBarceloSeccionBanners } from '../lib/barceloBanners';
import styles from './Barcelo.module.css';

const PERFILES_VALIDOS = new Set<string>(BARCELO_PERFILES.map((p) => p.id));

/** Landing exclusiva del grupo Barceló (se abre desde el banner Barceló de la Home). */
export function Barcelo() {
  const { setContext } = useFlorContext();
  const bannerSrc = useBarceloBannerSrc();
  const { porClave: bannersSeccion, isMobile: isMobileBanner } = useBarceloSeccionBanners();
  const [searchParams, setSearchParams] = useSearchParams();
  const [hotels, setHotels] = useState<Hotel[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const perfilParam = searchParams.get('perfil') || '';
  const perfil = (PERFILES_VALIDOS.has(perfilParam) ? perfilParam : '') as PerfilBarcelo | '';
  const destino = searchParams.get('destino') || '';

  useEffect(() => {
    setContext(undefined);
  }, [setContext]);

  useEffect(() => {
    document.title = 'Exclusivo Barceló | Checkin24hs';
  }, []);

  useEffect(() => {
    if (!supabase) {
      setError('config');
      setLoading(false);
      return;
    }
    let cancelled = false;
    void Promise.resolve(
      supabase
        .from('hotels')
        .select('*')
        .or('status.eq.active,status.eq.activo,status.eq.Activo,status.is.null')
        .order('name')
    )
      .then(({ data, error: err }) => {
        if (cancelled) return;
        if (err) {
          setError(err.message || 'Error al cargar');
        } else {
          const all = (data as Hotel[]) || [];
          setHotels(ordenarBarcelo(all.filter((h) => esAlojamiento(h) && esHotelGrupoBarcelo(h))));
        }
        setLoading(false);
      })
      .catch((e: unknown) => {
        if (cancelled) return;
        setError(e instanceof Error ? e.message : 'Error al cargar');
        setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const perfilesPorHotel = useMemo(() => {
    const m = new Map<string, Set<PerfilBarcelo>>();
    for (const h of hotels) m.set(h.id, perfilesHotel(h));
    return m;
  }, [hotels]);

  /** Destinos disponibles (siempre todos, para que el filtro no "desaparezca"). */
  const destinos = useMemo(() => agruparPorDestino(hotels), [hotels]);

  /** Perfiles con al menos un hotel real: solo se muestran esos botones. */
  const perfilesDisponibles = useMemo(
    () => BARCELO_PERFILES.filter((p) => hotels.some((h) => perfilesPorHotel.get(h.id)?.has(p.id))),
    [hotels, perfilesPorHotel]
  );

  const grupos = useMemo(() => {
    const filtrados = hotels.filter((h) => {
      if (perfil && !perfilesPorHotel.get(h.id)?.has(perfil)) return false;
      if (destino && destinoDeHotel(h).id !== destino) return false;
      return true;
    });
    return agruparPorPais(filtrados);
  }, [hotels, perfil, destino, perfilesPorHotel]);

  const setFiltro = (key: 'perfil' | 'destino', value: string) => {
    const next = new URLSearchParams(searchParams);
    if (value) next.set(key, value);
    else next.delete(key);
    setSearchParams(next, { replace: true });
  };

  const hayFiltros = !!perfil || !!destino;

  return (
    <>
      <Header />
      <main>
        <section className={styles.hero} aria-label="Exclusivo Barceló">
          <img src={bannerSrc} alt="" className={styles.heroImg} />
          <div className={styles.heroOverlay} />
          <div className={`container ${styles.heroContent}`}>
            <p className={styles.heroKicker}>
              <span className={styles.stars} aria-hidden>★★★</span> Exclusivo Checkin24hs{' '}
              <span className={styles.stars} aria-hidden>★★★</span>
            </p>
            <h1 className={styles.heroTitle}>Barceló Hotel Group</h1>
            <p className={styles.heroSubtitle}>
              Barceló, Occidental, Allegro y Royal Hideaway: elegí tu resort y te asesoramos sin compromiso.
            </p>
          </div>
        </section>

        <section className={styles.filtros} aria-label="Filtrar hoteles">
          <div className="container">
            {perfilesDisponibles.length > 0 && (
              <div className={styles.filtroFila}>
                <span className={styles.filtroLabel}>Viajo con</span>
                <div className={styles.chips} role="group" aria-label="Tipo de viaje">
                  <button
                    type="button"
                    className={!perfil ? styles.chipActive : styles.chip}
                    aria-pressed={!perfil}
                    onClick={() => setFiltro('perfil', '')}
                  >
                    Todos
                  </button>
                  {perfilesDisponibles.map((p) => (
                    <button
                      key={p.id}
                      type="button"
                      className={perfil === p.id ? styles.chipActive : styles.chip}
                      aria-pressed={perfil === p.id}
                      onClick={() => setFiltro('perfil', perfil === p.id ? '' : p.id)}
                    >
                      {p.label}
                    </button>
                  ))}
                </div>
              </div>
            )}
            {destinos.length > 1 && (
              <div className={styles.filtroFila}>
                <label className={styles.filtroLabel} htmlFor="barcelo-destino">
                  Destino
                </label>
                <select
                  id="barcelo-destino"
                  className={styles.select}
                  value={destino}
                  onChange={(e) => setFiltro('destino', e.target.value)}
                >
                  <option value="">Todos los destinos</option>
                  {destinos.map((d) => (
                    <option key={d.id} value={d.id}>
                      {d.label} ({d.hotels.length})
                    </option>
                  ))}
                </select>
                {hayFiltros && (
                  <button
                    type="button"
                    className={styles.limpiar}
                    onClick={() => setSearchParams(new URLSearchParams(), { replace: true })}
                  >
                    Limpiar filtros
                  </button>
                )}
              </div>
            )}
          </div>
        </section>

        <div className="container">
          {loading ? (
            <p className={styles.status}>Cargando hoteles Barceló…</p>
          ) : error === 'config' ? (
            <p className={styles.status}>
              No está configurada la conexión a la base de datos. El administrador debe definir VITE_SUPABASE_URL y
              VITE_SUPABASE_ANON_KEY al construir la web.
            </p>
          ) : error ? (
            <p className={styles.status}>Error al cargar alojamientos: {error}</p>
          ) : hotels.length === 0 ? (
            <p className={styles.status}>Próximamente más hoteles del grupo Barceló.</p>
          ) : grupos.length === 0 ? (
            <p className={styles.status}>
              No hay hoteles con esos filtros.{' '}
              <button
                type="button"
                className={styles.limpiarInline}
                onClick={() => setSearchParams(new URLSearchParams(), { replace: true })}
              >
                Ver todos
              </button>
            </p>
          ) : (
            grupos.map((pais) => {
              const fotoPais = srcSeccion(
                bannersSeccion,
                [pais.id, pais.destinos.length === 1 ? pais.destinos[0].id : null],
                isMobileBanner
              );
              return (
              <section key={pais.id} className={styles.grupo} aria-label={`Hoteles en ${pais.label}`}>
                <h2 className={fotoPais ? `${styles.grupoTitulo} ${styles.grupoTituloFoto}` : styles.grupoTitulo}>
                  {fotoPais && <img src={fotoPais} alt="" className={styles.grupoTituloImg} />}
                  <CountryFlag code={pais.flag} />
                  <span>Hoteles en {pais.label}</span>
                </h2>
                {pais.destinos.map((d) => {
                  const fotoDestino = pais.destinos.length > 1
                    ? srcSeccion(bannersSeccion, [d.id], isMobileBanner)
                    : null;
                  return (
                  <div key={d.id} className={styles.destinoBloque}>
                    {pais.destinos.length > 1 && (
                      <h3 className={fotoDestino ? `${styles.destinoTitulo} ${styles.destinoTituloFoto}` : styles.destinoTitulo}>
                        {fotoDestino && <img src={fotoDestino} alt="" className={styles.grupoTituloImg} />}
                        <span>{d.label}</span>
                      </h3>
                    )}
                    <div className={styles.grid} role="list">
                      {d.hotels.map((h) => (
                        <div key={h.id} className={styles.cell} role="listitem">
                          <HotelCard hotel={h} variant="carousel" ubicacion={etiquetaUbicacion(h)} />
                        </div>
                      ))}
                    </div>
                  </div>
                  );
                })}
              </section>
              );
            })
          )}
        </div>

        <WhatsAppCta
          mensajeProducto="hoteles Exclusivo Barceló"
          titulo="¿Querés cotizar un Barceló?"
          textoBoton="Escribinos por WhatsApp"
        />
        <Footer />
      </main>
    </>
  );
}
