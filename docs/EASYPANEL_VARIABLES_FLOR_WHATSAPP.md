# Variables de entorno en EasyPanel para Flor (WhatsApp)

En la sección **Chats** del Dashboard, quien contesta como Flor es el **servidor de WhatsApp**, no el Dashboard. Las variables se configuran en el **servicio de WhatsApp** en EasyPanel.

---

## Dónde configurarlas

1. En EasyPanel, abrí el **servicio/app de WhatsApp** (por ejemplo **checkin24hs / whatsapp** o el nombre que tenga en tu panel).
2. Entrá a **Variables de entorno** (o **Environment**).
3. Agregá las variables que necesites (ver abajo).
4. Guardá y **reiniciá** el servicio para que tome los cambios.

---

## Variables que usa Flor en el servidor WhatsApp

| Variable | Obligatoria | Descripción |
|----------|-------------|-------------|
| **GEMINI_API_KEY** | Sí (para que Flor use IA) | API Key de Google AI Studio (Gemini). Sin ella, Flor no puede generar respuestas con IA. |
| **GEMINI_MODEL** | No | Modelo a usar. Por defecto en código: `gemini-3.1-flash-lite-preview` (migración desde 2.0, anunciado apagado ~jun 2026). Podés fijar otro modelo estable cuando Google lo publique sin `-preview`. |
| **SUPABASE_URL** | Sí | URL del proyecto Supabase. Ej: `https://lmoeuyasuvoqhtvhkyia.supabase.co` |
| **SUPABASE_ANON_KEY** | Sí | Clave anon de Supabase (Project Settings → API). Para leer hoteles, configuración de Flor, chats. |
| **FLOR_ENABLED** | No | `true` o `false`. Por defecto `true`. Si es `false`, Flor no responde automáticamente. |
| **FLOR_DELAY_MS** | No | Milisegundos para agrupar mensajes antes de responder (ej. `5000`). |
| **IMAGEN_COTIZACION_URL** | No | URL de imagen para enlaces de cotización en WhatsApp. Opcional. |

---

## Cómo obtener GEMINI_API_KEY

1. Entrá a [Google AI Studio](https://aistudio.google.com/apikey).
2. Creá o elegí una API key.
3. Copiá el valor y pegalo en **GEMINI_API_KEY** en EasyPanel (servicio WhatsApp).

---

## Resumen por servicio en EasyPanel

| Servicio / App | Qué hace | Variables típicas |
|----------------|----------|-------------------|
| **appwebcheckin24hs** (web) | Sitio www.checkin24hs.com, widget Flor en la web | **Build args:** VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY, VITE_FLOR_CHATBOT_URL |
| **whatsapp** | Flor contesta por WhatsApp; Chats en el Dashboard | **Env vars:** GEMINI_API_KEY, SUPABASE_URL, SUPABASE_ANON_KEY, (opcional) GEMINI_MODEL, FLOR_ENABLED |
| **Dashboard** | dashboard.checkin24hs.com | Suele usar config en el HTML o en el deploy; no suele usar env en EasyPanel. |

Si Flor ya contesta en Chats, es porque el servicio WhatsApp ya tiene Supabase y probablemente GEMINI_API_KEY configurados. Si querés cambiar modelo, delay o desactivar Flor, usá **FLOR_ENABLED** o **GEMINI_MODEL** en ese mismo servicio.
