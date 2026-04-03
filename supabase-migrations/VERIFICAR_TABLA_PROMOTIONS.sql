-- ============================================
-- VERIFICAR SI LA TABLA PROMOTIONS EXISTE
-- ============================================
-- Ejecuta este script primero para verificar si la tabla ya existe

-- Verificar si la tabla promotions existe
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'promotions'
        ) THEN '✅ La tabla PROMOTIONS YA EXISTE'
        ELSE '❌ La tabla PROMOTIONS NO EXISTE - Puedes ejecutar el script de creación'
    END AS estado_tabla;

-- Si la tabla existe, mostrar su estructura
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'promotions'
ORDER BY ordinal_position;

-- Si la tabla existe, mostrar cuántas promociones hay
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'promotions'
        ) THEN (SELECT COUNT(*) FROM promotions)
        ELSE 0
    END AS total_promociones;

-- Verificar si existen índices
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public' 
AND tablename = 'promotions';

-- Verificar si existen políticas RLS
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname = 'public' 
AND tablename = 'promotions';
