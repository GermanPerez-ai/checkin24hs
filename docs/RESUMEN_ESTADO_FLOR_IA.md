# Resumen: cómo está armada Flor IA

Además del **Prompt General** que está en Supabase, Flor IA usa otras configuraciones en Supabase, variables de entorno y lógica fija en el servidor. Este doc resume todo.

**Hoja de ruta completa (propuesta Gemini):** ver `docs/HOJA_DE_RUTA_FLOR_GEMINI.md` (especificación literal, tabla `fichas_hoteles` o ampliación de Hotels, lógica de búsqueda/PDF/multimedia, tareas pendientes, mensaje de bienvenida oficial).

---

## 1. Supabase (tabla `system_config`)

Todo se guarda por **clave** en `system_config` (campo `key`). El **valor** suele ser JSON en la columna `value`.

| Clave | Qué es | Dónde se edita |
|-------|--------|-----------------|
| **flor_general_config** | Prompt General + nombre, saludo, multimodal. El servidor usa **solo** `promptGeneral` para el texto del prompt. | Dashboard → Flor IA → Configuración → Prompt General (y Guardar). |
| **flor_ai_config** | Modelo, temperatura, tokens, activar/desactivar Flor. | Dashboard → Flor IA → pestaña IA (o directo en Supabase). |
| **flor_responses** | Respuestas predefinidas: saludo, despedida, transferir, noEntendido, rateLimitExceeded, etc. | Dashboard → Flor IA → Respuestas predefinidas (si existe) o Supabase. |

**Prioridad:** Si existe en Supabase, el servidor usa eso. Si no, usa los valores por defecto del código.

---

## 2. Prompt que usa Flor (resumen)

- **Prompt “base”:**  
  Viene de **Supabase** (`flor_general_config` → `promptGeneral`) si está guardado.  
  Si no hay nada en Supabase, se usa el **FLOR_PROMPT_DEFAULT** del código (prompt mínimo con function calling).
- **Reglas que siempre se agregan (código):**  
  Se concatenan siempre al prompt que venga de Supabase o default:
  - Usar **siempre** la función `consultarCatalogoHoteles` para hoteles; no inventar datos.
  - Saludo formal solo en el **primer mensaje**; después ir directo al tema.
  - Emojis con **mesura** (uno o dos por mensaje).

Es decir: **Prompt General en Supabase** + **reglas inyectadas en código** = lo que realmente ve la IA.

---

## 3. Configuración de IA (modelo, temperatura, etc.)

- **Origen:** Supabase `flor_ai_config` (JSON) o, si no existe, **FLOR_AI_CONFIG_DEFAULT** en código.
- **Valores por defecto en código:**
  - `enabled: true`
  - `model: 'gemini-3.1-flash-lite-preview'` (o el ID estable que publique Google)
  - `temperature: 0.7`
  - `maxTokens: 500`
- **Variables de entorno (EasyPanel):**  
  `GEMINI_MODEL` y `GEMINI_API_KEY` pueden sobreescribir modelo y clave. El servidor combina: primero Supabase, luego env.

---

## 4. Respuestas predefinidas (sin llamar a Gemini)

- **Origen:** Supabase `flor_responses` o **FLOR_RESPONSES_DEFAULTS** en código.
- Se usan cuando el mensaje es:
  - **Transferir a humano** (palabras como "agente", "asesor", "humano").
  - **Despedida** ("gracias", "chau", "adiós", etc.).
  - **Saludo simple** (hola, buen día, etc.) → se responde con el texto de `saludo` (ej. "¡Hola! Soy Flor IA 🌸...").
- Otras claves típicas: `noEntendido`, `rateLimitExceeded`, `despedida`, `audioFallback`, etc.

---

## 5. Variables de entorno (servidor WhatsApp)

En EasyPanel (o donde corra el servicio) podés definir:

| Variable | Uso |
|----------|-----|
| **GEMINI_API_KEY** | Clave de la API de Gemini (obligatoria para que Flor responda con IA). |
| **GEMINI_MODEL** | Modelo por defecto si no hay `flor_ai_config` (ej. `gemini-3.1-flash-lite-preview`). |
| **FLOR_ENABLED** | `true` / `false` para activar o desactivar Flor a nivel global. |
| **FLOR_DELAY_MS** | Milisegundos de espera para agrupar varios mensajes (por defecto 5000). |
| **SUPABASE_URL** / **SUPABASE_ANON_KEY** | Para leer `flor_general_config`, `flor_ai_config`, `flor_responses` y hoteles. |

---

## 6. Lógica en el servidor (además del prompt)

- **Function calling:**  
  Flor no lleva el catálogo de hoteles en el prompt. Usa la función **consultarCatalogoHoteles** (ubicación y/o nombre de hotel). El servidor consulta Supabase (tabla `hotels`) y devuelve el resultado a la IA. Si no hay resultados, la IA debe ofrecer alternativas sin nombrar competencia (según el prompt).
