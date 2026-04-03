# Corregir Traefik v3 - Sintaxis Correcta

## Error Detectado

Traefik v3.3.7 ya no usa `--providers.docker.swarmmode`. Ahora usa `--providers.docker.swarm=true` o el Swarm Provider directamente.

## Solución

### Eliminar Servicio Fallido y Recrear con Sintaxis Correcta

```bash
# 1. Eliminar el servicio fallido
docker service rm traefik

# 2. Crear con sintaxis correcta para Traefik v3
docker service create \
  --name traefik \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock:ro \
  traefik:v3.3.7 \
  --providers.docker.swarm=true \
  --providers.docker.exposedbydefault=false

# 3. Verificar que se creó correctamente
docker service ls | grep traefik
docker service ps traefik

# 4. Esperar y verificar logs
sleep 10
docker service logs traefik --tail 30
```

### Alternativa: Configuración Más Completa

Si necesitas más configuración:

```bash
docker service create \
  --name traefik \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock:ro \
  traefik:v3.3.7 \
  --providers.docker.swarm=true \
  --providers.docker.exposedbydefault=false \
  --entrypoints.web.address=:80 \
  --entrypoints.websecure.address=:443 \
  --api.insecure=true
```

## Verificar que Funciona

Después de crear el servicio:

```bash
# Ver servicios
docker service ls | grep traefik

# Ver estado
docker service ps traefik

# Ver logs (debería estar sin errores)
docker service logs traefik --tail 30

# Verificar puertos
sudo lsof -i :80
sudo lsof -i :443
```

## Configurar Dominio en EasyPanel

Una vez que Traefik esté corriendo:

1. Ve a EasyPanel: http://72.61.58.240:3000
2. Ve al servicio "dashboard"
3. Ve a la pestaña **"Dominios"**
4. Agrega: `dashboard.checkin24hs.com`
5. Guarda los cambios

Traefik debería detectar automáticamente el servicio y crear las reglas de enrutamiento.

## Notas sobre Traefik v3

- `--providers.docker.swarmmode` fue removido en v3
- Ahora usa `--providers.docker.swarm=true`
- O puedes usar el Swarm Provider directamente sin especificar docker
- La sintaxis cambió significativamente de v2 a v3

## Si Aún Hay Problemas

### Opción 1: Usar Traefik v2 (si es compatible)

```bash
docker service create \
  --name traefik \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock:ro \
  traefik:v2.10 \
  --providers.docker.swarmmode=true \
  --providers.docker.exposedbydefault=false
```

### Opción 2: Dejar que EasyPanel Gestione Traefik

La mejor opción puede ser eliminar Traefik manual y dejar que EasyPanel lo gestione:

```bash
docker service rm traefik
```

Luego agrega el dominio en EasyPanel y deja que EasyPanel inicie Traefik con su configuración.


