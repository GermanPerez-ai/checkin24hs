-- ============================================
-- VERIFICAR Y CORREGIR TABLA whatsapp_messages
-- ============================================
-- Este script verifica la estructura de la tabla
-- y agrega la columna chat_id si no existe
-- ============================================

-- 1. Verificar estructura actual de la tabla
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'whatsapp_messages'
ORDER BY ordinal_position;

-- 2. Verificar si existe la columna chat_id
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'whatsapp_messages' 
      AND column_name = 'chat_id'
) as chat_id_exists;

-- 3. Si chat_id NO existe, agregarlo
-- IMPORTANTE: Ejecuta esto solo si chat_id_exists es false
-- Descomenta y ejecuta las siguientes líneas si chat_id no existe:

-- PASO 1: Agregar la columna chat_id (puede ser NULL inicialmente)
ALTER TABLE whatsapp_messages 
ADD COLUMN IF NOT EXISTS chat_id UUID;

-- PASO 2: Crear la relación con whatsapp_chats
-- Primero verifica que la tabla whatsapp_chats exista
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'whatsapp_chats') THEN
        -- Agregar la foreign key constraint
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'whatsapp_messages_chat_id_fkey'
        ) THEN
            ALTER TABLE whatsapp_messages 
            ADD CONSTRAINT whatsapp_messages_chat_id_fkey 
            FOREIGN KEY (chat_id) REFERENCES whatsapp_chats(id) ON DELETE CASCADE;
        END IF;
    END IF;
END $$;

-- PASO 3: Crear índice para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_chat_id ON whatsapp_messages(chat_id);

-- 4. Verificar estructura de flor_interactions también
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'flor_interactions'
ORDER BY ordinal_position;

-- 5. Verificar si flor_interactions tiene columna id
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'flor_interactions' 
      AND column_name = 'id'
) as flor_interactions_has_id;

-- 6. Si flor_interactions NO tiene id, agregarlo (ejecutar solo si es necesario)
-- Descomenta las siguientes líneas si id no existe:

/*
ALTER TABLE flor_interactions 
ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid();
*/

