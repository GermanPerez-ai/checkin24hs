-- ============================================
-- SCRIPT COMPLETO: RENOMBRAR TODAS LAS TABLAS A INGLÉS
-- ============================================
-- Este script renombra TODAS las tablas de español a inglés
-- Los nombres en inglés son los que espera el código JavaScript

-- Renombrar hoteles → hotels
ALTER TABLE IF EXISTS hoteles RENAME TO hotels;

-- Renombrar reservas → reservations
ALTER TABLE IF EXISTS reservas RENAME TO reservations;

-- Renombrar presupuestos → quotes (o cotizaciones si existe)
ALTER TABLE IF EXISTS presupuestos RENAME TO quotes;
ALTER TABLE IF EXISTS cotizaciones RENAME TO quotes;

-- Renombrar gastos → expenses (también corrige "costs" si existe)
ALTER TABLE IF EXISTS gastos RENAME TO expenses;
ALTER TABLE IF EXISTS costs RENAME TO expenses;

-- Renombrar usuarios_del_sistema → system_users
ALTER TABLE IF EXISTS usuarios_del_sistema RENAME TO system_users;

-- Renombrar administradores del panel de control → dashboard_admins
ALTER TABLE IF EXISTS "administradores del panel de control" RENAME TO dashboard_admins;

-- Verificar nombres finales esperados (esto no hace cambios, solo para referencia)
-- Las tablas deberían llamarse ahora:
-- hotels, reservations, quotes, expenses, system_users, dashboard_admins

-- ============================================
-- ¡LISTO! Todas las tablas ahora tienen nombres en inglés
-- ============================================

