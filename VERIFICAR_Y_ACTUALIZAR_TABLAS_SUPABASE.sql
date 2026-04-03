-- ============================================
-- SCRIPT PARA VERIFICAR Y ACTUALIZAR TABLAS EN SUPABASE
-- ============================================
-- Este script:
-- 1. Verifica qué tablas existen
-- 2. Crea las tablas que faltan
-- 3. Agrega columnas que falten a las tablas existentes
-- 4. Crea índices que falten
-- 5. NO duplica datos existentes
--
-- INSTRUCCIONES:
-- 1. Abre Supabase Dashboard (https://supabase.com/dashboard)
-- 2. Selecciona tu proyecto
-- 3. Ve a "SQL Editor" (Editor SQL)
-- 4. Pega este script completo
-- 5. Haz clic en "Run" (Ejecutar)
-- ============================================

-- ============================================
-- PASO 1: VERIFICAR TABLAS EXISTENTES
-- ============================================
DO $$
DECLARE
    table_exists BOOLEAN;
    column_exists BOOLEAN;
    index_exists BOOLEAN;
BEGIN
    RAISE NOTICE '🔍 Verificando tablas existentes...';
    
    -- ============================================
    -- TABLA: hotels
    -- ============================================
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'hotels'
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE '📦 Creando tabla: hotels';
        CREATE TABLE hotels (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            location TEXT,
            description TEXT,
            rating DECIMAL(2,1),
            price DECIMAL(10,2),
            status VARCHAR(50) DEFAULT 'Activo',
            amenities JSONB,
            images JSONB,
            coordinates JSONB,
            google_maps TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    ELSE
        RAISE NOTICE '✅ Tabla hotels ya existe, verificando columnas...';
        
        -- Verificar y agregar columnas faltantes
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'hotels' AND column_name = 'amenities'
        ) INTO column_exists;
        IF NOT column_exists THEN
            ALTER TABLE hotels ADD COLUMN amenities JSONB;
            RAISE NOTICE '  ➕ Agregada columna: amenities';
        END IF;
        
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'hotels' AND column_name = 'images'
        ) INTO column_exists;
        IF NOT column_exists THEN
            ALTER TABLE hotels ADD COLUMN images JSONB;
            RAISE NOTICE '  ➕ Agregada columna: images';
        END IF;
        
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'hotels' AND column_name = 'coordinates'
        ) INTO column_exists;
        IF NOT column_exists THEN
            ALTER TABLE hotels ADD COLUMN coordinates JSONB;
            RAISE NOTICE '  ➕ Agregada columna: coordinates';
        END IF;
        
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'hotels' AND column_name = 'google_maps'
        ) INTO column_exists;
        IF NOT column_exists THEN
            ALTER TABLE hotels ADD COLUMN google_maps TEXT;
            RAISE NOTICE '  ➕ Agregada columna: google_maps';
        END IF;
    END IF;
    
    -- ============================================
    -- TABLA: reservations
    -- ============================================
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'reservations'
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE '📦 Creando tabla: reservations';
        CREATE TABLE reservations (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            code VARCHAR(50) UNIQUE NOT NULL,
            hotel_id UUID REFERENCES hotels(id) ON DELETE SET NULL,
            customer_name VARCHAR(255),
            customer_email VARCHAR(255),
            customer_phone VARCHAR(50),
            check_in DATE,
            check_out DATE,
            adults INTEGER DEFAULT 1,
            children INTEGER DEFAULT 0,
            total_amount DECIMAL(10,2),
            status VARCHAR(50) DEFAULT 'Pendiente',
            notes TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    ELSE
        RAISE NOTICE '✅ Tabla reservations ya existe';
    END IF;
    
    -- ============================================
    -- TABLA: quotes
    -- ============================================
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'quotes'
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE '📦 Creando tabla: quotes';
        CREATE TABLE quotes (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            customer_name VARCHAR(255),
            customer_email VARCHAR(255),
            customer_phone VARCHAR(50),
            hotel_id UUID REFERENCES hotels(id) ON DELETE SET NULL,
            check_in DATE,
            check_out DATE,
            adults INTEGER DEFAULT 1,
            children INTEGER DEFAULT 0,
            total DECIMAL(10,2),
            status VARCHAR(50) DEFAULT 'Pendiente',
            notes TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    ELSE
        RAISE NOTICE '✅ Tabla quotes ya existe';
    END IF;
    
    -- ============================================
    -- TABLA: expenses
    -- ============================================
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'expenses'
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE '📦 Creando tabla: expenses';
        CREATE TABLE expenses (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            date DATE NOT NULL,
            type VARCHAR(50) NOT NULL,
            category VARCHAR(100),
            subcategory VARCHAR(100),
            description TEXT,
            amount DECIMAL(10,2) NOT NULL,
            exchange_rate DECIMAL(10,4),
            usd_amount DECIMAL(10,2),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    ELSE
        RAISE NOTICE '✅ Tabla expenses ya existe';
    END IF;
    
    -- ============================================
    -- TABLA: system_users
    -- ============================================
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'system_users'
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE '📦 Creando tabla: system_users';
        CREATE TABLE system_users (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            phone VARCHAR(50),
            status VARCHAR(50) DEFAULT 'active',
            tipo_cuenta VARCHAR(50),
            birth_day INTEGER,
            birth_month INTEGER,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    ELSE
        RAISE NOTICE '✅ Tabla system_users ya existe';
    END IF;
    
    -- ============================================
    -- TABLA: dashboard_admins
    -- ============================================
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'dashboard_admins'
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE '📦 Creando tabla: dashboard_admins';
        CREATE TABLE dashboard_admins (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            username VARCHAR(100) UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            name VARCHAR(255) NOT NULL,
            email VARCHAR(255),
            role VARCHAR(50) DEFAULT 'usuario',
            status VARCHAR(50) DEFAULT 'active',
            last_login TIMESTAMP WITH TIME ZONE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    ELSE
        RAISE NOTICE '✅ Tabla dashboard_admins ya existe';
    END IF;
    
    -- ============================================
    -- TABLA: agents
    -- ============================================
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'agents'
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE '📦 Creando tabla: agents';
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
    ELSE
        RAISE NOTICE '✅ Tabla agents ya existe';
    END IF;
    
    -- ============================================
    -- TABLA: users (alias de system_users o tabla separada)
    -- ============================================
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'users'
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE '📦 Creando tabla: users (alias de system_users)';
        CREATE TABLE users (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            phone VARCHAR(50),
            status VARCHAR(50) DEFAULT 'active',
            tipo_cuenta VARCHAR(50),
            birth_day INTEGER,
            birth_month INTEGER,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    ELSE
        RAISE NOTICE '✅ Tabla users ya existe';
    END IF;
    
    -- ============================================
    -- TABLA: system_config
    -- ============================================
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'system_config'
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE '📦 Creando tabla: system_config';
        CREATE TABLE system_config (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            key VARCHAR(255) UNIQUE NOT NULL,
            value TEXT,
            description TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    ELSE
        RAISE NOTICE '✅ Tabla system_config ya existe';
    END IF;
    
    RAISE NOTICE '✅ Verificación de tablas completada';
END $$;

-- ============================================
-- PASO 2: CREAR ÍNDICES (solo si no existen)
-- ============================================
DO $$
DECLARE
    index_exists BOOLEAN;
BEGIN
    RAISE NOTICE '🔍 Verificando índices...';
    
    -- Índices para reservations
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' AND indexname = 'idx_reservations_hotel'
    ) INTO index_exists;
    IF NOT index_exists THEN
        CREATE INDEX idx_reservations_hotel ON reservations(hotel_id);
        RAISE NOTICE '  ➕ Creado índice: idx_reservations_hotel';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' AND indexname = 'idx_reservations_status'
    ) INTO index_exists;
    IF NOT index_exists THEN
        CREATE INDEX idx_reservations_status ON reservations(status);
        RAISE NOTICE '  ➕ Creado índice: idx_reservations_status';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' AND indexname = 'idx_reservations_checkin'
    ) INTO index_exists;
    IF NOT index_exists THEN
        CREATE INDEX idx_reservations_checkin ON reservations(check_in);
        RAISE NOTICE '  ➕ Creado índice: idx_reservations_checkin';
    END IF;
    
    -- Índices para quotes
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' AND indexname = 'idx_quotes_status'
    ) INTO index_exists;
    IF NOT index_exists THEN
        CREATE INDEX idx_quotes_status ON quotes(status);
        RAISE NOTICE '  ➕ Creado índice: idx_quotes_status';
    END IF;
    
    -- Índices para expenses
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' AND indexname = 'idx_expenses_date'
    ) INTO index_exists;
    IF NOT index_exists THEN
        CREATE INDEX idx_expenses_date ON expenses(date);
        RAISE NOTICE '  ➕ Creado índice: idx_expenses_date';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' AND indexname = 'idx_expenses_type'
    ) INTO index_exists;
    IF NOT index_exists THEN
        CREATE INDEX idx_expenses_type ON expenses(type);
        RAISE NOTICE '  ➕ Creado índice: idx_expenses_type';
    END IF;
    
    -- Índices para agents
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' AND indexname = 'idx_agents_status'
    ) INTO index_exists;
    IF NOT index_exists THEN
        CREATE INDEX idx_agents_status ON agents(status);
        RAISE NOTICE '  ➕ Creado índice: idx_agents_status';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' AND indexname = 'idx_agents_agency'
    ) INTO index_exists;
    IF NOT index_exists THEN
        CREATE INDEX idx_agents_agency ON agents(agency);
        RAISE NOTICE '  ➕ Creado índice: idx_agents_agency';
    END IF;
    
    RAISE NOTICE '✅ Verificación de índices completada';
