# 🔍 Diagnóstico de Red y Nginx

## Problemas detectados:
1. ❌ Health check falla (Connection refused) - Nginx no responde
2. ❌ No puede conectar al dashboard (Host unreachable) - Problema de red

## Comandos de diagnóstico:

```bash
# 1. Verificar que Nginx está corriendo en el contenedor del proxy
PROXY_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
echo "Proxy ID: $PROXY_ID"
docker exec $PROXY_ID ps aux | grep nginx

# 2. Verificar en qué puerto está escuchando Nginx
docker exec $PROXY_ID netstat -tlnp | grep nginx

# 3. Verificar la configuración actual de Nginx
docker exec $PROXY_ID cat /etc/nginx/conf.d/default.conf

# 4. Verificar las redes del proxy
docker inspect $PROXY_ID | grep -A 30 "Networks"

# 5. Verificar las redes del dashboard
DASHBOARD_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
echo "Dashboard ID: $DASHBOARD_ID"
docker inspect $DASHBOARD_ID | grep -A 30 "Networks"

# 6. Verificar si están en la misma red
docker inspect $PROXY_ID | grep -E "easypanel|checkin24hs" | head -5
docker inspect $DASHBOARD_ID | grep -E "easypanel|checkin24hs" | head -5

# 7. Probar resolución DNS desde el proxy
docker exec $PROXY_ID nslookup checkin24hs_dashboard

# 8. Verificar logs de Nginx
docker exec $PROXY_ID cat /var/log/nginx/error.log 2>/dev/null || echo "No hay error.log"
```
