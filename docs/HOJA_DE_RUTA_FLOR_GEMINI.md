# Hoja de ruta Flor IA (propuesta Gemini)

Este doc responde **si conviene modificar la ficha de Hotels o crear algo nuevo**, incluye la **especificación literal que pasó Gemini** y desglosa todo lo que hay que construir, marcando qué **ya está** y qué **falta**.

---

## 1. ¿Modificar la ficha Hotels o hacer algo nuevo?

**Recomendación: conviene modificar (extender) la ficha de la sección Hotels**, no crear una pantalla nueva. Ya tenés el formulario de Hotels con la sección "Información para Flor IA" y el campo de Google Maps; ampliando esa misma ficha con alias de búsqueda, programas dinámicos, servicios (checkboxes), gastronomía, tips, y URLs de imágenes/PDFs tenés una sola fuente de verdad. Si preferís separar datos operativos de "contenido para Flor", se puede crear la tabla `fichas_hoteles` con `hotel_id` (FK a `hotels`) y el mismo formulario puede escribir ahí.

- **Opción A (recomendada):** Ampliar la **ficha de Hotels** que ya tenés en el panel:
  - En Supabase: agregar columnas a `hotels` o ampliar el JSON **`flor_info`** con los campos nuevos (alias_busqueda, narrativa_poetica, ubicacion_maps, programas, servicios_json, gastronomía, tips, URLs de imágenes/PDFs, etc.).
  - En el panel: en la misma pantalla de edición del hotel, sumar pestaña o bloque **“Ficha para Flor”** (narrativa poética, alias, programas, servicios, tips, mapa, subida de imágenes y PDFs).
  - Flor sigue usando la función `consultarCatalogoHoteles`; el servidor lee de `hotels` (y de ese bloque/JSON ampliado).
  - Ventaja: un solo lugar para mantener datos; no duplicar hotel en otra tabla.

- **Opción B (tabla aparte):** Crear tabla **`fichas_hoteles`** con `hotel_id` (FK a `hotels`) y el esquema completo que propuso Gemini. Formulario aparte “Fichas Flor” o una sección por hotel que escriba en `fichas_hoteles`. Flor leería de `fichas_hoteles` (o de `hotels` + join a `fichas_hoteles`).
  - Tiene sentido si querés separar “datos operativos del hotel” de “contenido rico solo para Flor”.

---

## 2. Especificación literal de Gemini (para el programador)

Texto que pasó Gemini para tener la hoja de ruta completa.

### 2.1 Base de datos: tabla `fichas_hoteles`

Esquema de columnas que debe tener la tabla:

| Columna | Tipo | Descripción |
| --- | --- | --- |
| `id` | `uuid` | Identificador único. |
| `nombre` | `text` | Nombre oficial del hotel. |
| `alias_busqueda` | `text` | Sinónimos y errores (ej: "Puyehue, Guilo, Wilo"). |
| `narrativa_poetica` | `text` | La descripción poética y emocional (mística). |
| `ubicacion_maps` | `text` | URL de Google Maps. |
| `detalles_programas` | `jsonb` | Lista de programas (Nombre, Qué incluye, Política niños). |
| `servicios_json` | `jsonb` | Checkboxes: {wifi: bool, mascotas: text, spa: bool}. |
| `gastronomia_info` | `text` | Detalle del Chef y tipo de cocina. |
| `tips_agencia` | `text` | Secretos y recomendaciones de Checkin24hs. |
| `img_general` | `text` | URL de foto de fachada. |
| `img_habitacion` | `text` | URL de foto de habitación. |
| `img_spa` | `text` | URL de foto de piscina/spa. |
| `img_cuadro_programas` | `text` | URL de la imagen resumen de programas. |
| `pdf_menu_resto` | `text` | URL del PDF de la carta. |
| `pdf_menu_spa` | `text` | URL del PDF de masajes. |
| `pdf_programas` | `text` | URL del PDF detallado de programas. |
| `link_cotizacion` | `text` | Siempre `https://cotizar.checkin24hs.com/`. |

*(Si se integra con la ficha Hotels existente, se puede usar `hotel_id` FK a `hotels` y guardar estos campos en esa tabla o en un JSONB en `hotels`.)*

### 2.2 Panel web (administrador)

- **Editor de texto:** Para la "Narrativa Poética" y "Tips".
- **Gestor de archivos:** Para subir fotos y PDFs (Supabase Storage; la URL va a la tabla).
- **Sección dinámica de Programas:** Botón "Agregar Programa" con nombre y lista de lo que incluye.
- **Sección de Mapa:** Campo para pegar el link de Google Maps.

### 2.3 Lógica para Flor IA (inyectar en Flor / Gemini 2.0 Flash)

**A. Lógica de búsqueda (Fuzzy Match)**  
"Flor, antes de responder, usa la función `buscarHotel`. Si el usuario escribe mal el nombre (ej. 'wilo'), busca en la columna `alias_busqueda`. Si hay dos hoteles similares, pregunta: '¿Te referís al Hotel A o al Hotel B?'."

