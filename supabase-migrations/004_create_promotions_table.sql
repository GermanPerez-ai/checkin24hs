-- ============================================
-- Crear tabla de promociones
-- ============================================

-- Crear tabla promotions
CREATE TABLE IF NOT EXISTS promotions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100),
    description TEXT,
    discount DECIMAL(5,2) DEFAULT 0,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'expired')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_promotions_hotel_id ON promotions(hotel_id);
CREATE INDEX IF NOT EXISTS idx_promotions_status ON promotions(status);
CREATE INDEX IF NOT EXISTS idx_promotions_dates ON promotions(start_date, end_date);

-- Crear función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_promotions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger para actualizar updated_at
DROP TRIGGER IF EXISTS trigger_update_promotions_updated_at ON promotions;
CREATE TRIGGER trigger_update_promotions_updated_at
    BEFORE UPDATE ON promotions
    FOR EACH ROW
    EXECUTE FUNCTION update_promotions_updated_at();

-- Habilitar Row Level Security (RLS)
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;

-- Política: Permitir lectura pública (para que el cotizador pueda leer)
CREATE POLICY "Promotions are viewable by everyone"
    ON promotions FOR SELECT
    USING (true);

-- Política: Solo usuarios autenticados pueden insertar/actualizar/eliminar
-- (Nota: Ajusta según tu sistema de autenticación)
CREATE POLICY "Promotions are insertable by authenticated users"
    ON promotions FOR INSERT
    WITH CHECK (true); -- Cambiar a auth.role() = 'authenticated' si usas autenticación

CREATE POLICY "Promotions are updatable by authenticated users"
    ON promotions FOR UPDATE
    USING (true); -- Cambiar a auth.role() = 'authenticated' si usas autenticación

CREATE POLICY "Promotions are deletable by authenticated users"
    ON promotions FOR DELETE
    USING (true); -- Cambiar a auth.role() = 'authenticated' si usas autenticación

-- Comentarios en la tabla
COMMENT ON TABLE promotions IS 'Tabla para almacenar promociones de hoteles';
COMMENT ON COLUMN promotions.hotel_id IS 'ID del hotel al que pertenece la promoción';
COMMENT ON COLUMN promotions.name IS 'Nombre de la promoción';
COMMENT ON COLUMN promotions.type IS 'Tipo de promoción (ej: "Descuento", "Paquete", etc.)';
COMMENT ON COLUMN promotions.description IS 'Descripción detallada de la promoción';
COMMENT ON COLUMN promotions.discount IS 'Porcentaje de descuento (0-100)';
COMMENT ON COLUMN promotions.start_date IS 'Fecha de inicio de la promoción';
COMMENT ON COLUMN promotions.end_date IS 'Fecha de fin de la promoción';
COMMENT ON COLUMN promotions.status IS 'Estado de la promoción: active, inactive, expired';
