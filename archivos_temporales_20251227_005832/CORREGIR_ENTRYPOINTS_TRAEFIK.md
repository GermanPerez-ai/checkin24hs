# Corregir Entrypoints de Traefik

## Problema

- ✅ Las etiquetas se agregaron correctamente
- ❌ Traefik dice: `entryPoint "web" doesn't exist`
- ❌ El acceso sigue dando 404

## Causa

Traefik v2.11 necesita que los entrypoints se definan explícitamente. No tiene entrypoints por defecto.

## Solución: Recrear Traefik con Entrypoints Definidos

### Paso 1: Ver Configuración Actual

```bash
docker service inspect traefik | grep -A 20 Args
```

### Paso 2: Eliminar Traefik Actual

```bash
docker service rm traefik
```

### Paso 3: Crear Traefik con Entrypoints Definidos

```bash
docker service create \
  --name traefik \
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

### Paso 4: Verificar que Funciona

```bash
# Esperar 10 segundos
sleep 10

# Ver logs de Traefik
docker service logs traefik --tail 30

# Verificar que no hay errores de entrypoint
docker service logs traefik --tail 50 | grep -i error
```

No deberías ver errores sobre entrypoints.

### Paso 5: Verificar que Detecta el Servicio

```bash
# Esperar 30 segundos más
sleep 30

# Ver logs buscando el dashboard
docker service logs traefik --tail 100 | grep -i dashboard

# Verificar etiquetas del servicio
docker service inspect checkin24hs_dashboard | grep -A 30 Labels
```

### Paso 6: Probar Acceso

```bash
# Probar acceso HTTP
curl -I http://dashboard.checkin24hs.com

# Ver respuesta completa
curl -v http://dashboard.checkin24hs.com 2>&1 | head -20
```

Deberías recibir una respuesta HTTP 200 ahora.

## Entrypoints Definidos

- `web`: Puerto 80 (HTTP)
- `websecure`: Puerto 443 (HTTPS)

## Etiquetas del Servicio

Las etiquetas que agregamos son correctas:
- `traefik.enable=true`
- `traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)`
- `traefik.http.routers.dashboard.entrypoints=web`
- `traefik.http.services.dashboard.loadbalancer.server.port=3000`

## Si Aún No Funciona

### Verificar que el Servicio Está en la Red Correcta

```bash
# Ver en qué red está el servicio
docker service inspect checkin24hs_dashboard | grep -A 10 Networks

# Ver en qué red está Traefik
docker service inspect traefik | grep -A 10 Networks

# Ambos deben estar en la red "easypanel"
```

### Verificar que Traefik Puede Acceder al Servicio

```bash
# Obtener la IP virtual del servicio en la red easypanel
docker service inspect checkin24hs_dashboard --format '{{range .Endpoint.VirtualIPs}}{{if eq .NetworkID "xmv09tpxwryie79b0jv531623"}}{{.Addr}}{{end}}{{end}}'

# Probar acceso desde Traefik (reemplaza CONTAINER_ID con el ID del contenedor de Traefik)
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -qO- --timeout=5 http://[IP_DEL_SERVICIO]:3000 2>&1 | head -5
```

## Resumen

1. ✅ Etiquetas agregadas correctamente
2. ❌ Traefik necesita entrypoints definidos
3. ⏳ Recrear Traefik con entrypoints `web` y `websecure`
4. ⏳ Verificar que detecta el servicio
5. ⏳ Probar acceso al dominio


