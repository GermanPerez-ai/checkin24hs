# 🔍 Verificar Servicio Detenido

## Problema:
- El punto de estado desapareció en EasyPanel
- El servicio puede haberse detenido

## Verificaciones:

```bash
# 1. Ver estado del servicio
echo "=== Estado del servicio dashboard ==="
docker service ps checkin24hs_dashboard --no-trunc | head -5

# 2. Ver si hay contenedores corriendo
echo ""
echo "=== Contenedores del dashboard ==="
docker ps | grep dashboard

# 3. Ver logs recientes para entender qué pasó
echo ""
echo "=== Logs recientes ==="
docker service logs checkin24hs_dashboard --tail 30

# 4. Verificar si el servicio existe
echo ""
echo "=== Verificando si el servicio existe ==="
docker service ls | grep dashboard
```
