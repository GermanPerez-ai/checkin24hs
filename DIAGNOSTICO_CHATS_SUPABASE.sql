-- ============================================
-- DIAGNÓSTICO COMPLETO: CHATS Y MENSAJES EN SUPABASE
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- 1. VERIFICAR EXISTENCIA DE TABLAS
SELECT 
    'TABLAS EXISTENTES' as seccion,
    table_name as tabla,
    CASE 
        WHEN table_name = 'whatsapp_chats' THEN '✅ Tabla principal de chats'
        WHEN table_name = 'whatsapp_messages' THEN '✅ Tabla de mensajes'
        WHEN table_name = 'whatsapp_conversations' THEN '⚠️ Tabla alternativa (puede no usarse)'
        ELSE 'ℹ️ Otra tabla relacionada'
    END as descripcion
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND (table_name LIKE '%whatsapp%' OR table_name LIKE '%conversation%')
ORDER BY table_name;

-- 2. ESTRUCTURA DE whatsapp_chats
SELECT 
    'ESTRUCTURA whatsapp_chats' as seccion,
    column_name as columna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as default_value
FROM information_schema.columns
WHERE table_name = 'whatsapp_chats'
ORDER BY ordinal_position;

-- 3. ESTRUCTURA DE whatsapp_messages
SELECT 
    'ESTRUCTURA whatsapp_messages' as seccion,
    column_name as columna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as default_value
FROM information_schema.columns
WHERE table_name = 'whatsapp_messages'
ORDER BY ordinal_position;

-- 4. CONTEO GENERAL
SELECT 
    'CONTEO GENERAL' as seccion,
    (SELECT COUNT(*) FROM whatsapp_chats) as total_chats,
    (SELECT COUNT(*) FROM whatsapp_messages) as total_mensajes,
    (SELECT COUNT(DISTINCT phone) FROM whatsapp_chats) as contactos_unicos,
    (SELECT COUNT(*) FROM whatsapp_messages WHERE is_from_me = false) as mensajes_recibidos,
    (SELECT COUNT(*) FROM whatsapp_messages WHERE is_from_me = true) as mensajes_enviados;

-- 5. ÚLTIMOS CHATS CREADOS
SELECT 
    'ÚLTIMOS CHATS' as seccion,
    id,
    phone,
    name,
    LEFT(last_message, 50) as ultimo_mensaje_preview,
    last_message_time,
    unread_count,
    whatsapp_instance,
    created_at
FROM whatsapp_chats
ORDER BY created_at DESC
LIMIT 10;

-- 6. ÚLTIMOS MENSAJES
SELECT 
    'ÚLTIMOS MENSAJES' as seccion,
    wm.id,
    wm.chat_id,
    wm.phone,
    LEFT(wm.message, 50) as mensaje_preview,
    wm.is_from_me,
    wm.created_at,
    wm.whatsapp_instance,
    CASE WHEN wc.id IS NULL THEN '❌ SIN CHAT' ELSE '✅ OK' END as chat_valido
FROM whatsapp_messages wm
LEFT JOIN whatsapp_chats wc ON wc.id = wm.chat_id
ORDER BY wm.created_at DESC
LIMIT 10;

-- 7. CHATS SIN MENSAJES
SELECT 
    'CHATS SIN MENSAJES' as seccion,
    wc.id,
    wc.phone,
    wc.name,
    wc.created_at,
    COUNT(wm.id) as mensajes_count
FROM whatsapp_chats wc
LEFT JOIN whatsapp_messages wm ON wm.chat_id = wc.id
GROUP BY wc.id, wc.phone, wc.name, wc.created_at
HAVING COUNT(wm.id) = 0
ORDER BY wc.created_at DESC
LIMIT 10;

-- 8. MENSAJES SIN CHAT_ID VÁLIDO
SELECT 
    'MENSAJES SIN CHAT' as seccion,
    wm.id,
    wm.phone,
    wm.chat_id,
    LEFT(wm.message, 50) as mensaje_preview,
    wm.created_at,
    CASE 
        WHEN wc.id IS NULL THEN '❌ CHAT NO EXISTE'
        ELSE '✅ OK'
    END as estado
FROM whatsapp_messages wm
LEFT JOIN whatsapp_chats wc ON wc.id = wm.chat_id
WHERE wc.id IS NULL
ORDER BY wm.created_at DESC
LIMIT 10;

-- 9. CHATS CON MÁS ACTIVIDAD
SELECT 
    'CHATS MÁS ACTIVOS' as seccion,
    wc.id,
    wc.phone,
    wc.name,
    COUNT(wm.id) as total_mensajes,
    MAX(wm.created_at) as ultimo_mensaje,
    wc.last_message_time
FROM whatsapp_chats wc
LEFT JOIN whatsapp_messages wm ON wm.chat_id = wc.id
GROUP BY wc.id, wc.phone, wc.name, wc.last_message_time
ORDER BY COUNT(wm.id) DESC, MAX(wm.created_at) DESC
LIMIT 10;

-- 10. VERIFICAR whatsapp_conversations (si existe)
SELECT 
    'whatsapp_conversations (si existe)' as seccion,
    COUNT(*) as total_conversaciones
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'whatsapp_conversations';

-- Si existe, mostrar datos
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'whatsapp_conversations'
    ) THEN
        RAISE NOTICE 'Tabla whatsapp_conversations existe';
    ELSE
        RAISE NOTICE 'Tabla whatsapp_conversations NO existe';
    END IF;
END $$;

-- 11. VERIFICAR POLÍTICAS RLS
SELECT 
    'POLÍTICAS RLS' as seccion,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename IN ('whatsapp_chats', 'whatsapp_messages')
ORDER BY tablename, policyname;

-- 12. RESUMEN FINAL
SELECT 
    'RESUMEN FINAL' as seccion,
    CASE 
        WHEN (SELECT COUNT(*) FROM whatsapp_chats) = 0 THEN '❌ NO HAY CHATS'
        WHEN (SELECT COUNT(*) FROM whatsapp_messages) = 0 THEN '⚠️ HAY CHATS PERO NO MENSAJES'
        WHEN EXISTS (
            SELECT 1 FROM whatsapp_messages wm
            LEFT JOIN whatsapp_chats wc ON wc.id = wm.chat_id
            WHERE wc.id IS NULL
        ) THEN '⚠️ HAY MENSAJES SIN CHAT VÁLIDO'
        ELSE '✅ ESTRUCTURA CORRECTA'
    END as estado_general,
    (SELECT COUNT(*) FROM whatsapp_chats) as total_chats,
    (SELECT COUNT(*) FROM whatsapp_messages) as total_mensajes,
    (SELECT COUNT(*) FROM whatsapp_messages WHERE chat_id IS NULL) as mensajes_sin_chat_id;
