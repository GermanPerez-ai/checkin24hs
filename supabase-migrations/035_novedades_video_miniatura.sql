-- Video miniatura opcional para novedades (si está presente, la tarjeta muestra video en vez de imagen)
ALTER TABLE public.novedades
ADD COLUMN IF NOT EXISTS video_miniatura TEXT;

COMMENT ON COLUMN public.novedades.video_miniatura IS 'URL de video para la tarjeta (opcional). Si está presente, se muestra en lugar de la imagen. Formato recomendado: MP4 o WebM.';
