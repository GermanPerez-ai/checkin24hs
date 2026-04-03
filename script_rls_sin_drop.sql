-- ============================================
-- SCRIPT RLS SIN DROP (VERSIÓN SEGURA)
-- ============================================
-- Esta versión NO elimina políticas existentes
-- Si las políticas ya existen, obtendrás un error
-- pero puedes ignorarlo o ejecutar la versión con DROP
-- ============================================

-- ============================================
-- TABLA: whatsapp_chats
-- ============================================

-- Habilitar RLS
ALTER TABLE IF EXISTS public.whatsapp_chats ENABLE ROW LEVEL SECURITY;

-- Política SELECT (Lectura)
CREATE POLICY IF NOT EXISTS "Allow read access to all users"
ON public.whatsapp_chats
FOR SELECT
TO public
USING (true);

-- Política INSERT (Inserción)
CREATE POLICY IF NOT EXISTS "Allow insert access to all users"
ON public.whatsapp_chats
FOR INSERT
TO public
WITH CHECK (true);

-- Política UPDATE (Actualización)
CREATE POLICY IF NOT EXISTS "Allow update access to all users"
ON public.whatsapp_chats
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- Política DELETE (Eliminación)
CREATE POLICY IF NOT EXISTS "Allow delete access to all users"
ON public.whatsapp_chats
FOR DELETE
TO public
USING (true);

-- ============================================
-- TABLA: whatsapp_messages
-- ============================================

-- Habilitar RLS
ALTER TABLE IF EXISTS public.whatsapp_messages ENABLE ROW LEVEL SECURITY;

-- Política SELECT (Lectura)
CREATE POLICY IF NOT EXISTS "Allow read access to all users"
ON public.whatsapp_messages
FOR SELECT
TO public
USING (true);

-- Política INSERT (Inserción)
CREATE POLICY IF NOT EXISTS "Allow insert access to all users"
ON public.whatsapp_messages
FOR INSERT
TO public
WITH CHECK (true);

-- Política UPDATE (Actualización)
CREATE POLICY IF NOT EXISTS "Allow update access to all users"
ON public.whatsapp_messages
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- Política DELETE (Eliminación)
CREATE POLICY IF NOT EXISTS "Allow delete access to all users"
ON public.whatsapp_messages
FOR DELETE
TO public
USING (true);

-- ============================================
-- TABLA: flor_interactions
-- ============================================

-- Habilitar RLS
ALTER TABLE IF EXISTS public.flor_interactions ENABLE ROW LEVEL SECURITY;

-- Política SELECT (Lectura)
CREATE POLICY IF NOT EXISTS "Allow read access to all users"
ON public.flor_interactions
FOR SELECT
TO public
USING (true);

-- Política INSERT (Inserción)
CREATE POLICY IF NOT EXISTS "Allow insert access to all users"
ON public.flor_interactions
FOR INSERT
TO public
WITH CHECK (true);

-- Política UPDATE (Actualización)
CREATE POLICY IF NOT EXISTS "Allow update access to all users"
ON public.flor_interactions
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- Política DELETE (Eliminación)
CREATE POLICY IF NOT EXISTS "Allow delete access to all users"
ON public.flor_interactions
FOR DELETE
TO public
USING (true);

