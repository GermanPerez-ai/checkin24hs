-- ============================================
-- VERIFICAR SI chat_id EXISTE EN whatsapp_messages
-- ============================================

-- Verificar estructura completa de whatsapp_messages
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'whatsapp_messages'
ORDER BY ordinal_position;

-- Verificar específicamente si chat_id existe
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'whatsapp_messages' 
      AND column_name = 'chat_id'
) as chat_id_exists;

