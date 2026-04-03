# Instructivo: Flor IA experta e independiente

Objetivo: que **Flor IA** tenga todo el conocimiento e información que necesita para responder como experta a los usuarios de Checkin24hs, con **independencia** (una sola fuente de verdad, Hoteles como base, WhatsApp y Dashboard alineados).

---

## 1. Objetivo

- Flor debe **conocer todos los hoteles** con los que trabajan + los que se vayan sumando.
- Esa información vive en **Dashboard → Hoteles** (cada hotel con su info específica).
- Flor debe **usarla** al responder por WhatsApp (y donde aplique).
- **Organizar todo** en torno a Flor: configuración, conocimiento, interacciones y aprendizaje en un flujo claro.

---

## 2. Estado actual (resumen)

| Qué | Estado | Dónde |
|-----|--------|-------|
| **Prompt General** | ✅ Activo | Supabase `flor_general_config` → WhatsApp lo usa en Gemini |
| **Hoteles** | ✅ En Dashboard | Tabla `hotels` (Supabase) + `hotelsDB` (localStorage) |
| **Info para Flor por hotel** | ✅ Editable | Hoteles → Editar → “Información para Flor IA” + “Base de Conocimiento Adicional” |
| **Uso en WhatsApp** | ✅ Sí | Prompt + **hoteles** (`hotels` + `flor_info`) + mensaje + contexto |
| **Interacciones** | ✅ Sí | WhatsApp escribe en `flor_interactions`; Dashboard → Interacciones las muestra |
| **Aprendizaje** | ⚠️ Solo análisis | Dashboard analiza; no actualiza base que Flor use al responder |

---

## 3. Lo que falta para que Flor esté “activa con todo”

### 3.1 Conocimiento de hoteles en WhatsApp

- [x] **Servidor WhatsApp** lee la tabla `hotels` (Supabase), incl. `flor_info` / `florInfo`.
- [x] En cada llamada a Gemini: **Prompt General** + **bloque de hoteles** (activos) + mensaje + contexto.
- [x] Cache 5 min; truncado por campo para no exceder tokens.

### 3.2 Interacciones desde WhatsApp

- [x] Cuando Flor responde por WhatsApp, el servidor **inserta** en `flor_interactions` (`phone`, `user_message`, `bot_response`, etc.).
- [x] Dashboard → **Interacciones** muestra ese historial; "Actualizar" para ver las últimas.

### 3.3 (Opcional) Historial en el prompt

- [ ] Recuperar últimas N mensajes del chat (desde `whatsapp_messages` o `flor_interactions`) y añadirlos al contexto que se manda a Gemini.
- [ ] Definir N y tope de tokens para no romper latencia ni límites.

### 3.4 (Opcional) Aprendizaje → conocimiento

- [ ] Que el análisis de interacciones (intents, preguntas frecuentes) pueda **derivar** en Q&A o reglas que se guardan en `flor_general_config` o en una base aparte, y que Flor use al responder.

---

## 4. Sección Hoteles: revisión y mejoras

### 4.1 Estructura actual

- **Dashboard → Hoteles**: lista de hoteles, botones Agregar / Exportar / Actualizar / Promociones / Marketing.
- **Editar hotel**: modal con datos básicos (nombre, ubicación, web, rating, precio, estado, imagen, galería, descripción, amenities).
- **Información para Flor IA**: descripción detallada, servicios, excursiones, precios, políticas, cómo llegar, contacto.
- **Base de Conocimiento Adicional** (expandible): description, servicesDetail, pricing, transport, notes, websiteInfo (se guarda en `flor_hotel_knowledge` + sync a Flor).

### 4.2 Botones que no funcionan o hay que revisar

| Botón | Comportamiento actual | Estado |
|-------|------------------------|--------|
| **Exportar Datos** | ~~Solo `console.log`~~ | ✅ **Corregido**: exporta JSON con todos los hoteles (incl. `flor_info`) y descarga `hoteles-checkin24hs-YYYY-MM-DD.json` |
| **Actualizar** | ~~Stub que pisaba al que llamaba `loadHotelsTable` + `updateStats`~~ | ✅ **Corregido**: `refreshHotels` unificado; llama `loadHotelsTable` + `updateStats` y muestra alert de confirmación |
| **Promociones** | Abre modal de promociones por hotel | ⏳ Revisar en uso que `showHotelPromotions` / `showHotelPromotionsModal` y dependencias funcionen |
| **Marketing** | ~~`loadUsersData()` async sin await → modal recibía Promise~~ | ✅ **Corregido**: `showMarketingTools` ahora es `async`, hace `await loadUsersData()` y pasa el array de usuarios al modal |
| **Imagen principal / Galería** | “Desde URL” → `openImageManagerSimple`; “Seleccionar desde Disco” → `handleMainImageUpload` / `handleGalleryImagesUpload` | ⏳ Revisar juntos: consola, subida, URLs |

### 4.3 Qué revisar juntos (Hoteles)

