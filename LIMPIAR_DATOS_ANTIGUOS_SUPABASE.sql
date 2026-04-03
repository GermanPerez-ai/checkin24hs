-- ============================================
-- LIMPIAR DATOS ANTIGUOS DE SUPABASE
-- ⚠️ CUIDADO: Este script elimina datos antiguos
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- 1. Ver cuántos datos antiguos hay ANTES de eliminar
SELECT 
    'whatsapp_chats' as tabla,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE updated_at < NOW() - INTERVAL '90 days') as mas_90_dias,
    COUNT(*) FILTER (WHERE updated_at < NOW() - INTERVAL '60 days') as mas_60_dias,
    COUNT(*) FILTER (WHERE updated_at < NOW() - INTERVAL '30 days') as mas_30_dias
FROM whatsapp_chats;

SELECT 
    'whatsapp_messages' as tabla,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '90 days') as mas_90_dias,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '60 days') as mas_60_dias,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '30 days') as mas_30_dias
FROM whatsapp_messages;

SELECT 
    'flor_interactions' as tabla,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '90 days') as mas_90_dias,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '60 days') as mas_60_dias,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '30 days') as mas_30_dias
FROM flor_interactions;

SELECT 
    'reservations' as tabla,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '90 days') as mas_90_dias,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '60 days') as mas_60_dias,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '30 days') as mas_30_dias
FROM reservations;

SELECT 
    'quotes' as tabla,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '90 days') as mas_90_dias,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '60 days') as mas_60_dias,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '30 days') as mas_30_dias
FROM quotes;

-- ============================================
-- ELIMINAR DATOS ANTIGUOS
-- ⚠️ DESCOMENTAR SOLO SI ESTÁS SEGURO
-- ============================================

-- Opción 1: Eliminar mensajes muy antiguos (más de 90 días)
-- DELETE FROM whatsapp_messages 
-- WHERE created_at < NOW() - INTERVAL '90 days';

-- Opción 2: Eliminar chats inactivos muy antiguos (más de 90 días sin actualizar y sin mensajes no leídos)
-- DELETE FROM whatsapp_chats 
-- WHERE updated_at < NOW() - INTERVAL '90 days' 
--   AND unread_count = 0
--   AND id NOT IN (
--       SELECT DISTINCT chat_id FROM whatsapp_messages 
--       WHERE created_at >= NOW() - INTERVAL '90 days'
--   );

-- Opción 3: Eliminar interacciones antiguas (más de 60 días)
-- DELETE FROM flor_interactions 
-- WHERE created_at < NOW() - INTERVAL '60 days';

-- Opción 4: Eliminar reservas canceladas antiguas (más de 180 días)
-- DELETE FROM reservations 
-- WHERE status = 'CANCELADA' 
--   AND created_at < NOW() - INTERVAL '180 days';

-- Opción 5: Eliminar cotizaciones rechazadas antiguas (más de 90 días)
-- DELETE FROM quotes 
-- WHERE status = 'RECHAZADA' 
--   AND created_at < NOW() - INTERVAL '90 days';

-- ============================================
-- VERIFICAR DESPUÉS DE ELIMINAR
-- ============================================

-- Ejecutar después de eliminar para verificar:
-- SELECT COUNT(*) as total_chats FROM whatsapp_chats;
-- SELECT COUNT(*) as total_mensajes FROM whatsapp_messages;
-- SELECT COUNT(*) as total_interacciones FROM flor_interactions;
-- SELECT COUNT(*) as total_reservas FROM reservations;
-- SELECT COUNT(*) as total_cotizaciones FROM quotes;
