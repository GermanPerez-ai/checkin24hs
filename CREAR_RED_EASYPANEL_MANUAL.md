# Crear Red EasyPanel Manualmente

## Problema

EasyPanel no encuentra la red `easypanel` después de reiniciar Docker Swarm.

## Solución

### Crear la Red Manualmente

```bash
# 1. Crear la red easypanel como overlay de Swarm
docker network create --driver overlay --attachable easypanel

# 2. Verificar que se creó
docker network ls | grep easypanel
docker network inspect easypanel

# 3. Reiniciar EasyPanel para que detecte la red
docker restart easypanel
sleep 10

# 4. Verificar que EasyPanel esté corriendo
docker ps | grep easypanel
docker logs easypanel --tail 20
```

### Verificar el Estado

```bash
# Ver todas las redes
docker network ls

# Ver detalles de la red easypanel
docker network inspect easypanel

# Ver servicios de Swarm
docker service ls
```

## Luego en EasyPanel

1. **Espera 1-2 minutos** después de crear la red y reiniciar EasyPanel
2. **Recarga la página** de EasyPanel (F5 o Ctrl+R)
3. Ve al servicio "dashboard"
4. Haz clic en **"Implementar"** nuevamente
5. El error debería estar resuelto ahora

## Si el Problema Persiste

### Opción 1: Verificar que EasyPanel Puede Acceder a Docker

```bash
# Verificar que EasyPanel puede acceder a Docker Socket
docker exec easypanel docker network ls

# Si hay errores, verificar permisos
ls -la /var/run/docker.sock
```

### Opción 2: Reinstalar EasyPanel Completamente

```bash
# Detener y eliminar EasyPanel
docker stop easypanel
docker rm easypanel

# Eliminar configuración (opcional)
rm -rf /etc/easypanel/* 2>/dev/null || true

# Crear la red primero
docker network create --driver overlay --attachable easypanel

# Reinstalar EasyPanel
docker run -d \
  --name easypanel \
  --restart unless-stopped \
  --network easypanel \
  -p 3000:3000 \
  -v /etc/easypanel:/etc/easypanel \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  easypanel/easypanel:latest

# Esperar a que se inicie
sleep 20

# Verificar
docker ps | grep easypanel
docker logs easypanel --tail 30
```

## Notas

- La red debe ser de tipo `overlay` para funcionar con Docker Swarm
- La opción `--attachable` permite que contenedores normales se conecten
- EasyPanel necesita esta red para crear servicios de Swarm


