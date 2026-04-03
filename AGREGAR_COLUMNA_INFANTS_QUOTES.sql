-- ============================================
-- AGREGAR COLUMNA INFANTS A LA TABLA QUOTES
-- ============================================
-- Este script agrega la columna 'infants' a la tabla 'quotes' en Supabase
-- Copia y pega este código en el SQL Editor de Supabase

-- Verificar si la columna ya existe antes de agregarla
DO $$ 
BEGIN
    -- Intentar agregar la columna solo si no existe
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'quotes' 
        AND column_name = 'infants'
    ) THEN
        ALTER TABLE quotes 
        ADD COLUMN infants INTEGER DEFAULT 0;
        
        RAISE NOTICE '✅ Columna "infants" agregada exitosamente a la tabla "quotes"';
    ELSE
        RAISE NOTICE 'ℹ️ La columna "infants" ya existe en la tabla "quotes"';
    END IF;
END $$;

-- Verificar que la columna se agregó correctamente
SELECT 
    column_name, 
    data_type, 
    column_default,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'quotes' 
AND column_name = 'infants';
