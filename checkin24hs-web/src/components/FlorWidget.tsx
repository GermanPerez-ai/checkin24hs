import { useState, useMemo, useEffect, useRef } from 'react';
import { FLOR_CHATBOT_URL, FLOR_API_URL, SUPABASE_URL, SUPABASE_ANON_KEY } from '../config';
import { useFlorContext } from '../context/FlorContext';
import styles from './FlorWidget.module.css';

export interface FlorContext {
  hotelSlug?: string;
  hotelName?: string;
  destinoId?: string;
}

export function FlorWidget({ context: contextProp, inline }: { context?: FlorContext; inline?: boolean }) {
  const [open, setOpen] = useState(false);
  const { context: contextFromProvider } = useFlorContext();
  const context = contextProp ?? contextFromProvider;

  const iframeSrc = useMemo(() => {
    if (!FLOR_CHATBOT_URL) return '';
    const url = new URL(FLOR_CHATBOT_URL);
    if (context?.hotelSlug) url.searchParams.set('hotel', context.hotelSlug);
    if (context?.hotelName) url.searchParams.set('hotel_name', context.hotelName);
    if (context?.destinoId) url.searchParams.set('destino', context.destinoId);
    url.searchParams.set('v', '5');
    // Pasar config por URL para que el iframe siempre reciba hoteles (postMessage a veces falla entre checkin24hs.com y www)
    if (SUPABASE_URL && SUPABASE_ANON_KEY) {
      url.searchParams.set('supabaseUrl', SUPABASE_URL);
      url.searchParams.set('supabaseAnonKey', SUPABASE_ANON_KEY);
    }
    if (FLOR_API_URL) url.searchParams.set('florApiUrl', FLOR_API_URL);
    return url.toString();
  }, [context?.hotelSlug, context?.hotelName, context?.destinoId]);

  useEffect(() => {
    const handler = () => setOpen(true);
    window.addEventListener('open-flor', handler);
    return () => window.removeEventListener('open-flor', handler);
  }, []);

  const iframeRef = useRef<HTMLIFrameElement>(null);

  const sendFlorConfigToIframe = () => {
    if (!iframeRef.current?.contentWindow || !SUPABASE_URL || !SUPABASE_ANON_KEY) return;
    iframeRef.current.contentWindow.postMessage(
      { type: 'flor-config', supabaseUrl: SUPABASE_URL, supabaseAnonKey: SUPABASE_ANON_KEY },
      '*'
    );
  };

  // Escuchar cuando el iframe dice que está listo (así aseguramos que ya cargó FlorKnowledgeBase)
  useEffect(() => {
    const onMessage = (e: MessageEvent) => {
      if (e.data?.type === 'flor-iframe-ready') sendFlorConfigToIframe();
    };
    window.addEventListener('message', onMessage);
    return () => window.removeEventListener('message', onMessage);
  }, []);

  return (
    <div className={inline ? styles.containerInline : styles.container}>
      <button
        type="button"
        className={styles.bubble}
        onClick={() => setOpen((o) => !o)}
        aria-label="Abrir chat con Flor"
        title="Chateá con Flor - Asistente Virtual"
        style={{ boxSizing: 'border-box' }}
      >
        <span style={{ display: 'block', lineHeight: 1 }} aria-hidden>{open ? '✕' : '🌸'}</span>
      </button>
      <div className={`${styles.window} ${open ? styles.windowOpen : ''}`}>
        <div className={styles.header}>
          <span className={styles.avatar}>🌸</span>
          <div>
            <strong>Flor</strong>
            <span className={styles.sub}>Asistente Virtual</span>
          </div>
          <button type="button" className={styles.close} onClick={() => setOpen(false)} aria-label="Cerrar">
            ×
          </button>
        </div>
        <div className={styles.body}>
          {iframeSrc ? (
            <iframe
              ref={iframeRef}
              title="Chat Flor"
              src={iframeSrc}
              className={styles.iframe}
              onLoad={() => {
                setTimeout(sendFlorConfigToIframe, 800);
              }}
            />
          ) : (
            <div style={{ padding: 24, textAlign: 'center', color: '#666', fontSize: '0.9rem' }}>
              <p>El chat de Flor no está configurado en esta web.</p>
              <p style={{ marginTop: 8, fontSize: '0.8rem' }}>Configurá <strong>VITE_FLOR_CHATBOT_URL</strong> en el build (EasyPanel) y volvé a desplegar.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
