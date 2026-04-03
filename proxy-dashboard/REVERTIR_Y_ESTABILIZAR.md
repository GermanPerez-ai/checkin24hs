# 🔄 Revertir Cambios y Estabilizar

## Problema:
- ❌ El servicio se puso amarillo después de agregar etiquetas
- El comando `docker service update` puede estar causando problemas

## Solución:
1. Verificar estado actual
2. Estabilizar el servicio primero
3. Luego agregar las etiquetas de forma diferente

## Comandos:

```bash
# 1. Ver estado actual
echo "=== Estado del servicio ==="
docker service ps checkin24hs_dashboard-proxy --no-trunc | head -5

# 2. Ver logs para entender qué está pasando
echo ""
echo "=== Logs recientes ==="
docker service logs checkin24hs_dashboard-proxy --tail 20

# 3. Detener y reiniciar el servicio para estabilizarlo
echo ""
echo "=== Estabilizando el servicio ==="
docker service scale checkin24hs_dashboard-proxy=0
sleep 5
docker service scale checkin24hs_dashboard-proxy=1
sleep 15

# 4. Verificar que está estable
echo ""
echo "=== Verificando estado ==="
docker service ps checkin24hs_dashboard-proxy --no-trunc | head -3
docker ps | grep dashboard-proxy
```
