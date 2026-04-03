# ✅ Verificar que el Dashboard Responde

## Estado actual:
- ✅ Nginx está corriendo en el proxy
- ✅ Nginx escucha en puerto 80
- ✅ Ambos están en la misma red "easypanel"
- ✅ DNS resuelve: `checkin24hs_dashboard` → `10.0.1.111`
- ❓ Necesitamos verificar que el dashboard responde en puerto 3000

## Comandos para verificar:

```bash
# 1. Verificar que el dashboard está escuchando en puerto 3000
DASHBOARD_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
echo "Dashboard ID: $DASHBOARD_ID"
docker exec $DASHBOARD_ID netstat -tlnp 2>/dev/null | grep 3000 || docker exec $DASHBOARD_ID ss -tlnp | grep 3000

# 2. Probar el health endpoint del dashboard directamente
docker exec $DASHBOARD_ID wget -qO- http://localhost:3000/health 2>&1

# 3. Probar desde el proxy usando la IP directa
PROXY_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
echo ""
echo "Probando desde el proxy usando IP directa (10.0.1.111)..."
docker exec $PROXY_ID wget -qO- http://10.0.1.111:3000/health 2>&1

# 4. Probar desde el proxy usando el nombre del servicio
echo ""
echo "Probando desde el proxy usando nombre del servicio..."
docker exec $PROXY_ID wget -qO- http://checkin24hs_dashboard:3000/health 2>&1

# 5. Probar el health check del proxy usando la IP del contenedor
echo ""
echo "Probando health check del proxy usando IP del contenedor..."
PROXY_IP=$(docker inspect $PROXY_ID | grep -A 5 '"easypanel"' | grep '"IPv4Address"' | head -1 | cut -d'"' -f4 | cut -d'/' -f1)
echo "IP del proxy: $PROXY_IP"
docker exec $PROXY_ID wget -qO- http://$PROXY_IP/health 2>&1 || docker exec $PROXY_ID wget -qO- http://127.0.0.1/health 2>&1
```
