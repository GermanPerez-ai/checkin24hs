#!/bin/bash
echo "=== VERIFICANDO INICIO COMPLETO DE WHATSAPP1 ==="
echo ""

echo "Logs completos desde el inicio (últimas 100 líneas):"
docker service logs checkin24hs_whatsapp1 --tail 100 2>&1 | grep -v "█" | tail -50

echo ""
echo "=== VERIFICANDO PROCESO ACTUAL ==="
CONTAINER=$(docker ps --filter "name=checkin24hs_whatsapp1" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER" ]; then
    echo "Contenedor: $CONTAINER"
    echo ""
    echo "Proceso Node.js:"
    docker exec $CONTAINER ps aux 2>/dev/null | grep node | grep -v grep
    echo ""
    echo "Puertos escuchando:"
    docker exec $CONTAINER netstat -tuln 2>/dev/null | grep LISTEN || docker exec $CONTAINER ss -tuln 2>/dev/null | grep LISTEN
    echo ""
    echo "Verificando si el servidor inició correctamente:"
    docker exec $CONTAINER grep -A 5 "Servidor corriendo" /app/whatsapp-server.js 2>/dev/null || echo "No se encontró mensaje de inicio"
    echo ""
    echo "Últimas líneas de logs del contenedor actual:"
    docker logs $CONTAINER --tail 20 2>&1 | tail -20
fi






