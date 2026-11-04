-- ============================================
-- MIGRACIÓN OPCIONAL: Flags de cambios en reservas
-- ============================================
-- 
-- Esta migración es OPCIONAL y NO necesaria para la funcionalidad actual.
-- El dashboard detecta cambios parseando el campo `notes` existente.
-- 
-- Estas columnas pueden agregarse en el futuro para mejorar la performance
-- si se necesita filtrar/consultar reservas con cambios de forma más eficiente.
-- 
-- ⚠️  NO EJECUTAR esta migración a menos que se decida explícitamente optimizar
--    las consultas de reservas con cambios.
-- 
-- ============================================

-- Agregar flags booleanos para indicar cambios realizados por auto-cierre
ALTER TABLE public.reservations
    ADD COLUMN IF NOT EXISTS has_amount_change BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS has_date_change BOOLEAN DEFAULT FALSE;

-- Comentarios
COMMENT ON COLUMN public.reservations.has_amount_change IS 
    'Indica si la reserva tuvo un cambio de tarifa (total_amount) confirmado por auto-cierre';
COMMENT ON COLUMN public.reservations.has_date_change IS 
    'Indica si la reserva tuvo un cambio de fechas (check_in/check_out) confirmado por auto-cierre';

-- Índices opcionales para consultas eficientes (solo crear si se necesitan)
-- CREATE INDEX IF NOT EXISTS idx_reservations_has_amount_change 
--     ON public.reservations (has_amount_change) WHERE has_amount_change = TRUE;
-- CREATE INDEX IF NOT EXISTS idx_reservations_has_date_change 
--     ON public.reservations (has_date_change) WHERE has_date_change = TRUE;

-- ============================================
-- ACTUALIZACIÓN OPCIONAL DEL MONITOR
-- ============================================
--
-- Si se ejecuta esta migración, se pueden agregar estas líneas al monitor.js
-- en la función updateReservationStatus(), después de la línea updateData.notes = updatedNotes:
--
--   // Agregar flags de cambios (solo si las columnas existen)
--   if (dataChanges) {
--       if (dataChanges.totalAmount) {
--           updateData.has_amount_change = true;
--       }
--       if (dataChanges.checkIn || dataChanges.checkOut) {
--           updateData.has_date_change = true;
--       }
--   }
--
-- ============================================
