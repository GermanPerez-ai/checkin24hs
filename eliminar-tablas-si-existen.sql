-- ============================================
-- SCRIPT PARA ELIMINAR TABLAS EXISTENTES
-- ============================================
-- ⚠️ ATENCIÓN: Este script ELIMINARÁ todas las tablas y sus datos
-- Solo úsalo si quieres empezar desde cero

-- Eliminar tablas en orden (respetando dependencias)
DROP TABLE IF EXISTS reservations CASCADE;
DROP TABLE IF EXISTS quotes CASCADE;
DROP TABLE IF EXISTS expenses CASCADE;
DROP TABLE IF EXISTS system_users CASCADE;
DROP TABLE IF EXISTS dashboard_admins CASCADE;
DROP TABLE IF EXISTS hotels CASCADE;
DROP TABLE IF EXISTS hoteles CASCADE; -- Por si existe con nombre en español

-- Eliminar índices si existen
DROP INDEX IF EXISTS idx_reservations_hotel;
DROP INDEX IF EXISTS idx_reservations_status;
DROP INDEX IF EXISTS idx_reservations_checkin;
DROP INDEX IF EXISTS idx_quotes_status;
DROP INDEX IF EXISTS idx_expenses_date;
DROP INDEX IF EXISTS idx_expenses_type;

-- ============================================
-- ¡LISTO! Todas las tablas han sido eliminadas
-- Ahora puedes ejecutar create-tables-safe.sql
-- ============================================

