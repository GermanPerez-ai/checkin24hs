-- Columna discount en quotes (monto del descuento aplicado).
-- El dashboard guarda tariff, discount y total; sin esta columna el PATCH devuelve 400.
ALTER TABLE quotes
ADD COLUMN IF NOT EXISTS discount NUMERIC(12,2) DEFAULT 0;

COMMENT ON COLUMN quotes.discount IS 'Monto del descuento aplicado a la cotización (ej. 1032.98).';
