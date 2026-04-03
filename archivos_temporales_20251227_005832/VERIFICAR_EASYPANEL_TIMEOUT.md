# Verificar EasyPanel Después de Timeout

## Problema

EasyPanel no responde después del reinicio de Docker. Error: `ERR_CONNECTION_TIMED_OUT`

## Solución

### Paso 1: Verificar Estado de EasyPanel

```bash
# Ver si EasyPanel está corriendo
docker ps | grep easypanel

# Ver todos los contenedores (incluyendo detenidos)
docker ps -a | grep easypanel

# Ver logs de EasyPanel
docker logs easypanel --tail 50
```

### Paso 2: Si EasyPanel Está Detenido

```bash
# Iniciar EasyPanel si está detenido
docker start easypanel

# Esperar a que se inicie
sleep 10

# Verificar que esté corriendo
docker ps | grep easypanel
docker logs easypanel --tail 20
```

### Paso 3: Si EasyPanel No Existe

```bash
# Verificar que la red existe
docker network ls | grep easypanel

# Recrear EasyPanel
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

### Paso 4: Verificar Puerto 3000

```bash
# Ver qué está usando el puerto 3000
sudo lsof -i :3000

# O con netstat
sudo netstat -tulpn | grep 3000
```

### Paso 5: Si Hay Conflictos de Puerto

```bash
# Ver todos los procesos usando puerto 3000
sudo lsof -i :3000

# Si hay otro proceso, detenerlo
sudo kill -9 <PID>

# O cambiar el puerto de EasyPanel (si es necesario)
docker stop easypanel
docker rm easypanel

docker run -d \
  --name easypanel \
  --restart unless-stopped \
  --network easypanel \
  -p 3001:3000 \
  -v /etc/easypanel:/etc/easypanel \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  easypanel/easypanel:latest
```

## Verificar el Estado

Después de aplicar la solución:

```bash
# Ver contenedores corriendo
docker ps

# Ver logs de EasyPanel
docker logs easypanel --tail 30

# Verificar puerto
sudo lsof -i :3000

# Probar conexión local
curl http://localhost:3000
```

## Luego en el Navegador

1. Espera 1-2 minutos después de iniciar/recrear EasyPanel
2. Intenta acceder nuevamente: **http://72.61.58.240:3000**
3. Si aún no funciona, verifica:
   - Firewall del servidor
   - Reglas de iptables
   - Configuración de red del servidor

## Solución de Problemas Adicionales

### Verificar Firewall

```bash
# Ver reglas de firewall
sudo ufw status
sudo iptables -L -n | grep 3000
```

### Verificar que Docker Está Corriendo

```bash
# Ver estado de Docker
sudo systemctl status docker

# Si no está corriendo, iniciarlo
sudo systemctl start docker
```

### Verificar Redes Docker

```bash
# Ver todas las redes
docker network ls

# Verificar que la red easypanel existe
docker network inspect easypanel
```


