# WhatsApp — Entrega serializada y logs de ack

Evita **"Esperando el mensaje"** cuando Flor envía imagen + link + texto.

## Cambios en `whatsapp-server-baileys.js`

| Feature | Comportamiento |
|---------|----------------|
| Cola por chat | Una burbuja a la vez por JID |
| Gap entre burbujas | Default **2500 ms** (`WA_OUTBOUND_GAP_MS`) |
| Link preview | **`linkPreview: false`** en todo texto con URL |
| Cotización | Imagen **sola** → pausa → texto (nunca caption+link juntos) |
| Wait ack | Opcional **8000 ms** antes de siguiente burbuja (`WA_OUTBOUND_WAIT_ACK_MS`) |

## Logs a buscar

```bash
docker service logs checkin24hs_whatsapp --tail 100 2>&1 | grep -iE 'WA OUT|WA DELIVERED|WA SERVER_ACK|WA DELIVERY|ACK timeout'
```

| Log | Significado |
|-----|-------------|
| `📤 WA OUT SENT` | Baileys aceptó el envío |
| `📬 WA SERVER_ACK` | WhatsApp servidor recibió |
| `✅ WA DELIVERED` | Entregado al dispositivo (status ≥ 3) |
| `❌ WA DELIVERY ERROR` | Rebotó (status 0) |
| `⚠️ WA DELIVERY TIMEOUT` | Sin ack en 120 s |

## Variables de entorno

```bash
WA_OUTBOUND_GAP_MS=2500        # ms entre burbujas (2–3 s recomendado)
WA_OUTBOUND_WAIT_ACK_MS=8000   # esperar ack servidor antes de siguiente (0=off)
```

## Deploy

```bash
cd /root/checkin24hs
git pull origin main
docker build -t easypanel/checkin24hs/whatsapp:latest whatsapp-server/
docker service update --image easypanel/checkin24hs/whatsapp:latest --force checkin24hs_whatsapp
# Repetir whatsapp2, whatsapp3, whatsapp4
```
