-- Estado de sesión persistente Flor IA por chat WhatsApp
-- Sobrevive reinicios del servidor; complementa flor_paused_until (006) y last_human_outbound_at (050)

ALTER TABLE whatsapp_chats
ADD COLUMN IF NOT EXISTS current_hotel_id UUID REFERENCES public.hotels(id) ON DELETE SET NULL;

ALTER TABLE whatsapp_chats
ADD COLUMN IF NOT EXISTS cotizador_sent_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN whatsapp_chats.current_hotel_id IS
  'Hotel activo en la conversación (contexto Flor). Se actualiza al detectar consulta de otro hotel.';

COMMENT ON COLUMN whatsapp_chats.cotizador_sent_at IS
  'Primera vez que Flor envió el link cotizar.checkin24hs.com en este chat. Evita reenvíos.';

-- flor_paused_until ya existe (006_flor_paused_until.sql)
-- last_human_outbound_at ya existe (050_flor_protocolo_silencio_humano.sql)

-- Verificar:
-- SELECT id, phone, current_hotel_id, cotizador_sent_at, flor_paused_until
-- FROM whatsapp_chats ORDER BY updated_at DESC LIMIT 5;
