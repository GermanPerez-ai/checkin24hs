-- ============================================
-- SCRIPT PARA SOLO VERIFICAR EL ESTADO DE LAS TABLAS
-- ============================================
-- Este script SOLO VERIFICA, NO hace cambios
-- Úsalo para ver qué tablas existen y cuáles faltan
--
-- INSTRUCCIONES:
-- 1. Abre Supabase Dashboard
-- 2. Ve a "SQL Editor"
-- 3. Pega este script
-- 4. Haz clic en "Run"
-- ============================================

-- Verificar qué tablas existen
SELECT 
    table_name as "Tabla",
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = t.table_name
        ) THEN '✅ Existe'
        ELSE '❌ No existe'
    END as "Estado",
    (
        SELECT COUNT(*)::text 
        FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = t.table_name
    ) as "Columnas"
FROM (
    VALUES 
        ('hotels'),
        ('reservations'),
        ('quotes'),
        ('expenses'),
        ('system_users'),
        ('dashboard_admins'),
        ('agents'),
        ('users'),
        ('system_config')
) AS t(table_name)
ORDER BY t.table_name;

-- Verificar columnas de cada tabla (si existe)
SELECT 
    table_name as "Tabla",
    column_name as "Columna",
    data_type as "Tipo",
    is_nullable as "Nullable"
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name IN (
    'hotels', 'reservations', 'quotes', 'expenses', 
    'system_users', 'dashboard_admins', 'agents', 
    'users', 'system_config'
  )
ORDER BY table_name, ordinal_position;

-- Verificar índices
SELECT 
    tablename as "Tabla",
    indexname as "Índice",
    indexdef as "Definición"
FROM pg_indexes
WHERE schemaname = 'public' 
  AND tablename IN (
    'hotels', 'reservations', 'quotes', 'expenses', 
    'system_users', 'dashboard_admins', 'agents', 
    'users', 'system_config'
  )
ORDER BY tablename, indexname;

-- Contar registros en cada tabla (solo si existe)
SELECT 
    'hotels' as tabla,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'hotels')
        THEN (SELECT COUNT(*)::text FROM hotels)
        ELSE 'Tabla no existe'
    END as registros
UNION ALL
SELECT 'reservations', 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'reservations')
        THEN (SELECT COUNT(*)::text FROM reservations)
        ELSE 'Tabla no existe'
    END
UNION ALL
SELECT 'quotes',
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'quotes')
        THEN (SELECT COUNT(*)::text FROM quotes)
        ELSE 'Tabla no existe'
    END
UNION ALL
SELECT 'expenses',
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'expenses')
        THEN (SELECT COUNT(*)::text FROM expenses)
        ELSE 'Tabla no existe'
    END
UNION ALL
SELECT 'system_users',
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'system_users')
        THEN (SELECT COUNT(*)::text FROM system_users)
        ELSE 'Tabla no existe'
    END
UNION ALL
SELECT 'dashboard_admins',
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'dashboard_admins')
        THEN (SELECT COUNT(*)::text FROM dashboard_admins)
        ELSE 'Tabla no existe'
    END
UNION ALL
SELECT 'agents',
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'agents')
        THEN (SELECT COUNT(*)::text FROM agents)
        ELSE 'Tabla no existe'
    END
UNION ALL
SELECT 'users',
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users')
        THEN (SELECT COUNT(*)::text FROM users)
        ELSE 'Tabla no existe'
    END
UNION ALL
SELECT 'system_config',
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'system_config')
        THEN (SELECT COUNT(*)::text FROM system_config)
        ELSE 'Tabla no existe'
    END
ORDER BY tabla;

