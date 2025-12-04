-- ============================================
-- VERIFICACIÓN FINAL: NOMBRES REALES DE TABLAS
-- ============================================
-- Este script muestra los nombres REALES en la base de datos
-- Sin importar cómo se muestren en la interfaz

SELECT 
    table_name AS "Nombre Real en Base de Datos",
    table_schema AS "Esquema"
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ============================================
-- Si ves nombres en INGLÉS = ✅ Todo está bien
-- Si ves nombres en ESPAÑOL = ❌ Necesitan renombrarse
-- ============================================