- **Historial de sesión:**  
  Se guardan los últimos turnos por chat (por número) para poder responder seguimientos tipo "¿Y tiene spa?" sin repetir el hotel. Máximo unos 5 pares user/model.
- **Indicador “escribiendo”:**  
  Al procesar un mensaje se envía presencia "composing" en WhatsApp; al terminar, "paused".
- **Emojis en mensajes salientes:**  
  Se agregan emojis según tipo: 🌸 respuestas de Flor, 📋 mensajes de cotización, 💬 mensajes manuales del asesor.
- **Pausa de Flor:**  
  Si un asesor envía mensaje o audio desde el dashboard, Flor se “pausa” para ese chat durante un tiempo (campo `flor_paused_until` en `whatsapp_chats`).

---

## 7. Flujo resumido (mensaje entrante → respuesta)

1. Llega un mensaje por WhatsApp.
2. Se envía “escribiendo” (composing).
3. Se espera **FLOR_DELAY_MS** (5 s) por si llegan más mensajes; se agrupan.
4. Se comprueba si Flor está pausada para ese chat (`flor_paused_until`).
5. Si el mensaje es saludo simple, transferir o despedida → se responde con **flor_responses** (sin Gemini).
6. Si no → se llama a **procesarConFlor**:
   - Se arma el prompt: **Prompt General (Supabase o default)** + **reglas inyectadas**.
   - Se envían a Gemini los últimos turnos de la sesión + mensaje actual.
   - Gemini puede llamar la herramienta **consultarCatalogoHoteles**; el servidor ejecuta la consulta en Supabase y devuelve el resultado; Gemini genera la respuesta final.
7. Se envía la respuesta por WhatsApp, se quita “escribiendo” y se guarda en Supabase (mensajes, interacciones, etc.).

---

## 8. Dónde cambiar qué

| Quiero cambiar… | Dónde |
|----------------|--------|
| El texto del prompt (rol, tono, reglas de negocio) | **Supabase** `flor_general_config` → `promptGeneral` (desde Dashboard → Flor IA → Configuración, o directo en Supabase). |
| Modelo, temperatura o desactivar Flor | **Supabase** `flor_ai_config` o variables de entorno (p. ej. `GEMINI_MODEL`). |
| Saludo, despedida, “transferir”, “no entendido”, etc. | **Supabase** `flor_responses`. |
| Reglas que siempre se inyectan (función, saludo una vez, emojis) | **Código** del servidor (`FLOR_REGLAS_PRIORIDAD` y lógica en `whatsapp-server-baileys.js`). |
| Catálogo de hoteles | **Supabase** tabla `hotels` (Flor los consulta vía la función, no vía prompt). |

En conjunto: el **Prompt General en Supabase** define la personalidad y reglas de negocio; el resto (Supabase + env + código) define modelo, respuestas predefinidas, function calling y comportamiento del servidor.

---

## 9. Búsqueda de hoteles (alias y fuzzy)

- **Alias de búsqueda:** En cada hotel (Dashboard → Hoteles → Editar → Ficha Flor), el campo **Alias de búsqueda** permite sinónimos y errores de tipeo. Ejemplo para Hotel Huilo-Huilo: `Guilo, Wilo, Huilo, Huilo Huilo`. Así, si el usuario escribe "Guilo" o "info de guilo", Flor encuentra el hotel.
- **Fuzzy (1 carácter):** El servidor además hace coincidencia por **1 carácter de diferencia** (ej. "Guilo" ↔ "Huilo"). No hace falta poner todos los typos en el alias, pero conviene tener al menos `Guilo, Huilo, Huilo Huilo` para Huilo-Huilo.
- **Logs:** Si Flor responde "no entendí" ante "info de Guilo", revisar en los logs del servidor:  
  `🔧 Flor llamó consultarCatalogoHoteles(..., hotel_especifico=guilo) → no encontrado`  
  Si aparece eso, la búsqueda no encontró nada (revisar alias en Supabase o nombre del hotel). Si **no** aparece esa línea, Gemini no está llamando la función (revisar prompt o descripción de la herramienta).
