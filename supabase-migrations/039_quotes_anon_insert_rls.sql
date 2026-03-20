-- Cotizador público: permitir INSERT con la clave anon (rol anon).
-- Si RLS está activo en `quotes` y no hay política de inserción para anon,
-- el navegador recibirá error al enviar y la cotización solo quedará en localStorage.
--
-- Ejecutar en Supabase → SQL Editor si las cotizaciones desde cotizar.checkin24hs.com no aparecen en el dashboard.

ALTER TABLE public.quotes ENABLE ROW LEVEL SECURITY;

-- Evitar error si la política ya existe (Postgres 15+): usar nombre único o dropear antes en el editor.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'quotes' AND policyname = 'quotes_insert_anon_public'
  ) THEN
    CREATE POLICY quotes_insert_anon_public
      ON public.quotes
      FOR INSERT
      TO anon
      WITH CHECK (true);
  END IF;
END $$;

COMMENT ON POLICY quotes_insert_anon_public ON public.quotes IS 'Cotizador web: inserción pública con anon key.';
