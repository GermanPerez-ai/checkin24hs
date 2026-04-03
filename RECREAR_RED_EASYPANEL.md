# Recrear Red de EasyPanel

## Error Detectado

```
network easypanel not found
```

Este error ocurre porque al reiniciar Docker Swarm, se perdió la red de EasyPanel.

## Solución

### Opción 1: Reiniciar EasyPanel (Recomendado)

EasyPanel debería recrear automáticamente su red al reiniciarse:

```bash
# Reiniciar el contenedor de EasyPanel
docker restart easypanel

# Esperar unos segundos
sleep 5

# Verificar que esté corriendo
docker ps | grep easypanel

# Verificar que la red se haya recreado
docker network ls | grep easypanel
```

### Opción 2: Recrear la Red Manualmente

Si reiniciar no funciona:

```bash
# Ver redes actuales
docker network ls

# Crear la red de EasyPanel manualmente
docker network create --driver overlay easypanel

# Verificar que se creó
docker network ls | grep easypanel
```

### Opción 3: Reinstalar EasyPanel (Último Recurso)

Si nada funciona, puedes reinstalar EasyPanel:

```bash
# Detener EasyPanel
docker stop easypanel
docker rm easypanel

# Reinstalar EasyPanel
docker run -d \
  --name easypanel \
  --restart unless-stopped \
  -p 3000:3000 \
  -v /etc/easypanel:/etc/easypanel \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  easypanel/easypanel:latest
```

## Verificar el Estado

Después de aplicar la solución:

```bash
# Ver redes Docker
docker network ls

# Ver contenedores
docker ps

# Ver logs de EasyPanel
docker logs easypanel --tail 30
```

## Luego en EasyPanel

Una vez que la red esté recreada:

1. Recarga la página de EasyPanel
2. Ve al servicio "dashboard"
3. Haz clic en **"Implementar"** nuevamente
4. El error debería estar resuelto


