-- Columna tariff en quotes (tarifa base antes de descuento).
-- El dashboard envía tariff, discount y total; sin esta columna el PATCH devuelve 400.
ALTER TABLE quotes
ADD COLUMN IF NOT EXISTS tariff NUMERIC(12,2) DEFAULT 0;

COMMENT ON COLUMN quotes.tariff IS 'Tarifa base de la cotización (antes de descuento).';
