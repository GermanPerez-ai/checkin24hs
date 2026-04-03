-- ============================================
-- VERIFICAR ESTRUCTURA REAL DE whatsapp_messages
-- Ejecutar en Supabase SQL Editor
-- Este script muestra EXACTAMENTE qué columnas tiene la tabla
-- ============================================

-- 1. Ver TODAS las columnas con sus propiedades completas
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'whatsapp_messages'
ORDER BY ordinal_position;

-- 2. Columnas REQUERIDAS (NOT NULL sin default)
SELECT 
    column_name,
    data_type,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'whatsapp_messages'
  AND is_nullable = 'NO'
  AND column_default IS NULL
ORDER BY column_name;

-- 3. Columnas OPCIONALES (NULL permitido o con default)
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'whatsapp_messages'
  AND (is_nullable = 'YES' OR column_default IS NOT NULL)
ORDER BY column_name;

-- 4. Verificar columnas específicas que hemos visto en errores
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'id') THEN '✅' ELSE '❌' END as id,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'conversation_id') THEN '✅' ELSE '❌' END as conversation_id,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'external_id') THEN '✅' ELSE '❌' END as external_id,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'direction') THEN '✅' ELSE '❌' END as direction,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'sender') THEN '✅' ELSE '❌' END as sender,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'phone') THEN '✅' ELSE '❌' END as phone,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'message') THEN '✅' ELSE '❌' END as message,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'chat_id') THEN '✅' ELSE '❌' END as chat_id,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'is_from_me') THEN '✅' ELSE '❌' END as is_from_me,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'whatsapp_instance') THEN '✅' ELSE '❌' END as whatsapp_instance,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'created_at') THEN '✅' ELSE '❌' END as created_at;

-- 5. Ver un ejemplo de registro si existe (para ver qué columnas tienen datos)
SELECT *
FROM whatsapp_messages
LIMIT 1;
