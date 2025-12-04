-- ============================================
-- SCRIPT INTELIGENTE: VERIFICAR Y RENOMBRAR
-- ============================================
-- Este script primero verifica qué tablas existen
-- y luego renombra solo las que están en español

-- Primero, veamos qué tablas tenemos actualmente
SELECT 
    table_name AS "Tabla Actual",
    CASE 
        WHEN table_name = 'hoteles' THEN '→ Renombrar a: hotels'
        WHEN table_name = 'reservas' THEN '→ Renombrar a: reservations'
        WHEN table_name = 'cotizaciones' THEN '→ Renombrar a: quotes'
        WHEN table_name = 'gastos' THEN '→ Renombrar a: expenses'
        WHEN table_name = 'usuarios del sistema' THEN '→ Renombrar a: system_users'
        WHEN table_name = 'administradores del panel de control' THEN '→ Renombrar a: dashboard_admins'
        WHEN table_name IN ('hotels', 'reservations', 'quotes', 'expenses', 'system_users', 'dashboard_admins') THEN '✓ Ya está en inglés'
        ELSE '⚠ Nombre no reconocido'
    END AS "Estado"
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_type = 'BASE TABLE'
ORDER BY 
    CASE 
        WHEN table_name IN ('hotels', 'reservations', 'quotes', 'expenses', 'system_users', 'dashboard_admins') THEN 2
        ELSE 1
    END,
    table_name;

-- ============================================
-- Ejecuta esta primera parte para ver el estado
-- ============================================
-- Después, según lo que veas, ejecuta las renombraciones necesarias
-- ============================================

