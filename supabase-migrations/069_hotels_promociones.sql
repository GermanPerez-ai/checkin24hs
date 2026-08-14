-- Promociones vigentes por hotel (ficha comercial para Flor).
-- Independiente de programas (detalles_programas) y de la tabla promotions del dashboard.
-- Ejecutar en Supabase SQL Editor.

ALTER TABLE public.hotels
  ADD COLUMN IF NOT EXISTS promociones jsonb DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.hotels.promociones IS
  'Array JSON de promociones vigentes para Flor. Ej: [{"nombre":"Flexi Pass 10 días","precio":"330 USD","detalle":"Transferible, válido toda la temporada","hasta":"2026-09-30","activa":true}]';

-- Lectura pública (mismo criterio que ficha hotel para Flor / web)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'hotels' AND policyname = 'Hotels are viewable by everyone'
  ) THEN
    NULL;
  END IF;
END $$;