**B. Protocolo de formatos (bajo demanda)**  
"Cuando el usuario pida detalles de programas o servicios: 1) Da un resumen breve por texto. 2) Pregunta: '¿Cómo preferís que te envíe el detalle completo? ¿En un **PDF**, en una **Imagen** rápida, o seguimos por **Texto**?' 3) Según la respuesta, dispara la URL correspondiente de la base de datos."

**C. Manejo de multimedia**  
"Las imágenes y PDFs deben enviarse como archivos nativos de WhatsApp (usando la función de Baileys), no solo como un link de texto, para que el usuario vea la miniatura."

### 2.4 Tareas pendientes (lista final para el programador)

1. **Conexión Baileys + Gemini:** Que Flor escuche y responda en WhatsApp.
2. **Transcripción de audios:** Usar Gemini para leer audios de clientes y responder por texto.
3. **Estado "Composing":** Que aparezca "Escribiendo..." mientras Flor consulta Supabase.
4. **Alerta de humano:** Si el usuario dice "quiero hablar con alguien", notificar al equipo y pausar Flor en ese chat.
5. **Cierre inevitable:** No terminar una charla sin haber enviado el link de cotización.

### 2.5 Mensaje de bienvenida oficial

Configurar como respuesta al primer "Hola":

> "¡Hola! Soy **Flor 🌸**, tu asistente de **Checkin24hs**. Estoy aquí para ayudarte a planificar tu escapada ideal hacia el relax y la naturaleza de la Patagonia. 🏔️✨  
> ¿Tenés algún hotel en mente (como Puyehue o Huilo Huilo) o te gustaría que te recomiende un refugio mágico para descansar?"

---

## 3. Base de datos (Supabase) – resumen técnico

El esquema completo está en la sección 2.1. Si se usa **tabla aparte** `fichas_hoteles`, agregar `hotel_id` (FK a `hotels`) y `created_at` / `updated_at`. Si se **amplía Hotels**, las mismas columnas pueden sumarse a `hotels` o guardarse en un JSONB (ej. `flor_info` ampliado). La función de Flor seguiría leyendo de `hotels` (o de `hotels` + ese JSON).

---

## 4. Panel web (administrador)

- **Editor de texto:** Para “Narrativa poética” y “Tips agencia” (en la ficha del hotel o en Fichas Flor).
- **Gestor de archivos:** Subir fotos y PDFs a **Supabase Storage** y guardar las URLs en la tabla (o en `flor_info`/`ficha_flor`).
- **Sección dinámica “Programas”:** Botón “Agregar programa” con campos: nombre, qué incluye, política niños → guardar en `detalles_programas` (jsonb) o equivalente en `flor_info`.
- **Campo mapa:** Input para pegar link de Google Maps → guardar en `ubicacion_maps` (o campo equivalente).
- **Servicios (checkboxes/opciones):** wifi, mascotas, spa, etc. → guardar en `servicios_json` (jsonb) o en `flor_info`.

Todo esto puede vivir **en la misma ficha del hotel** (pestaña “Para Flor” o “Ficha Flor”) para no tener dos pantallas distintas por hotel.

---

## 5. Lógica para Flor IA (instrucciones al programador)

### A. Búsqueda (fuzzy / alias)

- Antes de responder, Flor debe usar la función **buscarHotel** (o la actual `consultarCatalogoHoteles` ampliada).
- Si el usuario escribe mal (ej. "wilo"), buscar también en **alias_busqueda** (o equivalente en la estructura que elijan).
- Si hay **varios hoteles** que coinciden, Flor debe preguntar: *"¿Te referís al Hotel A o al Hotel B?"* y no responder como si fuera uno solo.

Implementación sugerida: en el servidor, la función que consulta hoteles debe aceptar un término de búsqueda y matchear contra `name` y `alias_busqueda` (y opcionalmente ubicación). Si devuelve más de uno, la respuesta de Flor debe ser “elegí entre estos” y no dar el detalle de uno solo.

### B. Protocolo “PDF / Imagen / Texto” (bajo demanda)

- Cuando el usuario pida **detalles de programas o servicios**:
  1. Dar un **resumen breve por texto**.
  2. Preguntar: *"¿Cómo preferís que te envíe el detalle completo? ¿En **PDF**, en una **imagen** rápida, o seguimos por **texto**?"*.
  3. Según la respuesta, usar la URL correspondiente de la base (PDF programas, imagen resumen, o seguir por texto).

Implementación: la función que devuelve datos del hotel ya debe incluir las URLs (pdf_programas, img_cuadro_programas, etc.). El prompt de Flor debe indicar que ofrezca esas tres opciones y que, según la elección del usuario, envíe el archivo o el link (y si se implementa envío nativo, ver punto C).

### C. Multimedia en WhatsApp (archivos nativos)

