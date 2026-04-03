# 🔧 Obtener IP Correcta del Dashboard

## Problema
El comando para obtener la IP no está funcionando correctamente.

## Solución: Método alternativo

```bash
# Obtener el contenedor más reciente
ACTIVE_DASHBOARD=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
echo "Contenedor activo: $ACTIVE_DASHBOARD"

# Método 1: Obtener todas las IPs y filtrar la de la red correcta
docker inspect $ACTIVE_DASHBOARD | grep -A 10 "nvhtv52umzihypz8u7adejvpo" | grep "IPAddress" | head -1 | awk '{print $2}' | tr -d '",'

# Método 2: Usar jq si está disponible
docker inspect $ACTIVE_DASHBOARD | grep -A 20 "Networks" | grep -A 10 "nvhtv52umzihypz8u7adejvpo" | grep "IPAddress" | head -1 | sed 's/.*"IPAddress": "\([^"]*\)".*/\1/'

# Método 3: Más simple - obtener la IP de la red que empieza con 10.0.2
ACTIVE_IP=$(docker inspect $ACTIVE_DASHBOARD | grep -A 5 "nvhtv52umzihypz8u7adejvpo" | grep "IPAddress" | grep "10.0.2" | head -1 | sed 's/.*"IPAddress": "\([^"]*\)".*/\1/')
echo "IP activa: $ACTIVE_IP"

# Probar conexión
curl -I http://$ACTIVE_IP:3000/
```

## Si aún no funciona, usar el nombre completo del contenedor

```bash
# Obtener el nombre completo del contenedor
FULL_NAME=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
echo "Nombre completo: $FULL_NAME"

# Actualizar proxy con el nombre completo
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
docker exec $PROXY_CONTAINER_ID sed -i "s|proxy_pass http://\$backend_upstream:3000;|proxy_pass http://$FULL_NAME:3000;|" /etc/nginx/conf.d/default.conf
docker exec $PROXY_CONTAINER_ID nginx -t
docker exec $PROXY_CONTAINER_ID nginx -s reload
```
