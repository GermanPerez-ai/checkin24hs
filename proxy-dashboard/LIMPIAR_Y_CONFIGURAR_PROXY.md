# 🧹 Limpiar Contenedores y Configurar Proxy

## Problema
Hay 6 contenedores activos del dashboard, causando confusión en el DNS.

## Solución

### Paso 1: Escalar el servicio a 1 réplica

```bash
# Escalar el servicio dashboard a 1 réplica
docker service scale checkin24hs_dashboard=1

# Esperar unos segundos
sleep 5
```

### Paso 2: Limpiar contenedores antiguos

```bash
# Ver contenedores activos
docker ps | grep dashboard

# Detener y eliminar contenedores antiguos (mantener solo el más reciente)
docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}} {{.CreatedAt}}" | sort -k2 -r | tail -n +2 | awk '{print $1}' | xargs -r docker stop
docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.ID}} {{.CreatedAt}}" | sort -k2 -r | tail -n +2 | awk '{print $1}' | xargs -r docker rm
```

### Paso 3: Obtener IP del contenedor activo

```bash
# Obtener el contenedor más reciente
ACTIVE_DASHBOARD=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
echo "Contenedor activo: $ACTIVE_DASHBOARD"

# Obtener IP en la red easypanel-checkin24hs (10.0.2.x)
ACTIVE_IP=$(docker inspect $ACTIVE_DASHBOARD --format '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "nvhtv52umzihypz8u7adejvpo"}}{{$value.IPAddress}}{{end}}{{end}}')
echo "IP activa en red easypanel-checkin24hs: $ACTIVE_IP"

# Probar conexión
curl -I http://$ACTIVE_IP:3000/
```

### Paso 4: Actualizar proxy con IP directa

```bash
# Obtener ID del contenedor del proxy
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
echo "Proxy container: $PROXY_CONTAINER_ID"

# Actualizar nginx.conf con la IP directa
docker exec $PROXY_CONTAINER_ID sed -i "s|proxy_pass http://\$backend_upstream:3000;|proxy_pass http://$ACTIVE_IP:3000;|" /etc/nginx/conf.d/default.conf

# Verificar sintaxis
docker exec $PROXY_CONTAINER_ID nginx -t

# Recargar Nginx
docker exec $PROXY_CONTAINER_ID nginx -s reload

echo "✅ Proxy actualizado para usar IP directa: $ACTIVE_IP"
```

### Paso 5: Probar el proxy

```bash
# Probar desde el proxy
docker exec $PROXY_CONTAINER_ID curl -I http://$ACTIVE_IP:3000/

# Probar acceso al proxy desde el host
PROXY_IP=$(docker inspect $PROXY_CONTAINER_ID --format '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "nvhtv52umzihypz8u7adejvpo"}}{{$value.IPAddress}}{{end}}{{end}}')
curl -I http://$PROXY_IP:80/
```

---

**⚠️ NOTA**: Esta solución usa IP directa, que cambiará si el contenedor se recrea. Para una solución permanente, necesitamos usar el nombre completo del contenedor o configurar un script que actualice automáticamente.
