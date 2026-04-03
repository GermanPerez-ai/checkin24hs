-- ============================================
-- Agregar campo selected_promotion_id a quotes
-- ============================================

-- Agregar columna selected_promotion_id (UUID que referencia a promotions)
ALTER TABLE quotes 
ADD COLUMN IF NOT EXISTS selected_promotion_id UUID REFERENCES promotions(id) ON DELETE SET NULL;

-- Agregar columna selected_promotion_name (VARCHAR para guardar el nombre de la promoción)
ALTER TABLE quotes 
ADD COLUMN IF NOT EXISTS selected_promotion_name VARCHAR(255);

-- Crear índice para mejorar el rendimiento de búsquedas
CREATE INDEX IF NOT EXISTS idx_quotes_selected_promotion_id ON quotes(selected_promotion_id);

-- Comentarios
COMMENT ON COLUMN quotes.selected_promotion_id IS 'ID de la promoción seleccionada por el cliente';
COMMENT ON COLUMN quotes.selected_promotion_name IS 'Nombre de la promoción seleccionada por el cliente';
