# Integración Prompt General ↔ WhatsApp (Flor IA)

Resumen técnico de cómo el **Prompt General** (Flor IA → General) se persiste en Supabase y lo usa el servidor WhatsApp para las respuestas de Gemini.

---

## Flujo

1. **Dashboard** (Flor IA → General): el usuario edita el prompt y hace "Guardar Configuración General".
2. **Guardado**: se escribe en `localStorage` y en **Supabase** (`system_config`, key `flor_general_config`).
3. **WhatsApp**: al procesar un mensaje, el servidor lee `flor_general_config` (prompt) y la tabla **`hotels`** (base de conocimiento). Arma el prompt completo (system + bloque de hoteles + mensaje + contexto) y llama a Gemini.
4. Tras responder, el servidor inserta en **`flor_interactions`** (`phone`, `user_message`, `bot_response`, etc.). El Dashboard → **Interacciones** muestra ese historial.

---

## Supabase

- **Tabla:** `system_config`
- **Keys usadas por Flor:**
  - **`flor_general_config`**: `name`, `role`, `greeting`, `personality`, `promptGeneral`, `multimodal`. Upsert por `key`; `updated_at` al guardar.
  - **`flor_responses`**: respuestas predefinidas (noEntendido, transferir, despedida, audio/image fallbacks). Dashboard → Flor IA → Respuestas; se guarda en Supabase y localStorage.
  - **`flor_ai_config`**: `enabled`, `provider`, `model`, `temperature`, `maxTokens`. Dashboard → Flor IA → IA.

Upsert por `key`; se usa `updated_at` al guardar.

---

## Dashboard (`dashboard.html`)

- **`saveFlorGeneral`** (async): config General + multimodal → localStorage + Supabase. Soporta `saveFlorGeneral(true)` para modo silencioso (sin alert).
- **`loadFlorGeneral`** (async): Supabase → localStorage → formulario. Se ejecuta al abrir Flor IA.
- **`saveFlorResponses`** (async): respuestas generales y multimodales → localStorage + Supabase (`flor_responses`). Modo silencioso con `saveFlorResponses(true)`.
- **`loadFlorResponses`** (async): Supabase → localStorage → formulario; se ejecuta al abrir Flor IA.
- **`saveAIConfig`** (async): IA (model, temperature, etc.) → localStorage + Supabase (`flor_ai_config`). Modo silencioso con `saveAIConfig(true)`.
- **`saveAllFlorConfig`** (async): guarda General + Respuestas + IA de una vez (sin alerts individuales) y muestra un solo mensaje de éxito. Botón **"Guardar toda la configuración de Flor"** arriba de las pestañas.

---

## Servidor WhatsApp (`whatsapp-server/whatsapp-server-baileys.js`)

- **`FLOR_PROMPT_DEFAULT`**: mismo texto que en el dashboard (fallback si no hay config en Supabase).
- **`getFlorPromptForGemini()`**: lee `system_config` → `flor_general_config` → `promptGeneral`. Cache **5 min**.
- **`getHotelsBlockForFlor()`**: lee tabla **`hotels`** (activos), arma bloque de texto con nombre, ubicación y `flor_info` (descripción, servicios, excursiones, precios, políticas, transporte, contacto). Cache **5 min**.
- **`procesarConFlor`**: obtiene prompt + bloque de hoteles, arma el prompt completo (system + hoteles + mensaje + contexto) y lo envía a Gemini.
- **`guardarFlorInteraction()`**: tras cada respuesta de Flor, inserta en **`flor_interactions`** (`phone`, `user_message`, `bot_response`, `intent`, `success`, `used_ai`, `ai_model`, `whatsapp_instance`, `response_time_ms`).

Si Supabase falla o no hay registro de config, se usa `FLOR_PROMPT_DEFAULT`. Si falla hoteles, se usa un mensaje de fallback.

---

## Dashboard → Interacciones

- **Menú:** "Interacciones" (sección "Interacciones con Flor").
- **Origen:** `getFlorInteractions` (Supabase `flor_interactions`). Las conversaciones por WhatsApp se registran ahí; usar **Actualizar** para ver las últimas.
- **Funciones:** Historial, estadísticas (total, tasa de éxito, intents, respuestas IA), "Analizar", "Ver Detalles", "Exportar".

## Cache (WhatsApp)

- **TTL:** 5 minutos (prompt y hoteles).
- **Efecto:** tras guardar un nuevo prompt o editar hoteles en el Dashboard, WhatsApp puede tardar hasta 5 min en usarlo. Reiniciar el servicio WhatsApp aplica el cambio de inmediato.

---

## Requisitos

- Mismo proyecto Supabase para Dashboard y servidor WhatsApp.
- Variables en el servidor: `SUPABASE_URL`, `SUPABASE_ANON_KEY` (o las que use el cliente Supabase del WhatsApp).
- Tabla `system_config` existente y con columnas `key`, `value`, `updated_at` y unique en `key`.

---

## Build

- **Dashboard:** Build #75 – Prompt General → Supabase + WhatsApp.
