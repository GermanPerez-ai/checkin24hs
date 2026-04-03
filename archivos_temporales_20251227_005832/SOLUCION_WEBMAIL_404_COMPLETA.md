# Solución Completa: Webmail 404

## Diagnóstico

El webmail está corriendo correctamente, pero **no tiene configuración de Traefik**, por eso Traefik no puede enrutar las peticiones a `webmail.checkin24hs.com`.

## Solución: Configurar Traefik

Ejecuta este script completo en el servidor:

```bash
SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')

# Agregar a la red de Traefik
docker service update --network-add $EASYPANEL_NET $SERVICE_NAME
sleep 10

# Agregar etiquetas de Traefik
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.webmail.entrypoints=web" \
  --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
  $SERVICE_NAME

# Esperar y verificar
sleep 15
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep -i traefik
```

## Verificación

Después de ejecutar el script:

```bash
# Ver logs de Traefik
docker service logs traefik --tail 100 | grep -i webmail

# Ver estado del servicio
docker service ps checkin24hs_webmail

# Verificar etiquetas
docker service inspect checkin24hs_webmail --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep -i traefik
```

## Acceso

Después de configurar, deberías poder acceder a:
- `http://webmail.checkin24hs.com`

## Si aún no funciona

1. **Verifica el DNS:**
   ```bash
   nslookup webmail.checkin24hs.com
   ```

2. **Verifica logs de Traefik:**
   ```bash
   docker service logs traefik --tail 200 | grep -i webmail
   ```

3. **Verifica que el servicio esté en la red correcta:**
   ```bash
   docker service inspect checkin24hs_webmail --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'
   docker service inspect traefik --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'
   ```
   
   Ambos deben estar en la misma red.

## Nota

El webmail está funcionando correctamente (Apache está corriendo). El problema es solo la configuración de Traefik para enrutar el dominio.






