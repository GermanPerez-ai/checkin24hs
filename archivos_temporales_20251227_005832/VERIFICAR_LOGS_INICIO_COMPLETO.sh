#!/bin/bash
# Ver logs completos desde el inicio

echo "=== LOGS COMPLETOS DESDE EL INICIO (whatsapp4) ==="
echo ""
docker service logs checkin24hs_whatsapp4 2>&1 | grep -A 5 -B 5 "Servidor corriendo\|running on\|puerto\|PORT\|listen" | head -20

echo ""
echo "=== PRIMERAS 30 LÍNEAS DE LOGS ==="
docker service logs checkin24hs_whatsapp4 2>&1 | head -30

echo ""
echo "=== PROBANDO PUERTOS DIRECTAMENTE ==="
CONTAINER=$(docker ps --filter "name=checkin24hs_whatsapp4" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER" ]; then
    echo "Probando puerto 80:"
    docker exec $CONTAINER curl -s --max-time 3 http://localhost:80 2>&1 | head -10 || echo "No responde en 80"
    echo ""
    echo "Probando puerto 3004:"
    docker exec $CONTAINER curl -s --max-time 3 http://localhost:3004 2>&1 | head -10 || echo "No responde en 3004"
fi






