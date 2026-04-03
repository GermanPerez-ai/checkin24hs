-- ============================================
-- Permitir al Dashboard (anon) gestionar novedades (INSERT/UPDATE/DELETE)
-- La web sigue leyendo con SELECT anon ya existente.
-- ============================================

DROP POLICY IF EXISTS "novedades_insert_anon" ON public.novedades;
CREATE POLICY "novedades_insert_anon"
ON public.novedades FOR INSERT TO anon WITH CHECK (true);

DROP POLICY IF EXISTS "novedades_update_anon" ON public.novedades;
CREATE POLICY "novedades_update_anon"
ON public.novedades FOR UPDATE TO anon USING (true);

DROP POLICY IF EXISTS "novedades_delete_anon" ON public.novedades;
CREATE POLICY "novedades_delete_anon"
ON public.novedades FOR DELETE TO anon USING (true);

COMMENT ON TABLE public.novedades IS 'Feed de noticias para la web. Dashboard gestiona con anon (RLS).';
