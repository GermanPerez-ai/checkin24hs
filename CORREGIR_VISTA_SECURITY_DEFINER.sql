-- ============================================
-- CORREGIR PROBLEMA DE SEGURIDAD: SECURITY DEFINER VIEW
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- El problema: La vista whatsapp_chats_no_spam tiene SECURITY DEFINER
-- Esto significa que ejecuta con los permisos del creador, no del usuario que consulta
-- Solución: Recrear la vista y la función sin SECURITY DEFINER

-- 1. Verificar si la función is_spam_chat tiene SECURITY DEFINER
SELECT 
    p.proname as function_name,
    pg_get_functiondef(p.oid) as definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname = 'is_spam_chat'
AND n.nspname = 'public';

-- 2. Recrear la función sin SECURITY DEFINER (usa SECURITY INVOKER por defecto)
CREATE OR REPLACE FUNCTION public.is_spam_chat(phone_text TEXT, name_text TEXT DEFAULT '')
RETURNS BOOLEAN 
LANGUAGE plpgsql 
IMMUTABLE
SECURITY INVOKER  -- Explícitamente usar SECURITY INVOKER
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

-- 3. Eliminar la vista existente
DROP VIEW IF EXISTS public.whatsapp_chats_no_spam CASCADE;

-- 4. Recrear la vista sin SECURITY DEFINER (usa SECURITY INVOKER por defecto)
-- Esto asegura que la vista respete las políticas RLS del usuario que consulta
CREATE OR REPLACE VIEW public.whatsapp_chats_no_spam
WITH (security_invoker = true) AS
SELECT *
FROM public.whatsapp_chats
WHERE NOT public.is_spam_chat(phone, COALESCE(name, ''))
ORDER BY last_message_time DESC NULLS LAST;

-- 5. Otorgar permisos necesarios
GRANT SELECT ON public.whatsapp_chats_no_spam TO authenticated;
GRANT SELECT ON public.whatsapp_chats_no_spam TO anon;
GRANT EXECUTE ON FUNCTION public.is_spam_chat TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_spam_chat TO anon;

-- 6. Verificar que la vista se creó correctamente
SELECT 
    schemaname,
    viewname,
    viewowner
FROM pg_views
WHERE viewname = 'whatsapp_chats_no_spam';

-- 7. Verificar que la función no tiene SECURITY DEFINER
SELECT 
    p.proname as function_name,
    CASE 
        WHEN p.prosecdef THEN 'SECURITY DEFINER'
        ELSE 'SECURITY INVOKER'
    END as security_type
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname = 'is_spam_chat'
AND n.nspname = 'public';

-- 8. Probar que la vista funciona correctamente
SELECT COUNT(*) as total_chats_no_spam FROM public.whatsapp_chats_no_spam;

