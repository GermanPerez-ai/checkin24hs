-- ============================================
-- SCRIPT SIMPLE Y DIRECTO: RENOMBRAR TABLAS
-- ============================================
-- Este script renombra las tablas de forma directa
-- Sin bloques DO, solo ALTER TABLE simple

-- Renombrar hoteles → hotels
ALTER TABLE hoteles RENAME TO hotels;

-- Renombrar reservas → reservations  
ALTER TABLE reservas RENAME TO reservations;

-- Renombrar cotizaciones → quotes
ALTER TABLE cotizaciones RENAME TO quotes;

-- Renombrar gastos → expenses
ALTER TABLE gastos RENAME TO expenses;

-- Renombrar usuarios del sistema → system_users
-- Nota: Para tablas con espacios, usamos comillas dobles
ALTER TABLE "usuarios del sistema" RENAME TO system_users;

-- Renombrar administradores del panel de control → dashboard_admins
-- Nota: Para tablas con espacios, usamos comillas dobles
ALTER TABLE "administradores del panel de control" RENAME TO dashboard_admins;

-- ============================================
-- ¡LISTO! Ejecuta este script completo
-- ============================================
-- Si alguna tabla da error porque no existe, ignóralo
-- Luego ejecuta el script de verificación
-- ============================================

