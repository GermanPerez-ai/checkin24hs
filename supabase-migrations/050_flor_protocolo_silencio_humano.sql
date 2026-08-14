-- Protocolo de Silencio Flor: intervención humana agnóstica al origen (WhatsApp app, /api/send, dashboard).
-- El servidor compara last_human_outbound_at + flor_paused_until con FLOR_SILENCE_MINUTES (default 30).

ALTER TABLE whatsapp_chats
ADD COLUMN IF NOT EXISTS last_human_outbound_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN whatsapp_chats.last_human_outbound_at IS
  'Último mensaje saliente de un humano (cualquier canal). Flor calla si now() - esto < FLOR_SILENCE_MINUTES.';

ALTER TABLE whatsapp_messages
ADD COLUMN IF NOT EXISTS is_from_flor BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN whatsapp_messages.is_from_flor IS
  'true si el mensaje saliente lo envió Flor IA; false si lo envió un humano (dashboard, móvil, API).';
