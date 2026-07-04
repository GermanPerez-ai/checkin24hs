-- Message Lock Flor: evita "ghost replies" (reprocesar el mismo message_id).
-- El servidor compara flor_last_processed_inbound_id antes de llamar a Gemini.

ALTER TABLE whatsapp_chats
ADD COLUMN IF NOT EXISTS flor_last_processed_inbound_id TEXT;

COMMENT ON COLUMN whatsapp_chats.flor_last_processed_inbound_id IS
'Último message_id entrante de WhatsApp ya respondido por Flor en este chat. Si coincide con un nuevo inbound, no se dispara segunda respuesta.';