END $$;

-- ============================================
-- PASO 3: VERIFICAR Y MOSTRAR RESUMEN
-- ============================================
SELECT 
    '📊 RESUMEN DE TABLAS' as titulo,
    COUNT(*) as total_tablas
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'hotels', 'reservations', 'quotes', 'expenses', 
    'system_users', 'dashboard_admins', 'agents', 
    'users', 'system_config'
  );

-- Listar todas las tablas principales
SELECT 
    table_name as "Tabla",
    CASE 
        WHEN table_name IN (
            SELECT table_name FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name IN ('hotels', 'reservations', 'quotes', 'expenses', 'system_users', 'dashboard_admins', 'agents', 'users', 'system_config')
        ) THEN '✅ Existe'
        ELSE '❌ No existe'
    END as "Estado"
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'hotels', 'reservations', 'quotes', 'expenses', 
    'system_users', 'dashboard_admins', 'agents', 
    'users', 'system_config'
  )
ORDER BY table_name;

-- Contar registros en cada tabla (sin duplicar)
SELECT 
    'hotels' as tabla,
    COUNT(*) as registros
FROM hotels
UNION ALL
SELECT 'reservations', COUNT(*) FROM reservations
UNION ALL
SELECT 'quotes', COUNT(*) FROM quotes
UNION ALL
SELECT 'expenses', COUNT(*) FROM expenses
UNION ALL
SELECT 'system_users', COUNT(*) FROM system_users
UNION ALL
SELECT 'dashboard_admins', COUNT(*) FROM dashboard_admins
UNION ALL
SELECT 'agents', COUNT(*) FROM agents
UNION ALL
SELECT 'users', COUNT(*) FROM users
UNION ALL
SELECT 'system_config', COUNT(*) FROM system_config
ORDER BY tabla;

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
-- Si todo salió bien, deberías ver:
-- - ✅ Todas las tablas creadas o verificadas
-- - ✅ Todos los índices creados o verificados
-- - 📊 Resumen con el estado de cada tabla
-- ============================================

