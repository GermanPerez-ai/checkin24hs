-- ============================================
-- SCRIPT PARA CORREGIR NOMBRES DE TABLAS
-- ============================================
-- Este script corrige los nombres incorrectos que quedaron

-- Corregir: costs → expenses (el código espera "expenses", no "costs")
ALTER TABLE IF EXISTS costs RENAME TO expenses;

-- Corregir: usuarios_del_sistema → system_users (si todavía existe con ese nombre)
ALTER TABLE IF EXISTS usuarios_del_sistema RENAME TO system_users;

-- Verificar que hotels existe (renombrar hoteles si todavía existe)
ALTER TABLE IF EXISTS hoteles RENAME TO hotels;

-- Verificar que reservations existe (renombrar reservas si todavía existe)
ALTER TABLE IF EXISTS reservas RENAME TO reservations;

-- Verificar que quotes existe (renombrar cotizaciones si todavía existe)
ALTER TABLE IF EXISTS cotizaciones RENAME TO quotes;

-- ============================================
-- ¡LISTO! Todas las tablas ahora tienen los nombres correctos
-- ============================================

