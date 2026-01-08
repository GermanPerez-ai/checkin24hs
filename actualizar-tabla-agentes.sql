-- ============================================
-- ACTUALIZAR TABLA AGENTS CON COLUMNAS FALTANTES
-- ============================================
-- Ejecuta este SQL en el Editor SQL de Supabase

-- Agregar columna 'code' si no existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'agents' AND column_name = 'code') THEN
        ALTER TABLE agents ADD COLUMN code VARCHAR(50);
    END IF;
END $$;

-- Agregar columna 'agency' si no existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'agents' AND column_name = 'agency') THEN
        ALTER TABLE agents ADD COLUMN agency VARCHAR(255);
    END IF;
END $$;

-- Agregar columna 'active' si no existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'agents' AND column_name = 'active') THEN
        ALTER TABLE agents ADD COLUMN active BOOLEAN DEFAULT true;
    END IF;
END $$;

-- Agregar columna 'commission_rate' si no existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'agents' AND column_name = 'commission_rate') THEN
        ALTER TABLE agents ADD COLUMN commission_rate DECIMAL(5,2) DEFAULT 0;
    END IF;
END $$;

-- Agregar columna 'created_at' si no existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'agents' AND column_name = 'created_at') THEN
        ALTER TABLE agents ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Agregar columna 'updated_at' si no existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'agents' AND column_name = 'updated_at') THEN
        ALTER TABLE agents ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Actualizar registros existentes: copiar 'role' a 'agency' si agency está vacío
UPDATE agents 
SET agency = role 
WHERE agency IS NULL AND role IS NOT NULL;

-- Generar códigos automáticos para agentes que no tienen código
UPDATE agents 
SET code = 'AGT-2025-' || LPAD(ROW_NUMBER() OVER (ORDER BY created_at, id)::TEXT, 3, '0')
WHERE code IS NULL;

-- Asegurar que active sea true para todos los activos
UPDATE agents 
SET active = true 
WHERE status = 'Activo' AND (active IS NULL OR active = false);

UPDATE agents 
SET active = false 
WHERE status = 'Inactivo';

-- ============================================
-- ¡LISTO! Tabla actualizada
-- ============================================
SELECT 'Tabla agents actualizada correctamente' as resultado;

