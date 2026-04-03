-- ============================================
-- CORREGIR PROBLEMA DE SEGURIDAD: FUNCTION SEARCH PATH MUTABLE
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- El problema: Las funciones tienen search_path mutable, lo cual es un riesgo de seguridad
-- porque puede permitir ataques de inyección SQL
-- Solución: Establecer search_path explícitamente en las funciones

-- 1. Corregir función is_spam_chat
CREATE OR REPLACE FUNCTION public.is_spam_chat(phone_text TEXT, name_text TEXT DEFAULT '')
RETURNS BOOLEAN 
LANGUAGE plpgsql 
IMMUTABLE
SECURITY INVOKER
SET search_path = public, pg_temp  -- Fijar search_path para seguridad
AS $$
BEGIN
    RETURN (
        phone_text ILIKE '%status@broadcast%' OR
        phone_text ILIKE '%broadcast%' OR
        phone_text ILIKE '%status.broadcast%' OR
        phone_text ILIKE '%@lid%' OR
        phone_text ILIKE '%@newsletter%' OR
        phone_text ILIKE '%@g.us%' OR
        phone_text ILIKE '%gid%' OR
        phone_text ILIKE '%group%' OR
        phone_text ILIKE '%grupo%' OR
        phone_text ILIKE '%notify%' OR
        phone_text ILIKE '%notification%' OR
        phone_text ILIKE '%system%' OR
        phone_text ILIKE '%server%' OR
        phone_text ILIKE '%bot%' OR
        phone_text ILIKE '%automated%' OR
        phone_text ILIKE '%auto-reply%' OR
        COALESCE(name_text, '') ILIKE '%status@broadcast%' OR
        COALESCE(name_text, '') ILIKE '%broadcast%' OR
        COALESCE(name_text, '') ILIKE '%gid%' OR
        COALESCE(name_text, '') ILIKE '%group%' OR
        COALESCE(name_text, '') ILIKE '%grupo%' OR
        COALESCE(name_text, '') ILIKE '%notify%' OR
        COALESCE(name_text, '') ILIKE '%notification%' OR
        COALESCE(name_text, '') ILIKE '%system%' OR
        COALESCE(name_text, '') ILIKE '%server%' OR
        COALESCE(name_text, '') ILIKE '%bot%' OR
        COALESCE(name_text, '') ILIKE '%automated%' OR
        COALESCE(name_text, '') ILIKE '%auto-reply%'
    );
END;
$$;

-- 2. Corregir función trigger_set_updated_at (o update_updated_at_column)
-- Esta función se usa en triggers para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION public.trigger_set_updated_at()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public, pg_temp  -- Fijar search_path para seguridad
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Si la función se llama update_updated_at_column, también la corregimos
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public, pg_temp  -- Fijar search_path para seguridad
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 3. Otorgar permisos necesarios
GRANT EXECUTE ON FUNCTION public.is_spam_chat TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_spam_chat TO anon;
GRANT EXECUTE ON FUNCTION public.trigger_set_updated_at TO authenticated;
GRANT EXECUTE ON FUNCTION public.trigger_set_updated_at TO anon;
GRANT EXECUTE ON FUNCTION public.update_updated_at_column TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_updated_at_column TO anon;

-- 4. Verificar que las funciones tienen search_path fijo
SELECT 
    p.proname as function_name,
    pg_get_functiondef(p.oid) as definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname IN ('is_spam_chat', 'trigger_set_updated_at', 'update_updated_at_column')
AND n.nspname = 'public'
ORDER BY p.proname;

-- 5. Probar que las funciones funcionan correctamente
SELECT public.is_spam_chat('test@broadcast.us', 'Test') as is_spam_test;
SELECT public.is_spam_chat('5491112345678@c.us', 'Juan Pérez') as is_spam_valid;

-- Nota: Después de ejecutar este script, ve a Security Advisor y haz clic en "Rerun linter"
-- para verificar que los warnings desaparecieron.



