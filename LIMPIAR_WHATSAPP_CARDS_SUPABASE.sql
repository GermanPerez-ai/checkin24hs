-- ============================================
-- ELIMINAR TABLA whatsapp_cards DE SUPABASE
-- ============================================
-- Este script elimina SOLO la tabla whatsapp_cards
-- que almacenaba la configuración de conexiones WhatsApp
-- 
-- ⚠️ NOTA: Las tablas whatsapp_chats y whatsapp_messages
-- se mantienen porque se usan para almacenar conversaciones
-- ============================================
-- Ejecutar en Supabase SQL Editor
-- Ruta: Supabase Dashboard > SQL Editor > New Query
-- ============================================

-- ⚠️ ADVERTENCIA: Esto eliminará la tabla whatsapp_cards y todos sus datos
-- Esta tabla solo almacenaba la configuración de conexiones que ya no se usa

-- Paso 1: Eliminar políticas de seguridad (RLS) si existen
DROP POLICY IF EXISTS "Allow authenticated users to manage whatsapp_cards" ON public.whatsapp_cards;
DROP POLICY IF EXISTS "Allow public read access to whatsapp_cards" ON public.whatsapp_cards;

-- Paso 2: Eliminar índices si existen
DROP INDEX IF EXISTS public.idx_whatsapp_cards_card_number;

-- Paso 3: Eliminar la tabla (CASCADE elimina dependencias)
DROP TABLE IF EXISTS public.whatsapp_cards CASCADE;

-- Verificar que se eliminó correctamente
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
              AND table_name = 'whatsapp_cards'
        ) 
        THEN '❌ La tabla whatsapp_cards AÚN EXISTE'
        ELSE '✅ La tabla whatsapp_cards fue eliminada correctamente'
    END as resultado;

-- ============================================
-- NOTAS IMPORTANTES:
-- ============================================
-- ✅ Las siguientes tablas SE MANTIENEN porque se usan para conversaciones:
--    - whatsapp_chats (conversaciones)
--    - whatsapp_messages (mensajes)
--    - flor_interactions (interacciones con Flor IA)
--
-- ❌ Solo se eliminó whatsapp_cards (configuración de conexión)
-- ============================================
