-- ============================================
-- Tarjetas de presentación digitales (vCard + QR)
-- Públicas en checkin24hs.com/[slug]
-- CRUD + métricas desde Dashboard
-- ============================================

CREATE TABLE IF NOT EXISTS public.tarjetas_contacto (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT NOT NULL,
    nombre TEXT NOT NULL,
    apellido TEXT NOT NULL DEFAULT '',
    cargo TEXT NOT NULL DEFAULT '',
    descripcion TEXT NOT NULL DEFAULT '',
    telefono TEXT NOT NULL,
    email TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT tarjetas_contacto_slug_format CHECK (
        slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS tarjetas_contacto_slug_uidx
    ON public.tarjetas_contacto (slug);

CREATE INDEX IF NOT EXISTS tarjetas_contacto_activo_idx
    ON public.tarjetas_contacto (activo);

CREATE TABLE IF NOT EXISTS public.tarjetas_analiticas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tarjeta_id UUID NOT NULL REFERENCES public.tarjetas_contacto(id) ON DELETE CASCADE,
    tipo_evento TEXT NOT NULL
        CHECK (tipo_evento IN (
            'page_view',
            'vcard_download',
            'whatsapp_click',
            'email_click'
        )),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS tarjetas_analiticas_tarjeta_fecha_idx
    ON public.tarjetas_analiticas (tarjeta_id, created_at DESC);

CREATE INDEX IF NOT EXISTS tarjetas_analiticas_tipo_idx
    ON public.tarjetas_analiticas (tipo_evento, created_at DESC);

ALTER TABLE public.tarjetas_contacto ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tarjetas_analiticas ENABLE ROW LEVEL SECURITY;

-- Lectura + CRUD con anon (mismo patrón que testimonios/novedades)
DROP POLICY IF EXISTS "tarjetas_contacto_select_anon" ON public.tarjetas_contacto;
CREATE POLICY "tarjetas_contacto_select_anon"
ON public.tarjetas_contacto FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "tarjetas_contacto_select_authenticated" ON public.tarjetas_contacto;
CREATE POLICY "tarjetas_contacto_select_authenticated"
ON public.tarjetas_contacto FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "tarjetas_contacto_select_all_anon" ON public.tarjetas_contacto;

DROP POLICY IF EXISTS "tarjetas_contacto_insert_anon" ON public.tarjetas_contacto;
CREATE POLICY "tarjetas_contacto_insert_anon"
ON public.tarjetas_contacto FOR INSERT TO anon WITH CHECK (true);

DROP POLICY IF EXISTS "tarjetas_contacto_update_anon" ON public.tarjetas_contacto;
CREATE POLICY "tarjetas_contacto_update_anon"
ON public.tarjetas_contacto FOR UPDATE TO anon USING (true);

DROP POLICY IF EXISTS "tarjetas_contacto_delete_anon" ON public.tarjetas_contacto;
CREATE POLICY "tarjetas_contacto_delete_anon"
ON public.tarjetas_contacto FOR DELETE TO anon USING (true);

-- Analíticas: la web inserta eventos; el dashboard lee
DROP POLICY IF EXISTS "tarjetas_analiticas_insert_anon" ON public.tarjetas_analiticas;
CREATE POLICY "tarjetas_analiticas_insert_anon"
ON public.tarjetas_analiticas FOR INSERT TO anon WITH CHECK (true);

DROP POLICY IF EXISTS "tarjetas_analiticas_select_anon" ON public.tarjetas_analiticas;
CREATE POLICY "tarjetas_analiticas_select_anon"
ON public.tarjetas_analiticas FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "tarjetas_analiticas_select_authenticated" ON public.tarjetas_analiticas;
CREATE POLICY "tarjetas_analiticas_select_authenticated"
ON public.tarjetas_analiticas FOR SELECT TO authenticated USING (true);

COMMENT ON TABLE public.tarjetas_contacto IS
  'Tarjetas digitales (vCard/QR). Públicas en /[slug]. CRUD desde Dashboard.';
COMMENT ON TABLE public.tarjetas_analiticas IS
  'Eventos de interacción de tarjetas digitales (page_view, vcard, whatsapp, email).';

-- Seeds iniciales (editar teléfono/email/avatar desde el Dashboard)
INSERT INTO public.tarjetas_contacto (slug, nombre, apellido, cargo, descripcion, telefono, email, activo)
SELECT v.slug, v.nombre, v.apellido, v.cargo, v.descripcion, v.telefono, v.email, true
FROM (VALUES
    ('axel', 'Axel', '', 'Asesor de Viajes', 'Atención personalizada y reservas', '5492944000001', 'axel@checkin24hs.com'),
    ('german', 'German', '', 'Asesor de Viajes', 'Atención personalizada y reservas', '5492944000002', 'german@checkin24hs.com'),
    ('mariano', 'Mariano', '', 'Asesor de Viajes', 'Atención personalizada y reservas', '5492944000003', 'mariano@checkin24hs.com'),
    ('nazareno', 'Nazareno', '', 'Asesor de Viajes', 'Atención personalizada y reservas', '5492944000004', 'nazareno@checkin24hs.com')
) AS v(slug, nombre, apellido, cargo, descripcion, telefono, email)
WHERE NOT EXISTS (
    SELECT 1 FROM public.tarjetas_contacto t WHERE t.slug = v.slug
);
