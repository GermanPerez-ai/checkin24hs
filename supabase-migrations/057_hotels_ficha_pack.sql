-- Ficha de pack/paquete para la web (tarjeta + detalle).
-- Ejecutar en Supabase SQL Editor.

ALTER TABLE public.hotels
  ADD COLUMN IF NOT EXISTS ficha_pack JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.hotels.ficha_pack IS
  'Datos de pack web: noches, destinos_count, precio_por_persona, moneda, incluye, excluye, itinerario, etc.';
