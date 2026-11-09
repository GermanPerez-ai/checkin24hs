-- Flag "Grupo Barceló": aparece en Home bajo el banner Exclusivo Barceló,
-- aunque el nombre no empiece con Barceló (ej. Occidental at Xcaret).
-- Ejecutar en Supabase SQL Editor. No corre solo.

ALTER TABLE public.hotels
  ADD COLUMN IF NOT EXISTS grupo_barcelo BOOLEAN DEFAULT false;

COMMENT ON COLUMN public.hotels.grupo_barcelo IS
  'Si true, el producto aparece en Home → carrusel debajo del banner Barceló (tarjeta estilo Pack), además de los que el nombre empieza con Barceló';

CREATE INDEX IF NOT EXISTS idx_hotels_grupo_barcelo
  ON public.hotels (grupo_barcelo)
  WHERE grupo_barcelo = true;
