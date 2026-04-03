-- ============================================
-- ELIMINAR RESERVAS DE PUYEHUE (HTP) Y AGUAS CALIENTES (ACC)
-- Ejecutar en Supabase → SQL Editor
-- ============================================
-- Borra solo las reservas cuyo hotel sea Termas de Puyehue / HTP
-- o Termas Aguas Calientes / ACC. El resto de hoteles no se toca.
-- ============================================

-- Ver cuántas se van a borrar (opcional, podés ejecutar solo esto primero)
-- SELECT id, reservation_code, hotel_name, hotel_id, check_in, check_out, total_amount
-- FROM public.reservations
-- WHERE (TRIM(LOWER(COALESCE(hotel_name, ''))) IN ('htp', 'acc')
--    OR LOWER(COALESCE(hotel_name, '')) LIKE '%puyehue%'
--    OR LOWER(COALESCE(hotel_name, '')) LIKE '%aguas calientes%');

-- Borrar reservas HTP / Puyehue / ACC / Aguas Calientes
DELETE FROM public.reservations
WHERE (
  TRIM(LOWER(COALESCE(hotel_name, ''))) = 'htp'
  OR TRIM(LOWER(COALESCE(hotel_name, ''))) = 'acc'
  OR LOWER(COALESCE(hotel_name, '')) LIKE '%puyehue%'
  OR LOWER(COALESCE(hotel_name, '')) LIKE '%aguas calientes%'
);

-- Opcional: ver cuántas quedan
-- SELECT COUNT(*) AS total_reservas FROM public.reservations;
