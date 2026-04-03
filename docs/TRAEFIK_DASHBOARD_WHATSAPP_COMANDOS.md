# Traefik: Dashboard y WhatsApp (comandos Linux/bash)

Ejecutar en el servidor **uno por uno**. El dashboard usa **puerto 3000** (no 80).  
Obligatorio: `traefik.enable=true` y, si Traefik usa la red `easypanel`, `traefik.docker.network=easypanel`.

---

## Opción recomendada: labels en el repo (sin reconfigurar en cada redeploy)

En la **raíz del repo** está `docker-compose.easypanel.yml` con los labels de Traefik ya definidos. Si en EasyPanel usás **Deploy / Redeploy from Compose** apuntando a ese archivo (o importás el compose al crear la app), cada redeploy **mantendrá** la configuración de Traefik sin tener que volver a ejecutar `docker service update`.

- **Archivo:** `docker-compose.easypanel.yml`
- **Uso en EasyPanel:** Apps → New App → From Compose (o Redeploy from Compose) y seleccionar este archivo / repo con este compose.

Si no usás compose en EasyPanel, aplicá los labels a mano con los comandos de abajo después de cada redeploy.

---

## 1. Verificar red (opcional)

```bash
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'
docker network ls | grep easypanel
```

Si el servicio no está en `easypanel`, agregarlo:

```bash
docker service update --network-add easypanel checkin24hs_dashboard
docker service update --network-add easypanel checkin24hs_whatsapp
```

## 2. Dashboard (puerto 3000 + traefik.enable + red)

**Etiquetas Traefik para el dashboard:**

| Label | Valor |
|-------|--------|
| `traefik.enable` | `true` |
| `traefik.docker.network` | `easypanel` |
| `traefik.http.routers.dashboard.rule` | `Host(\`dashboard.checkin24hs.com\`)` |
| `traefik.http.routers.dashboard.entrypoints` | `websecure` |
| `traefik.http.routers.dashboard.service` | `dashboard` |
| `traefik.http.routers.dashboard.tls` | `true` |
| `traefik.http.routers.dashboard.tls.certresolver` | `letsencrypt` |
| `traefik.http.services.dashboard.loadbalancer.server.port` | `3000` |

**Comando (varias líneas):**

```bash
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.docker.network=easypanel" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.service=dashboard" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  checkin24hs_dashboard
```

**En una sola línea (copiar/pegar):**

```bash
docker service update --label-add "traefik.enable=true" --label-add "traefik.docker.network=easypanel" --label-add 'traefik.http.routers.dashboard.rule=Host(`dashboard.checkin24hs.com`)' --label-add "traefik.http.routers.dashboard.entrypoints=websecure" --label-add "traefik.http.routers.dashboard.service=dashboard" --label-add "traefik.http.routers.dashboard.tls=true" --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" checkin24hs_dashboard
```

*(Ejecutar en el servidor Linux; el dashboard escucha en puerto 3000.)*

- Servicio: `checkin24hs_dashboard`
- Red: `easypanel`
- Puerto interno: `3000`

## 3. WhatsApp (traefik.enable + red)

```bash
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.docker.network=easypanel" \
  --label-add "traefik.http.routers.whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp.service=whatsapp" \
  --label-add "traefik.http.routers.whatsapp.tls=true" \
  --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=3001" \
  checkin24hs_whatsapp
```

**En una sola línea:**

```bash
docker service update --label-add "traefik.enable=true" --label-add "traefik.docker.network=easypanel" --label-add 'traefik.http.routers.whatsapp.rule=Host(`whatsapp.checkin24hs.com`)' --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" --label-add "traefik.http.routers.whatsapp.service=whatsapp" --label-add "traefik.http.routers.whatsapp.tls=true" --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=3001" checkin24hs_whatsapp
```

## 4. Si la red no se llama `easypanel`

Listar redes:

```bash
docker network ls
```

Si Traefik usa otra (p. ej. `traefik-public` o `proxy`), reemplazar `easypanel` por ese nombre en las etiquetas `traefik.docker.network=...`. En EasyPanel suele ser `easypanel`.

## 5. Probar

- https://dashboard.checkin24hs.com
- https://whatsapp.checkin24hs.com (o https://whatsapp.checkin24hs.com/api/qr)
