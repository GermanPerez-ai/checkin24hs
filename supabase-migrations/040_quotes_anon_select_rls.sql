-- Dashboard y cotizador usan la clave anon en el navegador.
-- Si solo existe política INSERT (039) pero no SELECT, getQuotes falla o devuelve vacío
-- y las cotizaciones "no aparecen" aunque el INSERT haya funcionado.
--
-- Ejecutar en Supabase → SQL Editor si el listado de Cotizaciones no muestra filas nuevas.

ALTER TABLE public.quotes ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'quotes' AND policyname = 'quotes_select_anon_dashboard'
  ) THEN
    CREATE POLICY quotes_select_anon_dashboard
      ON public.quotes
      FOR SELECT
      TO anon
      USING (true);
  END IF;
END $$;

COMMENT ON POLICY quotes_select_anon_dashboard ON public.quotes IS 'Dashboard/cotizador: lectura con anon key (misma que ya puede insertar cotizaciones públicas).';
