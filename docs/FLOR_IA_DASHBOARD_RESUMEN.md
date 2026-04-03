# Flor IA en el Dashboard – Resumen

## Dónde está

En el **Dashboard** (dashboard.html): menú lateral → **Flor IA**. Se abre la sección **Configuración de Flor IA** con pestañas.

---

## Pestañas

| Pestaña | Contenido | Dónde se guarda |
|--------|-----------|------------------|
| **General** | Nombre, Rol, Mensaje de bienvenida, Personalidad, **Prompt General**, opciones multimodales (audio, imágenes) | Supabase `system_config` → key **`flor_general_config`**. El servidor WhatsApp usa solo **`promptGeneral`** del JSON. |
| **WhatsApp** | Estado de conexión, botón para abrir QR y conectar | Solo lectura/estado; la conexión vive en el servidor. |
| **Conocimiento** | Base de conocimiento por hotel (selector + datos por hotel) | Hoteles y `flor_info` en Supabase. |
| **Respuestas** | noEntendido, transferir, despedida, audio fallback, imagen fallback, etc. | Supabase `system_config` → key **`flor_responses`**. |
| **Políticas** | Texto de políticas (si se usa) | Supabase según implementación. |
| **Integraciones** | Config de integraciones por canal | Supabase. |
| **IA** | Proveedor (OpenAI/Gemini), API key, modelo, temperatura | Supabase `system_config` → key **`flor_ai_config`**. |

---

## Lo más importante para que Flor responda bien

1. **Prompt General (pestaña General)**  
   - Es el texto que usa **WhatsApp (Gemini)** y, si aplica, la **web**.  
   - Se guarda en Supabase como **`flor_general_config`** → campo **`promptGeneral`** dentro del JSON.  
   - Después de guardar, el servidor WhatsApp tiene **cache ~5 min**; si no ves el cambio, esperá unos minutos o reiniciá el servicio WhatsApp.

2. **Botón "Guardar toda la configuración de Flor"**  
   - Guarda General, Respuestas e IA en Supabase.  
   - También podés usar en cada pestaña su propio **Guardar** (ej. "Guardar Configuración General").

3. **Restaurar por defecto**  
   - En **General**, al lado de "Prompt General", el botón **Restaurar por defecto** vuelve a poner el prompt por defecto del código (y al guardar se sobrescribe en Supabase).

---

## Verificar que se guardó en Supabase

En **Supabase → SQL Editor**:

```sql
SELECT key, updated_at, LEFT(value::text, 300) AS value_preview
FROM system_config
WHERE key IN ('flor_general_config', 'flor_responses', 'flor_ai_config');
```

Ahí ves si existen las filas y una vista previa del contenido. El **Prompt General** que usa el servidor está dentro de `flor_general_config` → `promptGeneral`.

---

## Posibles problemas

- **Flor responde raro después de editar:** Revisar que en **Prompt General** no haya frases que contradigan el uso de herramientas (ej. "si no entendés, decí que no entendés" sin pedir antes consultar catálogo). Ver `docs/VERIFICAR_FLOR_BUCLE_NO_ENTIENDO.md`.
- **El servidor no toma el nuevo prompt:** Cache 5 min; reiniciar el servicio WhatsApp para forzar recarga.
- **Dashboard no guarda:** Revisar que Supabase esté configurado en el dashboard y que existan las políticas RLS de `system_config` (insert/update para anon). Ver migración `027_system_config_rls.sql`.
