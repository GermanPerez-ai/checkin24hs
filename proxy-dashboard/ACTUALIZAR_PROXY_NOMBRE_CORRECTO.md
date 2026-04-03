# ✅ Actualizar Proxy con Nombre Correcto

## 📊 Estado Actual

- ✅ Servicio existe: `checkin24hs_dashboard-proxy`
- ✅ Servicio corriendo (1/1 réplicas)
- ⚠️ 2 contenedores activos (debería haber 1)

## 🔧 Actualizar Configuración

### Paso 1: Obtener nombre del contenedor activo del dashboard

```bash
# Obtener nombre del contenedor activo del dashboard
DASHBOARD_CONTAINER=$(docker ps --format "{{.Names}}" --filter "name=checkin24hs_dashboard" | head -1)
echo "Contenedor activo del dashboard: $DASHBOARD_CONTAINER"
```

### Paso 2: Obtener ID del contenedor del proxy más reciente

```bash
# Obtener ID del contenedor del proxy más reciente
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
echo "Contenedor del proxy: $PROXY_CONTAINER_ID"
```

### Paso 3: Actualizar configuración del proxy

```bash
# Actualizar configuración con el nombre del contenedor activo
docker exec $PROXY_CONTAINER_ID sed -i "s/set \$backend_upstream.*$/set \$backend_upstream $DASHBOARD_CONTAINER;/" /etc/nginx/conf.d/default.conf

# Verificar la configuración
docker exec $PROXY_CONTAINER_ID nginx -t

# Recargar nginx
docker exec $PROXY_CONTAINER_ID nginx -s reload
```

### Paso 4: Probar acceso al proxy

```bash
# Probar acceso al proxy desde dentro de la red
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://checkin24hs_dashboard-proxy:80/

# Debería devolver HTTP/1.1 200 OK
```

### Paso 5: Limpiar contenedor antiguo del proxy (opcional)

```bash
# Detener y eliminar el contenedor antiguo del proxy
docker stop $(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | tail -1)
docker rm $(docker ps -a --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | tail -1)
```

---

**Ejecuta los Pasos 1-4 para actualizar y verificar el proxy. Si funciona, el dominio debería funcionar correctamente.**
