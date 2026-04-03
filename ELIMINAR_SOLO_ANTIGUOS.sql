-- ============================================
-- ELIMINAR SOLO DATOS ANTIGUOS (NO TODOS)
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- 1. Ver cuántos datos antiguos hay
SELECT 
    'whatsapp_chats' as tabla,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE updated_at < NOW() - INTERVAL '7 days') as mas_7_dias
FROM whatsapp_chats
UNION ALL
SELECT 
    'whatsapp_messages' as tabla,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '7 days') as mas_7_dias
FROM whatsapp_messages
UNION ALL
SELECT 
    'flor_interactions' as tabla,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '7 days') as mas_7_dias
FROM flor_interactions;

-- ============================================
-- ELIMINAR SOLO DATOS ANTIGUOS
-- ⚠️ DESCOMENTAR PARA EJECUTAR
-- ============================================

-- Opción 1: Eliminar datos más antiguos que 7 días
-- DELETE FROM whatsapp_chats WHERE updated_at < NOW() - INTERVAL '7 days';
-- DELETE FROM whatsapp_messages WHERE created_at < NOW() - INTERVAL '7 days';
-- DELETE FROM flor_interactions WHERE created_at < NOW() - INTERVAL '7 days';

-- Opción 2: Eliminar datos más antiguos que 30 días (más conservador)
-- DELETE FROM whatsapp_chats WHERE updated_at < NOW() - INTERVAL '30 days';
-- DELETE FROM whatsapp_messages WHERE created_at < NOW() - INTERVAL '30 days';
-- DELETE FROM flor_interactions WHERE created_at < NOW() - INTERVAL '30 days';
