-- ============================================
-- MIGRACIÓN: Agregar columna CODE a tabla QUOTES
-- Ejecutar en Supabase SQL Editor
-- ============================================
-- Esta migración agrega la columna 'code' a la tabla quotes
-- para almacenar códigos únicos de 5 caracteres (2 números + 3 letras mayúsculas)

-- Agregar columna code si no existe
ALTER TABLE quotes 
ADD COLUMN IF NOT EXISTS code VARCHAR(5);

-- Crear índice único para asegurar que los códigos sean únicos
CREATE UNIQUE INDEX IF NOT EXISTS idx_quotes_code ON quotes(code) WHERE code IS NOT NULL;

-- Crear índice para búsquedas rápidas por código
CREATE INDEX IF NOT EXISTS idx_quotes_code_search ON quotes(code);

-- Comentario de la columna
COMMENT ON COLUMN quotes.code IS 'Código único de 5 caracteres (2 números + 3 letras mayúsculas) para identificar cotizaciones';
