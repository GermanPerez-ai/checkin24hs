-- ============================================
-- Testimonios curados para la Home (checkin24hs.com)
-- Se cargan desde el Dashboard (no API Meta).
-- ============================================

CREATE TABLE IF NOT EXISTS public.testimonios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    texto TEXT NOT NULL,
    fuente TEXT NOT NULL DEFAULT 'instagram'
        CHECK (fuente IN ('instagram', 'facebook', 'google', 'whatsapp', 'otro')),
    estrellas SMALLINT NOT NULL DEFAULT 5
        CHECK (estrellas >= 1 AND estrellas <= 5),
    avatar_url TEXT,
    enlace_url TEXT,
    activo BOOLEAN NOT NULL DEFAULT true,
    orden INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_testimonios_activo_orden
    ON public.testimonios (activo, orden ASC, created_at DESC);

ALTER TABLE public.testimonios ENABLE ROW LEVEL SECURITY;

-- Web + Dashboard leen con anon
DROP POLICY IF EXISTS "testimonios_select_anon" ON public.testimonios;
CREATE POLICY "testimonios_select_anon"
ON public.testimonios FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "testimonios_select_authenticated" ON public.testimonios;
CREATE POLICY "testimonios_select_authenticated"
ON public.testimonios FOR SELECT TO authenticated USING (true);

-- Dashboard gestiona con anon (mismo patrón que novedades)
DROP POLICY IF EXISTS "testimonios_insert_anon" ON public.testimonios;
CREATE POLICY "testimonios_insert_anon"
ON public.testimonios FOR INSERT TO anon WITH CHECK (true);

DROP POLICY IF EXISTS "testimonios_update_anon" ON public.testimonios;
CREATE POLICY "testimonios_update_anon"
ON public.testimonios FOR UPDATE TO anon USING (true);

DROP POLICY IF EXISTS "testimonios_delete_anon" ON public.testimonios;
CREATE POLICY "testimonios_delete_anon"
ON public.testimonios FOR DELETE TO anon USING (true);

COMMENT ON TABLE public.testimonios IS
  'Opiniones curadas (IG/FB/Google/WhatsApp) para la Home. CRUD desde Dashboard.';
