# Base de conocimiento de Flor IA – Dónde está y qué la usa

Resumen de **dónde** se guarda la base de conocimiento y las interacciones de Flor, y **qué** las usa hoy.

---

## 1. Conocimiento por hotel (Base de conocimiento por hotel)

**Dónde se guarda**

| Ubicación | Clave / tabla | Contenido |
|-----------|----------------|-----------|
| **localStorage** (navegador) | `flor_hotel_knowledge` | Objeto `{ [hotelId]: { description, servicesDetail, pricing, transport, notes, websiteInfo } }` |
| **Supabase** | Tabla `hotels`, columna `flor_info` (o `florInfo`) | Info de Flor por hotel (servicios, excursiones, precios, políticas, etc.) |

**Dónde se edita**

- **Dashboard** → Flor IA → **📚 Conocimiento**: selector de hotel, ver/editar base por hotel.
- **Dashboard** → Hoteles → Editar hotel → sección **"Base de Conocimiento Adicional"** (description, services, pricing, transport, notes, etc.).

**Qué lo usa hoy**

- Dashboard y CRM (Flor, generación de respuestas en la UI, etc.).
- El **servidor WhatsApp** (`whatsapp-server-baileys.js`) **sí** lee la tabla `hotels` (Supabase), incluyendo `flor_info` / `florInfo`, y arma un bloque de conocimiento que envía a Gemini junto con el Prompt General. Cache 5 min.

**Conclusión:** La base por hotel se edita en Dashboard → Hoteles y **se usa** en las respuestas de Flor por WhatsApp.

---

## 2. Interacciones (cuando Flor “interactúa”)

**Dónde se guarda**

| Ubicación | Tabla / clave | Contenido |
|-----------|----------------|-----------|
| **Supabase** | `whatsapp_messages` | Mensajes de WhatsApp (entrantes y salientes). El servidor Baileys guarda aquí. |
| **Supabase** | `flor_interactions` | Interacciones tipo “Flor”: `user_message`, `bot_response`, `intent`, `success`, `used_ai`, `phone`, etc. |
| **localStorage** (Dashboard) | `flor_interactions` | Copia local / backup de interacciones para el Dashboard. |

**Quién escribe en `flor_interactions`**

- **Dashboard**: `saveFlorInteraction` / `saveFlorInteractionHelper` (vía `supabase-client`) cuando se registran interacciones desde la UI.
- **CRM**: `FlorLearningSystem` y lógica asociada.
- **Servidor WhatsApp Baileys**: cada vez que Flor responde por WhatsApp, el servidor inserta en `flor_interactions` (`phone`, `user_message`, `bot_response`, `intent`, `success`, `used_ai`, `ai_model`, `whatsapp_instance`, `response_time_ms`). También sigue guardando mensajes en `whatsapp_messages`.

**Qué lo usa hoy**

- **Dashboard** → **Interacciones** (menú lateral): “Interacciones con Flor”. Historial desde `getFlorInteractions`, estadísticas, “Analizar”, “Ver Detalles”, “Exportar”. Las conversaciones por WhatsApp se registran ahí; usar **Actualizar** para ver las últimas.
- **Supabase**: `getFlorInteractions`, `analyzeFlorInteractions`, etc.

**Conclusión:** Las interacciones de Flor (UI + WhatsApp) viven en `flor_interactions`. El servidor WhatsApp **sí** guarda ahí al responder.

---

## 3. Sistema de “aprendizaje” de Flor

**Dónde se guarda**

- **CRM** (`flor-learning-system.js`): `flor_learning_config`, `flor_learning_interactions`, `flor_learning_stats`, etc. en **localStorage**.
- **Dashboard**: análisis sobre `flor_interactions` (Supabase o localStorage).

**Qué hace**

- Guarda y analiza interacciones (éxito/fallo, intents, patrones).
- Muestra estadísticas y sugerencias de mejora.
- **No** actualiza hoy una “base de conocimiento” que Flor use en tiempo real al responder (ni en Dashboard ni en WhatsApp).

---

## 4. Resumen rápido

| Concepto | Dónde se guarda | ¿Lo usa el WhatsApp (Flor) al responder? |
|----------|------------------|------------------------------------------|
| **Prompt General** | `system_config.flor_general_config` (Supabase) + localStorage | ✅ Sí |
| **Base por hotel** | `hotels` (Supabase), `flor_info` por hotel | ✅ Sí (bloque en prompt) |
| **Interacciones** | `flor_interactions` (Supabase + localStorage), `whatsapp_messages` (Supabase) | ✅ WhatsApp escribe en ambos |
| **Aprendizaje** | localStorage (CRM) + análisis en Dashboard | ❌ No se usa aún para enriquecer respuestas |

---

## 5. Próximos pasos posibles

- **Hecho:** El servidor WhatsApp lee `hotels` + `flor_info` y arma un bloque de conocimiento para Gemini; escribe en `flor_interactions` al responder.
- **Pendiente (opcional):**
  1. **Historial en el prompt**: recuperar últimas N mensajes del chat y enviarlos en el contexto a Gemini (respetando tokens).
  2. **Aprendizaje → conocimiento**: que el análisis de interacciones derive en Q&A o reglas que Flor use al responder.
