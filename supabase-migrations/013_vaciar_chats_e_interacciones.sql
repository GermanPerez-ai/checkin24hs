-- ============================================
-- VACIAR CHATS E INTERACCIONES (base limpia)
-- Ejecutar en Supabase → SQL Editor
-- ============================================
-- Elimina todos los datos de:
--   - whatsapp_media (referenciada por whatsapp_messages)
--   - whatsapp_messages
--   - whatsapp_chats
--   - flor_interactions
--   - whatsapp_conversations (si existe)
-- Las tablas siguen existiendo; solo se borran los registros.
-- ============================================

-- 1. Mensajes (CASCADE vacía también whatsapp_media si tiene FK a whatsapp_messages)
TRUNCATE TABLE whatsapp_messages CASCADE;

-- 2. Chats de WhatsApp
TRUNCATE TABLE whatsapp_chats CASCADE;

-- 3. Interacciones de Flor IA
TRUNCATE TABLE flor_interactions;

-- 4. Conversaciones (tabla opcional; si no existe, ignorar el error)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'whatsapp_conversations') THEN
    EXECUTE 'TRUNCATE TABLE whatsapp_conversations';
    RAISE NOTICE 'whatsapp_conversations vaciada';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'whatsapp_conversations no existe o error: %', SQLERRM;
END $$;
