-- ============================================
-- SCRIPT ADICIONAL: HABILITAR RLS EN TABLAS ADICIONALES
-- ============================================
-- Este script habilita Row Level Security (RLS) y crea políticas
-- para las tablas que aparecen en el Security Advisor:
-- whatsapp_conversations, whatsapp_media, whatsapp_templates
--
-- INSTRUCCIONES:
-- 1. Abre Supabase Dashboard
-- 2. Ve a SQL Editor
-- 3. Pega este script completo
-- 4. Haz clic en "Run" (Ejecutar)
-- ============================================

-- ============================================
-- TABLA: whatsapp_conversations
-- ============================================

-- Habilitar RLS
ALTER TABLE IF EXISTS public.whatsapp_conversations ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen (para evitar errores)
DROP POLICY IF EXISTS "Allow read access to all users" ON public.whatsapp_conversations;
DROP POLICY IF EXISTS "Allow insert access to all users" ON public.whatsapp_conversations;
DROP POLICY IF EXISTS "Allow update access to all users" ON public.whatsapp_conversations;
DROP POLICY IF EXISTS "Allow delete access to all users" ON public.whatsapp_conversations;

-- Política SELECT (Lectura)
CREATE POLICY "Allow read access to all users"
ON public.whatsapp_conversations
FOR SELECT
TO public
USING (true);

-- Política INSERT (Inserción)
CREATE POLICY "Allow insert access to all users"
ON public.whatsapp_conversations
FOR INSERT
TO public
WITH CHECK (true);

-- Política UPDATE (Actualización)
CREATE POLICY "Allow update access to all users"
ON public.whatsapp_conversations
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- Política DELETE (Eliminación)
CREATE POLICY "Allow delete access to all users"
ON public.whatsapp_conversations
FOR DELETE
TO public
USING (true);

-- ============================================
-- TABLA: whatsapp_media
-- ============================================

-- Habilitar RLS
ALTER TABLE IF EXISTS public.whatsapp_media ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Allow read access to all users" ON public.whatsapp_media;
DROP POLICY IF EXISTS "Allow insert access to all users" ON public.whatsapp_media;
DROP POLICY IF EXISTS "Allow update access to all users" ON public.whatsapp_media;
DROP POLICY IF EXISTS "Allow delete access to all users" ON public.whatsapp_media;

-- Política SELECT (Lectura)
CREATE POLICY "Allow read access to all users"
ON public.whatsapp_media
FOR SELECT
TO public
USING (true);

-- Política INSERT (Inserción)
CREATE POLICY "Allow insert access to all users"
ON public.whatsapp_media
FOR INSERT
TO public
WITH CHECK (true);

-- Política UPDATE (Actualización)
CREATE POLICY "Allow update access to all users"
ON public.whatsapp_media
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- Política DELETE (Eliminación)
CREATE POLICY "Allow delete access to all users"
ON public.whatsapp_media
FOR DELETE
TO public
USING (true);

-- ============================================
-- TABLA: whatsapp_templates
-- ============================================

-- Habilitar RLS
ALTER TABLE IF EXISTS public.whatsapp_templates ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Allow read access to all users" ON public.whatsapp_templates;
DROP POLICY IF EXISTS "Allow insert access to all users" ON public.whatsapp_templates;
DROP POLICY IF EXISTS "Allow update access to all users" ON public.whatsapp_templates;
DROP POLICY IF EXISTS "Allow delete access to all users" ON public.whatsapp_templates;

-- Política SELECT (Lectura)
CREATE POLICY "Allow read access to all users"
ON public.whatsapp_templates
FOR SELECT
TO public
USING (true);

-- Política INSERT (Inserción)
CREATE POLICY "Allow insert access to all users"
ON public.whatsapp_templates
FOR INSERT
TO public
WITH CHECK (true);

-- Política UPDATE (Actualización)
CREATE POLICY "Allow update access to all users"
ON public.whatsapp_templates
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- Política DELETE (Eliminación)
CREATE POLICY "Allow delete access to all users"
ON public.whatsapp_templates
FOR DELETE
TO public
USING (true);

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Después de ejecutar, verifica que las políticas se crearon correctamente
-- ejecutando este query:

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename IN ('whatsapp_conversations', 'whatsapp_media', 'whatsapp_templates')
ORDER BY tablename, policyname;

-- Deberías ver 12 políticas en total (4 por cada tabla)