- [ ] **Campos para Flor**: ¿Alcanza con “Información para Flor IA” + “Base de Conocimiento Adicional” o querés más (ej. FAQs por hotel, temporadas, restricciones)?
- [ ] **Duplicación**: hoy `flor_info` (Supabase) y `flor_hotel_knowledge` (localStorage) se solapan. Definir **una** fuente de verdad (ej. solo `hotels.flor_info`) y que el resto derive de ahí.
- [ ] **Nuevos hoteles**: flujo claro para “Agregar Hotel” → completar datos → rellenar info para Flor → guardar. Que al guardar se sincronice con lo que use WhatsApp (cuando esté implementado).
- [ ] **Botones**: corregir Exportar, Actualizar, Marketing (y lo que surja en Promociones/Imágenes) y probar en ambiente real.

---

## 5. Organización: Flor IA y su independencia

Idea: **Flor como centro**; el resto (Hoteles, WhatsApp, Interacciones, Aprendizaje) orbitan alrededor.

### 5.1 Fuente de verdad por tipo de dato

| Dato | Dónde vive | Quién escribe | Quién lee |
|------|------------|----------------|-----------|
| **Prompt General** | `system_config.flor_general_config` | Dashboard (Flor → General) | Dashboard + WhatsApp |
| **Hoteles** | Supabase `hotels` | Dashboard (Hoteles) | Dashboard, CRM, **(pendiente)** WhatsApp |
| **Info Flor por hotel** | `hotels.flor_info` (y opcionalmente `flor_hotel_knowledge` unificado) | Dashboard (Editar hotel) | Dashboard, **(pendiente)** WhatsApp |
| **Mensajes WhatsApp** | `whatsapp_messages` | Servidor WhatsApp | Dashboard (Chats), **(pendiente)** contexto para Gemini |
| **Interacciones Flor** | `flor_interactions` | Dashboard, CRM; **(pendiente)** WhatsApp | Dashboard (Interacciones, Aprendizaje) |

### 5.2 Flujo deseado (cuando todo esté hecho)

1. **Hoteles**: se cargan/editan en Dashboard → Hoteles. Toda la info para Flor va en cada hotel (`flor_info` + conocimiento adicional si se unifica).
2. **Flor → General**: se edita y guarda el Prompt General en Supabase.
3. **WhatsApp**: al recibir mensaje, el servidor toma Prompt General + base de hoteles (o subconjunto) + mensaje (+ opcional historial). Llama a Gemini, responde, guarda en `whatsapp_messages` **y** en `flor_interactions`.
4. **Dashboard → Flor → Interacciones / Aprendizaje**: usa `flor_interactions` (y mensajes si hace falta) para estadísticas y análisis.
5. **(Opcional)** El aprendizaje genera mejoras (Q&A, reglas) que se incorporan a la base que Flor usa.

### 5.3 Checklist “Flor independiente”

- [ ] Una sola **configuración** de Flor (Prompt General, respuestas predefinidas, etc.) en Supabase; Dashboard y WhatsApp la comparten.
- [ ] **Hoteles** como única fuente de verdad de datos por hotel; Flor solo lee, no escribe.
- [ ] **WhatsApp** escribe en `whatsapp_messages` y `flor_interactions`; lee Prompt + hoteles (y opcional historial).
- [ ] **Dashboard** organiza todo en secciones claras: Flor (General, WhatsApp, Conocimiento, Respuestas, Políticas, IA), Hoteles, Interacciones, etc., sin duplicar lógica ni fuentes.

---

## 6. Próximos pasos concretos (orden sugerido)

1. **Arreglar botones en Hoteles**  
   - Unificar `refreshHotels` y quitar stubs.  
   - Implementar `exportHotels` (CSV/Excel).  
   - Corregir `showMarketingTools` (async/await).  
   - Revisar Promociones e imágenes si reportás fallos.

2. **Revisar juntos la sección Hoteles**  
   - Campos para Flor, posible unificación `flor_info` / `flor_hotel_knowledge`, flujo para nuevos hoteles.

3. ~~**Integrar base de hoteles en WhatsApp**~~ ✅ Hecho: `getHotelsBlockForFlor()` lee `hotels`, bloque en prompt.

4. ~~**Escribir en `flor_interactions` desde WhatsApp**~~ ✅ Hecho: `guardarFlorInteraction()` tras cada respuesta.

5. **(Opcional)** Historial en contexto y aprendizaje → conocimiento, según prioridad.

---

## 7. Referencias

- **Base de conocimiento y quién la usa**: `BASE_CONOCIMIENTO_FLOR_IA.md`
- **Prompt General ↔ WhatsApp**: `INTEGRACION_PROMPT_WHATSAPP.md`
- **Probar Prompt General**: `PROBAR_PROMPT_GENERAL.md`

---

Cuando quieras, podemos bajar al código paso a paso (empezando por botones de Hoteles o por la integración de hoteles en WhatsApp).
