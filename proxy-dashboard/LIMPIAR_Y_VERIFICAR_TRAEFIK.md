# 🔧 Limpiar Contenedores Duplicados y Verificar Traefik

## Problema:
- Hay 4 contenedores del dashboard corriendo (debería haber solo 1)
- El dominio sigue dando 404 después de agregar etiquetas

## Solución:

```bash
# 1. Escalar el servicio a 1 réplica
echo "=== Escalando servicio a 1 réplica ==="
docker service scale checkin24hs_dashboard=1
sleep 10

# 2. Limpiar contenedores antiguos
echo ""
echo "=== Limpiando contenedores antiguos ==="
docker ps -a | grep "checkin24hs_dashboard.1" | grep -v "Up" | awk '{print $1}' | xargs -r docker rm -f

# 3. Verificar estado
echo ""
echo "=== Estado después de limpiar ==="
docker service ps checkin24hs_dashboard --no-trunc | head -3
docker ps | grep dashboard

# 4. Verificar logs de Traefik
echo ""
echo "=== Logs de Traefik (buscando dashboard) ==="
docker service logs traefik --tail 50 | grep -i "dashboard\|checkin24hs" | tail -10

# 5. Esperar un poco más y probar de nuevo
echo ""
echo "⏳ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

# 6. Probar dominio
echo ""
echo "=== Probando dominio ==="
curl -I https://dashboard.checkin24hs.com/ 2>&1 | head -10
```
