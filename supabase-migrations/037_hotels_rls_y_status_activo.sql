-- ============================================
-- 1) RLS: asegurar que anon pueda hacer SELECT en hotels
-- 2) Opcional: marcar como activos los hoteles con status NULL (para que la web los muestre)
-- ============================================
-- Ejecutar en Supabase: SQL Editor → New query → pegar y Run.

-- 1) Políticas de lectura para la web y el cotizador
ALTER TABLE IF EXISTS public.hotels ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "hotels_select_anon" ON public.hotels;
CREATE POLICY "hotels_select_anon"
ON public.hotels
FOR SELECT
TO anon
USING (true);

DROP POLICY IF EXISTS "hotels_select_authenticated" ON public.hotels;
CREATE POLICY "hotels_select_authenticated"
ON public.hotels
FOR SELECT
TO authenticated
USING (true);

-- 2) Si la columna status existe pero está NULL en algunos hoteles, marcarlos como activos
-- (así la web y el cotizador los muestran; en el dashboard podés pasarlos a Inactivo si no los querés ofrecer)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'hotels' AND column_name = 'status'
  ) THEN
    UPDATE public.hotels SET status = 'active' WHERE status IS NULL;
  END IF;
END $$;
