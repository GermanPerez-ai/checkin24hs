-- Botón por slide: texto del CTA (ej. "Chateá con Flor IA", "Ver Hoteles")
-- tipo_link = 'flor' hace que el botón abra el widget de Flor IA

ALTER TABLE public.slider_ofertas
ADD COLUMN IF NOT EXISTS texto_boton TEXT;

COMMENT ON COLUMN public.slider_ofertas.texto_boton IS 'Texto del botón del slide (ej. Chateá con Flor IA, Ver Hoteles)';
