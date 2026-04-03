# 🔧 Usar IP Directa del Contenedor del Dashboard

## 📊 Problema

- ✅ Nginx está corriendo y escuchando
- ✅ Configuración correcta
- ❌ El nombre completo del contenedor no se resuelve en DNS
- ❌ Necesitamos usar IP directa o alias del servicio

## 🔧 Solución

### Paso 1: Obtener IP del contenedor del dashboard

```bash
# Obtener IP del contenedor del dashboard en la red easypanel-checkin24hs
DASHBOARD_CONTAINER=$(docker ps --format "{{.Names}}" | grep "checkin24hs_dashboard" | grep -v "proxy" | head -1)
DASHBOARD_IP=$(docker inspect $DASHBOARD_CONTAINER | grep -A 10 "easypanel-checkin24hs" | grep "IPv4Address" | head -1 | cut -d'"' -f4 | cut -d'/' -f1)
echo "IP del contenedor del dashboard: $DASHBOARD_IP"
```

### Paso 2: Probar conexión directa a la IP

```bash
# Probar conexión directa a la IP del dashboard
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://$DASHBOARD_IP:3000/
```

### Paso 3: Actualizar configuración del proxy con IP directa

```bash
# Obtener ID del contenedor del proxy
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)

# Actualizar configuración con la IP directa
docker exec $PROXY_CONTAINER_ID sed -i "s/set \$backend_upstream.*$/set \$backend_upstream $DASHBOARD_IP;/" /etc/nginx/conf.d/default.conf

# Verificar la configuración
docker exec $PROXY_CONTAINER_ID nginx -t

# Recargar nginx
docker exec $PROXY_CONTAINER_ID nginx -s reload
```

### Paso 4: Probar el proxy

```bash
# Probar acceso al proxy
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://dashboard-proxy:80/
```

### Alternativa: Usar alias del servicio

Si la IP no funciona, podemos usar el alias del servicio:

```bash
# Ver alias del servicio dashboard
docker service inspect checkin24hs_dashboard | grep -A 10 "Aliases"

# Probar con el alias
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup checkin24hs-dashboard
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://checkin24hs-dashboard:3000/
```

---

**Ejecuta primero el Paso 1 para obtener la IP del contenedor del dashboard.**
