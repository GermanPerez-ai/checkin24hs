-- ============================================
-- VERIFICACIÓN SIMPLE DE DATOS EN SUPABASE
-- ============================================
-- Versión simplificada que no requiere todas las columnas
-- ============================================

-- 1. Contar registros en cada tabla (sin usar columnas que puedan no existir)
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

-- 2. Verificar estructura de las tablas
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name IN ('whatsapp_chats', 'whatsapp_messages', 'flor_interactions')
ORDER BY table_name, ordinal_position;

-- 3. Últimos 5 chats (si la tabla existe y tiene datos)
SELECT 
    id,
    created_at,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_chats' AND column_name = 'phone')
        THEN phone
        ELSE 'N/A' 
    END as phone,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_chats' AND column_name = 'last_message')
        THEN LEFT(last_message, 50)
        ELSE 'N/A' 
    END as last_message
FROM whatsapp_chats
ORDER BY created_at DESC
LIMIT 5;

-- 4. Últimos 10 mensajes (si la tabla existe y tiene datos)
SELECT 
    id,
    created_at,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_messages' AND column_name = 'message')
        THEN LEFT(message, 50)
        ELSE 'N/A' 
    END as mensaje_preview
FROM whatsapp_messages
ORDER BY created_at DESC
LIMIT 10;

-- 5. Últimas 10 interacciones (si la tabla existe y tiene datos)
SELECT 
    id,
    created_at,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flor_interactions' AND column_name = 'intent')
        THEN intent
        ELSE 'N/A' 
    END as intent
FROM flor_interactions
ORDER BY created_at DESC
LIMIT 10;

-- 6. Verificar RLS habilitado
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_habilitado
FROM pg_tables
WHERE schemaname = 'public' 
  AND tablename IN ('whatsapp_chats', 'whatsapp_messages', 'flor_interactions')
ORDER BY tablename;

-- 7. Verificar políticas RLS
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

