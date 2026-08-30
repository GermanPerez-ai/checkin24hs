import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import type { SliderOferta } from '../types';
import styles from './SliderOfertas.module.css';

export function SliderOfertas() {
  const [slides, setSlides] = useState<SliderOferta[]>([]);
  const [index, setIndex] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!supabase) {
      setLoading(false);
      return;
    }
    supabase
      .from('slider_ofertas')
      .select('*')
      .eq('activo', true)
      .order('orden', { ascending: true })
      .then(({ data, error }) => {
        if (!error && data?.length) {
          setSlides(data.filter((s) => s.tipo_link !== 'promos'));
        }
        setLoading(false);
      });
  }, []);

  useEffect(() => {
    if (slides.length <= 1) return;
    const t = setInterval(() => {
      setIndex((i) => (i + 1) % slides.length);
    }, 5000);
    return () => clearInterval(t);
  }, [slides.length]);

  if (loading) return null;

  const isDevPreview = slides.length === 0 && import.meta.env.DEV;
  if (slides.length === 0 && !isDevPreview) return null;

  if (isDevPreview) {
    return (
      <section className={styles.slider} aria-label="Ofertas destacadas (vista previa local)">
        <div className={styles.track}>
          <div className={styles.slide} style={{ opacity: 1, zIndex: 1 }}>
            <div className={styles.slideContent}>
              <div className={styles.slidePlaceholder} aria-hidden />
              <div className={styles.slideCaption}>
                <span>Vista previa del slider (150px de alto)</span>
                <span className={styles.slideDevHint}>Configurá .env con Supabase para ver ofertas reales</span>
              </div>
            </div>
          </div>
        </div>
      </section>
    );
  }

  const slide = slides[index];
  const imgUrl = slide?.imagen_url || '';
  const isMobile = typeof window !== 'undefined' && window.innerWidth < 768;
  const mobileUrl = slide?.imagen_url_mobile;
  const src = (isMobile && mobileUrl) ? mobileUrl : imgUrl;
  const isFlor = slide?.tipo_link === 'flor' || slide?.link_destino === '#flor';
  const btnText = slide?.texto_boton || (isFlor ? 'Chateá con Flor IA' : 'Ver más');

  const renderCta = () => {
    if (isFlor) {
      return (
        <button
          type="button"
          className={styles.slideCaptionBtn}
          onClick={() => window.dispatchEvent(new CustomEvent('open-flor'))}
        >
          {btnText}
        </button>
      );
    }
    const dest = slide?.link_destino;
    if (!dest) return null;
    if (slide?.tipo_link === 'hotel' && !dest.startsWith('http')) {
      const to = dest.startsWith('/') ? dest : `/hotel/${dest}`;
      return (
        <Link to={to} className={styles.slideCaptionBtn}>
          {btnText}
        </Link>
      );
    }
    if (dest.startsWith('http')) {
      return (
        <a href={dest} target="_blank" rel="noopener noreferrer" className={styles.slideCaptionBtn}>
          {btnText}
        </a>
      );
    }
    return (
      <Link to={dest.startsWith('/') ? dest : `/?${dest}`} className={styles.slideCaptionBtn}>
        {btnText}
      </Link>
    );
  };

  return (
    <section className={styles.slider} aria-label="Ofertas destacadas">
      <div className={styles.track}>
        {slides.map((s, i) => (
          <div
            key={s.id}
            className={styles.slide}
            style={{
              opacity: i === index ? 1 : 0,
              zIndex: i === index ? 1 : 0,
            }}
          >
            {i === index && (
              <div className={styles.slideContent}>
                <img
                  src={src}
                  alt={s.titulo || 'Oferta'}
                  className={styles.slideImg}
                />
                <div className={styles.slideCaption}>
                  {s.titulo && <span>{s.titulo}</span>}
                  {renderCta()}
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
      {slides.length > 1 && (
        <div className={styles.dots}>
          {slides.map((_, i) => (
            <button
              key={i}
              type="button"
              className={index === i ? styles.dotActive : styles.dot}
              aria-label={`Slide ${i + 1}`}
              onClick={() => setIndex(i)}
            />
          ))}
        </div>
      )}
    </section>
  );
}
