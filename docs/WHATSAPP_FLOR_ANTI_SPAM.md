# Flor — Mensajes proactivos no solicitados (anti-spam)

## Síntoma

Flor envía mensajes a contactos que **no escribieron** (o que no escribieron recientemente). Riesgo: reportes de spam y bloqueo del número por WhatsApp.

## Causa técnica más probable (auditada en código)

1. **Reprocesamiento de mensajes `append`**  
   Al reconectar WhatsApp (reinicio, deploy, 4 líneas), Baileys entrega mensajes viejos del buffer offline con `type=append`. El servidor los trataba como inbound nuevo y Flor respondía **horas o días después** — mensaje “proactivo” para el cliente.

2. **Destino incorrecto (menos frecuente)**  
   Resolución LID→teléfono desde caché/Supabase podía apuntar a otro número. Se agregó validación antes de `sendMessage`.

3. **No hay cron ni marketing** en el repo que dispare Flor sola. `/api/send` solo envía si alguien lo llama desde dashboard/cotizador.

## Fix aplicado (whatsapp-server-baileys.js)

### 1. Protocolo de Silencio (DB-only, 30 min)

`assertFlorSilenceProtocolDbOnly()` consulta **solo Supabase** (`flor_paused_until`, `last_human_outbound_at`, fallback `whatsapp_messages` humanos). Se ejecuta:

- Al recibir inbound (antes de encolar Flor)
- Al inicio de `processPending` (antes de Gemini)
- Al inicio de `procesarConFlor` (antes de tokens/historial)
- Antes de enviar la respuesta

**No usa RAM** para decidir silencio en estos puntos críticos.

### 2. Entrega WhatsApp ("Esperando mensaje")

- Cola de salida por JID con **3 segundos** entre burbujas (`WA_OUTBOUND_BUBBLE_DELAY_MS=3000`)
- **Flor solo texto plano** activado por defecto (`FLOR_TEXT_ONLY_OUTBOUND` — sin imágenes, PDFs ni link preview)
- Links se envían como texto con `linkPreview: null`
- Desactivar modo texto: `FLOR_TEXT_ONLY_OUTBOUND=0` en el servicio WhatsApp

### 3. Message Lock (ghost replies)

- Columna `whatsapp_chats.flor_last_processed_inbound_id` (migración `052`)
- Antes de Gemini: si el `message_id` entrante ya fue procesado → abort
- Tras respuesta exitosa: se guarda el último `message_id` en DB
- Inbound sin `message_id` → no se encola
- Mensajes `append` antiguos (>3 min) → no auto-respuesta

| Protección | Comportamiento |
|------------|----------------|
| Antigüedad `notify` | Flor solo si el mensaje tiene ≤ **10 min** |
| Antigüedad `append` | Flor solo si ≤ **3 min**; sin timestamp → **no responde** |
| Message Lock DB | `flor_last_processed_inbound_id` evita segunda respuesta al mismo id |
| Historial IA | Últimos 10 mensajes por **chat_id** (no solo teléfono) |

Variables opcionales:

```bash
FLOR_SILENCE_MINUTES=30
WA_OUTBOUND_BUBBLE_DELAY_MS=3000
FLOR_TEXT_ONLY_OUTBOUND=1   # 0 para reactivar imágenes
FLOR_INBOUND_MAX_AGE_MS_NOTIFY=600000
FLOR_INBOUND_MAX_AGE_MS_APPEND=180000
```

## Deploy en servidor

```bash
cd /root/checkin24hs
git pull origin main

# Migración Supabase (Message Lock)
# Ejecutar 052_flor_last_processed_inbound_id.sql en Supabase SQL Editor

docker build -t easypanel/checkin24hs/whatsapp:latest whatsapp-server/
docker service update --force checkin24hs_whatsapp checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4
```

En logs deberías ver:
- `📤 Cola salida WA: 3000ms entre mensajes. Flor solo texto: SÍ`
- `🛑 Flor ABORT silencio DB` cuando un asesor intervino
- `🔒 Flor Message Lock` cuando bloquea duplicados

## Buscar qué disparó un mensaje a un contacto

```bash
bash scripts/buscar_log_flor_outbound_servidor.sh "Marisa"
bash scripts/buscar_log_flor_outbound_servidor.sh "profesionales"
```

En logs buscar:

- `📤 Flor OUT` — envío con destino y preview
- `⏭️ Flor: mensaje antiguo` — bloqueado por anti-spam (post-fix)
- `📱 Mensaje recibido de` — inbound que disparó Flor

## Modelo correcto

Flor debe ser **100% reactiva**: solo responde cuando hay un mensaje entrante **real y reciente** del mismo contacto.
