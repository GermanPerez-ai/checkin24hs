-- Columna sent_at en quotes (fecha/hora de envío al cliente por WhatsApp).
-- El dashboard actualiza status='enviado' y sent_at al usar "Guardar y Enviar al Cliente".
ALTER TABLE quotes
ADD COLUMN IF NOT EXISTS sent_at TIMESTAMPTZ;

COMMENT ON COLUMN quotes.sent_at IS 'Fecha y hora en que se envió la cotización al cliente (p. ej. por WhatsApp).';
