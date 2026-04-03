-- ============================================
-- LIMPIAR DATOS ANTIGUOS PARA PROBAR
-- Ejecutar en Supabase SQL Editor
-- ⚠️ CUIDADO: Este script elimina datos antiguos
-- ============================================

-- 1. VER CUÁNTOS DATOS HAY ANTES DE ELIMINAR
SELECT 
    'whatsapp_chats' as tabla,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE updated_at < NOW() - INTERVAL '30 days') as mas_30_dias
FROM whatsapp_chats;

SELECT 
    'whatsapp_messages' as tabla,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '30 days') as mas_30_dias
FROM whatsapp_messages;

SELECT 
    'flor_interactions' as tabla,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '30 days') as mas_30_dias
FROM flor_interactions;

SELECT 
    'reservations' as tabla,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '90 days') as mas_90_dias
FROM reservations;

SELECT 
    'quotes' as tabla,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '30 days') as mas_30_dias
FROM quotes;

-- ============================================
-- ELIMINAR DATOS ANTIGUOS
-- ⚠️ DESCOMENTAR SOLO SI ESTÁS SEGURO
-- ============================================

-- 1. Eliminar mensajes antiguos (más de 30 días)
-- DELETE FROM whatsapp_messages 
-- WHERE created_at < NOW() - INTERVAL '30 days';

-- 2. Eliminar chats inactivos antiguos (más de 30 días sin actualizar)
-- DELETE FROM whatsapp_chats 
-- WHERE updated_at < NOW() - INTERVAL '30 days'
--   AND unread_count = 0;

-- 3. Eliminar interacciones antiguas (más de 30 días)
-- DELETE FROM flor_interactions 
-- WHERE created_at < NOW() - INTERVAL '30 days';

-- 4. Eliminar reservas canceladas antiguas (más de 90 días)
-- DELETE FROM reservations 
-- WHERE status = 'CANCELADA' 
--   AND created_at < NOW() - INTERVAL '90 days';

-- 5. Eliminar cotizaciones rechazadas antiguas (más de 30 días)
-- DELETE FROM quotes 
-- WHERE status = 'RECHAZADA' 
--   AND created_at < NOW() - INTERVAL '30 days';

-- ============================================
-- VERIFICAR DESPUÉS DE ELIMINAR
-- ============================================

-- Ejecutar después de eliminar:
-- SELECT COUNT(*) as total_chats FROM whatsapp_chats;
-- SELECT COUNT(*) as total_mensajes FROM whatsapp_messages;
-- SELECT COUNT(*) as total_interacciones FROM flor_interactions;
-- SELECT COUNT(*) as total_reservas FROM reservations;
-- SELECT COUNT(*) as total_cotizaciones FROM quotes;
