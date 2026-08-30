import { FormEvent, ReactNode, useEffect, useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { buildWhatsAppConsultaUrl, buildWhatsAppTextUrl } from '../config';
import { formatPromoVigencia, promoBeneficiosList, promoVigente } from '../lib/promos';
import { supabase } from '../lib/supabase';
import type { LandingPromo } from '../types';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import styles from './PromoDetail.module.css';

function isValidEmail(email: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

/** Convierte URLs del cuerpo de la promo en links clickeables. */
function linkifyPromoCuerpo(text: string): ReactNode[] {
  const re = /(https?:\/\/[^\s<>"']+|www\.[^\s<>"']+)/gi;
  const nodes: ReactNode[] = [];
  let last = 0;
  let match: RegExpExecArray | null;
  let key = 0;
  while ((match = re.exec(text)) !== null) {
    if (match.index > last) {
      nodes.push(text.slice(last, match.index));
    }
    let raw = match[0];
    let trailing = '';
    const trailMatch = raw.match(/[.,;:!?)\]}>]+$/);
    if (trailMatch) {
      trailing = trailMatch[0];
      raw = raw.slice(0, -trailing.length);
    }
    const href = /^https?:\/\//i.test(raw) ? raw : `https://${raw}`;
    nodes.push(
      <a key={`l${key++}`} href={href} target="_blank" rel="noopener noreferrer">
        {raw}
      </a>
    );
    if (trailing) nodes.push(trailing);
    last = match.index + match[0].length;
  }
  if (last < text.length) nodes.push(text.slice(last));
  return nodes;
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

export function PromoDetail() {
  const { slug } = useParams<{ slug: string }>();
  const [promo, setPromo] = useState<LandingPromo | null>(null);
  const [loading, setLoading] = useState(true);
  const [email, setEmail] = useState('');
  const [nombre, setNombre] = useState('');
  const [status, setStatus] = useState<'idle' | 'loading' | 'ok' | 'dup' | 'error'>('idle');
  const [errorMsg, setErrorMsg] = useState('');
  const isMobile = useIsMobile();

  useEffect(() => {
    if (!slug || !supabase) {
      setLoading(false);
      return;
    }
    let cancelled = false;
    const key = decodeURIComponent(slug);
    void supabase
      .from('landing_promos')
      .select('*')
      .eq('slug', key)
      .eq('activo', true)
      .maybeSingle()
      .then(({ data }) => {
        if (cancelled) return;
        setPromo((data as LandingPromo) || null);
        setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [slug]);

  const beneficios = useMemo(() => promoBeneficiosList(promo?.beneficios), [promo?.beneficios]);
  const vigente = promo ? promoVigente(promo) : false;
  const vigenciaLabel = formatPromoVigencia(promo?.vigencia_hasta ?? null);

  const waHref = useMemo(() => {
    if (!promo) return '#';
    if (promo.mensaje_whatsapp?.trim()) {
      return buildWhatsAppTextUrl(promo.mensaje_whatsapp);
    }
    const label = [promo.titulo, promo.hotel_nombre].filter(Boolean).join(' — ');
    return buildWhatsAppConsultaUrl(
      `promo ${promo.slug}${label ? ` (${label})` : ''}`,
      'promo'
    );
  }, [promo]);

  async function onSubmitEmail(e: FormEvent) {
    e.preventDefault();
    const value = email.trim().toLowerCase();
    if (!isValidEmail(value)) {
      setStatus('error');
      setErrorMsg('Ingresá un email válido.');
      return;
    }
    if (!supabase || !promo) {
      setStatus('error');
      setErrorMsg('No se pudo conectar. Probá más tarde.');
      return;
    }
    setStatus('loading');
    setErrorMsg('');
    const origen = `promo:${promo.slug}`;
    const row: { email: string; origen: string; activo: boolean; nombre?: string } = {
      email: value,
      origen,
      activo: true,
    };
    const nom = nombre.trim();
    if (nom) row.nombre = nom;
    const { error } = await supabase.from('newsletter_subscribers').insert([row]);
    if (error) {
      const code = (error as { code?: string }).code;
      const msg = String(error.message || '').toLowerCase();
      if (code === '23505' || msg.includes('duplicate') || msg.includes('unique')) {
        setStatus('dup');
        return;
      }
      setStatus('error');
      setErrorMsg('No se pudo suscribir. Probá de nuevo.');
      return;
    }
    setEmail('');
    setNombre('');
    setStatus('ok');
  }

  if (loading) {
    return (
      <>
        <Header />
        <main className={styles.main}>
          <p className={styles.state}>Cargando promo…</p>
        </main>
        <Footer />
      </>
    );
  }

  if (!promo || !vigente) {
    return (
      <>
        <Header />
        <main className={styles.main}>
          <div className={`container ${styles.empty}`}>
            <h1 className={styles.emptyTitle}>Promo no disponible</h1>
            <p>Esta oferta no está activa o ya venció.</p>
            <Link to="/promos" className={styles.linkMore}>
              Ver promos vigentes
            </Link>
          </div>
        </main>
        <Footer />
      </>
    );
  }

  const heroSrc =
    (isMobile && promo.imagen_hero_mobile) ||
    promo.imagen_hero ||
    promo.imagen_hero_mobile ||
    '';

  return (
    <>
      <Header />
      <main className={styles.main}>
        <section className={styles.hero} aria-label="Oferta">
          {promo.video_hero ? (
            <video
              className={styles.heroBg}
              src={promo.video_hero}
              poster={heroSrc || undefined}
              muted
              loop
              playsInline
              autoPlay
              aria-hidden
            />
          ) : heroSrc ? (
            <img src={heroSrc} alt="" className={styles.heroBg} />
          ) : (
            <div className={styles.heroFallback} aria-hidden />
          )}
          <div className={styles.heroOverlay} />
          <div className={`container ${styles.heroContent}`}>
            <p className={styles.brand}>Checkin24hs</p>
            {promo.badge && <p className={styles.badge}>{promo.badge}</p>}
            <h1 className={styles.heroTitle}>{promo.titulo}</h1>
            {promo.subtitulo && <p className={styles.heroSub}>{promo.subtitulo}</p>}
            <div className={styles.ctaRow}>
              <a
                href={waHref}
                target="_blank"
                rel="noopener noreferrer"
                className={styles.btnWa}
              >
                {promo.cta_whatsapp || 'Consultar por WhatsApp'}
              </a>
              <a href="#suscribir" className={styles.btnEmail}>
                Recibir ofertas por email
              </a>
            </div>
          </div>
        </section>

        <div className={`container ${styles.body}`}>
          {(promo.hotel_nombre || promo.precio_texto || vigenciaLabel) && (
            <section className={styles.offerBlock} aria-label="Detalle de la oferta">
              {promo.hotel_nombre && (
                <p className={styles.hotelName}>{promo.hotel_nombre}</p>
              )}
              {promo.precio_texto && (
                <p className={styles.price}>{promo.precio_texto}</p>
              )}
              {vigenciaLabel && (
                <p className={styles.vigencia}>Válida hasta el {vigenciaLabel}</p>
              )}
            </section>
          )}

          {beneficios.length > 0 && (
            <section className={styles.section} aria-label="Beneficios">
              <h2 className={styles.sectionTitle}>Por qué reservar con nosotros</h2>
              <ul className={styles.benefits}>
                {beneficios.map((b) => (
                  <li key={b}>{b}</li>
                ))}
              </ul>
            </section>
          )}

          {promo.cuerpo && (
            <section className={styles.section} aria-label="Detalle de la oferta">
              <h2 className={styles.sectionTitle}>Detalle de la oferta</h2>
              <p className={styles.cuerpo}>{linkifyPromoCuerpo(promo.cuerpo)}</p>
            </section>
          )}

          <section className={styles.waBlock} aria-label="WhatsApp">
            <h2 className={styles.sectionTitle}>Hablá con un asesor ahora</h2>
            <p className={styles.waText}>
              Te armamos fechas, habitación y presupuesto sin compromiso. Respuesta rápida por WhatsApp.
            </p>
            <a
              href={waHref}
              target="_blank"
              rel="noopener noreferrer"
              className={styles.btnWaLarge}
            >
              {promo.cta_whatsapp || 'Consultar por WhatsApp'}
            </a>
          </section>

          <section id="suscribir" className={styles.emailBlock} aria-label="Suscripción email">
            <h2 className={styles.sectionTitle}>Recibí esta promo y las próximas</h2>
            <p className={styles.emailLead}>
              Dejanos tu email y te avisamos cuando haya tarifas especiales en hoteles como este.
            </p>
            {status === 'ok' || status === 'dup' ? (
              <p className={styles.success} role="status">
                {status === 'ok'
                  ? '¡Listo! Ya estás en la lista de ofertas.'
                  : 'Ese email ya está suscripto. ¡Gracias!'}
              </p>
            ) : (
              <form className={styles.emailForm} onSubmit={onSubmitEmail} noValidate>
                <label className={styles.srOnly} htmlFor="promo-nombre">
                  Nombre
                </label>
                <input
                  id="promo-nombre"
                  type="text"
                  name="nombre"
                  autoComplete="name"
                  placeholder="Tu nombre (opcional)"
                  value={nombre}
                  onChange={(ev) => setNombre(ev.target.value)}
                  className={styles.input}
                  disabled={status === 'loading'}
                />
                <label className={styles.srOnly} htmlFor="promo-email">
                  Email
                </label>
                <input
                  id="promo-email"
                  type="email"
                  name="email"
                  autoComplete="email"
                  placeholder="Tu e-mail"
                  value={email}
                  onChange={(ev) => {
                    setEmail(ev.target.value);
                    if (status === 'error') setStatus('idle');
                  }}
                  className={styles.input}
                  disabled={status === 'loading'}
                  required
                />
                <button type="submit" className={styles.btnSubmit} disabled={status === 'loading'}>
                  {status === 'loading' ? 'Enviando…' : 'Quiero recibir ofertas'}
                </button>
              </form>
            )}
            {status === 'error' && errorMsg && (
              <p className={styles.error} role="alert">
                {errorMsg}
              </p>
            )}
            <p className={styles.privacy}>
              Podés darte de baja cuando quieras. No compartimos tu email.
            </p>
          </section>

          <p className={styles.more}>
            <Link to="/promos">Ver todas las promos vigentes</Link>
          </p>
        </div>

        <div className={styles.stickyBar}>
          <a
            href={waHref}
            target="_blank"
            rel="noopener noreferrer"
            className={styles.stickyBtn}
          >
            WhatsApp — consultar promo
          </a>
        </div>
      </main>
      <Footer />
    </>
  );
}
