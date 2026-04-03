-- ============================================
-- ELIMINAR CHATS, MENSAJES E INTERACCIONES ANTIGUAS
-- ⚠️ CUIDADO: Esto elimina datos
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
FROM flor_interactions;

-- ============================================
-- ELIMINAR DATOS
-- ⚠️ DESCOMENTAR PARA EJECUTAR
-- ============================================

-- 1. Eliminar TODOS los chats
DELETE FROM whatsapp_chats;

-- 2. Eliminar TODOS los mensajes
DELETE FROM whatsapp_messages;

-- 3. Eliminar TODAS las interacciones
DELETE FROM flor_interactions;

-- ============================================
-- VERIFICAR DESPUÉS DE ELIMINAR
-- ============================================

-- Ejecutar después de eliminar:
SELECT COUNT(*) as total_chats FROM whatsapp_chats;
SELECT COUNT(*) as total_mensajes FROM whatsapp_messages;
SELECT COUNT(*) as total_interacciones FROM flor_interactions;

-- ============================================
-- NOTA IMPORTANTE
-- ============================================
-- Después de eliminar:
-- 1. Los chats nuevos se crearán automáticamente cuando lleguen mensajes nuevos
-- 2. Las interacciones nuevas se guardarán cuando Flor IA responda
-- 3. Los mensajes nuevos se guardarán cuando lleguen mensajes de WhatsApp
-- 4. Recarga el dashboard y envía un mensaje nuevo para probar
