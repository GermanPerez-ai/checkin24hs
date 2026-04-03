# Conectar EasyPanel a la Red

## Problema

La red `easypanel` existe pero EasyPanel no la detecta desde dentro del contenedor.

## Solución 1: Conectar EasyPanel a la Red

```bash
# 1. Conectar EasyPanel a la red easypanel
docker network connect easypanel easypanel

# 2. Reiniciar EasyPanel
docker restart easypanel
sleep 15

# 3. Verificar logs
docker logs easypanel --tail 30

# 4. Verificar que EasyPanel esté conectado a la red
docker network inspect easypanel | grep -A 10 easypanel
```

## Solución 2: Reinstalar EasyPanel Conectado a la Red

Si la solución 1 no funciona:

```bash
# 1. Detener y eliminar EasyPanel actual
docker stop easypanel
docker rm easypanel

# 2. Verificar que la red existe
docker network ls | grep easypanel

# 3. Reinstalar EasyPanel conectado a la red desde el inicio
docker run -d \
  --name easypanel \
  --restart unless-stopped \
  --network easypanel \
  -p 3000:3000 \
  -v /etc/easypanel:/etc/easypanel \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  easypanel/easypanel:latest

# 4. Esperar a que se inicie
sleep 20

# 5. Verificar
docker ps | grep easypanel
docker logs easypanel --tail 30
docker network inspect easypanel
```

## Solución 3: Verificar Permisos de Docker Socket

EasyPanel necesita acceso completo al Docker socket:

```bash
# Verificar permisos del Docker socket
ls -la /var/run/docker.sock

# Si no tiene permisos correctos, ajustarlos
chmod 666 /var/run/docker.sock

# Reiniciar EasyPanel
docker restart easypanel
```

## Verificar el Estado

Después de aplicar la solución:

```bash
# Ver redes
docker network ls | grep easypanel

# Ver detalles de la red (debe mostrar EasyPanel conectado)
docker network inspect easypanel

# Ver contenedores conectados
docker network inspect easypanel | grep -A 5 Containers

# Ver logs de EasyPanel
docker logs easypanel --tail 50
```

## Luego en EasyPanel

1. Espera 2-3 minutos después de conectar/reinstalar
2. Recarga la página de EasyPanel (F5)
3. Ve al servicio "dashboard"
4. Haz clic en **"Implementar"** nuevamente

## Notas

- EasyPanel necesita estar conectado a la red para poder verla y usarla
- La opción `--network easypanel` conecta el contenedor a la red desde el inicio
- El Docker socket debe tener permisos correctos para que EasyPanel pueda gestionar redes


