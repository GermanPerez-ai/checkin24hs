# Conectar Flor IA con Instagram y Facebook Messenger

Flor IA ya está conectada a **WhatsApp**. Para que también responda en **Instagram** y **Facebook Messenger** se usa un servidor de webhook que recibe los mensajes de Meta y los procesa con la misma Flor.

## Qué se agregó en el proyecto

1. **Endpoint en el servidor WhatsApp**  
   - `POST /api/flor/process`: recibe `{ message, context }` y devuelve `{ response }` (respuesta de Flor).  
   - Lo usan otros canales (Instagram, Facebook, etc.) para no duplicar la lógica de Flor.

2. **Servicio `meta-messaging-server`**  
   - Carpeta: `meta-messaging-server/`  
   - Recibe el webhook de Meta (Instagram y Messenger), llama a Flor con el mensaje del usuario y envía la respuesta por la API de Meta.

## Pasos para tener Flor en Instagram y Facebook

### 1. App en Meta (Facebook Developers)

1. Entrá a [developers.facebook.com](https://developers.facebook.com) y creá una app de tipo **Negocio** (o usá una existente).
2. Agregá los productos:
   - **Instagram** → permisos: `instagram_basic`, `instagram_manage_messages`, `pages_manage_metadata`
   - **Messenger** → permisos: `pages_messaging` (y lo que pida la app)
3. Vinculá una **Página de Facebook** a la app y, si querés Instagram DMs, una **cuenta Instagram Professional** (Business/Creator) a esa misma Página.

### 2. Desplegar el servidor de webhook

- El servidor debe estar en una **URL pública HTTPS** (ej: `https://meta-webhook.checkin24hs.com`).  
- En EasyPanel (o tu hosting):
  - Creá un servicio desde la carpeta `meta-messaging-server` (mismo repo, ruta de compilación `/meta-messaging-server`, Dockerfile).
  - Variables de entorno:
    - `FLOR_API_URL`: URL del servidor WhatsApp (ej: `https://whatsapp.checkin24hs.com` o `http://whatsapp:3001` si está en la misma red).
    - `META_VERIFY_TOKEN`: un valor secreto que vas a poner también en Meta (ej: `checkin24hs_flor_verify`).
    - `META_PAGE_ACCESS_TOKEN`: Page Access Token de la Página (con permisos de mensajería y, si usás Instagram, de Instagram).
  - Dominio: que apunte a ese servicio (ej: `meta-webhook.checkin24hs.com`).

Detalle de variables y despliegue: ver `meta-messaging-server/README.md`.

### 3. Configurar el webhook en Meta

**Instagram**

1. En la app → **Instagram** → Configuración → Webhooks.
2. URL de devolución: `https://meta-webhook.checkin24hs.com/webhook`
3. Token de verificación: el mismo valor que `META_VERIFY_TOKEN`.
4. Suscribir: **messages**.

**Facebook Messenger**

1. En la app → **Messenger** → Configuración → Webhooks.
2. Misma URL: `https://meta-webhook.checkin24hs.com/webhook`
3. Mismo token de verificación.
4. Suscribir: **messages** (y conectar la Página si te lo pide).

### 4. Token de acceso (Page Access Token)

- En la app, en Graph API Explorer o en la configuración de la Página, generá un **Page Access Token** con:
  - `pages_messaging` (Messenger)
  - `instagram_manage_messages` (y `instagram_basic`, `pages_manage_metadata` si usás Instagram).
- Ese token es el que va en `META_PAGE_ACCESS_TOKEN` en el servidor de webhook.

## Flujo resumido

1. El usuario escribe por Instagram DM o Messenger.
2. Meta envía un POST a `https://meta-webhook.checkin24hs.com/webhook`.
3. El servidor `meta-messaging-server` recibe el mensaje, llama a `FLOR_API_URL/api/flor/process` con el texto y contexto.
4. El servidor WhatsApp (Flor) responde con la respuesta de la IA.
5. El servidor de webhook envía esa respuesta al usuario con la API de Meta.

Así Flor IA queda conectada a los chats de Instagram y Facebook usando la misma configuración de Flor (Gemini, hoteles, respuestas) que ya tenés en WhatsApp.
