-- ============================================
-- SCRIPT PARA ELIMINAR SOLO LA TABLA whatsapp_connections
-- ============================================
-- Este script elimina únicamente la tabla whatsapp_connections
-- y todas sus dependencias (políticas RLS, índices, etc.)
--
-- ⚠️ ADVERTENCIA: Esta operación es IRREVERSIBLE.
-- Todos los datos de whatsapp_connections se perderán.
--
-- INSTRUCCIONES:
-- 1. Abre Supabase Dashboard (https://supabase.com/dashboard)
-- 2. Selecciona tu proyecto
-- 3. Ve a "SQL Editor" (Editor SQL)
-- 4. Pega este script completo
-- 5. Haz clic en "Run" (Ejecutar)
-- ============================================

-- ============================================
-- VERIFICAR SI LA TABLA EXISTE Y ELIMINAR
-- ============================================
DO $$ 
DECLARE
    table_exists BOOLEAN;
    r RECORD;
BEGIN
    -- Verificar si la tabla existe
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
          AND table_name = 'whatsapp_connections'
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE 'ℹ️ La tabla whatsapp_connections no existe. No hay nada que eliminar.';
        RETURN;
    END IF;
    
    -- ============================================
    -- PASO 1: ELIMINAR POLÍTICAS RLS (Row Level Security)
    -- ============================================
    -- Eliminar políticas conocidas
    DROP POLICY IF EXISTS "Permitir todo en whatsapp_connections" ON public.whatsapp_connections;
    DROP POLICY IF EXISTS "Allow read access to all users" ON public.whatsapp_connections;
    DROP POLICY IF EXISTS "Allow insert access to all users" ON public.whatsapp_connections;
    DROP POLICY IF EXISTS "Allow update access to all users" ON public.whatsapp_connections;
    DROP POLICY IF EXISTS "Allow delete access to all users" ON public.whatsapp_connections;
    
    -- Eliminar cualquier otra política que pueda existir
    FOR r IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
          AND tablename = 'whatsapp_connections'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON public.whatsapp_connections';
    END LOOP;
    
    -- ============================================
    -- PASO 2: ELIMINAR TRIGGERS
    -- ============================================
    -- Eliminar trigger conocido
    DROP TRIGGER IF EXISTS update_whatsapp_connections_updated_at ON public.whatsapp_connections;
    
    -- Eliminar cualquier otro trigger que pueda existir
    FOR r IN 
        SELECT trigger_name 
        FROM information_schema.triggers 
        WHERE event_object_schema = 'public' 
          AND event_object_table = 'whatsapp_connections'
    LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || quote_ident(r.trigger_name) || ' ON public.whatsapp_connections';
    END LOOP;
    
    -- ============================================
    -- PASO 3: ELIMINAR ÍNDICES
    -- ============================================
    -- Eliminar índices conocidos
    DROP INDEX IF EXISTS public.idx_whatsapp_connections_id;
    DROP INDEX IF EXISTS public.idx_whatsapp_connections_phone;
    DROP INDEX IF EXISTS public.idx_whatsapp_connections_status;
    DROP INDEX IF EXISTS public.idx_whatsapp_connections_instance;
    DROP INDEX IF EXISTS public.idx_whatsapp_connections_created_at;
    
    -- Eliminar cualquier otro índice que pueda existir
    FOR r IN 
        SELECT indexname 
        FROM pg_indexes 
        WHERE schemaname = 'public' 
          AND tablename = 'whatsapp_connections'
    LOOP
        EXECUTE 'DROP INDEX IF EXISTS ' || quote_ident(r.indexname) || ' CASCADE';
    END LOOP;
    
    -- ============================================
    -- PASO 4: ELIMINAR LA TABLA
    -- ============================================
    DROP TABLE IF EXISTS public.whatsapp_connections CASCADE;
    
    RAISE NOTICE '✅ La tabla whatsapp_connections ha sido eliminada correctamente';
END $$;

-- ============================================
-- VERIFICACIÓN FINAL
-- ============================================
-- Verificar el estado de la tabla

SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ La tabla whatsapp_connections NO existe (ya fue eliminada o nunca existió)'
        ELSE '⚠️ La tabla whatsapp_connections todavía existe'
    END as resultado
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name = 'whatsapp_connections';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
-- Si todo salió bien, deberías ver el mensaje de éxito
-- ============================================
