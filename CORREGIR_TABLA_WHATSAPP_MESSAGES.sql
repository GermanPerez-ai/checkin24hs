-- ============================================
-- CORREGIR TABLA whatsapp_messages
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- PROBLEMA: El código usa 'body' pero la tabla tiene 'message'
-- SOLUCIÓN: Agregar columna 'body' o renombrar 'message' a 'body'

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

-- 2. Verificar qué columnas existen
SELECT 
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'message') as message_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'body') as body_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'phone') as phone_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'chat_id') as chat_id_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'is_from_me') as is_from_me_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'is_read') as is_read_exists;

-- 3. OPCIÓN A: Si existe 'message' pero NO 'body', agregar 'body' y copiar datos
DO $$
BEGIN
    -- Si existe 'message' pero no 'body', agregar 'body' y copiar datos
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'message')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'body') THEN
        
        -- Agregar columna 'body'
        ALTER TABLE whatsapp_messages ADD COLUMN body TEXT;
        
        -- Copiar datos de 'message' a 'body'
        UPDATE whatsapp_messages SET body = message WHERE body IS NULL;
        
        -- Hacer 'body' NOT NULL si 'message' es NOT NULL
        ALTER TABLE whatsapp_messages ALTER COLUMN body SET NOT NULL;
        
        RAISE NOTICE '✅ Columna body agregada y datos copiados desde message';
    ELSE
        RAISE NOTICE 'ℹ️ La columna body ya existe o message no existe';
    END IF;
END $$;

-- 4. OPCIÓN B: Si existe 'body' pero NO 'message', agregar 'message' y copiar datos
DO $$
BEGIN
    -- Si existe 'body' pero no 'message', agregar 'message' y copiar datos
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'body')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'message') THEN
        
        -- Agregar columna 'message'
        ALTER TABLE whatsapp_messages ADD COLUMN message TEXT;
        
        -- Copiar datos de 'body' a 'message'
        UPDATE whatsapp_messages SET message = body WHERE message IS NULL;
        
        -- Hacer 'message' NOT NULL si 'body' es NOT NULL
        ALTER TABLE whatsapp_messages ALTER COLUMN message SET NOT NULL;
        
        RAISE NOTICE '✅ Columna message agregada y datos copiados desde body';
    ELSE
        RAISE NOTICE 'ℹ️ La columna message ya existe o body no existe';
    END IF;
END $$;

-- 5. Asegurar que existan todas las columnas necesarias
DO $$
BEGIN
    -- Agregar phone si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'phone') THEN
        ALTER TABLE whatsapp_messages ADD COLUMN phone VARCHAR(50);
        RAISE NOTICE '✅ Columna phone agregada';
    END IF;
    
    -- Agregar chat_id si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'chat_id') THEN
        ALTER TABLE whatsapp_messages ADD COLUMN chat_id UUID;
        RAISE NOTICE '✅ Columna chat_id agregada';
    END IF;
    
    -- Agregar is_from_me si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'is_from_me') THEN
        ALTER TABLE whatsapp_messages ADD COLUMN is_from_me BOOLEAN DEFAULT false;
        RAISE NOTICE '✅ Columna is_from_me agregada';
    END IF;
    
    -- Agregar is_read si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'is_read') THEN
        ALTER TABLE whatsapp_messages ADD COLUMN is_read BOOLEAN DEFAULT false;
        RAISE NOTICE '✅ Columna is_read agregada';
    END IF;
    
    -- Agregar whatsapp_instance si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'whatsapp_instance') THEN
        ALTER TABLE whatsapp_messages ADD COLUMN whatsapp_instance INTEGER DEFAULT 1;
        RAISE NOTICE '✅ Columna whatsapp_instance agregada';
    END IF;
    
    -- Agregar created_at si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'created_at') THEN
        ALTER TABLE whatsapp_messages ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Columna created_at agregada';
    END IF;
END $$;

-- 6. Verificar estructura final
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'whatsapp_messages'
ORDER BY ordinal_position;

-- 7. Verificar que ambas columnas existen (para compatibilidad)
SELECT 
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'message') as message_exists,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'body') as body_exists;

