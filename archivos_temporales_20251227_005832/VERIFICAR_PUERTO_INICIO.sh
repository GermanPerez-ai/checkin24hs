#!/bin/bash
# Verificar en qué puerto está escuchando realmente el servidor

echo "=== BUSCANDO MENSAJE DE INICIO EN LOGS ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    docker service logs $s 2>&1 | grep -E "Servidor corriendo|running on|puerto|port|PORT|listen" | head -5
    echo ""
done

echo "=== VERIFICANDO PUERTO 80 (puerto por defecto) ==="
echo ""

CONTAINER=$(docker ps --filter "name=checkin24hs_whatsapp4" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER" ]; then
    echo "Probando puerto 80 en whatsapp4:"
    docker exec $CONTAINER wget -qO- --timeout=3 http://localhost:80 2>&1 | head -10 || echo "No responde en puerto 80"
    echo ""
    echo "Probando puerto 3004 en whatsapp4:"
    docker exec $CONTAINER wget -qO- --timeout=3 http://localhost:3004 2>&1 | head -10 || echo "No responde en puerto 3004"
fi






