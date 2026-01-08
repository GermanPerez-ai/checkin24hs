-- ============================================
-- VERIFICAR Y CORREGIR ESTRUCTURA COMPLETA
-- ============================================
-- Este script verifica y corrige todas las columnas
-- necesarias en whatsapp_messages
-- ============================================

-- 1. Verificar estructura actual de whatsapp_messages
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'whatsapp_messages'
ORDER BY ordinal_position;

-- 2. Verificar columnas específicas
SELECT 
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'chat_id') as chat_id_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'is_from_me') as is_from_me_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'is_read') as is_read_exists;

-- 3. CORRECCIÓN AUTOMÁTICA: Agregar columnas faltantes
DO $$
BEGIN
    -- Agregar chat_id si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'whatsapp_messages' 
          AND column_name = 'chat_id'
    ) THEN
        ALTER TABLE whatsapp_messages ADD COLUMN chat_id UUID;
        RAISE NOTICE '✅ Columna chat_id agregada';
        
        -- Agregar foreign key si la tabla whatsapp_chats existe
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'whatsapp_chats') THEN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.table_constraints 
                WHERE constraint_name = 'whatsapp_messages_chat_id_fkey'
            ) THEN
                ALTER TABLE whatsapp_messages 
                ADD CONSTRAINT whatsapp_messages_chat_id_fkey 
                FOREIGN KEY (chat_id) REFERENCES whatsapp_chats(id) ON DELETE CASCADE;
                RAISE NOTICE '✅ Foreign key chat_id agregada';
            END IF;
        END IF;
        
        -- Crear índice
        CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_chat_id ON whatsapp_messages(chat_id);
        RAISE NOTICE '✅ Índice chat_id creado';
    ELSE
        RAISE NOTICE 'ℹ️ Columna chat_id ya existe';
    END IF;
    
    -- Agregar is_from_me si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'whatsapp_messages' 
          AND column_name = 'is_from_me'
    ) THEN
        ALTER TABLE whatsapp_messages ADD COLUMN is_from_me BOOLEAN DEFAULT false;
        RAISE NOTICE '✅ Columna is_from_me agregada';
    ELSE
        RAISE NOTICE 'ℹ️ Columna is_from_me ya existe';
    END IF;
    
    -- Agregar is_read si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'whatsapp_messages' 
          AND column_name = 'is_read'
    ) THEN
        ALTER TABLE whatsapp_messages ADD COLUMN is_read BOOLEAN DEFAULT false;
        RAISE NOTICE '✅ Columna is_read agregada';
    ELSE
        RAISE NOTICE 'ℹ️ Columna is_read ya existe';
    END IF;
END $$;

-- 4. Verificar estructura final
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'whatsapp_messages'
ORDER BY ordinal_position;

