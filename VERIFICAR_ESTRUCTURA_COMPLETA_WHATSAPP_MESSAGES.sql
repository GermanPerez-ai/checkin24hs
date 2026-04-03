-- ============================================
-- VERIFICAR ESTRUCTURA COMPLETA DE whatsapp_messages
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- 1. Ver TODAS las columnas de la tabla con sus propiedades
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

-- 2. Verificar qué columnas son NOT NULL (requeridas)
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'whatsapp_messages'
  AND is_nullable = 'NO'
ORDER BY column_name;

-- 3. Verificar constraints (foreign keys, etc.)
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
  AND tc.table_name = 'whatsapp_messages';

-- 4. Verificar índices
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'whatsapp_messages';

-- 5. Ver un ejemplo de registro (si hay datos)
SELECT *
FROM whatsapp_messages
LIMIT 1;
