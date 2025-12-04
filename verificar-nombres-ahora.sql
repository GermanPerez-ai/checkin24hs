-- ============================================
-- VERIFICACIÓN RÁPIDA: NOMBRES REALES DE TABLAS
-- ============================================
-- Ejecuta esto para ver los nombres REALES en la base de datos

SELECT 
    table_name AS "Nombre Real",
    'public' AS "Esquema"
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ============================================
-- Si ves nombres en INGLÉS = ✅ Todo está bien
-- Si ves nombres en ESPAÑOL = Necesitamos renombrar
-- ============================================

