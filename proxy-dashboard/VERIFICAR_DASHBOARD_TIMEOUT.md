# 🔍 Verificar Dashboard que no Responde

## Problemas:
- ❌ No hay etiquetas de Traefik
- ❌ Dashboard no responde directamente (timeout)
- ❌ Dominio da 404

## Verificaciones:

```bash
# 1. Verificar que el dashboard está corriendo
echo "=== Estado del servicio dashboard ==="
docker service ps checkin24hs_dashboard --no-trunc | head -3

# 2. Verificar procesos dentro del contenedor
echo ""
echo "=== Procesos en el contenedor ==="
DASHBOARD_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
docker exec $DASHBOARD_ID ps aux

# 3. Verificar si está escuchando en puerto 3000
echo ""
echo "=== Puertos que escucha ==="
docker exec $DASHBOARD_ID netstat -tlnp 2>/dev/null | grep 3000 || docker exec $DASHBOARD_ID ss -tlnp | grep 3000

# 4. Probar health endpoint (más rápido)
echo ""
echo "=== Probando health endpoint ==="
docker exec $DASHBOARD_ID wget -qO- http://localhost:3000/health 2>&1

# 5. Ver logs recientes del dashboard
echo ""
echo "=== Logs recientes del dashboard ==="
docker service logs checkin24hs_dashboard --tail 20
```