- Las imágenes y PDFs deben enviarse como **archivos nativos de WhatsApp** (Baileys: enviar imagen/PDF como mensaje de tipo imagen/documento), no solo como link en texto, para que se vea la miniatura y la descarga sea directa.

Implementación: en el servidor WhatsApp, cuando Flor decida “enviar PDF” o “enviar imagen”, el backend debe:
- Descargar el archivo desde la URL guardada (o leer desde Storage),
- Enviar con `sock.sendMessage(jid, { image: buffer }` o `{ document: buffer, fileName: '...' }` según el tipo.

La herramienta de Flor puede devolver “enviar_archivo: { tipo: 'pdf'|'imagen', url: '...', texto_opcional: '...' }” y el servidor ejecutar ese envío.

---

## 6. Tareas pendientes (estado actual)

| Tarea | Estado | Notas |
|-------|--------|--------|
| Baileys + Gemini: Flor escucha y responde en WhatsApp | Hecho | Function calling, prompt desde Supabase, consultarCatalogoHoteles. |
| Varios hoteles: preguntar "¿Te referís a A o a B?" | Hecho | consultarCatalogoHoteles devuelve varios=true; reglas inyectadas. |
| Estado "Composing" ("Escribiendo...") | Hecho | sendPresenceUpdate('composing' / 'paused'). |
| Alerta de humano: notificar y pausar Flor | Hecho | flor_paused_until, detección "agente"/"asesor"/"humano". |
| Cierre con link de cotización | Hecho | Prompt y reglas piden enviar https://cotizar.checkin24hs.com/ cuando pidan precio/reserva. |
| Transcripción de audios (Gemini) | Pendiente | Hoy se responde con mensaje tipo “envíame por escrito”; falta usar Gemini (o otro) para speech-to-text y luego procesar el texto con Flor. |
| Búsqueda con alias / fuzzy (ej. "wilo") | Hecho | Búsqueda en flor_info.alias_busqueda; servidor y dashboard con alias. |
| Protocolo PDF / Imagen / Texto | Hecho | Reglas inyectadas: Flor ofrece PDF/Imagen/Texto; tool devuelve URLs (pdf_programas, img_cuadro_programas, etc.). |
| Envío de imágenes/PDFs como archivos nativos (Baileys) | Pendiente | Hoy se pueden enviar links; falta descargar y enviar como archivo nativo (opcional). |
| Ficha rica (narrativa, programas, tips, URLs) | Hecho | Ampliado Hotels: flor_info con alias, programas, servicios_json, gastronomía, tips, URLs; formulario en Dashboard. |
| Mensaje de bienvenida oficial | Hecho | FLOR_RESPONSES_DEFAULTS.saludo y Dashboard flor-greeting actualizados. |

---

## 7. Mensaje de bienvenida oficial (Gemini)

Texto a configurar como **primer mensaje** (ej. en `flor_responses.saludo` en Supabase o en el Dashboard → Flor IA → Respuestas predefinidas):

> "¡Hola! Soy **Flor 🌸**, tu asistente de **Checkin24hs**. Estoy aquí para ayudarte a planificar tu escapada ideal hacia el relax y la naturaleza de la Patagonia. 🏔️✨  
> ¿Tenés algún hotel en mente (como Puyehue o Huilo Huilo) o te gustaría que te recomiende un refugio mágico para descansar?"

Quien implemente debe asegurarse de que ese sea el valor usado para el **primer saludo** (clave `saludo` en `flor_responses` o equivalente).

---

## 8. Orden sugerido para el programador

1. **Datos y panel**
   - Decidir: ampliar `hotels` (y formulario) o crear `fichas_hoteles` + formulario.
   - Crear migración (columnas o tabla) y formulario de carga (narrativa, alias, programas, servicios, tips, mapa, imágenes, PDFs, Storage).

2. **Flor: búsqueda**
   - Incluir `alias_busqueda` (o equivalente) en la función que consulta hoteles.
   - Si hay varios resultados, que Flor pregunte “¿Te referís a A o a B?”.

3. **Flor: protocolo PDF/Imagen/Texto**
   - Ajustar prompt/instrucciones para que Flor ofrezca las tres opciones.
   - Que la herramienta devuelva qué enviar (PDF, imagen o texto) y el backend use las URLs de la base.

4. **Flor: envío nativo**
   - Implementar en el servidor WhatsApp el envío de imagen/PDF como archivo (Baileys), usando las URLs de la ficha.

5. **Bienvenida**
   - Configurar el mensaje de bienvenida oficial en Supabase/Dashboard.

6. **Transcripción de audios** (opcional pero recomendado)
   - Integrar speech-to-text (Gemini o otro) para audios entrantes y pasar ese texto a la misma lógica de Flor.

Con esto el programador tiene la hoja de ruta completa: **seguir por la ficha de Hotels (ampliándola)** suele ser lo más directo; si prefieren separar, usar `fichas_hoteles` con `hotel_id` y el esquema de este doc.
