-- ============================================
-- AGREGAR CAMPOS DE PROMOCIÓN A LA TABLA QUOTES
-- ============================================
-- Ejecuta este script en el SQL Editor de Supabase

-- Agregar campo para el ID de la promoción seleccionada
ALTER TABLE quotes 
ADD COLUMN IF NOT EXISTS selected_promotion_id VARCHAR(255);

-- Agregar campo para el nombre de la promoción seleccionada
ALTER TABLE quotes 
ADD COLUMN IF NOT EXISTS selected_promotion_name VARCHAR(255);

-- Agregar comentarios a las columnas para documentación
COMMENT ON COLUMN quotes.selected_promotion_id IS 'ID de la promoción seleccionada por el cliente al solicitar la cotización';
COMMENT ON COLUMN quotes.selected_promotion_name IS 'Nombre de la promoción seleccionada por el cliente al solicitar la cotización';

-- Verificar que las columnas se agregaron correctamente
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'quotes' 
  AND column_name IN ('selected_promotion_id', 'selected_promotion_name');
