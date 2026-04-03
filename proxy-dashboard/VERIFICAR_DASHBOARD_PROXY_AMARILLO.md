# 🔍 Verificar dashboard-proxy en Amarillo

## Problema:
- El servicio `dashboard-proxy` está en amarillo (restarting/unhealthy)

## Verificaciones:

```bash
# 1. Ver estado del servicio
echo "=== Estado del servicio dashboard-proxy ==="
docker service ps checkin24hs_dashboard-proxy --no-trunc | head -5

# 2. Ver logs recientes para entender el problema
echo ""
echo "=== Logs recientes del proxy ==="
docker service logs checkin24hs_dashboard-proxy --tail 30

# 3. Verificar si hay contenedores corriendo
echo ""
echo "=== Contenedores del proxy ==="
docker ps | grep dashboard-proxy

# 4. Verificar si el proxy es necesario
echo ""
echo "=== Verificando si el proxy es necesario ==="
echo "El dashboard funciona directamente, así que el proxy puede no ser necesario"
echo "Opciones:"
echo "1. Detener el servicio dashboard-proxy (si no se necesita)"
echo "2. Arreglar el servicio dashboard-proxy (si se necesita)"
```
