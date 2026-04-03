# 🔧 Limpiar y Escalar Proxy a 1 Réplica

## 📊 Problema

- ⚠️ 3 contenedores activos del proxy (debería haber 1)
- ⚠️ Dashboard también tiene punto amarillo

## 🔧 Solución

### Paso 1: Escalar servicio a 1 réplica

```bash
# Escalar servicio a 1 réplica
docker service scale checkin24hs_dashboard-proxy=1
```

### Paso 2: Esperar y verificar

```bash
# Esperar 30 segundos
sleep 30

# Verificar contenedores (debería haber solo 1)
docker ps | grep dashboard-proxy
```

### Paso 3: Obtener IP del contenedor del dashboard más reciente

```bash
# Obtener nombre del contenedor del dashboard más reciente
DASHBOARD_CONTAINER=$(docker ps --format "{{.Names}}" | grep "checkin24hs_dashboard" | grep -v "proxy" | head -1)

# Obtener IP del contenedor del dashboard
DASHBOARD_IP=$(docker inspect $DASHBOARD_CONTAINER | grep -A 10 "easypanel-checkin24hs" | grep "IPv4Address" | head -1 | cut -d'"' -f4 | cut -d'/' -f1)
echo "IP del contenedor del dashboard: $DASHBOARD_IP"
```

### Paso 4: Actualizar configuración del proxy

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

### Paso 5: Obtener IP del proxy y configurar dominio

```bash
# Obtener IP del contenedor del proxy
PROXY_IP=$(docker inspect $PROXY_CONTAINER_ID | grep -A 10 "easypanel-checkin24hs" | grep "IPv4Address" | head -1 | cut -d'"' -f4 | cut -d'/' -f1)
echo "IP del contenedor del proxy: $PROXY_IP"
```

Luego, en EasyPanel:
1. Ve a Servicios → `dashboard`
2. Edita el dominio `dashboard.checkin24hs.com`
3. Cambia el destino a: `http://$PROXY_IP:80/` (usa la IP obtenida)

---

**Ejecuta los Pasos 1-5 en orden. Esto limpiará los contenedores duplicados y actualizará la configuración del proxy.**
