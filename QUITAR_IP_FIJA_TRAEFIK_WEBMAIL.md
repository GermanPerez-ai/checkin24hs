# Solución 404 webmail: EasyPanel revierte la IP

## Qué pasa

- La label vuelve siempre a `10.0.1.42:80` (EasyPanel la sobrescribe).
- El contenedor real está en `10.0.1.6`.
- Traefik puede conectar a `10.0.1.6:80` (el backend responde bien).

## Opción A: Quitar la IP fija y que Traefik use el servicio (recomendado)

En Swarm, si **no** pones `loadbalancer.server`, Traefik puede tomar las IPs de las tareas del servicio que tiene las labels. Así no dependes de una IP fija que EasyPanel revierte.

En el servidor:

```bash
docker service update --label-rm "traefik.http.services.webmail.loadbalancer.server" checkin24hs_webmail
```

Espera 20–30 segundos (y opcionalmente reinicia Traefik: `docker service update --force $(docker service ls -q --filter name=traefik)`).  
Luego prueba: **https://webmail.checkin24hs.com/**

Si tras quitar la label **sigue** 404, es que en tu setup Traefik **sí** necesita esa label (p. ej. EasyPanel la rellena siempre). En ese caso usa la Opción B.

## Opción B: Corregir desde EasyPanel

1. Entra en **EasyPanel**.
2. Abre el servicio **webmail** (checkin24hs / webmail).
3. En **Dominios** (o **Domains**):  
   - Quita `webmail.checkin24hs.com`, guarda e implementa.  
   - Vuelve a añadir `webmail.checkin24hs.com`, guarda e **Implementar** otra vez.  
   Así el panel debería detectar la IP actual del contenedor y crear la label con `10.0.1.6:80`.
4. Si hay una sección **Avanzado** / **Traefik** / **Proxy** donde se vea “backend” o “server” con una IP, cámbiala a la IP actual del contenedor (p. ej. `10.0.1.6`) o deja que se rellene solo al redesplegar.

## Opción C: Script que mantiene la IP correcta

Si quieres seguir usando IP fija y EasyPanel la sigue revirtiendo, puedes ejecutar cada vez que el webmail se reinicie (o por cron cada X minutos):

```bash
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
CURRENT_IP=$(docker inspect $CONTAINER_ID --format '{{range $k, $v := .NetworkSettings.Networks}}{{$v.IPAddress}} {{end}}' | awk '{print $1}')
docker service update --label-rm "traefik.http.services.webmail.loadbalancer.server" checkin24hs_webmail
sleep 3
docker service update --label-add "traefik.http.services.webmail.loadbalancer.server=$CURRENT_IP:80" checkin24hs_webmail
```

Primero prueba **Opción A** (quitar la label); si no basta, **Opción B** desde EasyPanel.
