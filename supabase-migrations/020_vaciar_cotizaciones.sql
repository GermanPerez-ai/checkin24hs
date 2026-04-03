-- ============================================
-- VACIAR TABLA DE COTIZACIONES (quotes)
-- Ejecutar en Supabase → SQL Editor
-- ============================================
-- Elimina todos los registros de la tabla quotes.
-- La tabla sigue existiendo; solo se borran los datos.
-- ============================================

DELETE FROM quotes;

-- Opcional: ver cuántas filas quedan (debe ser 0)
-- SELECT COUNT(*) FROM quotes;
