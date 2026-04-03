# 🔧 Corregir Filtro y Alias

## 📊 Problema

- ❌ El filtro captura el contenedor del proxy en lugar del dashboard
- ❌ DNS no resuelve `checkin24hs_dashboard-proxy`

## 🔧 Solución

### Paso 1: Obtener nombre del contenedor del dashboard (filtro corregido)

```bash
# Obtener nombre del contenedor del dashboard (excluyendo el proxy)
DASHBOARD_CONTAINER=$(docker ps --format "{{.Names}}" --filter "name=checkin24hs_dashboard" --filter "name=!checkin24hs_dashboard-proxy" | head -1)

# Si no funciona, usar este comando más específico:
DASHBOARD_CONTAINER=$(docker ps --format "{{.Names}}" | grep "checkin24hs_dashboard" | grep -v "proxy" | head -1)

echo "Contenedor activo del dashboard: $DASHBOARD_CONTAINER"
```

### Paso 2: Verificar alias del servicio proxy

```bash
# Ver aliases del servicio proxy
docker service inspect checkin24hs_dashboard-proxy | grep -A 10 "Aliases"

# Ver qué alias se resuelve
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup dashboard-proxy
```

### Paso 3: Actualizar configuración del proxy

```bash
# Obtener ID del contenedor del proxy más reciente
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)

# Actualizar configuración
docker exec $PROXY_CONTAINER_ID sed -i "s/set \$backend_upstream.*$/set \$backend_upstream $DASHBOARD_CONTAINER;/" /etc/nginx/conf.d/default.conf

# Verificar la configuración
docker exec $PROXY_CONTAINER_ID nginx -t

# Recargar nginx
docker exec $PROXY_CONTAINER_ID nginx -s reload
```

### Paso 4: Probar con el alias correcto

```bash
# Probar con diferentes aliases posibles
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup dashboard-proxy
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup checkin24hs-dashboard-proxy
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://dashboard-proxy:80/
```

---

**Ejecuta primero el Paso 1 con el filtro corregido para obtener el contenedor correcto del dashboard.**
