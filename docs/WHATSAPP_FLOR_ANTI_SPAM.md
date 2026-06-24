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

| Protección | Comportamiento |
|------------|----------------|
| Antigüedad `notify` | Flor solo si el mensaje tiene ≤ **10 min** (configurable) |
| Antigüedad `append` | Flor solo si ≤ **3 min**; sin timestamp → **no responde** |
| JID | Ignora grupos, `status@broadcast`, newsletters |
| Destino | Valida que `destJid` coincida con el remitente del inbound |
| Logs | `📤 Flor OUT L{n} trigger=... to=... from=... preview=...` |

Variables opcionales en el servicio WhatsApp:

```bash
FLOR_INBOUND_MAX_AGE_MS_NOTIFY=600000   # 10 min
FLOR_INBOUND_MAX_AGE_MS_APPEND=180000   # 3 min
```

## Deploy en servidor

```bash
cd /root/checkin24hs
git pull origin main
docker build -t easypanel/checkin24hs/whatsapp:latest whatsapp-server/
docker service update --force checkin24hs_whatsapp checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4
```

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
