-- ============================================
-- SCRIPT PARA RENOMBRAR TABLAS DE ESPAÑOL A INGLÉS
-- ============================================
-- Este script renombra las tablas existentes para que coincidan
-- con los nombres que espera el código JavaScript

-- Renombrar hoteles → hotels
ALTER TABLE IF EXISTS hoteles RENAME TO hotels;

-- Renombrar reservas → reservations
ALTER TABLE IF EXISTS reservas RENAME TO reservations;

-- Renombrar cotizaciones → quotes
ALTER TABLE IF EXISTS cotizaciones RENAME TO quotes;

-- Renombrar gastos → expenses
ALTER TABLE IF EXISTS gastos RENAME TO expenses;

-- Renombrar usuarios_del_sistema → system_users
ALTER TABLE IF EXISTS usuarios_del_sistema RENAME TO system_users;

-- dashboard_admins ya está bien, no necesita renombrarse

-- ============================================
-- ¡LISTO! Las tablas ahora tienen nombres en inglés
-- ============================================

