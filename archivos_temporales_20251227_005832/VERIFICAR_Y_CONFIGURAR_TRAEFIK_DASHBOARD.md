# Verificar y Configurar Traefik para Dashboard

## Problema

El dashboard está corriendo en el puerto 3000 (correcto), pero Traefik no puede enrutar el tráfico porque el servicio no tiene las etiquetas necesarias.

## Verificación

Ejecuta estos comandos en el servidor:

```bash
# 1. Ver si Traefik detecta el servicio dashboard
docker service logs traefik --tail 100 | grep -i dashboard

# 2. Ver etiquetas del servicio (Traefik las necesita)
docker service inspect checkin24hs_dashboard | grep -A 30 Labels

# 3. Ver todos los servicios de Swarm
docker service ls

# 4. Ver logs completos de Traefik
docker service logs traefik --tail 50

# 5. Ver en qué red está el servicio dashboard
docker service inspect checkin24hs_dashboard | grep -A 10 Networks
```

## Solución: Agregar Etiquetas de Traefik al Servicio

Si el servicio no tiene las etiquetas de Traefik, necesitas agregarlas. EasyPanel debería hacerlo automáticamente, pero si no lo hace, puedes hacerlo manualmente:

### Opción 1: Usar EasyPanel (Recomendado)

1. Ve a EasyPanel: http://72.61.58.240:3000
2. Ve al servicio "dashboard"
3. Ve a la pestaña **"Dominios"**
4. **Elimina** el dominio `dashboard.checkin24hs.com` si existe
5. **Agrega** el dominio `dashboard.checkin24hs.com` de nuevo
6. **Guarda** los cambios
7. Espera 1-2 minutos

EasyPanel debería agregar automáticamente las etiquetas de Traefik.

### Opción 2: Agregar Etiquetas Manualmente (Si EasyPanel no funciona)

```bash
# Obtener configuración actual del servicio
docker service inspect checkin24hs_dashboard > /tmp/dashboard-service.json

# Ver el nombre exacto del servicio
docker service ls | grep dashboard

# El servicio debe estar en la red "easypanel" para que Traefik lo detecte
# Verificar la red
docker service inspect checkin24hs_dashboard | grep -A 10 Networks
```

Si el servicio no está en la red `easypanel`, necesitas recrearlo en esa red. Pero primero verifica si EasyPanel puede hacerlo automáticamente.

## Verificar que Traefik Detecta el Servicio

Después de agregar el dominio en EasyPanel o las etiquetas manualmente:

```bash
# Esperar 30 segundos
sleep 30

# Ver logs de Traefik buscando el servicio
docker service logs traefik --tail 100 | grep -i dashboard

# Ver si Traefik detecta el servicio
docker service logs traefik --tail 200 | grep -i "checkin24hs_dashboard"
```

Deberías ver mensajes como:
- "Configuration loaded from flags"
- "Starting provider *docker.Provider"
- Sin errores relacionados con el servicio

## Verificar Configuración del Dominio

```bash
# Ver etiquetas del servicio después de configurar el dominio
docker service inspect checkin24hs_dashboard | grep -A 50 Labels

# Deberías ver etiquetas como:
# - traefik.enable=true
# - traefik.http.routers.dashboard.rule=Host(`dashboard.checkin24hs.com`)
# - traefik.http.services.dashboard.loadbalancer.server.port=3000
```

## Si Aún No Funciona

### Verificar que el Servicio Está en la Red Correcta

```bash
# Ver redes disponibles
docker network ls | grep easypanel

# Ver en qué red está el servicio
docker service inspect checkin24hs_dashboard | grep -A 10 Networks

# El servicio DEBE estar en la red "easypanel" para que Traefik lo detecte
```

### Verificar que Traefik Puede Acceder al Servicio

```bash
# Obtener la IP virtual del servicio en la red easypanel
docker service inspect checkin24hs_dashboard --format '{{range .Endpoint.VirtualIPs}}{{.Addr}}{{end}}'

# Probar acceso desde Traefik
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -qO- --timeout=5 http://[IP_DEL_SERVICIO]:3000 2>&1 | head -5
```

## Resumen

1. ✅ Dashboard corriendo en puerto 3000 (correcto)
2. ✅ Traefik corriendo en puertos 80/443 (correcto)
3. ⏳ Verificar que el servicio tiene etiquetas de Traefik
4. ⏳ Verificar que el servicio está en la red "easypanel"
5. ⏳ Configurar dominio en EasyPanel para que agregue las etiquetas automáticamente


