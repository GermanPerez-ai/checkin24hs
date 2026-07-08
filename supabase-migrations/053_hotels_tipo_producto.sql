-- ============================================
-- Dashboard Hoteles: tipo de producto (Hotel / Paquete)
-- Ubicación regional: usar columna pais existente
--   (Argentina | Chile | Internacional)
-- ============================================
-- Ejecutar en Supabase SQL Editor.

ALTER TABLE public.hotels
  ADD COLUMN IF NOT EXISTS tipo_producto TEXT;

-- Valores permitidos: hotel | paquete
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'hotels_tipo_producto_check'
  ) THEN
    ALTER TABLE public.hotels
      ADD CONSTRAINT hotels_tipo_producto_check
      CHECK (tipo_producto IS NULL OR tipo_producto IN ('hotel', 'paquete'));
  END IF;
END $$;

COMMENT ON COLUMN public.hotels.tipo_producto IS 'hotel = alojamiento; paquete = paquete turístico';
COMMENT ON COLUMN public.hotels.pais IS 'Ubicación regional para web/dashboard: Argentina | Chile | Internacional';

-- Default razonable para filas existentes sin tipo
UPDATE public.hotels
SET tipo_producto = 'hotel'
WHERE tipo_producto IS NULL;
