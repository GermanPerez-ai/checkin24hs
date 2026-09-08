# WhatsApp — Entrega serializada, rate-limit y cripto no-fatal

Evita **"Esperando el mensaje"** y caídas de L3/L4 por ráfagas de multimedia / reenvíos (Bad MAC).

## Cambios en `whatsapp-server-baileys.js`

| Feature | Comportamiento |
|---------|----------------|
| Cola por chat | Una burbuja a la vez por JID |
| Gap entre burbujas (mismo chat) | Default **3000 ms** (`WA_OUTBOUND_BUBBLE_DELAY_MS`) |
| Gap GLOBAL (toda la línea) | Default **900 ms** (`WA_GLOBAL_OUTBOUND_GAP_MS`) |
| Gap extra tras media | Default **4500 ms** (`WA_MEDIA_OUTBOUND_GAP_MS`) |
| ACK texto / media | 12s / 20s (`WA_OUTBOUND_DELIVERY_WAIT_MS`, `WA_MEDIA_DELIVERY_WAIT_MS`) |
| Cola inbound upsert | Serializa batches; yield entre msgs (`WA_INBOUND_MSG_YIELD_MS`) |
| Cripto no-fatal | Bad MAC / decrypt fallido → warn, **no** mata proceso ni wipea auth (`FLOR_CRYPTO_NONFATAL`) |
| `/api/send-media` y `/api/send-audio` | Pasan por la misma cola rate-limit (ya no bypassean) |
| Link preview | **`linkPreview: null`** en textos |
| Cotización | Imagen **sola** → pausa → texto |

## Variables de entorno

```bash
WA_OUTBOUND_BUBBLE_DELAY_MS=3000   # ms entre burbujas del mismo chat
WA_GLOBAL_OUTBOUND_GAP_MS=900      # ms mínimos entre CUALQUIER envío de la línea
WA_MEDIA_OUTBOUND_GAP_MS=4500      # ms extra tras imagen/video/audio/doc
WA_OUTBOUND_DELIVERY_WAIT_MS=12000
WA_MEDIA_DELIVERY_WAIT_MS=20000
WA_DEFAULT_QUERY_TIMEOUT_MS=120000
WA_INBOUND_UPSERT_CONCURRENCY=1
WA_INBOUND_MSG_YIELD_MS=40
FLOR_CRYPTO_NONFATAL=1             # 0 = comportamiento agresivo anterior
FLOR_SESSION_CRYPTO_WINDOW_MS=300000
```

## Logs a buscar

```bash
docker service logs checkin24hs_whatsapp3 --tail 150 2>&1 | grep -iE 'WA OUT|rate-limit|cripto no-fatal|Bad MAC|WA DELIVERY'
```

| Log | Significado |
|-----|-------------|
| `⏳ WA rate-limit global` | Esperando gap entre envíos (protección Signal) |
| `⚠️ ... cripto no-fatal` | Paquete multimedia corrupto ignorado; sesión viva |
| `📤 WA OUT` | Envío aceptado por Baileys |
| `📬 WA ENTREGA` | ACK servidor/dispositivo |

## Deploy

```bash
cd /root/checkin24hs
git pull origin main
docker build -t easypanel/checkin24hs/whatsapp:latest whatsapp-server/
docker service update --image easypanel/checkin24hs/whatsapp:latest --force checkin24hs_whatsapp
docker service update --image easypanel/checkin24hs/whatsapp:latest --force checkin24hs_whatsapp2
docker service update --image easypanel/checkin24hs/whatsapp:latest --force checkin24hs_whatsapp3
docker service update --image easypanel/checkin24hs/whatsapp:latest --force checkin24hs_whatsapp4
```

Si L3 sigue en `connecting` con sesión corrupta previa: QR en Dashboard → Flor → WhatsApp (o wipe auth de esa instancia).
