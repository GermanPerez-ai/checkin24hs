-- ============================================
-- SCRIPT DE VERIFICACIÓN: RLS Y POLÍTICAS
-- ============================================
-- Este script verifica que RLS esté habilitado
-- y que las políticas estén creadas correctamente
-- ============================================

-- Verificar RLS habilitado en todas las tablas
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public' 
  AND tablename IN (
    'whatsapp_chats',
    'whatsapp_messages', 
    'flor_interactions',
    'whatsapp_conversations',
    'whatsapp_media',
    'whatsapp_templates'
  )
ORDER BY tablename;

-- Verificar políticas creadas
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as command,
    CASE 
        WHEN qual IS NOT NULL THEN 'YES'
        ELSE 'NO'
    END as has_using_clause,
    CASE 
        WHEN with_check IS NOT NULL THEN 'YES'
        ELSE 'NO'
    END as has_with_check
FROM pg_policies
WHERE tablename IN (
    'whatsapp_chats',
    'whatsapp_messages',
    'flor_interactions',
    'whatsapp_conversations',
    'whatsapp_media',
    'whatsapp_templates'
)
ORDER BY tablename, cmd, policyname;

-- Resumen: Contar políticas por tabla
SELECT 
    tablename,
    COUNT(*) as total_policies,
    COUNT(CASE WHEN cmd = 'SELECT' THEN 1 END) as select_policies,
    COUNT(CASE WHEN cmd = 'INSERT' THEN 1 END) as insert_policies,
    COUNT(CASE WHEN cmd = 'UPDATE' THEN 1 END) as update_policies,
    COUNT(CASE WHEN cmd = 'DELETE' THEN 1 END) as delete_policies
FROM pg_policies
WHERE tablename IN (
    'whatsapp_chats',
    'whatsapp_messages',
    'flor_interactions',
    'whatsapp_conversations',
    'whatsapp_media',
    'whatsapp_templates'
)
GROUP BY tablename
ORDER BY tablename;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- Cada tabla debería tener:
-- - rls_enabled = true
-- - 4 políticas (SELECT, INSERT, UPDATE, DELETE)
-- ============================================

