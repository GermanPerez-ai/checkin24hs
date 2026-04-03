# Flor web: de dónde sale la respuesta y qué prompt usa

Flor en la web puede responder por **tres caminos**, en este orden:

---

## 1. Flor API (servidor WhatsApp)

- **Cuándo:** Si en la URL del iframe está `florApiUrl` (ej. `https://whatsapp.checkin24hs.com`) y el servidor permite CORS desde `https://www.checkin24hs.com`.
- **Origen:** El mismo backend que WhatsApp. Mismo prompt, misma base de hoteles, misma lógica.
- **En consola:** `[Flor AI] 📡 Origen: intentando Flor API (WhatsApp)` y, si va bien, `[Flor AI] 🌸 Respuesta desde Flor API (misma que WhatsApp)`.
- **Prompt:** El que usa el servidor WhatsApp (Supabase `flor_general_config`, `flor_responses`, hoteles, etc.).

---

## 2. Gemini en el navegador

- **Cuándo:** Si la Flor API no se usa (CORS, error, etc.) y en Supabase hay `flor_ai_config` con `apiKey` de Gemini.
- **Origen:** Prompt = **flor_general_config.promptGeneral** (Supabase) + bloque de hoteles (mismo estilo que WhatsApp) + reglas de prioridad.
- **En consola:** `[Flor AI] 📋 Origen: Gemini. Prompt = flor_general_config (Supabase) | Hoteles: 8`.
- **Datos:** Hoteles desde Supabase (`hotels` + `flor_info`), mismo formato que en WhatsApp.

---

## 3. Reglas + flor_info (sin IA)

- **Cuándo:** Si no hay Flor API y no hay API key de Gemini (o falla).
- **Origen:** Lógica de reglas en `flor-agent.js`: detecta intención (ej. `consulta_hotel`) y arma la respuesta con **flor_info** de cada hotel (Supabase, tabla `hotels`, columna `flor_info`) y/o `flor_hotel_knowledge` (system_config).
- **En consola:** `[Flor Agent] 📋 Origen: reglas (sin Flor API/Gemini). Intent: consulta_hotel` y `[Flor Agent] 🏨 Hotel: Corralco | flor_info: true/false | description: true/false`.
- **Prompt:** No hay un único “prompt”; la respuesta se construye con descripción, servicios, etc. de `flor_info` y conocimiento extra.

---

## Cómo ver qué camino se está usando

Abrí la consola (F12) y enviá un mensaje a Flor. Fijate cuál de estos aparece:

- `[Flor AI] 📡 Origen: intentando Flor API` → intenta usar WhatsApp.
- `[Flor AI] 🌸 Respuesta desde Flor API` → la respuesta vino de WhatsApp.
- `[Flor AI] Flor API no alcanzable (¿CORS?)` → la API falló; sigue con Gemini o reglas.
- `[Flor AI] 📋 Origen: Gemini` → está usando Gemini con prompt de Supabase.
- `[Flor AI] ⚠️ Origen: sin API key` → no hay Gemini; usa solo reglas + flor_info.
- `[Flor Agent] 📋 Origen: reglas` → respuesta armada por reglas y `flor_info`.

Si ves **reglas** y la respuesta es corta, revisá `[Flor Agent] 🏨 Hotel: ... | flor_info: ... | description: ...`. Si `flor_info` o `description` es false, en Supabase ese hotel no tiene `flor_info` (o `description`) cargado; hay que completar la columna `flor_info` en la tabla `hotels` para ese hotel.
