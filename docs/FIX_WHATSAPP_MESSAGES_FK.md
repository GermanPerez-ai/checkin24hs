# Corregir error FK al guardar mensajes (whatsapp_messages)

## Error

```
❌ Error guardando mensaje: insert or update on table "whatsapp_messages" violates foreign key constraint "fk_whatsapp_conversation"
```

## Causa

La tabla `whatsapp_messages` tiene una columna `conversation_id` (o similar) con FK a `whatsapp_conversations(id)`. El servidor obtiene el chat desde `whatsapp_chats` y usa ese `id` como `conversation_id`, pero si no existe la fila correspondiente en `whatsapp_conversations`, el insert falla.

## Cambio en código (whatsapp-server)

Antes de insertar cada mensaje, el servidor ahora llama a **`asegurarConversationExiste(chatId, numero, nombre)`**: hace un **upsert** en `whatsapp_conversations` con el mismo `id` que el chat en `whatsapp_chats`. Así la FK se cumple y el insert en `whatsapp_messages` puede ejecutarse.

- Si la tabla `whatsapp_conversations` **no existe** en tu proyecto de Supabase, el upsert se ignora y el error de FK puede seguir. En ese caso hay que crear la tabla (ver más abajo).
- Si la tabla **existe**, tras desplegar el nuevo código y reiniciar el servicio WhatsApp, los mensajes deberían guardarse sin ese error.

## Opcional: columna message_type

Si además ves:

```
⚠️ Tabla whatsapp_messages no tiene columna message_type, guardando sin ella
```

podés ejecutar en Supabase (SQL Editor) el script **`supabase-migrations/011_whatsapp_messages_message_type.sql`** para agregar la columna. No es obligatorio: el servidor ya guarda sin esa columna si no existe.

## Si whatsapp_conversations no existe

Si en Supabase no tenés la tabla `whatsapp_conversations` y el FK de `whatsapp_messages` apunta a ella, tenés que crearla. Estructura mínima sugerida:

```sql
CREATE TABLE IF NOT EXISTS whatsapp_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  external_id VARCHAR(50) NOT NULL,
  status VARCHAR(20) DEFAULT 'open',
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_whatsapp_conversations_external_id ON whatsapp_conversations(external_id);
```

Luego el servidor podrá hacer upsert con el mismo `id` que usa en `whatsapp_chats` y los mensajes se guardarán correctamente.
