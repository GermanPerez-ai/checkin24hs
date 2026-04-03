# Teléfono real en Chats de WhatsApp

## Dónde se guarda

- **Supabase:** tabla `whatsapp_chats`, columna `real_phone` (VARCHAR).
- El dashboard muestra primero `real_phone`; si está vacío, muestra `phone` (que puede ser un ID interno/LID como `95283883040898`).

## Por qué a veces no se ve el número real

WhatsApp puede identificar al contacto por un **LID** (Linked ID) en lugar del número. El servidor (Baileys) intenta resolver LID → número real y guardar en `real_phone`, pero **no siempre** tiene ese mapeo. Si nunca se resolvió, `real_phone` queda NULL y el dashboard muestra el ID.

## Cómo ver el número real en el dashboard

### 1. Actualizar número real a mano (recomendado)

1. Entrá a **Chats** en el dashboard.
2. Abrí la conversación (ej. Axel Bisio).
3. En el bloque **Contacto WhatsApp** hacé clic en **"Actualizar número real"**.
4. Ingresá el número con código de país (ej. `+54 9 2944 57-9759`).
5. Aceptar. Se guarda en `whatsapp_chats.real_phone` y se actualiza la vista.

Así podés cargar el número real para contactos como Axel Bisio aunque el chat haya llegado por LID.

### 2. Rellenar desde mensajes (automático en Supabase)

Si en `whatsapp_messages` ya hay mensajes con `phone` = número real (solo dígitos, sin `@`), podés rellenar `real_phone` de los chats con este script:

1. En **Supabase** → **SQL Editor**.
2. Pegá y ejecutá el contenido de:
   - `supabase-migrations/RELLENAR_REAL_PHONE_DESDE_MENSAJES.sql`

Eso actualiza `whatsapp_chats.real_phone` con el `phone` del último mensaje de cada chat cuando ese valor parece un número real. No modifica chats que ya tengan `real_phone`.

### 3. Servidor WhatsApp (Baileys)

El servidor ya intenta:

- Al recibir un mensaje de un LID, llamar a `resolveLidToPhone()` y, si obtiene número real, actualizar `whatsapp_chats` (phone + real_phone).
- Al crear o actualizar un chat con número “real” (solo dígitos, sin `@`), guardar ese valor en `real_phone`.

Si el mapeo LID→número no está en el estado de Baileys, no se puede resolver hasta que el usuario use **"Actualizar número real"** en el dashboard o se rellene desde mensajes con el script anterior.

## Resumen

| Acción                         | Dónde                         |
|--------------------------------|-------------------------------|
| Ver/editar número en la UI     | Chats → abrir chat → "Actualizar número real" |
| Guardar número en la base      | `whatsapp_chats.real_phone`   |
| Rellenar desde mensajes        | Script `RELLENAR_REAL_PHONE_DESDE_MENSAJES.sql` en Supabase |
