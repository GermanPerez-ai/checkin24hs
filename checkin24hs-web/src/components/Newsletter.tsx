import { FormEvent, useState } from 'react';
import { supabase } from '../lib/supabase';
import styles from './Newsletter.module.css';

function isValidEmail(email: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export function Newsletter() {
  const [email, setEmail] = useState('');
  const [status, setStatus] = useState<'idle' | 'loading' | 'ok' | 'dup' | 'error'>('idle');
  const [errorMsg, setErrorMsg] = useState('');

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    const value = email.trim().toLowerCase();
    if (!isValidEmail(value)) {
      setStatus('error');
      setErrorMsg('Ingresá un email válido.');
      return;
    }
    if (!supabase) {
      setStatus('error');
      setErrorMsg('No se pudo conectar. Probá más tarde.');
      return;
    }
    setStatus('loading');
    setErrorMsg('');
    const { error } = await supabase.from('newsletter_subscribers').insert([
      { email: value, origen: 'web', activo: true },
    ]);
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
    setStatus('ok');
  }

  return (
    <section id="newsletter" className={styles.section} aria-label="Newsletter">
      <div className="container">
        {status === 'ok' || status === 'dup' ? (
          <p className={styles.success} role="status">
            {status === 'ok' ? '¡Listo! Te sumaste al newsletter.' : 'Ese email ya está suscripto. ¡Gracias!'}
          </p>
        ) : (
          <form className={styles.row} onSubmit={onSubmit} noValidate>
            <label className={styles.srOnly} htmlFor="newsletter-email">
              Email
            </label>
            <input
              id="newsletter-email"
              type="email"
              name="email"
              autoComplete="email"
              placeholder="Tu email"
              value={email}
              onChange={(ev) => {
                setEmail(ev.target.value);
                if (status === 'error') setStatus('idle');
              }}
              className={styles.input}
              disabled={status === 'loading'}
              required
            />
            <p className={styles.copy}>
              Recibí nuestras
              <br />
              ofertas y novedades
            </p>
            <button type="submit" className={styles.btn} disabled={status === 'loading'}>
              {status === 'loading' ? 'Enviando…' : 'suscribirme'}
            </button>
          </form>
        )}
        {status === 'error' && errorMsg && (
          <p className={styles.error} role="alert">
            {errorMsg}
          </p>
        )}
      </div>
    </section>
  );
}
