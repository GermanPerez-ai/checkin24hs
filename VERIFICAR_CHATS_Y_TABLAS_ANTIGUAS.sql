-- ============================================
-- VERIFICAR CHATS Y TABLAS ANTIGUAS DEL CRM
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- 1. Verificar chats de WhatsApp
SELECT 
    'whatsapp_chats' as tabla,
    COUNT(*) as total_chats,
    COUNT(DISTINCT phone) as numeros_unicos,
    MAX(updated_at) as ultima_actualizacion
FROM whatsapp_chats;

-- 2. Verificar mensajes de WhatsApp
SELECT 
    'whatsapp_messages' as tabla,
    COUNT(*) as total_mensajes,
    COUNT(DISTINCT phone) as numeros_unicos,
    MAX(created_at) as ultimo_mensaje
FROM whatsapp_messages;

-- 3. Ver últimos 10 chats
SELECT 
    id,
    phone,
    name,
    LEFT(last_message, 50) as ultimo_mensaje_preview,
    unread_count,
    updated_at
FROM whatsapp_chats
ORDER BY updated_at DESC
LIMIT 10;

-- 4. Ver últimos 10 mensajes
SELECT 
    id,
    phone,
    LEFT(message, 50) as mensaje_preview,
    is_from_me,
    created_at
FROM whatsapp_messages
ORDER BY created_at DESC
LIMIT 10;

-- 5. Verificar interacciones de Flor
SELECT 
    'flor_interactions' as tabla,
    COUNT(*) as total_interacciones,
    COUNT(DISTINCT phone) as usuarios_unicos,
    MAX(created_at) as ultima_interaccion
FROM flor_interactions;

-- 6. Buscar tablas antiguas del CRM
SELECT 
    table_name,
    '⚠️ TABLA ANTIGUA ENCONTRADA' as advertencia
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'interactions',
    'crm_interactions',
    'chat_interactions',
    'flor_chat_interactions'
  );

-- 7. Verificar todas las tablas relacionadas con chats/interacciones
SELECT 
    table_name,
    CASE 
        WHEN table_name = 'flor_interactions' THEN '✅ CORRECTA - Interacciones de Flor'
        WHEN table_name = 'whatsapp_chats' THEN '✅ CORRECTA - Chats de WhatsApp'
        WHEN table_name = 'whatsapp_messages' THEN '✅ CORRECTA - Mensajes de WhatsApp'
        ELSE '⚠️ VERIFICAR - Puede ser tabla antigua'
    END as estado
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (
    table_name LIKE '%interaction%' OR
    table_name LIKE '%chat%' OR
    table_name LIKE '%message%'
  )
ORDER BY table_name;
