-- Migración: Agregar columnas para email threading (In-Reply-To / References)
-- Fecha: 2026-11-05
-- Propósito: Permitir que emails de modificación/cancelación se envíen como replies
--            al email de confirmación original del hotel

-- Agregar columnas para almacenar el Message-ID y subject del email de confirmación original
ALTER TABLE reservations
ADD COLUMN IF NOT EXISTS original_email_message_id TEXT,
ADD COLUMN IF NOT EXISTS original_email_subject TEXT;

-- Crear índice para búsqueda rápida por Message-ID
CREATE INDEX IF NOT EXISTS idx_reservations_original_email_message_id 
ON reservations(original_email_message_id) 
WHERE original_email_message_id IS NOT NULL;

-- Comentarios para documentación
COMMENT ON COLUMN reservations.original_email_message_id IS 
'RFC Message-ID del email de confirmación original del hotel (ej: <abc123@huilohuilo.com>). Se usa para threading con In-Reply-To/References.';

COMMENT ON COLUMN reservations.original_email_subject IS 
'Subject del email de confirmación original del hotel. Se usa para construir "RE: ..." en respuestas.';
