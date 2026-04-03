-- ============================================
-- Columnas para la web pública checkin24hs.com
-- Compatible con tabla hotels existente (Dashboard)
-- ============================================
-- Ejecutar en Supabase SQL Editor.

-- Slug para URLs amigables (/hotel/bariloche-lodge)
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS slug TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS idx_hotels_slug ON public.hotels(slug) WHERE slug IS NOT NULL;

-- Ubicación detallada (la web usa pais, region, ciudad)
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS pais TEXT;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS region TEXT;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS ciudad TEXT;

-- Media: imagen principal y galería (si ya existe "images" o "image_url", se pueden mapear en la app)
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS imagen_principal TEXT;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS galeria_fotos JSONB DEFAULT '[]'::jsonb;

-- Atributos booleanos para iconos en cards
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS wifi BOOLEAN DEFAULT false;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS desayuno BOOLEAN DEFAULT false;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS piscina BOOLEAN DEFAULT false;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS estacionamiento BOOLEAN DEFAULT false;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS calefaccion BOOLEAN DEFAULT false;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS pet_friendly BOOLEAN DEFAULT false;

-- Venta
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS precio_desde NUMERIC(12,2);
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS metodo_venta TEXT CHECK (metodo_venta IN ('cotizacion', 'directa'));
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS url_reserva_directa TEXT;

-- Social proof (pueden mapearse desde rating existente)
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS puntuacion_num NUMERIC(3,1);
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS puntuacion_texto TEXT;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS cantidad_opiniones INTEGER DEFAULT 0;

-- Comentarios
COMMENT ON COLUMN public.hotels.slug IS 'URL amigable, ej: bariloche-lodge';
COMMENT ON COLUMN public.hotels.metodo_venta IS 'cotizacion = botón Cotizar; directa = enlace externo';
