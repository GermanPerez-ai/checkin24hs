# Verificar por qué Flor sigue respondiendo "no he podido entender" (hotel Guilo, etc.)

Cuando el usuario pregunta por un hotel (ej. "info del hotel Guilo?") y Flor responde "Lo siento, no he podido entender tu consulta...", puede deberse a varias causas. Esta guía ayuda a acotarlas.

---

## 🔍 ¿Por qué Flor sigue fallando? (dos hipótesis)

En los chats, Flor responde "no he podido entender" cuando pedís info de "Guilo". Si ya verificaste que el alias existe en `hotels.flor_info.alias_busqueda`, solo quedan **dos opciones**:

| Hipótesis | Qué pasa | Cómo verificarlo |
|----------|----------|------------------|
| **1. Bloqueo de permisos (RLS)** | El servidor **sí** llama a `consultarCatalogoHoteles`, pero Supabase le devuelve **lista vacía** o error al leer `hotels` (falta política SELECT para `anon`). Flor recibe "no encontrado" y termina en "no entiendo" o mensaje genérico. | Logs: ves `🔧 Flor llamó consultarCatalogoHoteles(...) → 0 hotel(es)` o `🔍 Flor/Supabase: hotels devolvió 0 filas`. Solución: ejecutar `010_hotels_rls_select.sql` en Supabase. |
| **2. Falla de invocación** | Gemini **no** llama a la función `consultarCatalogoHoteles`; responde directo con "no entiendo". El Prompt General en Supabase (`flor_general_config`) no le da la orden clara de usar la herramienta, o la contradice. | Logs: ves `⚠️ Flor: mensaje parecía consulta de hotel pero Gemini NO llamó consultarCatalogoHoteles` o `⚠️ Flor: Gemini devolvió texto tipo "no entiendo"`. Solución: revisar o vaciar `promptGeneral` en Supabase (sección 4). |

**Orden recomendado:** (1) Redeploy whatsapp-server para tener los logs nuevos → (2) Repetir prueba "info del hotel Guilo" → (3) Mirar logs: si aparece "Flor llamó consultarCatalogoHoteles" → problema de RLS; si aparece "Gemini NO llamó" o "texto tipo no entiendo" → problema de Prompt en Supabase.

---

## ⚠️ Dónde está el código de Flor (importante)

**La lógica de Flor IA (Gemini, consultarCatalogoHoteles, reglas, hint de hotel) está en el servicio *whatsapp-server*,** no en el dashboard.

| Servicio | Rol |
|----------|-----|
| **whatsapp-server** | Procesa mensajes de WhatsApp, llama a Gemini, ejecuta `consultarCatalogoHoteles`, envía la respuesta. **Ahí hay que desplegar los cambios de Flor.** |
| **dashboard** | Panel admin: configuración de Flor, historial de interacciones, etc. No procesa los mensajes entrantes de WhatsApp. |

Si implementaste o desplegaste cambios de Flor en el **dashboard**, no afectan la respuesta en WhatsApp. Hay que **Redeploy del servicio whatsapp-server** con el código actual (p. ej. `whatsapp-server/whatsapp-server-baileys.js`).

---

## 1. Confirmar que el servicio **whatsapp-server** usa el código actual (Redeploy)

Si el contenedor del **servicio de WhatsApp (whatsapp-server)** en EasyPanel no se ha reconstruido después de los últimos cambios, seguirá ejecutando una versión antigua **sin**:

- Hint inyectado en el mensaje ("Debes llamar PRIMERO consultarCatalogoHoteles...")
- Reglas FLOR_REGLAS_PRIORIDAD (OBLIGATORIO usar la función)
- Logs de depuración (`🔧 Flor llamó consultarCatalogoHoteles` / `⚠️ Flor: mensaje parecía consulta de hotel pero Gemini NO llamó...`)

**Qué hacer:**

1. Subir el código al repo que usa EasyPanel: `git push` (o el método que uses para desplegar).
2. En EasyPanel, **servicio whatsapp-server** (el que procesa WhatsApp y Flor), no el dashboard → **Redeploy** (o **Rebuild** si construís la imagen ahí).
3. Esperar a que el nuevo contenedor esté en ejecución.

---

## 2. Revisar logs del servicio de WhatsApp

Los logs indican si el flujo nuevo se está ejecutando y si Gemini llama o no a la herramienta.

**Comandos (según cómo corra el servicio):**

