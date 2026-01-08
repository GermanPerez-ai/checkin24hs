-- ============================================
-- CORREGIR ESTRUCTURA DE TABLAS WHATSAPP
-- ============================================
-- Este script corrige la estructura de las tablas
-- si faltan columnas necesarias
-- ============================================

-- ============================================
-- CORRECCIÓN 1: Agregar chat_id a whatsapp_messages
-- ============================================

-- Verificar si chat_id existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'whatsapp_messages' 
          AND column_name = 'chat_id'
    ) THEN
        -- Agregar la columna
        ALTER TABLE whatsapp_messages 
        ADD COLUMN chat_id UUID;
        
        -- Agregar foreign key si la tabla whatsapp_chats existe
        IF EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = 'whatsapp_chats'
        ) THEN
            ALTER TABLE whatsapp_messages 
            ADD CONSTRAINT whatsapp_messages_chat_id_fkey 
            FOREIGN KEY (chat_id) REFERENCES whatsapp_chats(id) ON DELETE CASCADE;
        END IF;
        
        -- Crear índice
        CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_chat_id 
        ON whatsapp_messages(chat_id);
        
        RAISE NOTICE '✅ Columna chat_id agregada a whatsapp_messages';
    ELSE
        RAISE NOTICE 'ℹ️ La columna chat_id ya existe en whatsapp_messages';
    END IF;
END $$;

-- ============================================
-- CORRECCIÓN 2: Verificar que flor_interactions tenga id
-- ============================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'flor_interactions' 
          AND column_name = 'id'
    ) THEN
        -- Agregar la columna id como primary key
        ALTER TABLE flor_interactions 
        ADD COLUMN id UUID PRIMARY KEY DEFAULT gen_random_uuid();
        
        RAISE NOTICE '✅ Columna id agregada a flor_interactions';
    ELSE
        RAISE NOTICE 'ℹ️ La columna id ya existe en flor_interactions';
    END IF;
END $$;

-- ============================================
-- VERIFICACIÓN FINAL
-- ============================================

-- Verificar estructura de whatsapp_messages
SELECT 
    'whatsapp_messages' as tabla,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'whatsapp_messages'
ORDER BY ordinal_position;

-- Verificar estructura de flor_interactions
SELECT 
    'flor_interactions' as tabla,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'flor_interactions'
ORDER BY ordinal_position;

