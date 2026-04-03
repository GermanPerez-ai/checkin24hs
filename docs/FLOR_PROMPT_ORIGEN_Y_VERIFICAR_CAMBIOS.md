# Flor IA: de dónde sale el prompt y cómo ver si cambió

## 1. De dónde toma el prompt

### WhatsApp (servidor Baileys + Gemini)

- **Origen 1 (prioridad):** Supabase → tabla **`system_config`** → fila con **`key = 'flor_general_config'`** → en la columna **`value`** (JSON) el campo **`promptGeneral`**.
- **Origen 2 (si no hay nada en Supabase):** Código en **`whatsapp-server/whatsapp-server-baileys.js`** → constante **`FLOR_PROMPT_DEFAULT`** (líneas ~154-167).
- **Siempre se suman en código:** `FLOR_REGLAS_PRIORIDAD` y `FLOR_PROTOCOLO_VENTAS` (mismo archivo, ~169-214). No se guardan en Supabase.

### Flor en la web (chat iframe)

- **Mismo origen:** Lee **`flor_general_config`** desde Supabase (vía Flor API o desde el iframe con `flor-ai-service.js`). Si no hay en Supabase, usa un prompt por defecto en el cliente.

---

## 2. Ver si el prompt se modificó en las últimas 24 h

### En Supabase (donde sí puede haber cambiado)

1. Entrá a **Supabase** → tu proyecto → **Table Editor** → tabla **`system_config`**.
2. Buscá la fila con **`key`** = **`flor_general_config`**.
3. Revisá la columna **`updated_at`** (si existe): ahí ves la última vez que se guardó ese registro (por ejemplo desde el Dashboard de Flor).
4. Si no tenés `updated_at`, en **SQL Editor** podés agregarla y usarla para el futuro:

```sql
-- Ver última actualización de flor_general_config (si tenés columna updated_at)
SELECT key, updated_at, LEFT(value::text, 200) AS value_preview
FROM system_config
WHERE key = 'flor_general_config';
```

Si la tabla no tiene `updated_at`, no se puede ver el historial solo desde Supabase; los cambios serían los que alguien hizo al editar y guardar en el Dashboard.

### En el repositorio (código)

- **WhatsApp (prompt por defecto y reglas):** archivo **`whatsapp-server/whatsapp-server-baileys.js`**.
  - En los últimos commits **no** apareció modificado en las últimas 48 h; es decir, **el prompt por defecto y las reglas en código no cambiaron** en ese periodo.
- **Flor web (cliente):** en las últimas 48 h sí hubo cambios en:
  - `checkin24hs-web/public/flor-agent.js`
  - `checkin24hs-web/public/flor-ai-service.js`
  - `checkin24hs-web/public/flor-chatbot.html`
  - `checkin24hs-web/public/flor-knowledge-base.js`
  - `checkin24hs-web/public/flor-learning-system.js`

Si Flor “está rara” **en WhatsApp**, lo más probable es un cambio en **Supabase** (`flor_general_config` → `promptGeneral`) o en la config de IA (`flor_ai_config`).  
Si es **solo en la web**, además podrían influir los cambios recientes en esos archivos del chat.

---

## 3. Qué revisar cuando Flor responde raro

1. **Supabase → `system_config`:**
   - **`flor_general_config`** → que **`promptGeneral`** tenga el texto que querés (sin instrucciones contradictorias tipo “si no entendés, decí que no entendés” sin pedir antes usar herramientas).
   - **`flor_responses`** → saludo, noEntendido, etc., por si algo se cambió.
   - **`flor_ai_config`** → que `enabled` sea true y que la API key / modelo sigan siendo los correctos.

2. **Dashboard Checkin24hs → Flor IA:**  
   Revisar la sección **Configuración General** (Prompt General) y **Respuestas**. Si alguien guardó ahí, se actualiza **`flor_general_config`** y **`flor_responses`** en Supabase.

3. **Cache en el servidor:**  
   El servidor WhatsApp cachea el prompt unos **5 minutos** (`FLOR_PROMPT_CACHE_TTL_MS`). Si acabas de cambiar el prompt en Supabase, esperá unos minutos o reiniciá el servicio WhatsApp para que tome el nuevo valor.

---

## 4. Comando para ver el prompt actual en Supabase (solo lectura)

Ejecutá en **Supabase → SQL Editor**:

```sql
SELECT key, value, updated_at
FROM system_config
WHERE key IN ('flor_general_config', 'flor_responses', 'flor_ai_config');
```

Ahí ves el JSON completo de cada clave y, si existe, la fecha de última actualización.
