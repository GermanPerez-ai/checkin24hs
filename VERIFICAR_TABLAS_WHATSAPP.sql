-- Script para verificar el estado de las tablas de WhatsApp en Supabase

-- 1. Verificar si la tabla whatsapp_messages existe y su estructura
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'whatsapp_messages'
ORDER BY ordinal_position;

-- 2. Contar total de mensajes (debería ser 0 según tu consulta)
SELECT COUNT(*) as total_mensajes FROM whatsapp_messages;

-- 3. Verificar si hay chats en whatsapp_chats
SELECT COUNT(*) as total_chats FROM whatsapp_chats;

-- 4. Ver algunos chats de ejemplo
SELECT id, phone, name, last_message, last_message_time, created_at
FROM whatsapp_chats
ORDER BY last_message_time DESC
LIMIT 10;

-- 5. Verificar si hay alguna otra tabla relacionada con mensajes
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%whatsapp%' 
OR table_name LIKE '%message%'
ORDER BY table_name;

-- 6. Verificar la estructura de whatsapp_chats
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'whatsapp_chats'
ORDER BY ordinal_position;


