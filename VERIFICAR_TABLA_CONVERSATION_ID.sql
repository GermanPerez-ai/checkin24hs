-- ============================================
-- VERIFICAR A QUÉ TABLA REFERENCIA conversation_id
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- 1. Ver la foreign key constraint de conversation_id
SELECT
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public'
  AND tc.table_name = 'whatsapp_messages'
  AND kcu.column_name = 'conversation_id';

-- 2. Verificar si existe la tabla whatsapp_conversations
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
      AND table_name = 'whatsapp_conversations'
) as whatsapp_conversations_exists;

-- 3. Si existe, ver su estructura
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'whatsapp_conversations'
ORDER BY ordinal_position;
