-- ============================================
-- MULTI-CANAL: Web, Instagram, Facebook, TikTok
-- Mismos chats/mensajes, canal identificado por columna channel
-- ============================================

-- whatsapp_chats: canal (whatsapp | web | instagram | facebook | tiktok) y nombre para mostrar
ALTER TABLE whatsapp_chats
  ADD COLUMN IF NOT EXISTS channel TEXT DEFAULT 'whatsapp',
  ADD COLUMN IF NOT EXISTS display_name TEXT;

-- Para chats existentes sin channel, marcar como whatsapp
UPDATE whatsapp_chats SET channel = 'whatsapp' WHERE channel IS NULL;

-- Índice para buscar por canal + phone (ej. web + session_id)
CREATE INDEX IF NOT EXISTS idx_whatsapp_chats_channel_phone
  ON whatsapp_chats(channel, phone);

-- whatsapp_messages: canal para filtrar por origen
ALTER TABLE whatsapp_messages
  ADD COLUMN IF NOT EXISTS channel TEXT DEFAULT 'whatsapp';

UPDATE whatsapp_messages SET channel = 'whatsapp' WHERE channel IS NULL;

CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_channel
  ON whatsapp_messages(channel);

-- Comentarios para documentación
COMMENT ON COLUMN whatsapp_chats.channel IS 'whatsapp | web | instagram | facebook | tiktok';
COMMENT ON COLUMN whatsapp_chats.display_name IS 'Nombre para mostrar en dashboard (ej. Visitante web, Usuario Instagram)';
COMMENT ON COLUMN whatsapp_messages.channel IS 'Mismo canal que el chat al que pertenece el mensaje';