- **Protocolo de formatos (programas/spa):** Cuando pidan detalles de programas o spa, Flor **no** debe enviar el PDF o la imagen de una. Debe preguntar primero: *"¿Cómo preferís el detalle? ¿En un PDF, una Imagen rápida o te lo resumo por Texto?"* y solo después enviar el link o el resumen según lo que elija el usuario. Esto está en las reglas inyectadas (`FLOR_REGLAS_PRIORIDAD`).
- **URLs de multimedia:** Flor accede a las URLs de PDFs y fotos a través del **resultado de consultarCatalogoHoteles**. Ese resultado incluye, por hotel: `pdf_programas`, `pdf_menu_spa`, `pdf_menu_resto`, `img_cuadro_programas`, `img_spa`, `img_habitacion`. Esos campos vienen de la tabla **`hotels`**, columna **`flor_info`** (JSON). Asegurate de cargar las URLs en el Dashboard (Hotels → Editar → Ficha Flor) para que Flor pueda enviarlas cuando el usuario elija el formato.
- **Reset de contexto:** Tras **2 respuestas "no entiendo"** seguidas, el servidor **borra el historial** y ofrece empezar de nuevo. Si la sesión supera **30 minutos de inactividad**, también se limpia el historial para ese chat.
- **RLS tabla hotels:** La API (anon) debe poder hacer **SELECT** en la tabla `hotels`. Si en Supabase tenés RLS habilitado en `hotels`, ejecutá `supabase-migrations/010_hotels_rls_select.sql` para permitir lectura a anon y authenticated. (No existe tabla `fichas_hoteles`; todo está en `hotels` y `hotels.flor_info`.)
- **Temperatura:** Por defecto el servidor usa **0.3** para que la IA sea más precisa al usar las funciones. Si Flor responde muy rígida, en Supabase `flor_ai_config` podés poner `"temperature": 0.7`.

---

## 10. Si Flor sigue diciendo "no he podido entender" — checklist para el programador

Revisar estos dos puntos técnicos en este orden:

### 1. Logs de función: ¿Gemini está llamando la herramienta?

- En los **logs del servidor WhatsApp** (donde corre `whatsapp-server-baileys.js`), buscar cuando el usuario escribe algo como "info de Guilo" o "qué hoteles tienen":
  - **Si aparece:** `🔧 Flor llamó consultarCatalogoHoteles(ubicacion=..., hotel_especifico=...) → X hotel(es)`  
    → La IA sí está usando la herramienta. El problema puede ser que la búsqueda devuelva vacío (alias, nombre) o que Supabase devuelva error/vacío por permisos.
  - **Si no aparece** ninguna línea `🔧 Flor llamó consultarCatalogoHoteles`  
    → Es un **problema del System Prompt**: la IA no está reconociendo que debe usar esa herramienta. Reforzar en Supabase (`flor_general_config` → `promptGeneral`) y en código (`FLOR_REGLAS_PRIORIDAD`) que la **única fuente de verdad** para hoteles es la función `consultarCatalogoHoteles` y que **nunca** debe responder "no entiendo" a una pregunta sobre hoteles sin haberla llamado antes.

La herramienta en código se llama **`consultarCatalogoHoteles`** (no "buscarHotel"). Es la que el servidor declara a Gemini y la que debe verse en los logs.

### 1.1. ¿Flor está usando el código actual?

- El servidor que corre en EasyPanel (o donde tengas el WhatsApp) debe ser el **código actual** del repo: con **FLOR_REGLAS_PRIORIDAD** (única fuente de verdad, protocolo de formatos), **fuzzy match** (Guilo ↔ Huilo), **hint de hotel** (cuando el mensaje parece consulta de hotel se inyecta una instrucción para que Gemini llame la función) y **logging** (`Flor → Gemini`, `Flor llamó consultarCatalogoHoteles`, etc.).
- Si no hiciste **redeploy** después de los cambios, Flor sigue con la versión vieja y puede caer en el bucle "no entiendo". Hacé **push a Git** y **Redeploy** del servicio WhatsApp en EasyPanel.

### 1.2. ¿El prompt en Supabase contradice la herramienta?

- La **única fuente de verdad** para hoteles debe ser la función **consultarCatalogoHoteles**. Revisá en Supabase (`flor_general_config` → `promptGeneral`) que el texto **no** diga cosas como "no tengas herramientas" o "responde sin consultar base". Si querés reforzar, agregá: *"La única fuente de verdad para datos de hoteles es la función consultarCatalogoHoteles. No inventes datos. Si la búsqueda falla, ofrece alternativas sin nombrar competencia."*

### 2. Permisos de Supabase (RLS): ¿La API puede leer la tabla?

- El servidor usa la **API Key de Supabase** (anon o service) que esté configurada en las variables de entorno. Esa clave debe tener permiso de **lectura (SELECT)** sobre la tabla donde están los hoteles.
- En este proyecto **no existe la tabla `fichas_hoteles`**. Los datos de Flor están en la tabla **`hotels`** (columna **`flor_info`**). Hay que verificar permisos sobre **`hotels`**.
- Si en Supabase la tabla **`hotels`** tiene **RLS (Row Level Security)** habilitado y no hay políticas que permitan SELECT al rol **anon** (o al que use el servidor), las consultas pueden devolver **vacío** o **403 Forbidden** y Flor termina respondiendo "no he podido entender".
- **Solución:** Ejecutar en Supabase (SQL Editor) el script **`supabase-migrations/010_hotels_rls_select.sql`**, que crea políticas para permitir SELECT en `hotels` a `anon` y `authenticated`. Después de aplicarlo, reiniciar o probar de nuevo.
