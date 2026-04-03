#!/bin/bash
# Verificar puerto del servidor Node.js del dashboard

echo "=== VERIFICANDO PUERTO DEL SERVIDOR NODE.JS ==="
echo ""

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -n 1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

echo "1. Verificando archivo server.js..."
docker exec $CONTAINER cat /app/server.js 2>/dev/null | head -30 || \
docker exec $CONTAINER find / -name "server.js" 2>/dev/null | head -3

echo ""
echo "2. Verificando variable de entorno PORT..."
docker exec $CONTAINER env | grep PORT

echo ""
echo "3. Verificando puertos en escucha..."
docker exec $CONTAINER sh -c "netstat -tuln 2>/dev/null || ss -tuln 2>/dev/null" | grep LISTEN

echo ""
echo "4. Verificando logs del servidor Node.js..."
docker logs $CONTAINER --tail 20 2>&1 | grep -iE "listening|port|server|error" | tail -10

echo ""
echo "5. Probando puertos comunes..."
for port in 3000 8080 80 3001; do
    echo -n "   Puerto $port: "
    docker exec $CONTAINER wget -O- --timeout=2 http://localhost:$port/dashboard.html 2>&1 | grep -q "200\|<!DOCTYPE" && echo "✅ Funciona" || echo "❌ No responde"
done

echo ""
echo "=== SOLUCIÓN ==="
echo "Una vez identifiques el puerto correcto, actualiza Traefik con:"
echo "docker service update \\"
echo "  --label-rm 'traefik.http.services.dashboard.loadbalancer.server.port' \\"
echo "  --label-add 'traefik.http.services.dashboard.loadbalancer.server.port=PUERTO_CORRECTO' \\"
echo "  checkin24hs_dashboard"
echo ""






