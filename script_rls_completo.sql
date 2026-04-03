-- ============================================
-- SCRIPT COMPLETO: HABILITAR RLS Y CREAR POLÍTICAS
-- ============================================
-- Este script habilita Row Level Security (RLS) y crea políticas
-- para las tablas: whatsapp_chats, whatsapp_messages, flor_interactions
--
-- INSTRUCCIONES:
-- 1. Abre Supabase Dashboard
-- 2. Ve a SQL Editor
-- 3. Pega este script completo
-- 4. Haz clic en "Run" (Ejecutar)
-- ============================================

-- ============================================
-- TABLA: whatsapp_chats
-- ============================================

-- Habilitar RLS
ALTER TABLE IF EXISTS public.whatsapp_chats ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen (para evitar errores)
DROP POLICY IF EXISTS "Allow read access to all users" ON public.whatsapp_chats;
DROP POLICY IF EXISTS "Allow insert access to all users" ON public.whatsapp_chats;
DROP POLICY IF EXISTS "Allow update access to all users" ON public.whatsapp_chats;
DROP POLICY IF EXISTS "Allow delete access to all users" ON public.whatsapp_chats;

-- Política SELECT (Lectura)
CREATE POLICY "Allow read access to all users"
ON public.whatsapp_chats
FOR SELECT
TO public
USING (true);

-- Política INSERT (Inserción)
CREATE POLICY "Allow insert access to all users"
ON public.whatsapp_chats
FOR INSERT
TO public
WITH CHECK (true);

-- Política UPDATE (Actualización)
CREATE POLICY "Allow update access to all users"
ON public.whatsapp_chats
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- Política DELETE (Eliminación)
CREATE POLICY "Allow delete access to all users"
ON public.whatsapp_chats
FOR DELETE
TO public
USING (true);

-- ============================================
-- TABLA: whatsapp_messages
-- ============================================

-- Habilitar RLS
ALTER TABLE IF EXISTS public.whatsapp_messages ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Allow read access to all users" ON public.whatsapp_messages;
DROP POLICY IF EXISTS "Allow insert access to all users" ON public.whatsapp_messages;
DROP POLICY IF EXISTS "Allow update access to all users" ON public.whatsapp_messages;
DROP POLICY IF EXISTS "Allow delete access to all users" ON public.whatsapp_messages;

-- Política SELECT (Lectura)
CREATE POLICY "Allow read access to all users"
ON public.whatsapp_messages
FOR SELECT
TO public
USING (true);

-- Política INSERT (Inserción)
CREATE POLICY "Allow insert access to all users"
ON public.whatsapp_messages
FOR INSERT
TO public
WITH CHECK (true);

-- Política UPDATE (Actualización)
CREATE POLICY "Allow update access to all users"
ON public.whatsapp_messages
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- Política DELETE (Eliminación)
CREATE POLICY "Allow delete access to all users"
ON public.whatsapp_messages
FOR DELETE
TO public
USING (true);

-- ============================================
-- TABLA: flor_interactions
-- ============================================

-- Habilitar RLS
ALTER TABLE IF EXISTS public.flor_interactions ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Allow read access to all users" ON public.flor_interactions;
DROP POLICY IF EXISTS "Allow insert access to all users" ON public.flor_interactions;
DROP POLICY IF EXISTS "Allow update access to all users" ON public.flor_interactions;
DROP POLICY IF EXISTS "Allow delete access to all users" ON public.flor_interactions;

-- Política SELECT (Lectura)
CREATE POLICY "Allow read access to all users"
ON public.flor_interactions
FOR SELECT
TO public
USING (true);

-- Política INSERT (Inserción)
CREATE POLICY "Allow insert access to all users"
ON public.flor_interactions
FOR INSERT
TO public
WITH CHECK (true);

-- Política UPDATE (Actualización)
CREATE POLICY "Allow update access to all users"
ON public.flor_interactions
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- Política DELETE (Eliminación)
CREATE POLICY "Allow delete access to all users"
ON public.flor_interactions
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
WHERE tablename IN ('whatsapp_chats', 'whatsapp_messages', 'flor_interactions')
ORDER BY tablename, policyname;

-- Deberías ver 12 políticas en total (4 por cada tabla)

