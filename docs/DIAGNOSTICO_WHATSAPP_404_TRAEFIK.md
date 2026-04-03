# WhatsApp `https://whatsapp.checkin24hs.com` → 404 (OPTIONS o GET)

Si `curl` a `/api/send` (OPTIONS) o `/health` devuelve **HTTP 404** y cuerpo tipo `404 page not found`, **Traefik no está enrutando al contenedor** (o el host no coincide). No es un bug de CORS en Node todavía: la petición no llega a Express.

## 1. Comprobar si **alguna** ruta responde desde Node

```bash
curl -sI 'https://whatsapp.checkin24hs.com/health'
curl -sI 'https://whatsapp.checkin24hs.com/api/health'
curl -sI 'https://whatsapp.checkin24hs.com/status'
```

- Si **todo** es 404 → router Traefik / red / DNS.
- Si GET da **200** y solo OPTIONS da 404 → raro; revisar middlewares que filtren por método.

## 2. Ver labels reales del servicio Swarm

```bash
docker service inspect checkin24hs_whatsapp --format '{{json .Spec.Labels}}' | jq .
```

Comprobar:

| Requisito | Ejemplo correcto (ver `docker-compose.easypanel.yml`) |
|-----------|------------------------------------------------------|
| Red Traefik | `traefik.docker.network=easypanel` |
| Router + regla Host | `traefik.http.routers.whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`)` |
| Entrypoint HTTPS | `traefik.http.routers.whatsapp.entrypoints=websecure` |
| Servicio backend | `traefik.http.routers.whatsapp.service=whatsapp` |
| Puerto del contenedor | `traefik.http.services.whatsapp.loadbalancer.server.port=3001` |
| TLS | `tls=true` + `certresolver=letsencrypt` (o el que uses) |

**Importante:** el nombre del **router** (`whatsapp`) y el del **servicio Traefik** (`traefik.http.services.whatsapp`) deben coincidir con lo que pone `traefik.http.routers.<router>.service=`.

Si el router apunta a `service=checkin24hs_whatsapp` pero **no** existe `traefik.http.services.checkin24hs_whatsapp.loadbalancer.server.port`, Traefik no tendrá backend → errores / 404.

## 3. Red `easypanel`

El contenedor debe estar en la misma red que Traefik:

```bash
docker service inspect checkin24hs_whatsapp --format '{{json .Spec.TaskTemplate.Networks}}'
```

Si falta `easypanel`:

```bash
docker service update --network-add easypanel checkin24hs_whatsapp
```

## 4. Middlewares CORS en Traefik (`whatsapp-cors`)

En `docker-compose.easypanel.yml` el router usa:

`traefik.http.routers.whatsapp.middlewares=whatsapp-cors,whatsapp-body`

Esas middlewares están definidas **en los mismos labels** del servicio. Si en el servidor solo añadiste el router **sin** las líneas `traefik.http.middlewares.whatsapp-cors...`, Traefik puede dejar el router inválido o comportarse mal.

**Recomendación:** desplegar WhatsApp desde el **compose del repo** (`docker-compose.easypanel.yml` sección `whatsapp`) para que labels y middlewares vayan juntos.

## 5. DNS

Comprobar que el dominio apunta al mismo servidor donde corre Traefik:

```bash
dig +short whatsapp.checkin24hs.com
```

## 6. Tras arreglar el 404

Cuando `curl -sI` a `/api/health` devuelva **200** desde HTTPS, volver a probar CORS:

```bash
curl -sI -X OPTIONS 'https://whatsapp.checkin24hs.com/api/send' \
  -H 'Origin: https://dashboard.checkin24hs.com' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type'
```

Deberías ver **204** (o 200) y cabeceras `Access-Control-*` (Traefik y/o Node).

---

**Resumen:** `404` en el `curl` que mostraste = **problema de enrutado Traefik/Swarm/DNS**, no del código de `/api/send`. Corregí labels + red + despliegue desde compose; luego el parche CORS en `whatsapp-server-baileys.js` tendrá efecto.
