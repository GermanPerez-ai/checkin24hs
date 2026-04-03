-- ============================================
-- LIMPIAR CHATS ANTIGUOS PARA PROBAR
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- 1. Ver cuántos chats hay y cuántos son antiguos
SELECT 
    'whatsapp_chats' as tabla,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE updated_at < NOW() - INTERVAL '7 days') as mas_7_dias,
    COUNT(*) FILTER (WHERE updated_at < NOW() - INTERVAL '30 days') as mas_30_dias,
    COUNT(*) FILTER (WHERE updated_at IS NULL) as sin_updated_at,
    MAX(updated_at) as ultima_actualizacion
FROM whatsapp_chats;

-- 2. Ver los chats más recientes (últimos 10)
SELECT 
    id,
    phone,
    name,
    LEFT(last_message, 50) as ultimo_mensaje,
    updated_at,
    created_at
FROM whatsapp_chats
ORDER BY updated_at DESC NULLS LAST
LIMIT 10;

-- ============================================
-- LIMPIAR CHATS ANTIGUOS
-- ⚠️ CUIDADO: Esto elimina chats antiguos
-- ============================================

-- Opción 1: Eliminar chats inactivos muy antiguos (más de 30 días sin actualizar)
-- DELETE FROM whatsapp_chats 
-- WHERE updated_at < NOW() - INTERVAL '30 days'
--   AND unread_count = 0;

-- Opción 2: Eliminar chats sin actualizar en los últimos 7 días (más agresivo)
-- DELETE FROM whatsapp_chats 
-- WHERE updated_at < NOW() - INTERVAL '7 days'
--   AND unread_count = 0;

-- Opción 3: Eliminar TODOS los chats antiguos (solo para probar)
-- ⚠️ MUY AGRESIVO - Solo si quieres empezar de cero
-- DELETE FROM whatsapp_chats 
-- WHERE updated_at < NOW() - INTERVAL '1 day';

-- ============================================
-- VERIFICAR DESPUÉS DE LIMPIAR
-- ============================================

-- Ejecutar después de limpiar para verificar:
-- SELECT COUNT(*) as total_chats FROM whatsapp_chats;
-- SELECT COUNT(*) as chats_recientes FROM whatsapp_chats WHERE updated_at >= NOW() - INTERVAL '24 hours';
