# Traefik para Dashboard — Si da 404 (dashboard.checkin24hs.com)

Si **https://dashboard.checkin24hs.com/** responde **404**, casi siempre es porque Traefik perdió la ruta al servicio del dashboard (por ejemplo después de un Redeploy en EasyPanel). Hay que volver a aplicar las etiquetas de Traefik al servicio del dashboard.

---

## 1. Comprobar que el servicio existe y tiene red

En el servidor (SSH):

```bash
docker service ls | grep -i dashboard
```

El nombre típico es `checkin24hs_dashboard` o `checkin24hs-dashboard`. El servicio debe estar en la **misma red que Traefik** (por ejemplo `easypanel`):

```bash
SERVICE_NAME="checkin24hs_dashboard"   # o el nombre que te dé el listado
docker service update --network-add easypanel "$SERVICE_NAME"
```

---

## 2. Aplicar etiquetas de Traefik al dashboard

### Opción A: Desde EasyPanel (Labels del servicio)

En **EasyPanel** → **Servicios** → **Dashboard** (o el que corresponda) → **Labels** / **Etiquetas**, agrega:

| Clave | Valor |
|-------|--------|
| `traefik.enable` | `true` |
| `traefik.http.routers.dashboard.rule` | `Host(\`dashboard.checkin24hs.com\`)` |
| `traefik.http.routers.dashboard.entrypoints` | `websecure` |
| `traefik.http.routers.dashboard.service` | `dashboard` |
| `traefik.http.routers.dashboard.tls` | `true` |
| `traefik.http.routers.dashboard.tls.certresolver` | `letsencrypt` |
| `traefik.http.services.dashboard.loadbalancer.server.port` | `3000` |

Guarda y, si hace falta, reinicia el servicio.

### Opción B: Desde SSH (terminal del servidor)

Reemplaza `checkin24hs_dashboard` por el nombre real del servicio si es distinto:

```bash
SERVICE_NAME="checkin24hs_dashboard"

# Red (por si se perdió después del redeploy)
docker service update --network-add easypanel "$SERVICE_NAME"

# Etiquetas Traefik
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.service=dashboard" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  "$SERVICE_NAME"
```

---

## 3. Verificar que se aplicaron las etiquetas

```bash
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep "^traefik" | sort
```

Deberías ver las claves `traefik.http.routers.dashboard.*` y `traefik.http.services.dashboard.*`.

---

## 4. Probar

- Espera **1–2 minutos** a que Traefik detecte los cambios.
- Abre: **https://dashboard.checkin24hs.com/**
- Opcional: `curl -I https://dashboard.checkin24hs.com/` (debería devolver 200, no 404).

---

## 5. Si sigue en 404

1. **Logs de Traefik:**  
   `docker service logs traefik --tail 100 2>&1 | grep -i dashboard`  
   (o el nombre del servicio de Traefik si es otro, p. ej. `checkin24hs_traefik`).

2. **Que el dashboard escuche en 3000:**  
   El contenedor del dashboard (Node/React) debe exponer el puerto **3000**. Si en EasyPanel el servicio está mapeado a otro puerto interno, la etiqueta `traefik.http.services.dashboard.loadbalancer.server.port` debe coincidir con ese puerto interno.

3. **Reiniciar Traefik (último recurso):**  
   `docker service update --force traefik`  
   (o el nombre del servicio Traefik en tu stack).

---

## Resumen rápido (copiar y pegar en SSH)

```bash
SERVICE_NAME="checkin24hs_dashboard"
docker service update --network-add easypanel "$SERVICE_NAME"
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.service=dashboard" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  "$SERVICE_NAME"
```

Luego espera 1–2 minutos y prueba **https://dashboard.checkin24hs.com/**.
