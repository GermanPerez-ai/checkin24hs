import { useEffect, useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { buildWhatsAppConsultaUrl } from '../config';
import {
  formatPackPrice,
  getFichaPack,
  getHotelImageUrl,
  getPackPrecio,
  linesFromText,
} from '../lib/packs';
import { sharePackUrl } from '../lib/share';
import { supabase } from '../lib/supabase';
import type { Hotel } from '../types';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import { ShareButton } from '../components/ShareButton';
import styles from './PackDetail.module.css';

function isUuid(s: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);
}

export function PackDetail() {
  const { slug } = useParams<{ slug: string }>();
  const [hotel, setHotel] = useState<Hotel | null>(null);
  const [loading, setLoading] = useState(true);
  const [imgIndex, setImgIndex] = useState(0);

  useEffect(() => {
    if (!slug || !supabase) {
      setLoading(false);
      return;
    }
    let cancelled = false;
    const key = decodeURIComponent(slug);
    const q = isUuid(key)
      ? supabase.from('hotels').select('*').eq('id', key).maybeSingle()
      : supabase.from('hotels').select('*').eq('slug', key).maybeSingle();

    void Promise.resolve(q).then(({ data }) => {
      if (cancelled) return;
      setHotel((data as Hotel) || null);
      setLoading(false);
    });
    return () => {
      cancelled = true;
    };
  }, [slug]);

  const fp = useMemo(() => (hotel ? getFichaPack(hotel) : {}), [hotel]);
  const images = useMemo(() => {
    if (!hotel) return [];
    const list: string[] = [];
    if (hotel.imagen_principal) list.push(hotel.imagen_principal);
    if (Array.isArray(hotel.galeria_fotos)) list.push(...hotel.galeria_fotos.filter(Boolean));
    if (Array.isArray(hotel.images)) {
      for (const img of hotel.images) {
        if (img && !list.includes(img)) list.push(img);
      }
    }
    if (!list.length) list.push(getHotelImageUrl(hotel));
    return list;
  }, [hotel]);

  useEffect(() => {
    setImgIndex(0);
  }, [hotel?.id]);

  if (loading) {
    return (
      <>
        <Header />
        <main className="container" style={{ padding: '48px 16px' }}>
          <p>Cargando pack…</p>
        </main>
        <Footer />
      </>
    );
  }

  if (!hotel || hotel.tipo_producto !== 'paquete') {
    return (
      <>
        <Header />
        <main className="container" style={{ padding: '48px 16px' }}>
          <p>Pack no encontrado.</p>
          <Link to="/packs">Volver a Packs</Link>
        </main>
        <Footer />
      </>
    );
  }

  const precio = getPackPrecio(hotel);
  const precioLabel = formatPackPrice(precio, fp.moneda);
  const adultos = fp.adultos != null ? Number(fp.adultos) : 2;
  const ninos = fp.ninos != null ? Number(fp.ninos) : 0;
  const noches = fp.noches != null ? Number(fp.noches) : null;
  const destinos = fp.destinos_count != null ? Number(fp.destinos_count) : 1;
  const alojamientos = fp.alojamientos_count != null ? Number(fp.alojamientos_count) : 1;
  const circuitos = fp.circuitos_count != null ? Number(fp.circuitos_count) : 1;
  const precioNota =
    fp.precio_nota?.trim() ||
    `En base a ${adultos} adulto${adultos === 1 ? '' : 's'}${ninos > 0 ? ` y ${ninos} niño${ninos === 1 ? '' : 's'}` : ''}`;
  const paxLabel = `${adultos} Adulto${adultos === 1 ? '' : 's'}${ninos > 0 ? ` + ${ninos} Niño${ninos === 1 ? '' : 's'}` : ''}`;
  const descripcion = linesFromText(fp.descripcion || hotel.description);
  const incluye = linesFromText(fp.incluye);
  const excluye = linesFromText(fp.excluye);
  const alojamientosPrev = linesFromText(fp.alojamientos_previstos);
  const itinerario = linesFromText(fp.itinerario);
  const waUrl = buildWhatsAppConsultaUrl(hotel.name);
  const currentImg = images[Math.min(imgIndex, images.length - 1)];

  const onShare = async () => {
    const url = typeof window !== 'undefined' ? window.location.href : '';
    const result = await sharePackUrl({
      url,
      title: hotel.name,
      text: `Mirá este pack: ${hotel.name}`,
    });
    if (result === 'copied') {
      window.alert('Link copiado al portapapeles');
    }
  };

  return (
    <>
      <Header />
      <main className={styles.page}>
        <div className={`container ${styles.layout}`}>
          <aside className={styles.sidebar}>
            <div className={styles.priceBlock}>
              <p className={styles.priceLabel}>Precio por persona Desde</p>
              <div className={styles.priceRow}>
                {precioLabel ? <p className={styles.priceValue}>{precioLabel}</p> : <p className={styles.priceValue}>Consultar</p>}
                <ShareButton className={styles.shareBtn} onClick={onShare} />
              </div>
              <p className={styles.priceNote}>{precioNota}</p>
            </div>

            <div className={styles.actions}>
              <a href={waUrl} target="_blank" rel="noopener noreferrer" className={styles.btn}>
                Contactanos
              </a>
            </div>

            <h2 className={styles.sideTitle}>Esta cotizacion incluye:</h2>
            <div className={styles.box}>
              <span className={styles.boxIcon} aria-hidden>
                👥
              </span>
              <span>{paxLabel}</span>
            </div>
            <div className={styles.box}>
              <span className={styles.boxIcon} aria-hidden>
                🌙
              </span>
              <span>Noches</span>
              <strong className={styles.boxRight}>{noches != null ? noches : '—'}</strong>
            </div>

            <div className={styles.box}>
              <span className={styles.boxIcon} aria-hidden>
                📍
              </span>
              <span>Destinos</span>
              <strong className={styles.boxRight}>{destinos}</strong>
            </div>
            <div className={styles.box}>
              <span className={styles.boxIcon} aria-hidden>
                🛏
              </span>
              <span>Alojamientos</span>
              <strong className={styles.boxRight}>{alojamientos}</strong>
            </div>
            <div className={styles.box}>
              <span className={styles.boxIcon} aria-hidden>
                📷
              </span>
              <span>Circuitos</span>
              <strong className={styles.boxRight}>{circuitos}</strong>
            </div>

            <div className={styles.tourCard}>
              <h3 className={styles.tourTitle}>Resumen de itinerario</h3>
              {fp.punto_encuentro?.trim() && (
                <p className={styles.tourLine}>
                  <strong>Punto de encuentro:</strong> {fp.punto_encuentro.trim()}
                </p>
              )}
              {incluye.length > 0 && (
                <>
                  <p className={styles.tourLabel}>Incluido:</p>
                  <ul className={styles.bullets}>
                    {incluye.map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                </>
              )}
              {excluye.length > 0 && (
                <>
                  <p className={styles.tourLabel}>Excluido:</p>
                  <ul className={styles.bullets}>
                    {excluye.map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                </>
              )}
              {alojamientosPrev.length > 0 && (
                <>
                  <p className={styles.tourLabel}>Alojamientos previstos:</p>
                  <ul className={styles.bullets}>
                    {alojamientosPrev.map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                </>
              )}
            </div>
          </aside>

          <section className={styles.main}>
            {fp.temas?.trim() && <p className={styles.temas}>{fp.temas.trim()}</p>}
            <h1 className={styles.h1}>{hotel.name}</h1>

            <h2 className={styles.sectionTitle}>Descripción</h2>
            {descripcion.length > 0 ? (
              <ul className={styles.bullets}>
                {descripcion.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            ) : (
              <p className={styles.muted}>Sin descripción cargada.</p>
            )}

            <div className={styles.itinerarioBar}>
              <span className={styles.itinerarioLeft}>
                <span aria-hidden>📋</span> Itinerario
              </span>
              <span className={styles.itinerarioRight}>Circuitos</span>
            </div>

            <div className={styles.slider}>
              <img src={currentImg} alt={hotel.name} className={styles.sliderImg} />
              {images.length > 1 && (
                <>
                  <button
                    type="button"
                    className={`${styles.sliderBtn} ${styles.sliderPrev}`}
                    aria-label="Anterior"
                    onClick={() => setImgIndex((i) => (i - 1 + images.length) % images.length)}
                  >
                    ‹
                  </button>
                  <button
                    type="button"
                    className={`${styles.sliderBtn} ${styles.sliderNext}`}
                    aria-label="Siguiente"
                    onClick={() => setImgIndex((i) => (i + 1) % images.length)}
                  >
                    ›
                  </button>
                </>
              )}
            </div>

            {(itinerario.length > 0 || incluye.length > 0) && (
              <ul className={styles.bullets}>
                {(itinerario.length ? itinerario : incluye).map((item) => (
                  <li key={`it-${item}`}>{item}</li>
                ))}
              </ul>
            )}

            {excluye.length > 0 && (
              <>
                <p className={styles.tourLabel}>Notas:</p>
                <ul className={styles.bullets}>
                  {excluye.map((item) => (
                    <li key={`ex-${item}`}>{item}</li>
                  ))}
                </ul>
              </>
            )}

            {fp.observaciones?.trim() && (
              <>
                <h2 className={styles.sectionTitle}>Observaciones:</h2>
                <p className={styles.obs}>{fp.observaciones.trim()}</p>
              </>
            )}
          </section>
        </div>
      </main>
      <Footer />
    </>
  );
}
