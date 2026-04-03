# Proceso que sigue Flor IA para responder

Este documento describe el flujo completo desde que llega un mensaje (por ejemplo por WhatsApp) hasta que Flor IA envía la respuesta.

---

## 1. Entrada del mensaje

- **WhatsApp:** El servidor (`whatsapp-server-baileys.js`) recibe el evento `messages.upsert` de Baileys cuando alguien envía un mensaje de texto.
- Se extrae el **texto** del mensaje, el **número** (o LID) del remitente y el **nombre**.
- El mensaje se **guarda de inmediato** en Supabase (`whatsapp_messages` y actualización de `whatsapp_chats`).
- Si está habilitado el auto-respuesta y Flor (`AUTO_REPLY` y `FLOR_ENABLED`), el mensaje entra al flujo de Flor.

---

## 2. Acumulación (delay opcional)

- Para no responder a cada mensaje por separado si el usuario escribe varios seguidos, hay un **delay** configurable (`FLOR_DELAY_MS`, por defecto 5 segundos).
- Los mensajes del mismo chat se **acumulan** en una cola por usuario.
- Cuando pasa el tiempo del delay **sin que llegue un mensaje nuevo**, se procesan **todos** los mensajes acumulados en un solo bloque (uno o varios “Consultas”).
- Así Flor puede responder a varias preguntas en una sola respuesta.

---

## 3. Procesamiento con Flor (`procesarConFlor`)

La función `procesarConFlor(mensaje, contexto)` hace lo siguiente, en orden:

### 3.1 Comprobaciones iniciales

- Verifica que Flor esté habilitado (`FLOR_ENABLED`) y que exista `GEMINI_API_KEY`.
- Lee la **configuración de IA** desde Supabase (`flor_ai_config` en `system_config`): si `enabled === false`, no responde.
- Carga las **respuestas predefinidas** desde Supabase (`flor_responses` en `system_config`): saludo, despedida, transferir a humano, rate limit, etc.

### 3.2 Respuestas predefinidas (sin llamar a Gemini)

Si el mensaje coincide con ciertos patrones, se responde **sin usar la IA**:

- **Transferir a humano:** palabras como “hablar con humano”, “transferir”, “asesor humano” → respuesta de `responses.transferir`.
- **Despedida:** “gracias”, “chau”, “hasta luego”, etc. (mensaje corto) → `responses.despedida`.
- **Saludo simple:** “hola”, “buen día”, “buenas”, etc. (mensaje corto) → `responses.saludo`.

Si entra en alguno de estos casos, se devuelve esa respuesta y **termina** el proceso (no se llama a Gemini).

### 3.3 Detección de hotel (RAG selectivo)

- Se toma el texto del mensaje y se buscan **palabras o frases** que puedan referirse a un hotel.
- Se consulta Supabase (**tabla `hotels`**) con `buscarHotelesPorNombreParcial`: se comparan nombre y ubicación del hotel con el término (por ejemplo “Puyehue” → “Termas de Puyehue”).
- Solo se consideran hoteles **activos** (no inactivos).
- Resultado: lista de **hoteles coincidentes** (o vacía si no hay mención clara de hotel).

### 3.4 Construcción del prompt para Gemini

- **Prompt de sistema:** Se obtiene de Supabase (`flor_general_config` en `system_config`) el “Prompt General” de Flor; si no existe, se usa un prompt por defecto (`FLOR_PROMPT_DEFAULT`). Ese texto define el rol, tono y reglas de Flor.
- **Bloque de hoteles (RAG):**  
  - Si se detectaron hoteles: se arma un bloque solo con la información de **esos** hoteles (nombre, ubicación, descripción, servicios, etc. desde `flor_info`).  
  - Si no se detectó ninguno: se indica en el prompt que no hay hotel específico en la consulta.
- **Instrucciones especiales:**  
  - Si hay **un** hotel coincidente: se pide a la IA que **confirme** con el cliente (“¿Te refieres a [hotel]?”) antes de dar toda la información, salvo que el mensaje sea una **confirmación** (sí, ok, correcto, etc.).  
  - Si hay **varios** hoteles: se pide que liste opciones y espere a que el cliente elija uno.  
  - Si el mensaje es una confirmación y ya hay hotel en contexto: se pide dar **toda** la información de ese hotel.
- **Mensaje del usuario:** Se agrega el texto del cliente y, si aplica, una nota de “múltiples consultas” (varios mensajes agrupados).
- **Reglas de prioridad:** Se añade un bloque fijo (`FLOR_REGLAS_PRIORIDAD`) con reglas de brevedad, formato, etc.

