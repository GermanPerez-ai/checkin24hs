import { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { buildCotizadorUrl } from '../config';
import type { Hotel } from '../types';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import { useFlorContext } from '../context/FlorContext';
import styles from './HotelDetail.module.css';

export function HotelDetail() {
  const { slug } = useParams<{ slug: string }>();
  const [hotel, setHotel] = useState<Hotel | null>(null);
  const [loading, setLoading] = useState(true);
  const [checkin, setCheckin] = useState('');
  const [checkout, setCheckout] = useState('');
  const [pax, setPax] = useState(2);
  const { setContext } = useFlorContext();

  useEffect(() => {
    if (!slug || !supabase) {
      setLoading(false);
      return;
    }
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(slug);
    let q = supabase.from('hotels').select('*').or('status.eq.active,status.eq.activo,status.eq.Activo,status.is.null');
    q = isUuid ? q.eq('id', slug) : q.eq('slug', slug);
    q.maybeSingle()
      .then(({ data, error }) => {
        if (error && error.code !== 'PGRST116') {
          setLoading(false);
          return;
        }
        setHotel((data as Hotel) || null);
        setLoading(false);
      });
  }, [slug]);

  useEffect(() => {
    if (hotel) {
      setContext({
        hotelSlug: hotel.slug || slug || undefined,
        hotelName: hotel.name,
      });
    }
    return () => setContext(undefined);
  }, [hotel, slug, setContext]);

  const imagenPrincipal = hotel?.imagen_principal
    || (Array.isArray(hotel?.galeria_fotos) && hotel?.galeria_fotos?.length ? hotel.galeria_fotos[0] : null)
    || (Array.isArray(hotel?.images) && hotel?.images?.length ? hotel.images[0] : null)
    || 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800';

  const galeria = (hotel?.galeria_fotos && Array.isArray(hotel.galeria_fotos) ? hotel.galeria_fotos : hotel?.images) || [];
  const puntuacion = hotel?.puntuacion_num ?? hotel?.rating ?? null;
  const precio = hotel?.precio_desde ?? hotel?.price ?? null;
  const metodoVenta = hotel?.metodo_venta || 'cotizacion';
  const cotizarUrl = hotel ? buildCotizadorUrl({
    hotel_id: hotel.id,
    checkin: checkin || undefined,
    checkout: checkout || undefined,
    pax,
  }) : '#';

  if (loading) {
    return (
      <>
        <Header />
        <main className="container"><p>Cargando…</p></main>
        <Footer />
      </>
    );
  }

  if (!hotel) {
    return (
      <>
        <Header />
        <main className="container">
          <p>No encontramos ese alojamiento.</p>
          <Link to="/">Volver al inicio</Link>
        </main>
        <Footer />
      </>
    );
  }

  return (
    <>
      <Header />
      <main className={styles.main}>
        <div className="container">
          <nav className={styles.breadcrumb}>
            <Link to="/">Inicio</Link>
            <span>/</span>
            <span>{hotel.name}</span>
          </nav>
          <div className={styles.hero}>
            <img src={imagenPrincipal} alt={hotel.name} className={styles.heroImg} />
            {puntuacion != null && (
              <span className={styles.badge}>
                {puntuacion.toFixed(1)} {hotel.puntuacion_texto || ''}
                {hotel.cantidad_opiniones != null && hotel.cantidad_opiniones > 0 && (
                  <> · {hotel.cantidad_opiniones} opiniones</>
                )}
              </span>
            )}
          </div>
          <div className={styles.twoCol}>
            <div>
              <h1 className={styles.title}>{hotel.name}</h1>
              <p className={styles.location}>
                {[hotel.ciudad, hotel.region, hotel.pais].filter(Boolean).join(' · ') || hotel.location || '—'}
              </p>
              {hotel.description && (
                <div className={styles.desc} dangerouslySetInnerHTML={{ __html: hotel.description }} />
              )}
              <div className={styles.amenities}>
                {hotel.wifi && <span className={styles.amenity}>Wi‑Fi</span>}
                {hotel.desayuno && <span className={styles.amenity}>Desayuno</span>}
                {hotel.piscina && <span className={styles.amenity}>Piscina</span>}
                {hotel.estacionamiento && <span className={styles.amenity}>Estacionamiento</span>}
                {hotel.calefaccion && <span className={styles.amenity}>Calefacción</span>}
                {hotel.pet_friendly && <span className={styles.amenity}>Pet friendly</span>}
              </div>
              {galeria.length > 0 && (
                <div className={styles.galeria}>
                  {galeria.slice(0, 6).map((url, i) => (
                    <img key={i} src={url} alt="" className={styles.galeriaImg} />
                  ))}
                </div>
              )}
            </div>
            <aside className={styles.aside}>
              <div className={styles.card}>
                {precio != null && (
                  <p className={styles.precio}>
                    Desde <strong>${precio.toLocaleString('es-AR')}</strong>
                  </p>
                )}
                <div className={styles.form}>
                  <label>
                    <span>Check-in</span>
                    <input type="date" value={checkin} onChange={(e) => setCheckin(e.target.value)} />
                  </label>
                  <label>
                    <span>Check-out</span>
                    <input type="date" value={checkout} onChange={(e) => setCheckout(e.target.value)} />
                  </label>
                  <label>
                    <span>Huéspedes</span>
                    <input type="number" min={1} max={20} value={pax} onChange={(e) => setPax(Number(e.target.value) || 1)} />
                  </label>
                </div>
                {metodoVenta === 'directa' && hotel.url_reserva_directa ? (
                  <a
                    href={hotel.url_reserva_directa}
                    target="_blank"
                    rel="noopener noreferrer"
                    className={styles.btnSec}
                  >
                    Reservar
                  </a>
                ) : (
                  <a href={cotizarUrl} className={styles.btnPrim}>
                    Cotizar
                  </a>
                )}
              </div>
            </aside>
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
