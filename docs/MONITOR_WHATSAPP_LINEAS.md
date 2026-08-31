# Monitor Checkin24hs — WhatsApp multi-línea

## Qué detecta ahora

| Check | Alerta WhatsApp |
|-------|-----------------|
| Web / Dashboard / Cotizador caídos | Sí |
| **L1–L4** `/api/health` timeout o `whatsapp != open` | Sí |
| Errores cripto de sesión (`florSessionCryptoIssuesLastWindow` > 80) | Sí |
| Línea sin msgs hoy + otras con tráfico **y** status disconnected / Flor off | Sí |
| Línea sin msgs pero status `connected` + Flor active | No (solo texto ⚠️ en digest) |

Las alertas se envían a `MONITOR_ALERT_PHONE` vía `WHATSAPP_API_URL/api/send` (normalmente L1).

## Diagnóstico actual Línea 4 (ago 2026)

`https://whatsapp4.checkin24hs.com/api/status` reportó:

- `whatsapp: disconnected` / `close`
- `phone: null`
- `florSessionCryptoIssuesLastWindow` muy alto

**Flor no contesta porque la sesión Baileys de L4 está caída**, no porque el monitor “ignore” el caso.

## Reparar L4 en el servidor

```bash
cd /root/checkin24hs
git pull origin main
bash scripts/reparar_whatsapp_linea_servidor.sh 4
```

Si sigue `disconnected`: Dashboard → Flor IA → WhatsApp → Línea 4 → escanear QR  
(o `https://whatsapp4.checkin24hs.com/qr`).

## Actualizar el monitor en el servidor

```bash
cd /root/checkin24hs && git pull origin main
# El cron que corre monitor.js ya usa el archivo nuevo tras el pull.
# Probar:
MONITOR_ALERT_PHONE=549XXXXXXXXXX node scripts/site-monitor/monitor.js --dry-run
```

Variables opcionales:

- `WHATSAPP2_API_URL`, `WHATSAPP3_API_URL`, `WHATSAPP4_API_URL`
- `MONITOR_CRYPTO_ISSUES_MAX` (default `80`)
- En Swarm interno:  
  `WHATSAPP_API_URL=http://checkin24hs_whatsapp:3001`  
  `WHATSAPP4_API_URL=http://checkin24hs_whatsapp4:3004` etc.
