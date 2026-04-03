# Reinstalar EasyPanel Completamente

## Problema

EasyPanel está conectado a la red pero sigue sin detectarla desde la API de Docker.

## Solución: Reinstalar EasyPanel

### Pasos Completos

```bash
# 1. Detener y eliminar EasyPanel actual
docker stop easypanel
docker rm easypanel

# 2. Verificar que la red existe
docker network ls | grep easypanel
docker network inspect easypanel

# 3. Reinstalar EasyPanel conectado a la red desde el inicio
docker run -d \
  --name easypanel \
  --restart unless-stopped \
  --network easypanel \
  -p 3000:3000 \
  -v /etc/easypanel:/etc/easypanel \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  easypanel/easypanel:latest

# 4. Esperar a que se inicie completamente
sleep 20

# 5. Verificar que esté corriendo
docker ps | grep easypanel

# 6. Verificar logs (no debería haber errores de red)
docker logs easypanel --tail 30

# 7. Verificar que esté conectado a la red
docker network inspect easypanel | grep -A 5 easypanel
```

### Verificar Permisos del Docker Socket

Si aún hay problemas, verifica los permisos:

```bash
# Ver permisos del Docker socket
ls -la /var/run/docker.sock

# Si es necesario, ajustar permisos (cuidado con esto)
chmod 666 /var/run/docker.sock

# Reiniciar EasyPanel
docker restart easypanel
```

## Luego en EasyPanel

1. **Espera 2-3 minutos** después de reinstalar
2. **Recarga la página** de EasyPanel (F5 o Ctrl+R)
3. Ve al servicio "dashboard"
4. Haz clic en **"Implementar"** nuevamente
5. El error debería estar resuelto ahora

## Si el Problema Persiste

### Verificar que EasyPanel Puede Acceder a Docker

```bash
# Ejecutar comando dentro del contenedor de EasyPanel
docker exec easypanel docker network ls

# Si funciona, debería mostrar todas las redes incluyendo easypanel
```

### Alternativa: Usar Docker Compose

Si el problema persiste, podríamos intentar usar Docker Compose para gestionar EasyPanel, pero esto requeriría más configuración.

## Notas Importantes

- La opción `--network easypanel` conecta el contenedor a la red desde el inicio
- El Docker socket debe tener permisos correctos
- EasyPanel necesita acceso completo al Docker daemon para gestionar redes y servicios
- La configuración en `/etc/easypanel` se preserva al reinstalar


