-- Script para verificar la estructura de la tabla whatsapp_messages en Supabase
-- Ejecuta esto en el SQL Editor de Supabase

-- Ver estructura de la tabla
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'whatsapp_messages'
ORDER BY ordinal_position;

-- Ver si hay alguna tabla relacionada con chat_id
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE column_name LIKE '%chat%' OR column_name LIKE '%message%'
ORDER BY table_name, ordinal_position;


