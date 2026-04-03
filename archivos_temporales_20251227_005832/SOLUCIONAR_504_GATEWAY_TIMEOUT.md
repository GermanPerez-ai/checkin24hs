# Solucionar 504 Gateway Timeout

## Problema

- ✅ Traefik está funcionando correctamente (sin errores de entrypoint)
- ✅ Traefik recibe las peticiones
- ❌ Traefik devuelve **504 Gateway Timeout** (no puede conectarse al servicio backend)

## Causa

Traefik no puede conectarse al servicio dashboard porque probablemente no están en la misma red Docker.

## Solución: Agregar Traefik a la Red Easypanel

### Paso 1: Verificar Redes

```bash
# Ver en qué red está Traefik
docker service inspect traefik | grep -A 10 Networks

# Ver en qué red está el servicio dashboard
docker service inspect checkin24hs_dashboard | grep -A 10 Networks

# Ver todas las redes
docker network ls | grep easypanel
```

### Paso 2: Agregar Traefik a la Red Easypanel

El servicio dashboard está en la red "easypanel" (ID: `xmv09tpxwryie79b0jv531623`). Traefik necesita estar en la misma red.

```bash
# Obtener ID de la red easypanel
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')

# Agregar Traefik a la red easypanel
docker service update --network-add $EASYPANEL_NET traefik
```

O directamente con el ID:

```bash
# Agregar Traefik a la red easypanel (usando el ID que vimos antes)
docker service update --network-add xmv09tpxwryie79b0jv531623 traefik
```

### Paso 3: Verificar que Funciona

```bash
# Esperar 30 segundos
sleep 30

# Verificar que Traefik está en la red correcta
docker service inspect traefik | grep -A 10 Networks

# Ver logs de Traefik
docker service logs traefik --tail 50 | grep -i dashboard

# Probar acceso
curl -I http://dashboard.checkin24hs.com
```

### Paso 4: Verificar Conectividad

Si aún no funciona, verifica que Traefik puede acceder al servicio:

```bash
# Obtener la IP virtual del servicio en la red easypanel
docker service inspect checkin24hs_dashboard --format '{{range .Endpoint.VirtualIPs}}{{if eq .NetworkID "xmv09tpxwryie79b0jv531623"}}{{.Addr}}{{end}}{{end}}'

# Obtener el contenedor de Traefik
TRAEFIK_CONTAINER=$(docker ps | grep traefik | awk '{print $1}')

# Probar acceso desde Traefik al servicio (reemplaza VIP con la IP obtenida arriba)
docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://[VIP]:3000 2>&1 | head -5
```

## Verificar Puerto del Servicio

También verifica que el servicio esté escuchando en el puerto correcto:

```bash
# Ver variables de entorno del servicio
docker service inspect checkin24hs_dashboard | grep -A 10 Env

# Ver puertos expuestos
docker service inspect checkin24hs_dashboard | grep -A 5 Ports
```

El servicio debería tener `PORT=3000` (no `PORT=80`).

## Solución Alternativa: Recrear Traefik en la Red Correcta

Si `docker service update` no funciona, puedes recrear Traefik directamente en la red correcta:

```bash
# Eliminar Traefik actual
docker service rm traefik

# Crear Traefik en la red easypanel
docker service create \
  --name traefik \
  --network xmv09tpxwryie79b0jv531623 \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  traefik:v2.11 \
  --entrypoints.web.address=:80 \
  --entrypoints.websecure.address=:443 \
  --providers.docker.swarmmode=true \
  --providers.docker.exposedbydefault=false \
  --log.level=INFO
```

## Resumen

1. ✅ Traefik funcionando correctamente
2. ✅ Entrypoints definidos
3. ✅ Etiquetas del servicio correctas
4. ❌ Traefik no puede conectarse al servicio (504 Gateway Timeout)
5. ⏳ Agregar Traefik a la red "easypanel"
6. ⏳ Verificar conectividad
7. ⏳ Probar acceso al dominio

El problema principal es que Traefik y el servicio dashboard deben estar en la misma red Docker para que puedan comunicarse.


