# Schema whatsapp_messages y por qué no se guardaban mensajes

## Tu schema (compatible)

Tu tabla `whatsapp_messages` tiene las columnas que usa el servidor:

- **conversation_id** (NOT NULL, FK → whatsapp_conversations.id)
- **chat_id** (nullable, FK → whatsapp_chats.id)
- **direction**, **sender**, **recipient**, **message**, **phone**, **is_from_me**, **is_read**, **whatsapp_instance**, **message_type**
- **body**, **sent_at** (opcionales)

El servidor ya envía **body** y **sent_at** además de **message** para alinearse con este schema.

---

## Por qué la tabla puede quedar vacía

El INSERT a `whatsapp_messages` exige que **conversation_id** exista en **whatsapp_conversations** (FK).

Si para el chat de German tenés:

- **whatsapp_chats**: una fila con `id = e9adc152-0e13-40...` (por ejemplo)
- **whatsapp_conversations**: ninguna fila con ese mismo `id`

entonces el INSERT falla por FK y los mensajes no se guardan.

El servidor hace:

1. Crear o obtener el chat en **whatsapp_chats** → obtiene `chatId`.
2. Llamar a **asegurarConversationExiste(chatId, numero, nombre)** → hace upsert en **whatsapp_conversations** con `id = chatId`.
3. Insertar en **whatsapp_messages** con `conversation_id = chatId` y `chat_id = chatId`.

Si el paso 2 falla (por ejemplo por columnas obligatorias en `whatsapp_conversations` que no enviamos, o por permisos), no existe la fila en `whatsapp_conversations` y el paso 3 falla.

---

## Qué verificar en Supabase

1. Para el chat de German, en **whatsapp_chats** anotá el **id** (UUID) de esa fila.
2. En **whatsapp_conversations** buscá una fila con **id** = ese mismo UUID.
   - Si **no existe**: ese es el motivo por el que no se guardan mensajes. Hay que lograr que el servidor cree esa fila (o crearla a mano una vez para probar).
   - Si **existe**: el problema puede ser otro (permisos RLS, red, etc.). En los logs del servidor debería aparecer el error al hacer el INSERT.

---

## Crear la conversación a mano (prueba)

Para el chat que ya tenés (German), podés crear la fila en **whatsapp_conversations** con el mismo **id** que el chat:

1. En **whatsapp_chats** copiá el **id** de la fila de German (ej. `e9adc152-0e13-40...`).
2. En **whatsapp_conversations** insertá una fila con:
   - **id** = ese mismo UUID
   - **external_id** = `5492944210725` (o el número que uses)
   - **status** = `open`
   - **metadata** = `{"phone":"5492944210725","name":"German","whatsapp_instance":1}` (ajustar si tenés más campos obligatorios)

Después de eso, los nuevos mensajes que guarde el servidor para ese chat deberían insertarse bien. Y en **whatsapp_chats** podés poner **real_phone** = `5492944210725` para que el dashboard muestre el número correcto.

---

## Cambios hechos en el servidor

- Se envían **body** y **sent_at** en el INSERT a `whatsapp_messages`.
- Si el INSERT falla por FK (conversation_id), en logs aparece un mensaje claro indicando que falta la fila en `whatsapp_conversations` con ese id.

Redeploy del servicio WhatsApp para aplicar los cambios.
