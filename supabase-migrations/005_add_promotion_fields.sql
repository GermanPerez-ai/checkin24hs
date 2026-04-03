-- ============================================
-- Agregar campos adicionales a la tabla promotions
-- ============================================
-- Ejecutar después de 004_create_promotions_table.sql

-- Agregar campo de precio promocional
ALTER TABLE promotions
ADD COLUMN IF NOT EXISTS promotional_price DECIMAL(10,2);

-- Agregar campos de fecha de viaje (intervalo para reservas)
ALTER TABLE promotions
ADD COLUMN IF NOT EXISTS travel_start_date DATE;

ALTER TABLE promotions
ADD COLUMN IF NOT EXISTS travel_end_date DATE;

-- Crear índice para las fechas de viaje
CREATE INDEX IF NOT EXISTS idx_promotions_travel_dates ON promotions(travel_start_date, travel_end_date);

-- Comentarios para los nuevos campos
COMMENT ON COLUMN promotions.promotional_price IS 'Precio promocional fijo (si aplica, en lugar de porcentaje de descuento)';
COMMENT ON COLUMN promotions.travel_start_date IS 'Fecha desde la cual se puede viajar/reservar con esta promoción';
COMMENT ON COLUMN promotions.travel_end_date IS 'Fecha hasta la cual se puede viajar/reservar con esta promoción';
