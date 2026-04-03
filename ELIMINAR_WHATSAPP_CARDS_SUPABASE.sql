-- ============================================
-- ELIMINAR TABLA whatsapp_cards DE SUPABASE
-- ============================================
-- Este script elimina la tabla whatsapp_cards que almacenaba
-- la configuración de conexiones WhatsApp (que ya no se usa)
-- ============================================
-- Ejecutar en Supabase SQL Editor
-- Ruta: Supabase Dashboard > SQL Editor > New Query
-- ============================================

-- ⚠️ ADVERTENCIA: Esto eliminará la tabla whatsapp_cards y todos sus datos
-- Esta tabla solo almacenaba la configuración de conexiones que ya no se usa

-- Paso 1: Eliminar políticas de seguridad (RLS)
DROP POLICY IF EXISTS "Allow authenticated users to manage whatsapp_cards" ON public.whatsapp_cards;
DROP POLICY IF EXISTS "Allow public read access to whatsapp_cards" ON public.whatsapp_cards;

-- Paso 2: Eliminar índices
DROP INDEX IF EXISTS public.idx_whatsapp_cards_card_number;

-- Paso 3: Eliminar la tabla
DROP TABLE IF EXISTS public.whatsapp_cards CASCADE;

-- Verificar que se eliminó
SELECT 
    table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name = 'whatsapp_cards';

-- Si la consulta anterior no devuelve resultados, la tabla fue eliminada correctamente
-- Si devuelve resultados, la tabla aún existe (verificar permisos)
