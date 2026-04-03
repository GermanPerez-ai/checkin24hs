-- Columna hotel_name en quotes: guardar el nombre del hotel que eligió el cliente
-- Evita que en "Detalles de Cotización" se muestre otro hotel por resolución errónea de hotel_id.
-- ============================================

ALTER TABLE quotes
ADD COLUMN IF NOT EXISTS hotel_name VARCHAR(255);

COMMENT ON COLUMN quotes.hotel_name IS 'Nombre del hotel elegido por el cliente al solicitar la cotización (evita confusión con hotel_id).';
