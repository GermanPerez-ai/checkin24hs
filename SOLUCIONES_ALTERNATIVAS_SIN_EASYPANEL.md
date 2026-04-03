# 🔧 Soluciones Alternativas Sin EasyPanel

## 📊 Problema

- ❌ DNS cacheado apunta a IP antigua (`10.0.2.104`)
- ❌ EasyPanel no puede recrear el servicio
- ✅ IPs directas funcionan perfectamente

## 🔧 Soluciones

### Solución 1: Reiniciar Servicio DNS de Docker Swarm

```bash
# Buscar el servicio DNS de Docker Swarm
docker service ls | grep -i dns

# Si existe, reiniciarlo
docker service update --force <nombre_servicio_dns>

# O buscar contenedores DNS
docker ps | grep -i dns

# Si hay un contenedor DNS, reiniciarlo
docker restart <container_id>
```

### Solución 2: Limpiar Cache DNS Manualmente

```bash
# Verificar si hay un contenedor DNS embebd
docker ps | grep "127.0.0.11"

# Buscar servicios de red de Docker
docker service ls | grep -i "network\|dns"

# Reiniciar el stack de Docker Swarm (cuidado: esto afecta todos los servicios)
# docker stack ps docker

# O intentar actualizar la red directamente
docker network update --alias-add dashboard easypanel-checkin24hs
```

### Solución 3: Usar Nombre de Contenedor en EasyPanel

Obtén el nombre del contenedor y úsalo en EasyPanel:

```bash
# Obtener nombre del contenedor activo
CONTAINER_NAME=$(docker ps | grep dashboard | head -1 | awk '{print $NF}')
echo "Nombre del contenedor: $CONTAINER_NAME"

# Probar si el nombre del contenedor se resuelve
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup $CONTAINER_NAME
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://$CONTAINER_NAME:3000/
```

Si funciona, configura EasyPanel para usar ese nombre en lugar de `dashboard`.

### Solución 4: Crear Servicio Proxy Nginx Temporal

Crear un servicio nginx simple que redirija `dashboard:3000` a la IP real.

### Solución 5: Modificar Configuración de Traefik Directamente

Si tienes acceso a la configuración de Traefik, puedes configurar una ruta directa a la IP.

---

**Probemos primero las Soluciones 1, 2 y 3.**
