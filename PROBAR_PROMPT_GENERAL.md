# Probar Prompt General (Flor IA → General)

Guía rápida para verificar que el **Prompt General** en Flor IA → General funciona bien.

---

## Cómo llegar

1. Abrí el **Dashboard** (local o producción):
   - **Local:** En la raíz del proyecto ejecutá `npm start` (o `node server.js`) y luego abrí `http://localhost:3000`. Asegurate de tener Node en el PATH.
   - **Producción:** `https://dashboard.checkin24hs.com`
2. Iniciá sesión si hace falta.
3. En el menú lateral, click en **Flor IA**.
4. Deberías ver la pestaña **⚙️ General** activa por defecto. El **Prompt General** se carga solo (guardado o por defecto).

---

## Checklist de pruebas

### 1. Carga inicial

- [ ] Al abrir **Flor IA → General**, el **textarea** "📝 Prompt General" tiene contenido (no está vacío).
- [ ] Si nunca guardaste nada, debería mostrarse el **prompt por defecto** (empieza con *"Eres Flor IA 🌸, asistente virtual de Checkin24hs..."*).
- [ ] Hay **18 filas** aproximadamente y se puede hacer scroll.
- [ ] Se ven la descripción, el botón **Restaurar por defecto** y el **Guardar Configuración General**.

### 2. Editar y guardar

- [ ] Editá el texto en el textarea (por ejemplo, agregá una línea de prueba).
- [ ] Click en **Guardar Configuración General**.
- [ ] Aparece el mensaje **"✅ Configuración general y multimodal guardada"**.
- [ ] Recargá la página, entrá de nuevo a **Flor IA → General**: el prompt editado se mantiene (se cargó desde `localStorage`).

### 3. Restaurar por defecto

- [ ] Con el prompt editado, click en **Restaurar por defecto**.
- [ ] Aparece el **confirm**: *"¿Restaurar el prompt general por defecto? Se perderán los cambios no guardados."*
- [ ] Aceptá: el textarea vuelve al **prompt por defecto** (FLOR_PROMPT_DEFAULT).
- [ ] Si **no** hacés click en **Guardar** y recargás, al volver a Flor → General se cargará lo que tenías guardado antes (el restore solo cambia el textarea en memoria hasta que guardes).

### 4. Restaurar + guardar

- [ ] **Restaurar por defecto** → Aceptar.
- [ ] Click en **Guardar Configuración General**.
- [ ] Recargá y volvé a **Flor IA → General**: ahora debe mostrarse el prompt por defecto también después de recargar.

### 5. Integración WhatsApp (opcional)

- [ ] Guardaste el Prompt General en el Dashboard.
- [ ] Enviás un mensaje por WhatsApp al número conectado: Flor debería responder usando ese prompt (tono, reglas, etc.).
- [ ] Si cambiás el prompt y guardás: en hasta ~5 min (o tras reiniciar el servicio WhatsApp) las nuevas respuestas deberían reflejar el cambio.

---

## Contenido del prompt por defecto (resumen)

El **FLOR_PROMPT_DEFAULT** incluye:

- Rol: *"Eres Flor IA 🌸, asistente virtual de Checkin24hs..."*
- Propósito, público, tono.
- Bienvenida con "Flor IA 🌸".
- Reglas: no `#`, no dar precios para cotizar, no cotizar.
- **Cotización:** si piden cotizar/tarifa → enviar `https://cotizar.checkin24hs.com/` y explicar que completen los datos.
- Manejo de errores y escalación a humano.
- Límites (máx. 3 oraciones, salvo listas).
- Base de conocimiento (qué usar / qué no).

---

## Dónde se guarda

- **localStorage** bajo la clave `flor_general_config`.
- **Supabase**: tabla `system_config`, clave `flor_general_config`. Se guarda al hacer "Guardar Configuración General".
- Incluye: `name`, `role`, `greeting`, `personality`, `promptGeneral` y la config **multimodal** (audio, imágenes).

---

## Integración con WhatsApp

El **Prompt General** que editás en Flor IA → General **se usa en el servidor WhatsApp** cuando Flor responde por Gemini:

1. **Al guardar** en el Dashboard: además de `localStorage`, se hace upsert en `system_config` (key `flor_general_config`).
2. **Al responder** un mensaje: el servidor WhatsApp (`whatsapp-server-baileys.js`) lee `flor_general_config` desde Supabase, toma `promptGeneral` y lo usa como *system prompt* en la llamada a Gemini. Si no hay valor en Supabase, usa `FLOR_PROMPT_DEFAULT`.
3. **Caché**: el servidor cachea el prompt 5 minutos. Los cambios pueden tardar hasta 5 min en aplicarse en WhatsApp; para aplicar de inmediato, reiniciá el servicio WhatsApp.

**Requisitos:** mismo proyecto Supabase para Dashboard y servidor WhatsApp (`SUPABASE_URL` y `SUPABASE_ANON_KEY` / `SUPABASE_SERVICE_KEY` donde corresponda).

---

## Si algo falla

- Abrí la **consola** del navegador (F12 → Console) y buscá mensajes como:
  - `💾 Configuración Flor guardada:`
  - `☁️ Configuración Flor General guardada en Supabase (prompt usado por WhatsApp)`
  - `✅ Prompt general restaurado por defecto`
- Si el prompt no se carga al abrir: revisá que exista `loadFlorGeneral` y que se llame al entrar a **Flor IA** (pestaña General).
- Si WhatsApp no usa tu prompt: revisá que el servidor tenga Supabase configurado y que exista `flor_general_config` en `system_config` (guardá desde el Dashboard primero).

Cuando termines de probar, podés seguir con **Promociones/Integraciones** o **ampliar la base de conocimiento**, según lo que prefieras.
