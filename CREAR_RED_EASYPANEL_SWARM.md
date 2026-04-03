# Crear Red de EasyPanel como Overlay de Swarm

## Problema

EasyPanel necesita la red `easypanel` como red de overlay de Docker Swarm, no como red normal.

## Solución

### 1. Verificar Estado de Swarm

```bash
# Verificar que Docker Swarm esté activo
docker info | grep Swarm

# Ver redes de overlay actuales
docker network ls | grep overlay
```

### 2. Crear la Red como Overlay de Swarm

```bash
# Crear la red easypanel como overlay de Swarm
docker network create --driver overlay --attachable easypanel

# Verificar que se creó
docker network ls | grep easypanel

# Ver detalles de la red
docker network inspect easypanel
```

### 3. Si EasyPanel Necesita Recrearse

Si la red no se conecta automáticamente:

```bash
# Detener EasyPanel
docker stop easypanel
docker rm easypanel

# Recrear EasyPanel conectado a la red
docker run -d \
  --name easypanel \
  --restart unless-stopped \
  --network easypanel \
  -p 3000:3000 \
  -v /etc/easypanel:/etc/easypanel \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  easypanel/easypanel:latest
```

### 4. Alternativa: Dejar que EasyPanel Cree la Red

EasyPanel puede crear sus propias redes automáticamente. Intenta:

```bash
# Detener el servicio dashboard si existe
docker service rm checkin24hs_dashboard 2>/dev/null || true

# Reiniciar EasyPanel completamente
docker stop easypanel
docker rm easypanel

# Reinstalar EasyPanel (creará sus propias redes)
docker run -d \
  --name easypanel \
  --restart unless-stopped \
  -p 3000:3000 \
  -v /etc/easypanel:/etc/easypanel \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  easypanel/easypanel:latest

# Esperar a que EasyPanel se inicie
sleep 10

# Verificar redes creadas
docker network ls | grep easypanel
```

## Verificar el Estado

```bash
# Ver todas las redes
docker network ls

# Ver redes de overlay
docker network ls | grep overlay

# Ver logs de EasyPanel
docker logs easypanel --tail 30
```


