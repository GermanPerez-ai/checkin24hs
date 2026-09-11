import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import styles from './Footer.module.css';

const REDES = [
  { name: 'Instagram', url: 'https://instagram.com/checkin24hs', icon: '📷' },
  { name: 'Facebook', url: 'https://facebook.com/checkin24hs', icon: '👍' },
];

type TarjetaMini = {
  slug: string;
  nombre: string;
  apellido: string;
  avatar_url: string | null;
};

function displayName(t: TarjetaMini): string {
  return [t.nombre, t.apellido].filter(Boolean).join(' ').trim() || t.slug;
}

function initials(t: TarjetaMini): string {
  const a = (t.nombre || '').trim().charAt(0);
  const b = (t.apellido || '').trim().charAt(0);
  return (a + b).toUpperCase() || (t.slug || '?').charAt(0).toUpperCase();
}

export function Footer() {
  const [contactos, setContactos] = useState<TarjetaMini[]>([]);

  useEffect(() => {
    if (!supabase) return;
    let cancelled = false;
    void supabase
      .from('tarjetas_contacto')
      .select('slug, nombre, apellido, avatar_url')
      .eq('activo', true)
      .order('nombre', { ascending: true })
      .then(({ data }) => {
        if (!cancelled && Array.isArray(data)) {
          setContactos(data as TarjetaMini[]);
        }
      });
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <footer className={styles.footer}>
      <div className="container">
        <div className={styles.grid}>
          <div>
            <strong className={styles.brand}>Checkin24hs</strong>
            <p className={styles.about}>
              Expertos en alojamientos de Patagonia y Buenos Aires. Te ayudamos a encontrar y reservar tu próxima estadía.
            </p>
          </div>
          <div>
            <div className={styles.redes}>
              {REDES.map((r) => (
                <a
                  key={r.name}
                  href={r.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={styles.redLink}
                  aria-label={r.name}
                >
                  {r.icon} {r.name}
                </a>
              ))}
            </div>
          </div>
        </div>

        {contactos.length > 0 ? (
          <div className={styles.contactosBlock}>
            <p className={styles.contactosTitle}>Contacto personal</p>
            <div className={styles.contactos} role="list">
              {contactos.map((t) => {
                const name = displayName(t);
                return (
                  <Link
                    key={t.slug}
                    to={`/${encodeURIComponent(t.slug)}`}
                    className={styles.contactoBtn}
                    role="listitem"
                    title={name}
                  >
                    {t.avatar_url ? (
                      <img className={styles.contactoAvatar} src={t.avatar_url} alt="" width={64} height={64} />
                    ) : (
                      <span className={styles.contactoAvatarFallback} aria-hidden>
                        {initials(t)}
                      </span>
                    )}
                    <span className={styles.contactoName}>{name}</span>
                  </Link>
                );
              })}
            </div>
          </div>
        ) : null}

        <div className={styles.legales}>
          <p>
            © {new Date().getFullYear()} Checkin24hs. Todas las imágenes son propiedad de los establecimientos o están utilizadas con fines ilustrativos.
          </p>
          <p className={styles.buildInfo} title="Para verificar que el deploy es el último">
            Build:{' '}
            {typeof __BUILD_TIME__ !== 'undefined'
              ? new Date(__BUILD_TIME__).toLocaleString('es-AR', { dateStyle: 'short', timeStyle: 'short' })
              : '—'}
          </p>
        </div>
      </div>
    </footer>
  );
}
