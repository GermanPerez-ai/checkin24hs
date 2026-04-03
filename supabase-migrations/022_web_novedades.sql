-- ============================================
-- Tabla de novedades / feed para la web
-- ============================================

CREATE TABLE IF NOT EXISTS public.novedades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    titulo TEXT NOT NULL,
    resumen TEXT,
    imagen_miniatura TEXT,
    fecha_publicacion TIMESTAMPTZ DEFAULT NOW(),
    cuerpo_nota TEXT,
    slug TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_novedades_fecha ON public.novedades(fecha_publicacion DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_novedades_slug ON public.novedades(slug) WHERE slug IS NOT NULL;

ALTER TABLE public.novedades ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "novedades_select_anon" ON public.novedades;
CREATE POLICY "novedades_select_anon"
ON public.novedades FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "novedades_select_authenticated" ON public.novedades;
CREATE POLICY "novedades_select_authenticated"
ON public.novedades FOR SELECT TO authenticated USING (true);

COMMENT ON TABLE public.novedades IS 'Feed de noticias/artículos para la web checkin24hs.com';
