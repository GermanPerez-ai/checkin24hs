# 🔍 Verificar Puerto del Dashboard

## Problema:
- ✅ Los logs dicen que el servidor está iniciado en puerto 3000
- ✅ El proceso `node server.js` está corriendo
- ✅ La variable `PORT=3000` está configurada
- ❌ Pero no responde a conexiones

## Posibles causas:
1. El servidor se está reiniciando constantemente
2. Hay un problema de red dentro del contenedor
3. El servidor está escuchando pero hay un error en la aplicación

## Comandos para verificar:

```bash
# 1. Verificar si el puerto 3000 está realmente abierto
DASHBOARD_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
echo "=== Verificando puerto 3000 ==="
docker exec $DASHBOARD_ID netstat -tlnp 2>/dev/null || docker exec $DASHBOARD_ID ss -tlnp

# 2. Probar con curl en lugar de wget
echo ""
echo "=== Probando con curl ==="
docker exec $DASHBOARD_ID curl -v http://localhost:3000/health 2>&1

# 3. Ver si hay errores en los logs recientes
echo ""
echo "=== Últimos logs del contenedor ==="
docker logs $DASHBOARD_ID --tail 20

# 4. Verificar si el contenedor se está reiniciando
echo ""
echo "=== Estado del contenedor ==="
docker inspect $DASHBOARD_ID | grep -A 10 '"State"'

# 5. Probar desde fuera del contenedor usando la IP
echo ""
echo "=== Probando desde el host usando IP del contenedor ==="
DASHBOARD_IP=$(docker inspect $DASHBOARD_ID | grep -A 5 '"easypanel"' | grep '"IPv4Address"' | head -1 | cut -d'"' -f4 | cut -d'/' -f1)
echo "IP del dashboard: $DASHBOARD_IP"
curl -v http://$DASHBOARD_IP:3000/health 2>&1
```
