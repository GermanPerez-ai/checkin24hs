-- ============================================
-- VACIAR TABLA DE RESERVAS
-- Ejecutar en Supabase → SQL Editor
-- ============================================
-- Elimina todos los registros de la tabla reservations.
-- La tabla sigue existiendo; solo se borran los datos.
-- Después podés subir de nuevo las reservas mejor ordenadas.
-- ============================================

DELETE FROM reservations;

-- Opcional: ver cuántas filas quedan (debe ser 0)
-- SELECT COUNT(*) FROM reservations;
