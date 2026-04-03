-- ============================================
-- ELIMINAR TODOS LOS CHATS DE SUPABASE
-- ⚠️ CUIDADO: Esto elimina TODOS los chats
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- 1. Ver cuántos chats hay ANTES de eliminar
SELECT 
    COUNT(*) as total_chats_antes,
    COUNT(*) FILTER (WHERE updated_at >= NOW() - INTERVAL '7 days') as chats_recientes_7d,
    COUNT(*) FILTER (WHERE updated_at >= NOW() - INTERVAL '24 hours') as chats_recientes_24h
FROM whatsapp_chats;

-- 2. Ver los últimos 10 chats antes de eliminar (para referencia)
SELECT 
    id,
    phone,
    name,
    LEFT(last_message, 50) as ultimo_mensaje,
    updated_at
FROM whatsapp_chats
ORDER BY updated_at DESC NULLS LAST
LIMIT 10;

-- ============================================
-- ELIMINAR TODOS LOS CHATS
-- ⚠️ DESCOMENTAR PARA EJECUTAR
-- ============================================

-- Opción 1: Eliminar TODOS los chats (sin condiciones)
-- DELETE FROM whatsapp_chats;

-- Opción 2: Eliminar todos los chats EXCEPTO los que tienen mensajes recientes (últimas 24 horas)
-- DELETE FROM whatsapp_chats 
-- WHERE id NOT IN (
--     SELECT DISTINCT chat_id 
--     FROM whatsapp_messages 
--     WHERE created_at >= NOW() - INTERVAL '24 hours'
-- );

-- ============================================
-- VERIFICAR DESPUÉS DE ELIMINAR
-- ============================================

-- Ejecutar después de eliminar:
-- SELECT COUNT(*) as total_chats_despues FROM whatsapp_chats;

-- ============================================
-- NOTA IMPORTANTE
-- ============================================
-- Después de eliminar todos los chats:
-- 1. Los chats nuevos se crearán automáticamente cuando lleguen mensajes nuevos
-- 2. El servidor creará nuevos chats en whatsapp_chats cuando procese mensajes
-- 3. Verifica que el servidor esté guardando chats nuevos correctamente
