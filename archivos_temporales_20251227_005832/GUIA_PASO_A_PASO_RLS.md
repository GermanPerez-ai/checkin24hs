# 📋 Guía Paso a Paso: Crear Políticas RLS en Supabase

## 🎯 Para la Tabla `whatsapp_chats`

### Paso 1: Crear Política de Lectura (SELECT)

1. **En el modal que tienes abierto:**
   - **Policy Name:** `Allow read access to all users`
   - **Table:** `public.whatsapp_chats` (ya está configurado)
   - **Policy Behavior:** `Permissive` (ya está configurado)
   - **Policy Command:** `SELECT` (ya está seleccionado)
   - **Target Roles:** `public` (dejar por defecto)

2. **En el SQL Code Preview, reemplaza la línea 7 con:**
   ```sql
   using (true);
   ```
   
   El código completo debería verse así:
   ```sql
   create policy "Allow read access to all users"
   on "public"."whatsapp_chats"
   as PERMISSIVE
   for SELECT
   to public
   using (true);
   ```

3. **Haz clic en "Save policy"**

### Paso 2: Crear Política de Inserción (INSERT)

1. **Haz clic en "New Policy" nuevamente**
2. **Configura:**
   - **Policy Name:** `Allow insert access to all users`
   - **Table:** `public.whatsapp_chats`
   - **Policy Behavior:** `Permissive`
   - **Policy Command:** `INSERT`
   - **Target Roles:** `public`

3. **En el SQL Code Preview:**
   ```sql
   create policy "Allow insert access to all users"
   on "public"."whatsapp_chats"
   as PERMISSIVE
   for INSERT
   to public
   with check (true);
   ```

4. **Haz clic en "Save policy"**

### Paso 3: Crear Política de Actualización (UPDATE)

1. **Haz clic en "New Policy" nuevamente**
2. **Configura:**
   - **Policy Name:** `Allow update access to all users`
   - **Table:** `public.whatsapp_chats`
   - **Policy Behavior:** `Permissive`
   - **Policy Command:** `UPDATE`
   - **Target Roles:** `public`

3. **En el SQL Code Preview:**
   ```sql
   create policy "Allow update access to all users"
   on "public"."whatsapp_chats"
   as PERMISSIVE
   for UPDATE
   to public
   using (true)
   with check (true);
   ```

4. **Haz clic en "Save policy"**

### Paso 4: Crear Política de Eliminación (DELETE)

1. **Haz clic en "New Policy" nuevamente**
2. **Configura:**
   - **Policy Name:** `Allow delete access to all users`
   - **Table:** `public.whatsapp_chats`
   - **Policy Behavior:** `Permissive`
   - **Policy Command:** `DELETE`
   - **Target Roles:** `public`

3. **En el SQL Code Preview:**
   ```sql
   create policy "Allow delete access to all users"
   on "public"."whatsapp_chats"
   as PERMISSIVE
   for DELETE
   to public
   using (true);
   ```

4. **Haz clic en "Save policy"**

## 🎯 Para la Tabla `whatsapp_messages`

Repite los mismos 4 pasos pero cambiando:
- **Table:** `public.whatsapp_messages`
- Los nombres de las políticas (ej: `Allow read access to all users - messages`)

## 🎯 Para la Tabla `flor_interactions`

Repite los mismos 4 pasos pero cambiando:
- **Table:** `public.flor_interactions`
- Los nombres de las políticas (ej: `Allow read access to all users - interactions`)

## ⚡ Método Rápido: Usar SQL Directo

Si prefieres, puedes ejecutar todo de una vez en el **SQL Editor** de Supabase:

```sql
-- ============================================
-- POLÍTICAS PARA whatsapp_chats
-- ============================================

-- Habilitar RLS
ALTER TABLE public.whatsapp_chats ENABLE ROW LEVEL SECURITY;

-- Política SELECT
CREATE POLICY "Allow read access to all users"
ON public.whatsapp_chats
FOR SELECT
TO public
USING (true);

-- Política INSERT
CREATE POLICY "Allow insert access to all users"
ON public.whatsapp_chats
FOR INSERT
TO public
WITH CHECK (true);

-- Política UPDATE
CREATE POLICY "Allow update access to all users"
ON public.whatsapp_chats
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- Política DELETE
CREATE POLICY "Allow delete access to all users"
ON public.whatsapp_chats
FOR DELETE
TO public
USING (true);

-- ============================================
-- POLÍTICAS PARA whatsapp_messages
-- ============================================

ALTER TABLE public.whatsapp_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read access to all users"
ON public.whatsapp_messages
FOR SELECT
TO public
USING (true);

CREATE POLICY "Allow insert access to all users"
ON public.whatsapp_messages
FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Allow update access to all users"
ON public.whatsapp_messages
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow delete access to all users"
ON public.whatsapp_messages
FOR DELETE
TO public
USING (true);

-- ============================================
-- POLÍTICAS PARA flor_interactions
-- ============================================

ALTER TABLE public.flor_interactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read access to all users"
ON public.flor_interactions
FOR SELECT
TO public
USING (true);

CREATE POLICY "Allow insert access to all users"
ON public.flor_interactions
FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Allow update access to all users"
ON public.flor_interactions
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow delete access to all users"
ON public.flor_interactions
FOR DELETE
TO public
USING (true);
```

## ✅ Verificar que Funciona

Después de crear las políticas, prueba en la consola del navegador:

```javascript
// Recargar la página del dashboard
location.reload();

// O probar directamente
const chats = await window.supabaseClient.getWhatsAppChats(10);
console.log('Chats:', chats);

const interactions = await window.supabaseClient.getFlorInteractions(10);
console.log('Interacciones:', interactions);
```

## 🔒 Nota de Seguridad

⚠️ **IMPORTANTE:** Estas políticas permiten acceso completo a todos los usuarios. En producción, deberías crear políticas más restrictivas basadas en:
- Autenticación de usuarios
- Roles y permisos
- Propiedad de los datos (ej: solo el usuario puede ver sus propios chats)

Para desarrollo y pruebas, estas políticas están bien.

