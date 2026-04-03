# Traefik: labels para la web (www.checkin24hs.com) – solucionar 404

Si después del deploy en EasyPanel **www.checkin24hs.com** devuelve 404, suele ser porque Traefik no tiene las labels en el servicio de la web. Aplicá las labels **en el servidor** (SSH).

---

## Nombre del servicio

En EasyPanel el servicio de la web puede llamarse:

- `checkin24hs_web`, o  
- `checkin24hs_appwebcheckin24hs`

Comprobá con:

```bash
docker service ls | grep -E "web|appweb"
```

---

## Labels de Traefik para la web

| Label | Valor |
|-------|--------|
| `traefik.enable` | `true` |
| `traefik.docker.network` | `easypanel` |
| `traefik.http.routers.web.rule` | `Host(\`www.checkin24hs.com\`) \|\| Host(\`checkin24hs.com\`)` |
| `traefik.http.routers.web.entrypoints` | `websecure` |
| `traefik.http.routers.web.service` | `web` |
| `traefik.http.routers.web.tls` | `true` |
| `traefik.http.routers.web.tls.certresolver` | `letsencrypt` |
| `traefik.http.services.web.loadbalancer.server.port` | `80` |

---

## Opción 1: Script (recomendado)

En el servidor, desde la raíz del repo:

```bash
cd /root/checkin24hs
bash scripts/reaplicar_traefik_despues_deploy.sh
```

Eso reaplica las labels de la web, cotizador y webmail. Esperá unos segundos y probá https://www.checkin24hs.com

---

## Opción 2: Comando solo para la web

Si el servicio se llama **checkin24hs_appwebcheckin24hs**:

```bash
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.docker.network=easypanel" \
  --label-add "traefik.http.routers.web.rule=Host(\`www.checkin24hs.com\`) || Host(\`checkin24hs.com\`)" \
  --label-add "traefik.http.routers.web.entrypoints=websecure" \
  --label-add "traefik.http.routers.web.service=web" \
  --label-add "traefik.http.routers.web.tls=true" \
  --label-add "traefik.http.routers.web.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.web.loadbalancer.server.port=80" \
  checkin24hs_appwebcheckin24hs
```

Si el servicio se llama **checkin24hs_web**, reemplazá al final por `checkin24hs_web`.

**Una sola línea (checkin24hs_appwebcheckin24hs):**

```bash
docker service update --label-add "traefik.enable=true" --label-add "traefik.docker.network=easypanel" --label-add 'traefik.http.routers.web.rule=Host(`www.checkin24hs.com`) || Host(`checkin24hs.com`)' --label-add "traefik.http.routers.web.entrypoints=websecure" --label-add "traefik.http.routers.web.service=web" --label-add "traefik.http.routers.web.tls=true" --label-add "traefik.http.routers.web.tls.certresolver=letsencrypt" --label-add "traefik.http.services.web.loadbalancer.server.port=80" checkin24hs_appwebcheckin24hs
```

---

## Red easypanel

Si aun así hay 404, asegurate de que el servicio esté en la red `easypanel`:

```bash
docker network inspect easypanel
docker service update --network-add easypanel checkin24hs_appwebcheckin24hs
```

(Reemplazá `checkin24hs_appwebcheckin24hs` por el nombre que te dé `docker service ls`.)

---

## Resumen

1. Conectate por SSH al servidor.  
2. `cd /root/checkin24hs && bash scripts/reaplicar_traefik_despues_deploy.sh`  
3. Esperá ~10 s y probá https://www.checkin24hs.com (Ctrl+Shift+R si hace falta).

Si en EasyPanel podés editar **labels** del servicio de la web, podés agregar ahí las de la tabla; así se mantienen en los próximos deploys.
