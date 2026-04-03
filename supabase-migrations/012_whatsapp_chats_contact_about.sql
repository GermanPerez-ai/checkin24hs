-- Estado / "about" del contacto en WhatsApp (para mostrar en el dashboard)
-- Ejecutar en Supabase SQL Editor

ALTER TABLE whatsapp_chats
ADD COLUMN IF NOT EXISTS contact_about TEXT;

COMMENT ON COLUMN whatsapp_chats.contact_about IS 'Estado o descripción del perfil de WhatsApp del contacto. El servidor puede rellenarlo al recibir mensajes (Baileys profile).';
