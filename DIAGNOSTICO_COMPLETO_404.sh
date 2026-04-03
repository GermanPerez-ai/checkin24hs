#!/bin/bash

cd /root/checkin24hs

echo "=== Diagnóstico completo de error 404 ==="
echo ""

# 1. Verificar que el contenedor está corriendo y escuchando
echo "=== 1. Estado del contenedor ==="
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -n "$CONTAINER" ]; then
    echo "✅ Contenedor activo: $CONTAINER"
    echo "Verificando puerto 3000:"
    docker exec "$CONTAINER" ss -tlnp 2>/dev/null | grep 3000 || docker exec "$CONTAINER" netstat -tlnp 2>/dev/null | grep 3000 || echo "⚠️ No se detectó el puerto 3000"
    
    echo ""
    echo "Probando acceso interno al contenedor:"
    HTTP_CODE=$(docker exec "$CONTAINER" curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ El contenedor responde correctamente (HTTP $HTTP_CODE)"
    else
        echo "❌ El contenedor no responde correctamente (HTTP $HTTP_CODE)"
    fi
else
    echo "❌ No se encontró el contenedor"
    exit 1
fi

echo ""
echo "=== 2. Verificando configuración de Traefik ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "✅ Traefik container: $TRAEFIK_CONTAINER"
    
    echo ""
    echo "Labels de Traefik en el servicio dashboard:"
    docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.ContainerSpec.Labels}}{{.}}{{println}}{{end}}' | grep -i traefik
    
    echo ""
    echo "Routers detectados por Traefik:"
    docker exec "$TRAEFIK_CONTAINER" wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i dashboard || echo "❌ No se encontraron routers de dashboard"
    
    echo ""
    echo "Services detectados por Traefik:"
    docker exec "$TRAEFIK_CONTAINER" wget -qO- http://localhost:8080/api/http/services 2>/dev/null | grep -i dashboard || echo "❌ No se encontraron services de dashboard"
    
    echo ""
    echo "Probando conexión desde Traefik al dashboard:"
    docker exec "$TRAEFIK_CONTAINER" wget -qO- --timeout=5 "http://checkin24hs_dashboard:3000/" 2>&1 | head -5 || echo "❌ No se pudo conectar desde Traefik"
else
    echo "❌ No se encontró el contenedor de Traefik"
fi

echo ""
echo "=== 3. Verificando acceso directo al puerto 3000 ==="
HOST_IP=$(hostname -I | awk '{print $1}')
echo "IP del servidor: $HOST_IP"
echo "Probando acceso directo desde el servidor:"
curl -s -o /dev/null -w "HTTP Code: %{http_code}\n" http://localhost:3000/ || echo "❌ No se pudo conectar"

echo ""
echo "=== 4. Verificando logs del servicio ==="
docker service logs checkin24hs_dashboard --tail 20 2>&1 | tail -20

echo ""
echo "=== 5. Verificando logs de Traefik (últimas 20 líneas) ==="
if [ -n "$TRAEFIK_CONTAINER" ]; then
    docker logs "$TRAEFIK_CONTAINER" --tail 50 2>&1 | grep -iE "dashboard|404|error" | tail -20 || echo "No se encontraron errores relacionados"
fi

echo ""
echo "=== 6. Solución: Reconfigurar Traefik ==="
echo "Aplicando configuración correcta..."

# Obtener VIP
VIP=$(docker service inspect checkin24hs_dashboard --format '{{range .Endpoint.VirtualIPs}}{{.Addr}}{{end}}' | cut -d/ -f1)
echo "VIP del servicio: $VIP"

# Actualizar servicio
docker service update \
  --label-rm "traefik.enable" \
  --label-rm "traefik.http.routers.dashboard.rule" \
  --label-rm "traefik.http.routers.dashboard.entrypoints" \
  --label-rm "traefik.http.routers.dashboard.tls" \
  --label-rm "traefik.http.services.dashboard.loadbalancer.server" \
  --label-rm "traefik.http.services.dashboard.loadbalancer.server.port" \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`) || Host(\`$HOST_IP\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure,web" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server=http://checkin24hs_dashboard:3000" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  checkin24hs_dashboard

if [ $? -eq 0 ]; then
    echo "✅ Configuración actualizada"
    echo ""
    echo "Esperando 20 segundos para que Traefik actualice..."
    sleep 20
    
    echo ""
    echo "=== Verificación final ==="
    echo "Prueba acceder ahora con:"
    echo "  - https://dashboard.checkin24hs.com"
    echo "  - http://$HOST_IP (si Traefik está configurado para HTTP)"
    echo ""
    echo "Si aún no funciona, el problema podría ser:"
    echo "  1. Traefik no está escuchando en el puerto 80/443"
    echo "  2. El firewall está bloqueando el acceso"
    echo "  3. El servicio no está en la red correcta de Docker"
fi


