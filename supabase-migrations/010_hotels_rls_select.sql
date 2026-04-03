-- ============================================
-- RLS: permitir lectura (SELECT) de la tabla hotels
-- ============================================
-- Flor IA (servidor WhatsApp) lee hoteles con la clave anon de Supabase.
-- Si RLS está habilitado en hotels sin políticas, la API recibe vacío y Flor
-- dispara "no entiendo". Este script asegura SELECT para anon (y authenticated).
--
-- Ejecutar en Supabase: SQL Editor → New query → pegar y Run.
-- Si la tabla hotels no tiene RLS habilitado, no hace falta; si sí tiene, estas políticas permiten leer.

-- Habilitar RLS en hotels (si no está)
ALTER TABLE IF EXISTS public.hotels ENABLE ROW LEVEL SECURITY;

-- Política: permitir SELECT a anon (API del dashboard y del servidor WhatsApp)
DROP POLICY IF EXISTS "hotels_select_anon" ON public.hotels;
CREATE POLICY "hotels_select_anon"
ON public.hotels
FOR SELECT
TO anon
USING (true);

-- Política: permitir SELECT a authenticated (por si usan login en el futuro)
DROP POLICY IF EXISTS "hotels_select_authenticated" ON public.hotels;
CREATE POLICY "hotels_select_authenticated"
ON public.hotels
FOR SELECT
TO authenticated
USING (true);

-- Nota: INSERT/UPDATE/DELETE se controlan con otras políticas o desde el Dashboard con servicio/rol que tenga permisos.
-- Este archivo solo asegura que la lectura (SELECT) para Flor y el panel no falle por RLS.
