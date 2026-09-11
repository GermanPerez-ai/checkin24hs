import { useEffect, useMemo, useRef, useState } from 'react';
import { Link, Navigate, useParams } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import styles from './DigitalCard.module.css';

export type TarjetaContacto = {
  id: string;
  slug: string;
  nombre: string;
  apellido: string;
  cargo: string;
  descripcion: string;
  telefono: string;
  email: string;
  avatar_url: string | null;
  activo: boolean;
};

/** Rutas fijas de la SPA que no deben resolverse como tarjeta. */
export const RESERVED_SLUGS = new Set([
  'chile',
  'argentina',
  'internacionales',
  'packs',
  'pack',
  'promos',
  'promo',
  'hotel',
  'novedad',
  'c',
  'card',
  'equipo',
  'api',
  'assets',
  'static',
  'favicon.ico',
  'robots.txt',
  'sitemap.xml',
]);

type EventoTarjeta = 'page_view' | 'vcard_download' | 'whatsapp_click' | 'email_click';

function digitsOnly(phone: string): string {
  return String(phone || '').replace(/\D/g, '');
}

function fullName(t: TarjetaContacto): string {
  return [t.nombre, t.apellido].filter(Boolean).join(' ').trim() || t.nombre;
}

function escapeVcf(value: string): string {
  return String(value || '')
    .replace(/\\/g, '\\\\')
    .replace(/\n/g, '\\n')
    .replace(/,/g, '\\,')
    .replace(/;/g, '\\;');
}

function buildVCard(t: TarjetaContacto): string {
  const fn = fullName(t);
  const tel = digitsOnly(t.telefono);
  const lines = [
    'BEGIN:VCARD',
    'VERSION:3.0',
    `N:${escapeVcf(t.apellido)};${escapeVcf(t.nombre)};;;`,
    `FN:${escapeVcf(fn)}`,
    'ORG:Checkin24hs',
    t.cargo ? `TITLE:${escapeVcf(t.cargo)}` : null,
    tel ? `TEL;TYPE=CELL:+${tel}` : null,
    t.email ? `EMAIL;TYPE=INTERNET:${escapeVcf(t.email)}` : null,
    `URL:https://checkin24hs.com/${encodeURIComponent(t.slug)}`,
    'END:VCARD',
  ];
  return lines.filter(Boolean).join('\r\n');
}

async function trackEvent(tarjetaId: string, tipo: EventoTarjeta) {
  if (!supabase) return;
  try {
    await supabase.from('tarjetas_analiticas').insert([{ tarjeta_id: tarjetaId, tipo_evento: tipo }]);
  } catch {
    /* no bloquear UX */
  }
}

function initials(t: TarjetaContacto): string {
  const a = (t.nombre || '').trim().charAt(0);
  const b = (t.apellido || '').trim().charAt(0);
  return (a + b).toUpperCase() || '?';
}

