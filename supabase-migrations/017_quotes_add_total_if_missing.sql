-- Columna total en quotes (tarifa final / monto final de la cotización).
-- El dashboard envía finalTariff -> total; sin esta columna el PATCH puede fallar.
ALTER TABLE quotes
ADD COLUMN IF NOT EXISTS total NUMERIC(12,2) DEFAULT 0;

COMMENT ON COLUMN quotes.total IS 'Monto final de la cotización (tarifa después de descuento).';
