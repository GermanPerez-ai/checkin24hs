#!/bin/bash
echo "=== VERIFICANDO PUERTOS REALES ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        echo "📋 $s:"
        
        # Ver todos los puertos en uso
        echo "   Puertos escuchando:"
        docker exec $CONTAINER netstat -tuln 2>/dev/null | grep LISTEN || docker exec $CONTAINER ss -tuln 2>/dev/null | grep LISTEN || echo "   No se pudo verificar"
        
        # Ver variables de entorno
        echo "   Variables PORT e INSTANCE_NUMBER:"
        docker exec $CONTAINER env 2>/dev/null | grep -E "PORT|INSTANCE" || echo "   No encontradas"
        
        echo ""
    fi
done

echo "=== LOGS DE INICIO ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    docker service logs $s 2>&1 | grep -E "puerto|port|Servidor corriendo|running on" | head -2
done