export function DigitalCard() {
  const { slug } = useParams<{ slug: string }>();
  const key = decodeURIComponent(slug || '')
    .trim()
    .toLowerCase();
  const [tarjeta, setTarjeta] = useState<TarjetaContacto | null>(null);
  const [loading, setLoading] = useState(true);
  const [notFound, setNotFound] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const trackedView = useRef<string | null>(null);

  useEffect(() => {
    if (!key || RESERVED_SLUGS.has(key)) {
      setLoading(false);
      setNotFound(true);
      return;
    }
    if (!supabase) {
      setLoading(false);
      setNotFound(true);
      return;
    }
    let cancelled = false;
    setLoading(true);
    setNotFound(false);
    void supabase
      .from('tarjetas_contacto')
      .select('id, slug, nombre, apellido, cargo, descripcion, telefono, email, avatar_url, activo')
      .eq('slug', key)
      .eq('activo', true)
      .maybeSingle()
      .then(({ data, error }) => {
        if (cancelled) return;
        if (error || !data) {
          setTarjeta(null);
          setNotFound(true);
        } else {
          setTarjeta(data as TarjetaContacto);
        }
        setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [key]);

  useEffect(() => {
    if (!tarjeta?.id) return;
    if (trackedView.current === tarjeta.id) return;
    trackedView.current = tarjeta.id;
    void trackEvent(tarjeta.id, 'page_view');
  }, [tarjeta?.id]);

  useEffect(() => {
    if (!toast) return;
    const t = window.setTimeout(() => setToast(null), 2200);
    return () => window.clearTimeout(t);
  }, [toast]);

  const displayName = useMemo(() => (tarjeta ? fullName(tarjeta) : ''), [tarjeta]);
  const phoneDigits = useMemo(() => (tarjeta ? digitsOnly(tarjeta.telefono) : ''), [tarjeta]);

  const cardUrl = useMemo(() => {
    if (!tarjeta?.slug) return '';
    const path = `/${encodeURIComponent(tarjeta.slug)}`;
    if (typeof window !== 'undefined' && window.location?.origin) {
      return `${window.location.origin}${path}`;
    }
    return `https://checkin24hs.com${path}`;
  }, [tarjeta?.slug]);

  const qrSrc = useMemo(() => {
    if (!cardUrl) return '';
    return `https://api.qrserver.com/v1/create-qr-code/?size=240x240&margin=10&data=${encodeURIComponent(cardUrl)}`;
  }, [cardUrl]);

  const waHref = useMemo(() => {
    if (!tarjeta || !phoneDigits) return '#';
    const text = `Hola ${tarjeta.nombre}, escaneé tu tarjeta digital de Checkin24hs.`;
    return `https://wa.me/${phoneDigits}?text=${encodeURIComponent(text)}`;
  }, [tarjeta, phoneDigits]);

  const mailHref = useMemo(() => {
    if (!tarjeta?.email) return '#';
    return `mailto:${tarjeta.email}`;
  }, [tarjeta]);

  const onSaveContact = () => {
    if (!tarjeta) return;
    const vcf = buildVCard(tarjeta);
    const blob = new Blob([vcf], { type: 'text/vcard;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${tarjeta.slug || 'contacto'}.vcf`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
    void trackEvent(tarjeta.id, 'vcard_download');
    setToast('Contacto descargado');
  };

  if (!key || RESERVED_SLUGS.has(key)) {
    return <Navigate to="/" replace />;
  }

  if (loading) {
    return (
      <div className={styles.page}>
        <div className={styles.card} aria-busy="true">
          <p className={styles.muted}>Cargando…</p>
        </div>
      </div>
    );
  }

  if (notFound || !tarjeta) {
    return (
      <div className={styles.page}>
        <div className={styles.card}>
          <h1 className={styles.name}>Tarjeta no encontrada</h1>
          <p className={styles.muted}>Este enlace no corresponde a un perfil activo.</p>
          <Link className={styles.footerLink} to="/">
            Ir a checkin24hs.com
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className={styles.page}>
      <article className={styles.card}>
        <header className={styles.header}>
          {tarjeta.avatar_url ? (
            <img
              className={styles.avatar}
              src={tarjeta.avatar_url}
              alt={displayName}
              width={112}
              height={112}
            />
          ) : (
            <div className={styles.avatarFallback} aria-hidden>
              {initials(tarjeta)}
            </div>
          )}
          <p className={styles.brand}>Checkin24hs</p>
          <h1 className={styles.name}>{displayName}</h1>
          {tarjeta.cargo ? <p className={styles.role}>{tarjeta.cargo}</p> : null}
          {tarjeta.descripcion ? <p className={styles.desc}>{tarjeta.descripcion}</p> : null}
        </header>

        <div className={styles.actions}>
          <button type="button" className={styles.btnPrimary} onClick={onSaveContact}>
            Guardar contacto
          </button>

          {phoneDigits ? (
            <a
              className={styles.btnWhatsapp}
              href={waHref}
              target="_blank"
              rel="noopener noreferrer"
              onClick={() => void trackEvent(tarjeta.id, 'whatsapp_click')}
            >
              Contactar por WhatsApp
            </a>
          ) : null}

          {tarjeta.email ? (
            <a
              className={styles.btnSecondary}
              href={mailHref}
              onClick={() => void trackEvent(tarjeta.id, 'email_click')}
            >
              Enviar correo
            </a>
          ) : null}
        </div>

        {qrSrc ? (
          <div className={styles.qrBlock}>
            <img
              className={styles.qrImg}
              src={qrSrc}
              alt={`Código QR de ${displayName}`}
              width={168}
              height={168}
            />
            <p className={styles.qrCaption}>Escaneá para abrir esta tarjeta</p>
          </div>
        ) : null}

        <footer className={styles.footer}>
          <a className={styles.footerLink} href="https://checkin24hs.com">
            checkin24hs.com
          </a>
        </footer>
      </article>
      {toast ? <div className={styles.toast}>{toast}</div> : null}
    </div>
  );
}
