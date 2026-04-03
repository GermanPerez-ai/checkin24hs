-- ============================================
-- Slider del Home (checkin24hs.com) - TODO EN UNO
-- Ejecutá este script en Supabase → SQL Editor si sale "relation slider_ofertas does not exist".
-- Crea la tabla, agrega texto_boton y deja listo para que el Dashboard gestione los banners.
-- ============================================

-- 1) Crear tabla slider_ofertas (si no existe)
CREATE TABLE IF NOT EXISTS public.slider_ofertas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    titulo TEXT,
    imagen_url TEXT NOT NULL,
    imagen_url_mobile TEXT,
    link_destino TEXT,
    tipo_link TEXT DEFAULT 'url',
    orden INTEGER DEFAULT 0,
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2) Agregar columna texto_boton (si no existe)
ALTER TABLE public.slider_ofertas
ADD COLUMN IF NOT EXISTS texto_boton TEXT;

COMMENT ON TABLE public.slider_ofertas IS 'Carrusel del Home de checkin24hs.com';
COMMENT ON COLUMN public.slider_ofertas.texto_boton IS 'Texto del botón (ej. Chateá con Flor IA, Ver Hoteles). tipo_link=flor abre el widget Flor.';

-- 3) RLS
ALTER TABLE public.slider_ofertas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "slider_ofertas_select_anon" ON public.slider_ofertas;
CREATE POLICY "slider_ofertas_select_anon"
ON public.slider_ofertas FOR SELECT TO anon USING (activo = true);

DROP POLICY IF EXISTS "slider_ofertas_select_authenticated" ON public.slider_ofertas;
CREATE POLICY "slider_ofertas_select_authenticated"
ON public.slider_ofertas FOR SELECT TO authenticated USING (true);

-- Permitir al Dashboard (anon) insertar/actualizar/borrar para gestionar slides
DROP POLICY IF EXISTS "slider_ofertas_insert_anon" ON public.slider_ofertas;
CREATE POLICY "slider_ofertas_insert_anon"
ON public.slider_ofertas FOR INSERT TO anon WITH CHECK (true);

DROP POLICY IF EXISTS "slider_ofertas_update_anon" ON public.slider_ofertas;
CREATE POLICY "slider_ofertas_update_anon"
ON public.slider_ofertas FOR UPDATE TO anon USING (true);

DROP POLICY IF EXISTS "slider_ofertas_delete_anon" ON public.slider_ofertas;
CREATE POLICY "slider_ofertas_delete_anon"
ON public.slider_ofertas FOR DELETE TO anon USING (true);

-- Listo. Creá el bucket "banners" en Storage (público) para subir imágenes desde el Dashboard.
