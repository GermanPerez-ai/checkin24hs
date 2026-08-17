-- ============================================
-- Newsletter: suscriptores desde la web
-- ============================================

CREATE TABLE IF NOT EXISTS public.newsletter_subscribers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    origen TEXT NOT NULL DEFAULT 'web',
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Email único (case-insensitive)
CREATE UNIQUE INDEX IF NOT EXISTS idx_newsletter_subscribers_email_lower
    ON public.newsletter_subscribers (lower(email));

CREATE INDEX IF NOT EXISTS idx_newsletter_subscribers_created
    ON public.newsletter_subscribers (created_at DESC);

ALTER TABLE public.newsletter_subscribers ENABLE ROW LEVEL SECURITY;

-- Web: cualquiera puede suscribirse
DROP POLICY IF EXISTS "newsletter_insert_anon" ON public.newsletter_subscribers;
CREATE POLICY "newsletter_insert_anon"
ON public.newsletter_subscribers FOR INSERT TO anon WITH CHECK (true);

-- Dashboard (anon) lista y borra — mismo patrón que novedades/testimonios
DROP POLICY IF EXISTS "newsletter_select_anon" ON public.newsletter_subscribers;
CREATE POLICY "newsletter_select_anon"
ON public.newsletter_subscribers FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "newsletter_select_authenticated" ON public.newsletter_subscribers;
CREATE POLICY "newsletter_select_authenticated"
ON public.newsletter_subscribers FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "newsletter_delete_anon" ON public.newsletter_subscribers;
CREATE POLICY "newsletter_delete_anon"
ON public.newsletter_subscribers FOR DELETE TO anon USING (true);

DROP POLICY IF EXISTS "newsletter_update_anon" ON public.newsletter_subscribers;
CREATE POLICY "newsletter_update_anon"
ON public.newsletter_subscribers FOR UPDATE TO anon USING (true);

COMMENT ON TABLE public.newsletter_subscribers IS
  'Emails del newsletter de checkin24hs.com. Alta desde la web; listado/export desde Dashboard.';
