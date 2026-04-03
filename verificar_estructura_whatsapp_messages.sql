-- ============================================
-- VERIFICAR ESTRUCTURA DE whatsapp_messages
-- ============================================
-- Este script verifica la estructura actual
-- y muestra qué columnas tiene la tabla
-- ============================================

-- 1. Ver todas las columnas de whatsapp_messages
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'whatsapp_messages'
ORDER BY ordinal_position;

-- 2. Verificar si existen las columnas que el código espera
SELECT 
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'phone') as phone_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'message') as message_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'chat_id') as chat_id_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'message_type') as message_type_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'is_from_me') as is_from_me_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'whatsapp_instance') as whatsapp_instance_exists;

-- 3. Verificar columnas que aparecen en la imagen (conversation_id, external_id, etc.)
SELECT 
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'conversation_id') as conversation_id_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'external_id') as external_id_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'direction') as direction_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'sender') as sender_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'recipient') as recipient_exists;

-- 4. Contar registros
SELECT COUNT(*) as total_mensajes FROM whatsapp_messages;

