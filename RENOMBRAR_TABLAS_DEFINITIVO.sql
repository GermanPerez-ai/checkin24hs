-- ============================================
-- SCRIPT DEFINITIVO: RENOMBRAR TABLAS A INGLÉS
-- ============================================
-- Este script renombra TODAS las tablas de español a inglés
-- Basado en la verificación real de las tablas existentes

-- Renombrar hoteles → hotels
ALTER TABLE IF EXISTS hoteles RENAME TO hotels;

-- Renombrar reservas → reservations
ALTER TABLE IF EXISTS reservas RENAME TO reservations;

-- Renombrar cotizaciones → quotes
ALTER TABLE IF EXISTS cotizaciones RENAME TO quotes;

-- Renombrar gastos → expenses
ALTER TABLE IF EXISTS gastos RENAME TO expenses;

-- Renombrar usuarios del sistema → system_users
ALTER TABLE IF EXISTS "usuarios del sistema" RENAME TO system_users;

-- Renombrar administradores del panel de control → dashboard_admins
ALTER TABLE IF EXISTS "administradores del panel de control" RENAME TO dashboard_admins;

-- ============================================
-- ¡LISTO! Todas las tablas ahora tienen nombres en inglés
-- ============================================
-- Después de ejecutar, verifica con:
-- SELECT table_name FROM information_schema.tables 
-- WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
-- ORDER BY table_name;
-- ============================================

