-- Texto exacto del botón en la tarjeta de novedad (sin contador -2, -3).
-- Si está vacío o NULL, la web muestra "Ver más" en el botón de la tarjeta.
ALTER TABLE public.novedades
ADD COLUMN IF NOT EXISTS etiqueta_boton TEXT;

COMMENT ON COLUMN public.novedades.etiqueta_boton IS 'Texto que se muestra en el botón de la tarjeta. Se guarda tal cual; la URL usa slug (único).';

-- Rellenar etiqueta_boton en filas existentes: quitar sufijo -2, -3 del slug para mostrar solo la palabra
UPDATE public.novedades
SET etiqueta_boton = regexp_replace(slug, '-[0-9]+$', '')
WHERE etiqueta_boton IS NULL AND slug IS NOT NULL AND slug ~ '-[0-9]+$';
UPDATE public.novedades
SET etiqueta_boton = slug
WHERE etiqueta_boton IS NULL AND slug IS NOT NULL;
