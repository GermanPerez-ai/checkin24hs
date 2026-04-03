# Traefik para WhatsApp — Después del Redeploy (EasyPanel)

Después de hacer **Redeploy** del servicio WhatsApp en EasyPanel, si el dominio `https://whatsapp.checkin24hs.com` deja de funcionar o da 404, aplicá de nuevo las etiquetas de Traefik.

---

## Opción A: Desde EasyPanel (si tiene sección Labels)

En **EasyPanel** → **Servicios** → **WhatsApp** → **Labels** (o **Etiquetas**), agregá estas etiquetas:

| Clave | Valor |
|-------|--------|
| `traefik.enable` | `true` |
| `traefik.http.routers.whatsapp.rule` | `Host(\`whatsapp.checkin24hs.com\`)` |
| `traefik.http.routers.whatsapp.entrypoints` | `websecure` |
| `traefik.http.routers.whatsapp.service` | `whatsapp` |
| `traefik.http.routers.whatsapp.tls` | `true` |
| `traefik.http.routers.whatsapp.tls.certresolver` | `letsencrypt` |
| `traefik.http.services.whatsapp.loadbalancer.server.port` | `3001` |

Guardá y, si hace falta, reiniciá el servicio.

---

## Opción B: Desde SSH (terminal del servidor)

Conectate por SSH al servidor donde corre EasyPanel y ejecutá (reemplazá `checkin24hs_whatsapp` por el nombre real del servicio si es distinto):

```bash
SERVICE_NAME="checkin24hs_whatsapp"

# Red (por si se perdió después del redeploy)
docker service update --network-add easypanel "$SERVICE_NAME"

# Etiquetas Traefik
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp.service=whatsapp" \
  --label-add "traefik.http.routers.whatsapp.tls=true" \
  --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=3001" \
  "$SERVICE_NAME"
```

**Verificar que se aplicaron:**

```bash
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep "^traefik" | sort
```

**Probar:**

- https://whatsapp.checkin24hs.com/api/health  
- https://whatsapp.checkin24hs.com/api/qr  

---

## Resumen rápido (copiar y pegar en SSH)

```bash
SERVICE_NAME="checkin24hs_whatsapp"
docker service update --network-add easypanel "$SERVICE_NAME"
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp.service=whatsapp" \
  --label-add "traefik.http.routers.whatsapp.tls=true" \
  --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=3001" \
  "$SERVICE_NAME"
```

Nota: Traefik puede tardar 1–2 minutos en detectar los cambios.
