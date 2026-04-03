-- ============================================
-- ELIMINAR TODOS LOS DATOS PARA PROBAR
-- ⚠️ CUIDADO: Esto elimina TODOS los datos
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- 1. Ver cuántos datos hay ANTES de eliminar
SELECT 
    'whatsapp_chats' as tabla,
    COUNT(*) as total
FROM whatsapp_chats
UNION ALL
SELECT 
    'whatsapp_messages' as tabla,
    COUNT(*) as total
FROM whatsapp_messages
UNION ALL
SELECT 
    'flor_interactions' as tabla,
    COUNT(*) as total
FROM flor_interactions
UNION ALL
SELECT 
    'reservations' as tabla,
    COUNT(*) as total
FROM reservations
UNION ALL
SELECT 
    'quotes' as tabla,
    COUNT(*) as total
FROM quotes;

-- ============================================
-- ELIMINAR TODOS LOS DATOS
-- ⚠️ DESCOMENTAR PARA EJECUTAR
-- ============================================

-- 1. Eliminar TODOS los chats
-- DELETE FROM whatsapp_chats;

-- 2. Eliminar TODOS los mensajes
-- DELETE FROM whatsapp_messages;

-- 3. Eliminar TODAS las interacciones
-- DELETE FROM flor_interactions;

-- 4. Eliminar TODAS las reservas (CUIDADO: Esto elimina datos importantes)
-- DELETE FROM reservations;

-- 5. Eliminar TODAS las cotizaciones (CUIDADO: Esto elimina datos importantes)
-- DELETE FROM quotes;

-- ============================================
-- VERIFICAR DESPUÉS DE ELIMINAR
-- ============================================

-- Ejecutar después de eliminar:
-- SELECT COUNT(*) as total_chats FROM whatsapp_chats;
-- SELECT COUNT(*) as total_mensajes FROM whatsapp_messages;
-- SELECT COUNT(*) as total_interacciones FROM flor_interactions;
-- SELECT COUNT(*) as total_reservas FROM reservations;
-- SELECT COUNT(*) as total_cotizaciones FROM quotes;

-- ============================================
-- RECOMENDACIÓN
-- ============================================
-- Si solo quieres probar los chats, elimina SOLO:
-- 1. whatsapp_chats
-- 2. whatsapp_messages
-- 
-- NO elimines reservations ni quotes a menos que estés seguro
