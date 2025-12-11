-- ============================================
-- SCRIPT SQL PARA AGREGAR TABLA DE AGENTES
-- ============================================
-- Ejecuta este SQL en el Editor SQL de Supabase
-- si ya tienes las otras tablas creadas

-- Verificar si la tabla ya existe antes de crearla
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'agents') THEN
        -- Crear tabla de Agentes
        CREATE TABLE agents (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            code VARCHAR(50) UNIQUE NOT NULL,
            name VARCHAR(255) NOT NULL,
            agency VARCHAR(255),
            status VARCHAR(50) DEFAULT 'Activo',
            active BOOLEAN DEFAULT true,
            commission_rate DECIMAL(5,2) DEFAULT 0,
            notes TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Crear índices
        CREATE INDEX idx_agents_status ON agents(status);
        CREATE INDEX idx_agents_agency ON agents(agency);
        
        RAISE NOTICE 'Tabla agents creada exitosamente';
    ELSE
        RAISE NOTICE 'La tabla agents ya existe';
    END IF;
END $$;

-- Habilitar tiempo real para la tabla agents
-- (Necesario para que funcionen las suscripciones en tiempo real)
ALTER PUBLICATION supabase_realtime ADD TABLE agents;

-- ============================================
-- IMPORTANTE: Configurar permisos de acceso
-- ============================================
-- Si no tienes RLS habilitado, puedes saltar esta parte.
-- Si lo tienes habilitado, agrega estas políticas:

-- ALTER TABLE agents ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "Public read access" ON agents FOR SELECT USING (true);
-- CREATE POLICY "Public insert access" ON agents FOR INSERT WITH CHECK (true);
-- CREATE POLICY "Public update access" ON agents FOR UPDATE USING (true);
-- CREATE POLICY "Public delete access" ON agents FOR DELETE USING (true);

-- ============================================
-- ¡LISTO! La tabla de agentes ha sido creada
-- ============================================

