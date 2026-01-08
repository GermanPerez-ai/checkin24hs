-- ============================================
-- SCRIPT SQL PARA CREAR TABLAS EN SUPABASE
-- ============================================
-- Copia y pega este código en el SQL Editor de Supabase

-- Tabla de Hoteles
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

-- Tabla de Reservas
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

-- Tabla de Cotizaciones
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

-- Tabla de Gastos
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'fixed' o 'variable'
    category VARCHAR(100),
    subcategory VARCHAR(100),
    description TEXT,
    amount DECIMAL(10,2) NOT NULL,
    exchange_rate DECIMAL(10,4),
    usd_amount DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Usuarios del Sistema
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

-- Tabla de Administradores del Dashboard
CREATE TABLE dashboard_admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    role VARCHAR(50) DEFAULT 'usuario', -- 'admin_total' o 'usuario'
    status VARCHAR(50) DEFAULT 'active',
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Agentes
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

-- Índices para mejor rendimiento
CREATE INDEX idx_reservations_hotel ON reservations(hotel_id);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_reservations_checkin ON reservations(check_in);
CREATE INDEX idx_quotes_status ON quotes(status);
CREATE INDEX idx_expenses_date ON expenses(date);
CREATE INDEX idx_expenses_type ON expenses(type);
CREATE INDEX idx_agents_status ON agents(status);
CREATE INDEX idx_agents_agency ON agents(agency);

-- Políticas de seguridad básicas (Row Level Security)
-- Por ahora, permitimos acceso público (ajusta según tus necesidades)

-- Activar RLS (Row Level Security) - Opcional por ahora
-- ALTER TABLE hotels ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE system_users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE dashboard_admins ENABLE ROW LEVEL SECURITY;

-- Políticas: Permite lectura y escritura pública (ajusta según necesites)
-- CREATE POLICY "Public read access" ON hotels FOR SELECT USING (true);
-- CREATE POLICY "Public write access" ON hotels FOR INSERT WITH CHECK (true);
-- CREATE POLICY "Public update access" ON hotels FOR UPDATE USING (true);
-- CREATE POLICY "Public delete access" ON hotels FOR DELETE USING (true);

-- Repetir para otras tablas según necesites

-- ============================================
-- ¡LISTO! Las tablas han sido creadas
-- ============================================

