# Flor IA — Protocolo de Silencio (45 min, agnóstico al origen)

Cuando un **humano** envía un mensaje en un chat, Flor entra en **silencio total** durante **45 minutos** (configurable con `FLOR_SILENCE_MINUTES`).

## Orígenes que activan el silencio

| Origen | Cómo se detecta |
|--------|-----------------|
| WhatsApp desde el celular | Baileys `fromMe` (excluye mensajes de Flor) |
| Dashboard / CRM | `POST /api/send`, `/api/send-audio`, `/api/send-media` + `setFlorPausedForChat` |
| API externa | Cualquier envío por `/api/send*` del servidor WhatsApp |

**No importa la plataforma**: si hubo un mensaje saliente humano hace menos de 45 min, Flor **no responde**.

## Dónde se guarda

| Campo | Tabla | Uso |
|-------|-------|-----|
| `flor_paused_until` | `whatsapp_chats` | Timestamp hasta cuándo callar |
| `last_human_outbound_at` | `whatsapp_chats` | Momento exacto del último mensaje humano |
| `is_from_flor` | `whatsapp_messages` | `true` = Flor; `false` = humano |
| RAM `florPauseMemoryUntil` | Servidor WhatsApp | Cache rápida por teléfono |

Flor también revisa el último mensaje saliente no-Flor en `whatsapp_messages` como **fallback**.

## Bug corregido (multi-chat LID / E.164)

Un mismo cliente puede tener **varias filas** en `whatsapp_chats` (phone = LID vs `real_phone` = +E.164).
Antes el check usaba `.limit(1)` por `updated_at` y a menudo leía la fila del **inbound** (sin pausa), ignorando la fila donde sí estaba `last_human_outbound_at`.

Ahora `assertFlorSilenceProtocolDbOnly()` revisa **todas** las filas relacionadas y `setFlorPausedUntil()` actualiza **todas** (chat_id + phone + real_phone + LID).

## Migración Supabase (obligatoria una vez)

Ejecutar en Supabase SQL Editor:

```bash
# Archivo: supabase-migrations/050_flor_protocolo_silencio_humano.sql
```

## Variables de entorno (servicio WhatsApp)

```bash
FLOR_SILENCE_MINUTES=45   # default en código: 45
FLOR_ENABLED=true
AUTO_REPLY=true
```

Si en EasyPanel ya tenés `FLOR_SILENCE_MINUTES=30`, cambialo a `45` o borrá la variable para usar el default del código.

## Verificar en logs

```bash
docker service logs checkin24hs_whatsapp --tail 50 2>&1 | grep -iE 'Modo Silencio|Flor pausa|Flor ABORT silencio|silencio activo'
```

## Deploy

```bash
cd /root/checkin24hs
git pull origin main
docker build -t easypanel/checkin24hs/whatsapp:latest whatsapp-server/
docker service update --image easypanel/checkin24hs/whatsapp:latest --force checkin24hs_whatsapp
```