- Docker: `docker logs <contenedor_whatsapp> --tail 200`
- Docker Swarm: `docker service logs checkin24hs_whatsapp --tail 200`
- EasyPanel: ver logs del servicio en la interfaz

**Qué buscar:**

| Log | Significado |
|-----|-------------|
| `🌸 Flor → Gemini (model=...), mensaje=... chars, herramienta consultarCatalogoHoteles activa, hint hotel inyectado` | El código nuevo está activo y el mensaje se detectó como consulta de hotel. |
| `🔧 Flor llamó consultarCatalogoHoteles(ubicacion=..., hotel_especifico=Guilo) → X hotel(es)` | Gemini **sí** llamó a la herramienta. Si X=0 o luego "no entiendo", sospechar **RLS** (ver punto 3). |
| `🔍 Flor/Supabase: hotels devolvió 0 filas` | Supabase devolvió 0 filas al leer `hotels`. **Hipótesis RLS:** ejecutar `010_hotels_rls_select.sql` en Supabase. |
| `⚠️ Flor/Supabase: error leyendo hotels (posible RLS o red)` | Error al consultar `hotels`. Revisar RLS y conectividad. |
| `⚠️ Flor: mensaje parecía consulta de hotel pero Gemini NO llamó consultarCatalogoHoteles` | **Hipótesis invocación:** Gemini no llama la función. Revisar `flor_general_config` en Supabase (ver punto 4). |
| `🔄 Usando respuesta predefinida: noEntendido (sin respuesta de IA)` | No hubo texto de Gemini (timeout, error o respuesta vacía); se devolvió la respuesta predefinida. |
| `🔄 Flor: Gemini devolvió texto tipo "no entiendo" (preview: ...)` | Gemini **sí** respondió, pero con un texto de "no entiendo"; no se usó la predefinida. Ajustar prompt en Supabase. |

Si **nunca** ves "hint hotel inyectado" ni "consultarCatalogoHoteles activa", el servicio casi seguro está corriendo una versión vieja del código → volver al punto 1.

---

## 3. Aplicar RLS en la tabla `hotels` (Supabase)

Si RLS está habilitado en `hotels` y no hay política SELECT para `anon`, las lecturas desde la API (cliente anónimo) devuelven vacío. Flor llama a la herramienta, recibe "no encontrado" y puede terminar en respuestas genéricas o de error.

**Qué hacer:**

1. En Supabase → **SQL Editor** → Nueva consulta.
2. Pegar y ejecutar el contenido de `supabase-migrations/010_hotels_rls_select.sql`.
3. Comprobar que no haya errores (si RLS ya estaba bien configurado, el script es idempotente).

---

## 4. Revisar `flor_general_config` en Supabase

El prompt que usa Flor se arma así: **prompt de Supabase (`flor_general_config`) + FLOR_REGLAS_PRIORIDAD** (reglas en código). Si en Supabase hay algo del estilo "si no entendés, decí que no podés entender" o "no inventes, si no sabés di no entiendo", Gemini puede priorizar eso y no llamar a la herramienta.

**Qué hacer:**

1. Supabase → **Table Editor** → tabla `system_config`.
2. Buscar la fila con `key = 'flor_general_config'`.
3. En `value` (JSON), revisar `promptGeneral`.
4. Asegurarse de que **no** diga que debe responder "no entiendo" o "no he podido entender" ante consultas de hoteles. El código ya añade al final las reglas que exigen usar `consultarCatalogoHoteles`; el prompt de Supabase no debe contradecirlas.

Opcional: temporalmente borrar o vaciar `promptGeneral` para que el servidor use solo `FLOR_PROMPT_DEFAULT` + `FLOR_REGLAS_PRIORIDAD` (definidos en código) y probar de nuevo con "info del hotel Guilo".

---

## 5. Resumen rápido

1. **Redeploy** del servicio WhatsApp para asegurar código actual.
2. **Logs**: confirmar "hint hotel inyectado" y si aparece "Flor llamó consultarCatalogoHoteles" o "Gemini NO llamó".
3. **RLS**: ejecutar `010_hotels_rls_select.sql` en Supabase si no se hizo.
4. **flor_general_config**: que el texto en `promptGeneral` no obligue a decir "no entiendo" para consultas de hoteles.

Con eso se puede saber si el fallo está en despliegue, en Gemini (no llamar la herramienta), en Supabase (RLS o prompt) o en errores/timeouts del servidor.
