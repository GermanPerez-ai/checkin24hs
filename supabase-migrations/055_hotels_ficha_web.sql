-- Ficha pública modular de hotel (página web checkin24hs.com).
-- Separada de flor_info (Flor/WhatsApp). Ejecutar en Supabase SQL Editor.

ALTER TABLE public.hotels
  ADD COLUMN IF NOT EXISTS ficha_web JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.hotels.ficha_web IS
  'Ficha modular para la web: sobre_propiedad, servicios[], opiniones, zona, cerca[], como_desplazarse, detalles_tecnicos, politicas, informacion_importante';
