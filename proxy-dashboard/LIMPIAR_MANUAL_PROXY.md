# 🔧 Limpiar Manualmente Contenedores Antiguos del Proxy

## 📊 Problema

- ⚠️ Después de escalar, todavía hay 4 contenedores activos
- ✅ Contenedor más reciente: `552b7fabe4cc` (checkin24hs_dashboard-proxy.1.7fr41g2nidvij59zbb0ii9m93)

## 🔧 Solución: Detener Contenedores Antiguos Manualmente

### Paso 1: Detener contenedores antiguos

```bash
# Detener los 3 contenedores antiguos (NO el más reciente 552b7fabe4cc)
docker stop 913adad37ed0 e62859284da8 19ba89e5c32d
```

### Paso 2: Eliminar contenedores detenidos

```bash
# Eliminar los contenedores detenidos
docker rm 913adad37ed0 e62859284da8 19ba89e5c32d
```

### Paso 3: Verificar que solo queda 1 contenedor

```bash
# Verificar que solo hay 1 contenedor activo
docker ps | grep dashboard-proxy
```

### Paso 4: Obtener IP del contenedor del dashboard más reciente

```bash
# Obtener nombre del contenedor del dashboard más reciente
DASHBOARD_CONTAINER=$(docker ps --format "{{.Names}}" | grep "checkin24hs_dashboard" | grep -v "proxy" | head -1)

# Obtener IP del contenedor del dashboard
DASHBOARD_IP=$(docker inspect $DASHBOARD_CONTAINER | grep -A 10 "easypanel-checkin24hs" | grep "IPv4Address" | head -1 | cut -d'"' -f4 | cut -d'/' -f1)
echo "IP del contenedor del dashboard: $DASHBOARD_IP"
```

### Paso 5: Actualizar configuración del proxy

```bash
# Obtener ID del contenedor del proxy más reciente
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)

# Actualizar configuración con la IP del dashboard
docker exec $PROXY_CONTAINER_ID sed -i "s/set \$backend_upstream.*$/set \$backend_upstream $DASHBOARD_IP;/" /etc/nginx/conf.d/default.conf

# Verificar la configuración
docker exec $PROXY_CONTAINER_ID nginx -t

# Recargar nginx
docker exec $PROXY_CONTAINER_ID nginx -s reload
```

---

**Ejecuta los Pasos 1-5 en orden. Esto limpiará los contenedores antiguos y actualizará la configuración del proxy.**
