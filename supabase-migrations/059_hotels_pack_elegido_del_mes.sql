-- Flag "Pack elegido del mes": aparece en Home → Nuestros Pack elegidos del mes.
-- Independiente de elegido_del_mes (hoteles).
-- Ejecutar en Supabase SQL Editor.

ALTER TABLE public.hotels
  ADD COLUMN IF NOT EXISTS pack_elegido_del_mes BOOLEAN DEFAULT false;

COMMENT ON COLUMN public.hotels.pack_elegido_del_mes IS
  'Si true, el producto aparece en Home → Nuestros Pack elegidos del mes (además de /packs)';

CREATE INDEX IF NOT EXISTS idx_hotels_pack_elegido_del_mes
  ON public.hotels (pack_elegido_del_mes)
  WHERE pack_elegido_del_mes = true;
