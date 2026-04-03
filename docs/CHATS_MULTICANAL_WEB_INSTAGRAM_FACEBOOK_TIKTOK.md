# Chats multi-canal: Web, Instagram, Facebook, TikTok

Los chats de Flor por **web**, y en el futuro por **Instagram**, **Facebook** y **TikTok**, se guardan en las mismas tablas que WhatsApp y se ven en el **mismo chat del dashboard**.

## Cómo funciona

- **Tablas:** `whatsapp_chats` y `whatsapp_messages` tienen una columna `channel` (`whatsapp` | `web` | `instagram` | `facebook` | `tiktok`).
- **Dashboard:** En la lista de chats se muestran todos los canales; cada chat tiene una etiqueta (Web, Instagram, etc.). Los de WhatsApp permiten responder desde el dashboard; el resto son solo lectura.
- **API:** `POST /api/flor/process` acepta opcionalmente `channel`, `external_id` y `display_name`. Si se envían, la conversación se guarda en Supabase y aparece en el dashboard.

## Web (ya implementado)

- El chatbot Flor en la página llama a la Flor API con `channel: 'web'`, `external_id: <sessionId>` (localStorage) y `display_name: 'Visitante web'`.
- Mismo visitante = mismo `external_id` = un solo hilo en el dashboard.

## Conectar Instagram, Facebook o TikTok

1. **Backend de la red** (Meta Business API, TikTok API, etc.): cuando llegue un mensaje, obtener el texto y un identificador estable del usuario (ej. `psid` de Meta, `user_id` de TikTok).

2. **Llamar a Flor:**
   ```http
   POST https://whatsapp.checkin24hs.com/api/flor/process
   Content-Type: application/json

   {
     "message": "Texto del mensaje del usuario",
     "context": {},
     "channel": "instagram",
     "external_id": "123456789",
     "display_name": "Usuario Instagram"
   }
   ```

3. **Respuesta:** El servidor devuelve `{ "response": "...", "success": true }`. Esa respuesta hay que enviarla al usuario por la API de la red (Instagram/Facebook/TikTok).

4. **Dashboard:** El chat aparecerá en la lista con la etiqueta "Instagram" (o "Facebook", "TikTok") y el nombre que hayas puesto en `display_name`.

Valores de `channel` recomendados: `web`, `instagram`, `facebook`, `tiktok`. Cualquier otro valor también se guarda y se muestra en el dashboard.

## Migración en Supabase

Ejecutá la migración para agregar las columnas de canal:

```sql
-- Ver supabase-migrations/030_chats_multi_canal.sql
```

Luego, en el SQL Editor de Supabase, ejecutá el contenido de ese archivo.
