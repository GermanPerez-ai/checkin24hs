-- ============================================
-- SCRIPT PARA VERIFICAR LOS NOMBRES REALES DE LAS TABLAS
-- ============================================
-- Este script muestra los nombres REALES de las tablas en la base de datos
-- sin importar cómo se muestren en la interfaz

-- Listar todas las tablas del esquema público
SELECT 
    table_name AS "Nombre Real de la Tabla",
    table_schema AS "Esquema"
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ============================================
-- Ejecuta este script y verás los nombres REALES
-- Compara con lo que espera el código:
-- hotels, reservations, quotes, expenses, system_users, dashboard_admins
-- ============================================

