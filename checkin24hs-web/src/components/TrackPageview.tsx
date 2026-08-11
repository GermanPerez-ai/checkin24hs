/**
 * Contador anónimo de visitas (1 pageview por carga de ruta).
 * visitor_id en localStorage — no PII.
 */
import { useEffect, useRef } from 'react';
import { useLocation } from 'react-router-dom';
import { supabase } from '../lib/supabase';

const VISITOR_KEY = 'c24_vid';

function getOrCreateVisitorId(): string {
  try {
    let id = localStorage.getItem(VISITOR_KEY);
    if (id && id.length >= 8) return id;
    id =
      typeof crypto !== 'undefined' && crypto.randomUUID
        ? crypto.randomUUID()
        : `v_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
    localStorage.setItem(VISITOR_KEY, id);
    return id;
  } catch {
    return `v_${Date.now()}`;
  }
}

export function TrackPageview() {
  const location = useLocation();
  const lastPath = useRef<string>('');

  useEffect(() => {
    if (!supabase) return;
    const path = `${location.pathname}${location.search || ''}` || '/';
    if (path === lastPath.current) return;
    lastPath.current = path;

    const visitor_id = getOrCreateVisitorId();
    const referrer =
      typeof document !== 'undefined' && document.referrer
        ? String(document.referrer).slice(0, 500)
        : null;

    void supabase
      .from('site_pageviews')
      .insert({
        visitor_id,
        path: path.slice(0, 500),
        referrer,
      })
      .then(({ error }) => {
        if (error && import.meta.env.DEV) {
          console.warn('[TrackPageview]', error.message);
        }
      });
  }, [location.pathname, location.search]);

  return null;
}
