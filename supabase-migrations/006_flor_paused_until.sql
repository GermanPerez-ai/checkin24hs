-- Flor IA: pausar por 20 minutos cuando un asesor envía mensaje/audio desde el dashboard
-- El servidor WhatsApp no responderá con Flor hasta que pase flor_paused_until

ALTER TABLE whatsapp_chats
ADD COLUMN IF NOT EXISTS flor_paused_until TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN whatsapp_chats.flor_paused_until IS 'Si es mayor que NOW(), Flor IA no responde en este chat (ej. asesor tomó la conversación). Se actualiza al enviar mensaje/audio desde el dashboard.';
