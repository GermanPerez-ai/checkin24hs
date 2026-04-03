# 🔍 Verificar 404 en Dashboard

## Problema:
- El dashboard devuelve 404 después de implementar

## Posibles causas:
1. El servicio se detuvo
2. Las etiquetas de Traefik se perdieron
3. El servicio está reiniciando

## Verificaciones:

```bash
# 1. Verificar estado del servicio
echo "=== Estado del servicio dashboard ==="
docker service ps checkin24hs_dashboard --no-trunc | head -5

# 2. Verificar contenedores
echo ""
echo "=== Contenedores del dashboard ==="
docker ps | grep dashboard

# 3. Verificar etiquetas de Traefik
echo ""
echo "=== Verificando etiquetas de Traefik ==="
DASHBOARD_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
if [ -n "$DASHBOARD_ID" ]; then
    docker inspect $DASHBOARD_ID | grep -A 40 "Labels" | grep -i traefik | head -15
else
    echo "❌ No hay contenedor del dashboard corriendo"
fi

# 4. Probar acceso directo
echo ""
echo "=== Probando acceso directo ==="
if [ -n "$DASHBOARD_ID" ]; then
    DASHBOARD_IP=$(docker inspect $DASHBOARD_ID | grep -A 5 '"easypanel"' | grep '"IPv4Address"' | head -1 | cut -d'"' -f4 | cut -d'/' -f1)
    curl -I http://$DASHBOARD_IP:3000/ 2>&1 | head -5
fi

# 5. Probar dominio
echo ""
echo "=== Probando dominio ==="
curl -I https://dashboard.checkin24hs.com/ 2>&1 | head -10
```
