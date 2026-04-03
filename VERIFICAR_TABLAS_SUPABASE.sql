-- ============================================
-- VERIFICAR TABLAS EN SUPABASE
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- 1. Verificar que flor_interactions existe
SELECT 
    'flor_interactions' as tabla,
    CASE 
        WHEN EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'flor_interactions'
        ) THEN '✅ EXISTE'
        ELSE '❌ NO EXISTE'
    END as estado;

-- 2. Verificar estructura de flor_interactions
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'flor_interactions'
ORDER BY ordinal_position;

-- 3. Contar interacciones
SELECT 
    COUNT(*) as total_interacciones,
    COUNT(DISTINCT phone) as usuarios_unicos,
    MIN(created_at) as primera_interaccion,
    MAX(created_at) as ultima_interaccion
FROM flor_interactions;

-- 4. Ver últimas 10 interacciones
SELECT 
    id,
    phone,
    LEFT(user_message, 50) as mensaje_preview,
    LEFT(bot_response, 50) as respuesta_preview,
    intent,
    success,
    used_ai,
    created_at
FROM flor_interactions
ORDER BY created_at DESC
LIMIT 10;

-- 5. Verificar si hay tablas antiguas del CRM
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

-- 6. Verificar whatsapp_chats
SELECT 
    'whatsapp_chats' as tabla,
    COUNT(*) as total_chats,
    COUNT(DISTINCT phone) as numeros_unicos
FROM whatsapp_chats;

-- 7. Verificar whatsapp_messages
SELECT 
    'whatsapp_messages' as tabla,
    COUNT(*) as total_mensajes,
    COUNT(DISTINCT phone) as numeros_unicos
FROM whatsapp_messages;

-- 8. Verificar Row Level Security (RLS)
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename IN ('flor_interactions', 'whatsapp_chats', 'whatsapp_messages')
ORDER BY tablename, policyname;
