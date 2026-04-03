-- ============================================
-- Slider de ofertas para el Home de la web
-- Cada slide: imagen, enlace (hotel o filtro), orden
-- ============================================

CREATE TABLE IF NOT EXISTS public.slider_ofertas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    titulo TEXT,
    imagen_url TEXT NOT NULL,
    imagen_url_mobile TEXT,
    link_destino TEXT,
    tipo_link TEXT DEFAULT 'url',
    orden INTEGER DEFAULT 0,
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- tipo_link: 'url' | 'hotel' | 'busqueda' (link_destino = URL, hotel_id/slug, o query ?ciudad=Bariloche)
ALTER TABLE public.slider_ofertas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "slider_ofertas_select_anon" ON public.slider_ofertas;
CREATE POLICY "slider_ofertas_select_anon"
ON public.slider_ofertas FOR SELECT TO anon USING (activo = true);

DROP POLICY IF EXISTS "slider_ofertas_select_authenticated" ON public.slider_ofertas;
CREATE POLICY "slider_ofertas_select_authenticated"
ON public.slider_ofertas FOR SELECT TO authenticated USING (true);

COMMENT ON TABLE public.slider_ofertas IS 'Carrusel del Home de checkin24hs.com';
