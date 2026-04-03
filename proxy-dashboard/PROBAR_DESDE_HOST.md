# 🔍 Probar Conexión desde el Host

## Estado:
- ✅ Puerto 3000 está abierto y escuchando
- ✅ Proceso Node.js está corriendo
- ❌ No responde desde dentro del contenedor
- ❓ Necesitamos probar desde el host

## Comandos:

```bash
# 1. Obtener IP del dashboard
DASHBOARD_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
DASHBOARD_IP=$(docker inspect $DASHBOARD_ID | grep -A 5 '"easypanel"' | grep '"IPv4Address"' | head -1 | cut -d'"' -f4 | cut -d'/' -f1)
echo "IP del dashboard: $DASHBOARD_IP"

# 2. Probar health endpoint desde el host
echo ""
echo "=== Probando /health desde el host ==="
curl -v http://$DASHBOARD_IP:3000/health 2>&1

# 3. Probar la ruta raíz
echo ""
echo "=== Probando / desde el host ==="
curl -I http://$DASHBOARD_IP:3000/ 2>&1 | head -10

# 4. Probar desde el proxy usando la IP
PROXY_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
echo ""
echo "=== Probando desde el proxy usando IP ==="
docker exec $PROXY_ID wget -qO- http://$DASHBOARD_IP:3000/health 2>&1
```
