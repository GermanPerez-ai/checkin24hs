# Número de teléfono real en Chats (dashboard)

En la sección **Chats** del dashboard, debajo del nombre del contacto (ej. LAURA VALERIA) se muestra el número de teléfono. Cuando el chat llega por **LID** (WhatsApp), a veces se guardaba un ID interno (ej. 245268536676496) en lugar del número real (ej. +5492944535477).

## Dónde se guarda

- **Tabla:** `whatsapp_chats`
- **Campos:**
  - `phone`: identificador del chat (puede ser LID o número real).
  - `real_phone`: número real del contacto (ej. +5492944535477). Lo rellena el servidor cuando resuelve LID → número.

El dashboard muestra **`real_phone`** si existe; si no, usa `phone`.

## Qué se hizo

1. **Supabase:** se agregó la columna `real_phone` en `whatsapp_chats` (migración `007_add_real_phone_whatsapp_chats.sql`).
2. **Servidor WhatsApp:** cuando resuelve un LID a número real, actualiza `whatsapp_chats` con `phone` y `real_phone` para ese chat.
3. **Dashboard:** en la lista de conversaciones y en el encabezado del chat se usa `real_phone` cuando existe, sino `phone`.

## Pasos para vos

1. **Ejecutar la migración en Supabase** (SQL Editor):
   - Abrí `supabase-migrations/007_add_real_phone_whatsapp_chats.sql`.
   - Ejecutá solo la parte que agrega la columna (las primeras líneas hasta el `COMMENT`).

2. **Desplegar** el servidor WhatsApp y el dashboard con los cambios (o hacer pull/rebuild si usás GitHub).

3. **Chats ya existentes (ej. LAURA VALERIA):**
   - Cuando esa persona **envíe un nuevo mensaje**, el servidor resolverá el LID y actualizará `real_phone` en ese chat; en el dashboard verás el número real.
   - Si querés corregir ya ese chat sin esperar un mensaje nuevo, podés ejecutar en Supabase (reemplazando por el número y nombre correctos si hace falta):
     ```sql
     UPDATE whatsapp_chats
     SET real_phone = '+5492944535477'
     WHERE name ILIKE '%LAURA VALERIA%' AND (real_phone IS NULL OR real_phone = '');
     ```

4. **Backfill opcional:** en la migración hay un bloque comentado para rellenar `real_phone` desde los mensajes existentes; si en `whatsapp_messages` ya tenés el número real en `phone`, descomentá y ejecutá ese bloque en Supabase.
