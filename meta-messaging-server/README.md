# Meta Messaging Server - Flor IA (Instagram + Facebook)

Servidor de webhook para conectar **Flor IA** con los chats de **Instagram** y **Facebook Messenger**. Recibe mensajes por webhook, los procesa con Flor (vía API del servidor WhatsApp) y responde por la API de Meta.

## Requisitos

1. **App en Meta for Developers** con productos:
   - Instagram Messaging (permisos: `instagram_basic`, `instagram_manage_messages`, `pages_manage_metadata`)
   - Messenger (permisos: `pages_messaging`)

2. **Cuenta Instagram Professional** (Business o Creator) vinculada a una **Página de Facebook** (para Instagram DMs).

3. **Servidor WhatsApp** desplegado y con Flor IA configurada (endpoint `/api/flor/process`).

4. **URL pública HTTPS** para el webhook (Meta no acepta HTTP ni localhost en producción).

## Variables de entorno

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `PORT` | Puerto del servidor | `3010` |
| `FLOR_API_URL` | URL base del servidor WhatsApp (Flor) | `https://whatsapp.checkin24hs.com` |
| `META_VERIFY_TOKEN` | Token que configurás en Meta para verificar el webhook | `checkin24hs_flor_verify` |
| `META_PAGE_ACCESS_TOKEN` | Page Access Token (Messenger) / mismo token para Instagram si está vinculado | Token largo de Meta |

## Configuración en Meta

### 1. Crear la app

- Entrá a [developers.facebook.com](https://developers.facebook.com) → Mis apps → Crear app → Tipo "Negocio".
- Agregá el producto **Instagram** y **Messenger** (o "Meta Business Suite" según la interfaz).

### 2. Permisos

- **Instagram**: `instagram_basic`, `instagram_manage_messages`, `pages_manage_metadata` (Advanced Access si querés recibir mensajes de cualquier usuario).
- **Messenger**: `pages_messaging` (y `pages_manage_metadata` si hace falta).

### 3. Webhook

- En la app → Configuración → Básica: anotá el **ID de la app** y el **Secreto de la app**.
- En **Instagram** → Configuración → Webhooks: "Configurar" o "Editar suscripción".
- **URL de devolución**: `https://tu-dominio.com/webhook` (donde esté desplegado este servidor).
- **Token de verificación**: el mismo valor que `META_VERIFY_TOKEN` (ej: `checkin24hs_flor_verify`).
- Suscribir: **messages** (y opcionalmente **messaging_postbacks**, **message_reactions**).

Repetir para **Messenger** (Página de Facebook) si usás Facebook Messenger: mismo URL y token, suscribir **messages**.

### 4. Token de acceso

- **Page Access Token**: En la app → Herramientas → Graph API Explorer (o Página → Configuración de la app).
- Seleccioná la Página y los permisos (`pages_messaging`, `instagram_manage_messages`, etc.) y generá un token.
- Para producción: token de larga duración o token del sistema (recomendado). Ese valor es `META_PAGE_ACCESS_TOKEN`.

Para **Instagram**: si la cuenta de Instagram está vinculada a la Página, el mismo Page Access Token suele servir para enviar mensajes por Instagram. Si usás la API nueva solo con Instagram (sin Página), podés tener un token específico de Instagram; en ese caso podés usar una variable extra y adaptar el código si hace falta.

## Despliegue (EasyPanel u otro)

1. Clonar/desplegar este repo; **Build context** o carpeta del servicio: `/meta-messaging-server`.
2. En el servicio, definir:
   - `FLOR_API_URL`: URL interna del servicio WhatsApp (ej: `http://whatsapp:3001`) o URL pública (ej: `https://whatsapp.checkin24hs.com`).
   - `META_VERIFY_TOKEN`: mismo que en el webhook de Meta.
   - `META_PAGE_ACCESS_TOKEN`: Page Access Token (y/o token de Instagram si es distinto).
3. Exponer el puerto (ej. 3010) y configurar dominio HTTPS (ej. `https://meta-webhook.checkin24hs.com`) para que la URL del webhook sea `https://meta-webhook.checkin24hs.com/webhook`.
4. En Meta, configurar esa URL y el token de verificación; suscribir **messages** en Instagram y en Messenger.

## Flujo

1. Un usuario envía un mensaje por Instagram DM o Facebook Messenger.
2. Meta envía un POST a `https://tu-dominio.com/webhook` con el evento.
3. Este servidor responde 200 y, en segundo plano, extrae el texto, llama a `FLOR_API_URL/api/flor/process` con el mensaje y contexto.
4. Flor (servidor WhatsApp) responde con el texto de Flor IA.
5. Este servidor envía esa respuesta al usuario con la Graph API de Meta (`POST .../messages`).

## Health

- `GET /health`: devuelve estado del servicio y si tiene token configurado.

## Notas

- Los mensajes con GIF o sticker en Instagram pueden no disparar webhook (limitación de Meta).
- En modo desarrollo, solo recibís mensajes de usuarios con rol en la app; para cualquiera necesitás Advanced Access y revisión de Meta si aplica.
