-- ============================================
-- VERIFICACIÓN DE DATOS EN SUPABASE
-- ============================================
-- Este script verifica que haya datos en Supabase
-- y muestra estadísticas de chats, mensajes e interacciones
-- ============================================

-- 1. Verificar estructura de las tablas primero
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name IN ('whatsapp_chats', 'whatsapp_messages', 'flor_interactions')
ORDER BY table_name, ordinal_position;

-- 2. Contar registros en cada tabla (versión simple)
SELECT 
    'whatsapp_chats' as tabla,
    COUNT(*) as total_registros,
    MAX(created_at) as registro_mas_reciente
FROM whatsapp_chats

UNION ALL

SELECT 
    'whatsapp_messages' as tabla,
    COUNT(*) as total_registros,
    MAX(created_at) as registro_mas_reciente
FROM whatsapp_messages

UNION ALL

SELECT 
    'flor_interactions' as tabla,
    COUNT(*) as total_registros,
    MAX(created_at) as registro_mas_reciente
FROM flor_interactions

ORDER BY tabla;

-- 3. Últimos 5 chats (ejecutar solo si las columnas existen según la consulta 1)
-- Descomenta y ajusta según la estructura de tu tabla
/*
SELECT 
    id,
    created_at
    -- Agrega aquí las columnas que veas en la consulta 1
FROM whatsapp_chats
ORDER BY created_at DESC
LIMIT 5;
*/

-- 4. Últimos 10 mensajes (ejecutar solo si las columnas existen según la consulta 1)
-- Descomenta y ajusta según la estructura de tu tabla
/*
SELECT 
    id,
    created_at
    -- Agrega aquí las columnas que veas en la consulta 1
FROM whatsapp_messages
ORDER BY created_at DESC
LIMIT 10;
*/

-- 5. Últimas 10 interacciones (ejecutar solo si las columnas existen según la consulta 1)
-- Descomenta y ajusta según la estructura de tu tabla
/*
SELECT 
    id,
    created_at
    -- Agrega aquí las columnas que veas en la consulta 1
FROM flor_interactions
ORDER BY created_at DESC
LIMIT 10;
*/

-- 7. Verificar RLS habilitado
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_habilitado
FROM pg_tables
WHERE schemaname = 'public' 
  AND tablename IN ('whatsapp_chats', 'whatsapp_messages', 'flor_interactions')
ORDER BY tablename;

-- 8. Verificar políticas RLS
SELECT 
    tablename,
    COUNT(*) as total_politicas,
    COUNT(CASE WHEN cmd = 'SELECT' THEN 1 END) as select_policies,
    COUNT(CASE WHEN cmd = 'INSERT' THEN 1 END) as insert_policies,
    COUNT(CASE WHEN cmd = 'UPDATE' THEN 1 END) as update_policies,
    COUNT(CASE WHEN cmd = 'DELETE' THEN 1 END) as delete_policies
FROM pg_policies
WHERE tablename IN ('whatsapp_chats', 'whatsapp_messages', 'flor_interactions')
GROUP BY tablename
ORDER BY tablename;

