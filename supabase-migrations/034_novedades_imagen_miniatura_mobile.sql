-- Imagen miniatura móvil para novedades (opcional, para tarjetas y detalle en pantallas chicas)
ALTER TABLE public.novedades
ADD COLUMN IF NOT EXISTS imagen_miniatura_mobile TEXT;

COMMENT ON COLUMN public.novedades.imagen_miniatura_mobile IS 'URL de imagen para móvil (sugerido 560×350 px 16:10). Opcional.';
