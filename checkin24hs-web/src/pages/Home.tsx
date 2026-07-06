import { useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import type { Hotel } from '../types';
import { Header } from '../components/Header';
import { HeroHome } from '../components/HeroHome';
import { SelectorDestinos } from '../components/SelectorDestinos';
import { AlojamientosCarousel } from '../components/AlojamientosCarousel';
import { Novedades } from '../components/Novedades';
import { Institucional } from '../components/Institucional';
import { WhatsAppCta } from '../components/WhatsAppCta';
import { Footer } from '../components/Footer';
import { useFlorContext } from '../context/FlorContext';

export function Home() {
  const [hotels, setHotels] = useState<Hotel[]>([]);
  const [loading, setLoading] = useState(true);
  const location = useLocation();
  const { setContext } = useFlorContext();
  const [configError, setConfigError] = useState(false);
  const [fetchError, setFetchError] = useState<string | null>(null);

  useEffect(() => {
    setContext(undefined);
  }, [setContext]);

  useEffect(() => {
    const hash = location.hash?.replace('#', '');
    if (hash !== 'novedades' && hash !== 'sobre-nosotros') return;
    const scroll = () => {
      const el = document.getElementById(hash);
      if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    };
    scroll();
    const t = setTimeout(scroll, 400);
    return () => clearTimeout(t);
  }, [location.hash]);

  useEffect(() => {
    if (!supabase) {
      setConfigError(true);
      setLoading(false);
      return;
    }
    setConfigError(false);
    setFetchError(null);
    let cancelled = false;
    const q = supabase
      .from('hotels')
      .select('*')
      .or('status.eq.active,status.eq.activo,status.eq.Activo,status.is.null')
      .order('name');

    void Promise.resolve(q).then(({ data, error }) => {
      if (cancelled) return;
      if (error) {
        setFetchError(error.message || 'Error al cargar');
      } else if (data) {
        setHotels((data as Hotel[]) || []);
      }
      setLoading(false);
    }).catch((err: unknown) => {
      if (cancelled) return;
      const message = err && typeof err === 'object' && 'message' in err ? String((err as { message: unknown }).message) : '';
      setFetchError(message || 'Error al cargar');
      setLoading(false);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <>
      <Header />
      <main>
        <HeroHome />
        <SelectorDestinos />
        <AlojamientosCarousel
          hotels={hotels}
          loading={loading}
          configError={configError}
          fetchError={fetchError}
          title="Nuestros elegidos del mes"
          sectionId="elegidos"
        />
        <Novedades />
        <Institucional />
        <WhatsAppCta />
        <Footer />
      </main>
    </>
  );
}
