-- ============================================
-- VERIFICAR NOMBRES DESPUÉS DEL RENOMBRADO
-- ============================================
-- Ejecuta esto para ver los nombres REALES actuales

SELECT 
    table_name AS "Nombre Real",
    table_schema AS "Esquema"
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ============================================
-- Deberías ver estos nombres en inglés:
-- dashboard_admins
-- expenses
-- hotels
-- quotes
-- reservations
-- system_users
-- ============================================

