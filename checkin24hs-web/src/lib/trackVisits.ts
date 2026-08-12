import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { supabase } from '../lib/supabase';

const SESSION_KEY = 'c24_visit_sid';
const UTM_KEY = 'c24_utm';

function getOrCreateSessionId(): string {
  try {
    let id = localStorage.getItem(SESSION_KEY);
    if (!id) {
      id =
        typeof crypto !== 'undefined' && crypto.randomUUID
          ? crypto.randomUUID()
          : `s_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
      localStorage.setItem(SESSION_KEY, id);
    }
    return id;
  } catch {
    return `s_${Date.now()}`;
  }
}

function readUtmFromLocation(search: string): {
  utm_source: string | null;
  utm_medium: string | null;
  utm_campaign: string | null;
} {
  try {
    const sp = new URLSearchParams(search || '');
    const fromUrl = {
      utm_source:
        sp.get('utm_source') ||
        sp.get('source') ||
        (sp.get('fbclid') ? 'facebook' : null) ||
        (sp.get('gclid') ? 'google' : null),
      utm_medium:
        sp.get('utm_medium') ||
        (sp.get('gclid') ? 'cpc' : sp.get('fbclid') ? 'paid_social' : null),
      utm_campaign: sp.get('utm_campaign') || sp.get('campaign') || null,
    };
    if (fromUrl.utm_source || fromUrl.utm_medium || fromUrl.utm_campaign) {
      try {
        localStorage.setItem(UTM_KEY, JSON.stringify(fromUrl));
      } catch {
        /* ignore */
      }
      return fromUrl;
    }
    const cached = localStorage.getItem(UTM_KEY);
    if (cached) {
      const parsed = JSON.parse(cached);
      return {
        utm_source: parsed?.utm_source || null,
        utm_medium: parsed?.utm_medium || null,
        utm_campaign: parsed?.utm_campaign || null,
      };
    }
  } catch {
    /* ignore */
  }
  return { utm_source: null, utm_medium: null, utm_campaign: null };
}

/** Registra una vista de página (fire-and-forget) para el digest diario por WhatsApp. */
export function trackPageview(path: string, search = '') {
  if (!supabase) return;
  const visitor_id = getOrCreateSessionId();
  const session_id = visitor_id;
  const referrer =
    typeof document !== 'undefined' && document.referrer
      ? String(document.referrer).slice(0, 500)
      : null;
  const utm = readUtmFromLocation(search);
  const row: Record<string, string | null> = {
    path: (path || '/').slice(0, 500),
    visitor_id,
    session_id,
    referrer,
  };
  if (utm.utm_source) row.utm_source = String(utm.utm_source).slice(0, 120);
  if (utm.utm_medium) row.utm_medium = String(utm.utm_medium).slice(0, 120);
  if (utm.utm_campaign) row.utm_campaign = String(utm.utm_campaign).slice(0, 180);

  void supabase
    .from('site_pageviews')
    .insert(row)
    .then(async ({ error }) => {
      if (!error) return;
      // Fallback si aún no corrió migración 068 (sin UTM / session_id)
      if (/utm_|session_id|column/i.test(error.message || '')) {
        const { error: e2 } = await supabase.from('site_pageviews').insert({
          path: row.path,
          visitor_id: row.visitor_id,
          referrer: row.referrer,
        });
        if (e2 && import.meta.env.DEV) console.warn('[visits]', e2.message);
        return;
      }
      if (import.meta.env.DEV) console.warn('[visits]', error.message);
    });
}

/** Hook: cuenta cada cambio de ruta en la web. */
export function useTrackPageviews() {
  const location = useLocation();
  useEffect(() => {
    trackPageview(location.pathname, location.search);
  }, [location.pathname, location.search]);
}
