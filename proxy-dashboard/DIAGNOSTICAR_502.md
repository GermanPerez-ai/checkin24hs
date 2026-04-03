# 🔍 Diagnosticar Error 502 Bad Gateway

## Problema
El proxy devuelve 502, lo que significa que no puede conectarse al dashboard.

## Diagnóstico

### Paso 1: Verificar configuración actual de Nginx

```bash
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
docker exec $PROXY_CONTAINER_ID cat /etc/nginx/conf.d/default.conf
```

### Paso 2: Verificar si el nombre del contenedor se resuelve desde el proxy

```bash
# Obtener el nombre completo del dashboard
FULL_NAME=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
echo "Nombre del dashboard: $FULL_NAME"

# Probar resolución DNS desde el proxy
docker exec $PROXY_CONTAINER_ID nslookup $FULL_NAME
```

### Paso 3: Probar conexión directa desde el proxy

```bash
# Probar conexión directa al dashboard desde el proxy
docker exec $PROXY_CONTAINER_ID curl -I http://$FULL_NAME:3000/
```

### Paso 4: Verificar logs del proxy

```bash
# Ver logs de Nginx para más detalles del error
docker logs $PROXY_CONTAINER_ID --tail 50
```

### Paso 5: Verificar que el dashboard está escuchando

```bash
# Verificar que el dashboard está escuchando en el puerto 3000
ACTIVE_DASHBOARD=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
docker exec $ACTIVE_DASHBOARD netstat -tlnp | grep 3000
# O
docker exec $ACTIVE_DASHBOARD ss -tlnp | grep 3000
```

---

**Ejecuta estos pasos para identificar el problema específico.**
