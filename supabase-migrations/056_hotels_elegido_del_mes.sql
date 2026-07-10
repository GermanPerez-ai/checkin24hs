-- Flag "Elegido del mes": aparece en el carrusel de la Home.
-- Sigue apareciendo también en su página de destino (Chile / Argentina / Internacionales).
-- Ejecutar en Supabase SQL Editor.

ALTER TABLE public.hotels
  ADD COLUMN IF NOT EXISTS elegido_del_mes BOOLEAN DEFAULT false;

COMMENT ON COLUMN public.hotels.elegido_del_mes IS
  'Si true, el hotel aparece en Home → Nuestros elegidos del mes (además de su destino/región)';

CREATE INDEX IF NOT EXISTS idx_hotels_elegido_del_mes
  ON public.hotels (elegido_del_mes)
  WHERE elegido_del_mes = true;