Todo eso forma el **system instruction** y el **contenido de usuario** que se envían a la API de Gemini.

### 3.5 Llamada a Gemini

- Se usa el **modelo** configurado en `flor_ai_config` (por ejemplo `gemini-2.5-flash`), con **temperature** y **maxOutputTokens** también de esa config.
- Se envía a la API de Google: `systemInstruction` + `contents` (mensaje del usuario).
- Si Gemini devuelve **429** (límite de uso), se hacen **reintentos** con espera creciente (backoff). Si tras los reintentos sigue fallando, se devuelve la respuesta predefinida de “rate limit” (`responses.rateLimitExceeded`).
- Si el modelo no existe (404), se intenta con un modelo alternativo (por ejemplo `gemini-2.0-flash`).
- Si hay otro error (400, 403, timeout, etc.), se devuelve la respuesta predefinida “no entendido” (`responses.noEntendido`).

### 3.6 Respuesta

- Si todo va bien, la respuesta de Flor es el **texto** generado por Gemini (primer candidato, primera parte de contenido).
- Ese texto (o la respuesta predefinida que corresponda) es lo que devuelve `procesarConFlor`.

---

## 4. Envío de la respuesta y registro

- El servidor toma la respuesta de `procesarConFlor` (string o objeto con `.text`).
- **Formato:** Si el texto tiene enlaces, se puede preparar un mensaje con preview (`prepararMensajeConPreview`).
- Se **envía** el mensaje por WhatsApp con Baileys (`sock.sendMessage`).
- Se **guarda** la respuesta en Supabase (`whatsapp_messages`) y, si está configurado, se registra la **interacción** de Flor (por ejemplo en `flor_interactions`) con mensaje del usuario, respuesta del bot, intención y tiempo de respuesta.

---

## 5. Resumen del flujo (diagrama de pasos)

```
Mensaje llega (WhatsApp)
    ↓
Guardar en Supabase (whatsapp_messages / whatsapp_chats)
    ↓
¿AUTO_REPLY y FLOR_ENABLED? → No: terminar
    ↓ Sí
Acumular en cola por usuario (delay FLOR_DELAY_MS)
    ↓
Al cumplirse el delay → procesarConFlor(mensaje acumulado, contexto)
    ↓
¿Flor deshabilitada en Supabase o sin API key? → Devolver null
    ↓
¿Transferir / despedida / saludo simple? → Devolver respuesta predefinida
    ↓
Buscar hoteles mencionados (Supabase hotels) → RAG selectivo
    ↓
Armar prompt: Prompt General + bloque hoteles + instrucciones + mensaje usuario
    ↓
Llamar a Gemini (modelo, temperature, maxTokens de flor_ai_config)
    ↓
Respuesta de Gemini (o respuesta predefinida si error/429)
    ↓
Enviar mensaje por WhatsApp + guardar en Supabase + registrar interacción
```

---

## 6. Dónde se configura todo

| Qué | Dónde |
|-----|--------|
| Habilitar/deshabilitar Flor | Variables de entorno: `FLOR_ENABLED`, `AUTO_REPLY`; Supabase: `flor_ai_config.enabled` |
| API Key de Gemini | Variable de entorno `GEMINI_API_KEY` (o desde Supabase según implementación) |
| Modelo, temperature, maxTokens | Supabase: `system_config` → key `flor_ai_config` |
| Prompt General (rol, reglas de Flor) | Supabase: `system_config` → key `flor_general_config` |
| Respuestas predefinidas (saludo, despedida, etc.) | Supabase: `system_config` → key `flor_responses` |
| Datos de hoteles para Flor | Supabase: tabla `hotels` (nombre, ubicación, `flor_info`, estado) |
| Delay antes de responder | Variable de entorno `FLOR_DELAY_MS` (por defecto 5000 ms) |

---

## 7. Otros canales (Instagram / Facebook)

Si usás el **meta-messaging-server**, el flujo es el mismo para la parte de Flor:

1. Meta envía el mensaje al webhook.
2. El servidor de Meta llama a `POST /api/flor/process` del servidor WhatsApp con el texto y contexto.
3. El servidor WhatsApp ejecuta **el mismo** `procesarConFlor` (mismas reglas, mismo Gemini, mismo RAG).
4. La respuesta se devuelve al meta-messaging-server y este la envía por la API de Meta (Instagram/Messenger).

Es decir: **el proceso de Flor es el mismo**; solo cambia quién entrega el mensaje y quién envía la respuesta (WhatsApp vs Meta).
