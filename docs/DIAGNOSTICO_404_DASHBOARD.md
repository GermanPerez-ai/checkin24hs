# Diagnóstico 404 dashboard.checkin24hs.com

## 1. ¿Los labels siguen en el servicio?

Después de `docker service update --label-add ...`, ejecutá:

```bash
docker service inspect checkin24hs_dashboard --format '{{json .Spec.Labels}}' | python3 -m json.tool
```

- Si sale **{}** otra vez: algo (p. ej. EasyPanel) está quitando los labels. En ese caso la ruta hay que configurarla **en la UI de EasyPanel** (dominio personalizado para el servicio dashboard).
- Si salen las claves `traefik.http.routers.dashboard.*`: los labels están; el problema es otro (red, Traefik, entrypoint).

## 2. Labels mínimos (sin middleware) con service=dashboard

En Traefik el nombre del **servicio** es el de la etiqueta (`traefik.http.services.dashboard...`), no el nombre del servicio en Swarm. El router debe apuntar a **service=dashboard**.

Aplicar solo estos labels (una sola línea, copiar/pegar):

```bash
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.docker.network=easypanel" \
  --label-add 'traefik.http.routers.dashboard.rule=Host(`dashboard.checkin24hs.com`)' \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.service=dashboard" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  checkin24hs_dashboard
```

(Usamos `service=dashboard` porque en las etiquetas el servicio se llama `traefik.http.services.**dashboard**.loadbalancer`.)

## 3. Red y Traefik

Comprobar que el dashboard está en la red `easypanel`:

```bash
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | python3 -m json.tool
```

Comprobar que existe la red y que Traefik está en ella:

```bash
docker network ls | grep easypanel
docker service ls | grep -i traefik
docker service inspect <nombre_traefik> --format '{{json .Spec.TaskTemplate.Networks}}' | python3 -m json.tool
```

Si Traefik no está en `easypanel`, el dashboard no será descubierto. En ese caso hay que añadir Traefik a la red `easypanel` (o usar la red que use Traefik en las etiquetas).

## 4. Si Traefik de EasyPanel no usa labels de Swarm

En EasyPanel, muchas veces la ruta (dominio) se configura **en la app**, no con labels del servicio:

1. Entrá a EasyPanel → Apps → la app del dashboard (checkin24hs).
2. Buscá **Dominio**, **Custom domain** o **Domains** para el servicio **dashboard**.
3. Añadí **dashboard.checkin24hs.com** y guardá.
4. Volvé a desplegar si hace falta.

Eso hace que EasyPanel genere la configuración de Traefik para ese dominio; si Traefik no lee labels de Swarm, esto es lo que va a hacer que deje de dar 404.

## 5. Probar

- https://dashboard.checkin24hs.com
- https://dashboard.checkin24hs.com/build_id.txt
