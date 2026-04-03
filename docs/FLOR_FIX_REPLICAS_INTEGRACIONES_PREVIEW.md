# Flor: Fix Réplicas, Integraciones y Preview Maps

## Cambios aplicados (según diagnóstico técnico)

### 1. Kill Duplicate Processes – Réplicas

**Problema:** Stream errored (conflict replaced). Varias instancias usando el mismo número de WhatsApp.

**Solución:**
- `docker-compose.easypanel.yml`: `update_config.order: stop-first` para evitar overlap durante deploy (detener tarea vieja antes de iniciar la nueva).
- Script `scripts/verificar_replicas_whatsapp.sh` para verificar que solo corre 1 réplica.

**Comando para verificar:**
```bash
bash scripts/verificar_replicas_whatsapp.sh
docker service scale checkin24hs_whatsapp=1
```

---

### 2. Integrations Priority – Bypass total del LLM

**Problema:** Flor respondía con Gemini incluso cuando había match en integraciones.

**Solución:**
- El bypass ya existía: si `detectarIntegracionActivada` retorna match, se envía texto literal y **no se llama a procesarConFlor**.
- Se mejoró la detección: el **nombre del hotel** (ej. "Futangue") actúa como trigger implícito. Si el usuario escribe "info de Futangue", ahora matchea aunque no esté en `triggerKeywords`.
- Se enriquecen integraciones con `hotel.name` al cargar desde `hotels.flor_info`.

**Requisito:** Que la integración del hotel tenga `content` y opcionalmente `triggerKeywords`. El nombre del hotel se usa automáticamente como keyword.

---

### 3. Fetch Error – Preview de Maps

**Problema:** `fetch failed` al obtener miniatura de Maps, ensuciando el log y demorando la respuesta.

**Solución:**
- `obtenerPreviewURL()`: retorna `null` inmediatamente si la URL es de Google Maps (evita el fetch).
- Timeout reducido a 3s.
- Errores silenciados (sin `console.warn`) para no ensuciar el log; Baileys genera preview automático si hace falta.

---

## Resumen para el programador

| Item | Acción |
|------|--------|
| Réplicas | `replicas: 1` + `update_config.order: stop-first` |
| Integraciones | Bypass LLM si hay match; nombre del hotel como trigger implícito |
| Preview Maps | No fetch para Maps; errores silenciados |

---

## Pregunta clave para diagnóstico

> "¿Cuántas réplicas del servicio checkin24hs_whatsapp hay corriendo?"

Si hay más de una, ese es el problema de las desconexiones y el bucle de Reconectando / statusCode 440.
