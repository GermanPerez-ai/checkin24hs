-- ============================================
-- Agregar message_type a whatsapp_messages (opcional)
-- ============================================
-- El servidor WhatsApp intenta guardar message_type; si la columna no existe, guarda sin ella.
-- Ejecutar en Supabase SQL Editor si querés quitar el aviso "Tabla whatsapp_messages no tiene columna message_type".

-- Agregar columna si no existe (idempotente)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'message_type'
  ) THEN
    ALTER TABLE public.whatsapp_messages
    ADD COLUMN message_type VARCHAR(20) DEFAULT 'text';
    RAISE NOTICE 'Columna message_type agregada a whatsapp_messages';
  ELSE
    RAISE NOTICE 'Columna message_type ya existe';
  END IF;
END $$;
