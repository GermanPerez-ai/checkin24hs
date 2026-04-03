# 🔍 Verificar Health Check del Servicio

## Problema:
- ❌ El servicio se reinicia constantemente (Shutdown -> Complete)
- ❌ Health check del proxy falla (Connection refused)
- ✅ El proxy SÍ puede conectar al dashboard
- ❌ Traefik no detecta el servicio

## Posible causa:
EasyPanel puede tener un health check configurado que está fallando, causando que el servicio se reinicie.

## Comandos para verificar:

```bash
# 1. Verificar si hay health check configurado en el servicio
echo "=== Health Check del servicio ==="
docker service inspect checkin24hs_dashboard-proxy --format '{{json .Spec.TaskTemplate.ContainerSpec.Healthcheck}}' | jq

# 2. Verificar la configuración completa del servicio
echo ""
echo "=== Configuración del servicio (buscando restart policy) ==="
docker service inspect checkin24hs_dashboard-proxy | grep -A 10 "RestartPolicy\|Healthcheck" | head -20

# 3. Verificar si Nginx está realmente escuchando
echo ""
echo "=== Verificando si Nginx está escuchando ==="
PROXY_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
if [ -n "$PROXY_ID" ]; then
    docker exec $PROXY_ID netstat -tlnp 2>/dev/null | grep 80 || docker exec $PROXY_ID ss -tlnp | grep 80
    echo ""
    echo "Probando health check con IP del contenedor..."
    PROXY_IP=$(docker inspect $PROXY_ID | grep -A 5 '"easypanel"' | grep '"IPv4Address"' | head -1 | cut -d'"' -f4 | cut -d'/' -f1)
    docker exec $PROXY_ID wget -qO- http://$PROXY_IP/health 2>&1 || docker exec $PROXY_ID wget -qO- http://127.0.0.1/health 2>&1
else
    echo "No hay contenedor del proxy corriendo"
fi

# 4. Verificar logs de EasyPanel o del servicio
echo ""
echo "=== Verificando si el servicio está corriendo ==="
docker service ps checkin24hs_dashboard-proxy --no-trunc | head -5
```
