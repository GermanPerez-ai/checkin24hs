import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import type { Testimonio } from '../types';
import styles from './Testimonios.module.css';

const FUENTE_LABEL: Record<string, string> = {
  instagram: 'Instagram',
  facebook: 'Facebook',
  google: 'Google',
  whatsapp: 'WhatsApp',
  otro: 'Cliente',
};

function Stars({ n }: { n: number }) {
  const count = Math.min(5, Math.max(1, n || 5));
  return (
    <span className={styles.stars} aria-label={`${count} de 5 estrellas`}>
      {'★'.repeat(count)}
      <span className={styles.starsEmpty}>{'★'.repeat(5 - count)}</span>
    </span>
  );
}

function Initial({ name }: { name: string }) {
  const letter = (name || '?').trim().charAt(0).toUpperCase() || '?';
  return <span className={styles.avatarInitial}>{letter}</span>;
}

export function Testimonios() {
  const [items, setItems] = useState<Testimonio[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!supabase) {
      setLoading(false);
      return;
    }
    supabase
      .from('testimonios')
      .select('id, nombre, texto, fuente, estrellas, avatar_url, enlace_url, orden')
      .eq('activo', true)
      .order('orden', { ascending: true })
      .order('created_at', { ascending: false })
      .then(({ data, error }) => {
        if (!error && data) setItems(data as Testimonio[]);
        setLoading(false);
      });
  }, []);

  if (loading || items.length === 0) return null;

  return (
    <section id="testimonios" className={styles.section}>
      <div className="container">
        <h2 className={styles.title}>Lo que dicen nuestros viajeros</h2>
        <p className={styles.subtitle}>
          Opiniones reales de quienes viajaron con Checkin24hs
        </p>
        <div className={styles.grid}>
          {items.map((t) => {
            const body = (
              <>
                <Stars n={t.estrellas} />
                <blockquote className={styles.quote}>“{t.texto}”</blockquote>
                <div className={styles.meta}>
                  {t.avatar_url ? (
                    <img
                      src={t.avatar_url}
                      alt=""
                      className={styles.avatar}
                      loading="lazy"
                      width={40}
                      height={40}
                    />
                  ) : (
                    <Initial name={t.nombre} />
                  )}
                  <div className={styles.metaText}>
                    <span className={styles.name}>{t.nombre}</span>
                    <span className={styles.fuente}>
                      {FUENTE_LABEL[t.fuente] || t.fuente}
                    </span>
                  </div>
                </div>
              </>
            );
            if (t.enlace_url) {
              return (
                <a
                  key={t.id}
                  href={t.enlace_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={styles.card}
                >
                  {body}
                </a>
              );
            }
            return (
              <article key={t.id} className={styles.card}>
                {body}
              </article>
            );
          })}
        </div>
      </div>
    </section>
  );
}
