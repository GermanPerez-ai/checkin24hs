-- Canal de origen del contacto para cotizaciones (Instagram, Facebook, WhatsApp, web, etc.)
-- Usado en "Guardar y Enviar al Cliente" para indicar por dónde enviar si falla el chat interno.
ALTER TABLE quotes
ADD COLUMN IF NOT EXISTS contact_origin TEXT;

COMMENT ON COLUMN quotes.contact_origin IS 'Canal por el que llegó el cliente: instagram, facebook, whatsapp, web, etc.';
