import { useEffect, useState } from 'react';
import { supabase } from './supabase';

export type BannerSlider = {
  titulo: string | null;
  imagen_url: string | null;
  imagen_url_mobile: string | null;
  link_destino: string | null;
  tipo_link: string | null;
  orden: number | null;
};

export function claveBanner(link: string | null | undefined): string {
  const raw = String(link || '').trim();
  if (!raw) return '';
  const sinQuery = raw.split('?')[0];
  const parte = sinQuery.split('/').filter(Boolean).pop() || raw;
  return parte
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}

/** Elige imagen mobile si existe y aplica; si no, desktop. Vacío = sin imagen. */
export function srcBanner(b: BannerSlider | undefined | null, isMobile: boolean): string | null {
  if (!b) return null;
  const desktop = (b.imagen_url || '').trim();
  const mobile = (b.imagen_url_mobile || '').trim();
  const src = (isMobile && mobile) || desktop || mobile;
  return src || null;
}

export function useIsMobileBanner(breakpoint = 768): boolean {
  const [isMobile, setIsMobile] = useState(
    typeof window !== 'undefined' && window.innerWidth < breakpoint
  );
  useEffect(() => {
    const onResize = () => setIsMobile(window.innerWidth < breakpoint);
    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, [breakpoint]);
  return isMobile;
}

/**
 * Banners de sección de la landing /barcelo (Dashboard → tipo barcelo_seccion).
 * Clave = link_destino (id de país o de destino, ej. mexico, punta-cana).
 */
export function useBarceloSeccionBanners(): {
  porClave: Map<string, BannerSlider>;
  isMobile: boolean;
} {
  const [rows, setRows] = useState<BannerSlider[]>([]);
  const isMobile = useIsMobileBanner();

  useEffect(() => {
    if (!supabase) return;
    let cancelled = false;
    void supabase
      .from('slider_ofertas')
      .select('titulo, imagen_url, imagen_url_mobile, link_destino, tipo_link, orden')
      .eq('tipo_link', 'barcelo_seccion')
      .eq('activo', true)
      .order('orden', { ascending: true })
      .then(({ data }) => {
        if (!cancelled) setRows((data as BannerSlider[]) || []);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const porClave = new Map<string, BannerSlider>();
  for (const r of rows) {
    const k = claveBanner(r.link_destino);
    if (k && !porClave.has(k)) porClave.set(k, r);
  }
  return { porClave, isMobile };
}

export function srcSeccion(
  porClave: Map<string, BannerSlider>,
  ids: Array<string | null | undefined>,
  isMobile: boolean
): string | null {
  for (const id of ids) {
    const k = claveBanner(id);
    if (!k) continue;
    const src = srcBanner(porClave.get(k), isMobile);
    if (src) return src;
  }
  return null;
}
