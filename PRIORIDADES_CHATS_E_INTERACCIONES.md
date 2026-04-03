# Chats vs Interacciones – Estado actual y prioridades

Resumen de lo que querés lograr, lo que hay hoy y en qué orden conviene conectarlo.

---

## 1. Lo que querés (tu definición)

| Sección | Objetivo |
|--------|----------|
| **Chats** | Que se vayan **reflejando** las conversaciones con Flor **y** las respuestas de los **agentes** (humanos). |
| **Interacciones** | Que se reflejen las **interacciones de Flor** para que vaya **aprendiendo** a lo largo del tiempo. |

---

## 2. Estado actual

### 2.1 Chats (Dashboard → Chats)

| Qué | Estado |
|-----|--------|
| **Lista de conversaciones** | Se carga desde **Supabase** (`whatsapp_chats`) vía `getWhatsAppChats`. Se muestra lista con nombre/teléfono, último mensaje y hora. |
| **Al hacer clic en un chat** | Hoy se busca en **localStorage** (`flor_active_chats`) y se muestran `chat.messages`. Esos datos **no** se rellenan desde Supabase: los chats vienen de `whatsapp_chats`, pero al seleccionar no se usa eso ni se piden los mensajes. |
| **Mensajes Flor vs agentes** | Existe `getWhatsAppMessages(chatId)` que lee de **`whatsapp_messages`** (por `chat_id`). Esa tabla tiene `is_from_me` (cliente vs “nosotros”). Tanto Flor como los agentes envían desde el mismo número, así que hoy no se distingue “Flor” vs “Agente” en los mensajes. |
| **Actualización en vivo** | Hay suscripción a cambios en `whatsapp_messages` y `whatsapp_chats`; al haber inserción se vuelve a llamar `loadChats`. |

**Conclusión:** La lista de Chats viene bien de Supabase, pero **al abrir un chat no se cargan los mensajes desde `whatsapp_messages`** y se usa localStorage que no se sincroniza. Falta **conectar** la selección de chat con `getWhatsAppMessages` y pintar ahí **toda** la conversación (usuario + respuestas de Flor y agentes).

### 2.2 Interacciones (Dashboard → Interacciones)

| Qué | Estado |
|-----|--------|
| **Origen de datos** | **`flor_interactions`** en Supabase. Se cargan con `getFlorInteractions`. |
| **Qué se muestra** | Tabla: fecha, cliente (teléfono/email), mensaje del usuario, intent, estado (Resuelto/Pendiente), “Ver Detalles”. |
| **Quién escribe** | El **servidor WhatsApp** inserta en `flor_interactions` cada vez que Flor responde (`guardarFlorInteraction`). El Dashboard y el CRM también pueden escribir. |
| **Aprendizaje** | Hoy solo se **muestra y analiza** (estadísticas, “Analizar”, exportar). Eso **no** actualiza aún la base que Flor usa al responder (prompt, conocimiento, etc.). |

**Conclusión:** Interacciones **sí reflejan** las interacciones de Flor y sirven para analizar. El uso para **“que vaya aprendiendo”** (alimentar conocimiento de Flor) todavía no está implementado.

---

## 3. Cómo priorizar

### Prioridad 1 – Chats: que reflejen conversaciones reales (Flor + agentes)

1. **Al seleccionar un chat** de la lista (origen: `whatsapp_chats`):
   - Usar el `id` de ese chat (no localStorage).
   - Llamar **`getWhatsAppMessages(chatId)`** y cargar los mensajes desde **`whatsapp_messages`**.
2. **Mostrar el hilo completo**: mensajes del cliente y mensajes “nuestros” (`is_from_me`), es decir, **respuestas de Flor y de agentes** (hoy ambas llegan del mismo número).
3. Dejar de depender de `flor_active_chats` en localStorage para el contenido del chat; usar Supabase como fuente de verdad.
4. Opcional: si en el futuro se guarda en `whatsapp_messages` si el mensaje es de Flor o de agente (ej. columna `source`), se podrá etiquetar “Flor” vs “Agente” en la UI.

Con esto, **Chats** pasa a reflejar de verdad las conversaciones que se van generando con Flor y las respuestas de los agentes.

### Prioridad 2 – Interacciones: que sigan sirviendo para aprender

- **Ya cumplen** el objetivo de “reflejar” las interacciones de Flor.
- Mejoras posibles:
  - Asegurar que “Actualizar” traiga siempre lo último de `flor_interactions`.
  - Mantener el “Analizar” y las estadísticas para explotar esos datos.
- **“Que vaya aprendiendo”**: en un paso posterior se puede hacer que el análisis de interacciones (intents, preguntas frecuentes, etc.) **derive** en reglas o Q&A que se guarden en la base que usa Flor (por ejemplo en `flor_general_config` o una tabla de conocimiento) y que Flor use al responder. Eso es la parte de **aprendizaje → conocimiento**, todavía no hecha.

### Prioridad 3 – Conectar Flor (Respuestas + IA) en el servidor WhatsApp

- Hacer que el servidor use **`flor_responses`** (no entendido, transferir, despedida, etc.) y **`flor_ai_config`** (modelo, temperatura, etc.) desde Supabase.
- Es independiente de Chats/Interacciones pero importante para que la configuración del Dashboard controle bien a Flor.

---

## 4. Orden sugerido para “bajar al código y conectar”

1. **Chats:** Conectar `selectChat` con `getWhatsAppMessages`, mostrar el hilo completo desde `whatsapp_messages` y dejar de usar `flor_active_chats` para el contenido. Así Chats refleja bien las conversaciones (Flor + agentes).
2. **Interacciones:** Revisar que “Actualizar” y el análisis sigan funcionando bien sobre `flor_interactions`. Dejar documentado que el “aprendizaje” (usar interacciones para mejorar a Flor) va en una siguiente fase.
3. **Flor en WhatsApp:** Conectar Respuestas e IA en el servidor (leer `flor_responses` y `flor_ai_config` desde Supabase).

Si estás de acuerdo con este orden, el siguiente paso práctico es implementar el punto 1 (Chats) en el Dashboard.
