#!/bin/bash
# Verificar puertos reales y logs de inicio

echo "=== VERIFICANDO PUERTOS REALES ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto esperado: $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Ver TODOS los puertos escuchando
        echo "   Todos los puertos escuchando:"
        docker exec $CONTAINER netstat -tuln 2>/dev/null | grep LISTEN || docker exec $CONTAINER ss -tuln 2>/dev/null | grep LISTEN || echo "   No se pudo verificar"
        
        # Buscar mensaje de inicio en logs
        echo "   Buscando mensaje de inicio del servidor:"
        docker service logs $s --tail 100 2>&1 | grep -E "Servidor corriendo|running on|puerto|port|listen|Servidor WhatsApp|📡" | head -3
        
        # Ver si hay errores
        echo "   Errores recientes:"
        docker service logs $s --tail 50 2>&1 | grep -iE "error|Error|ERROR|failed|Failed|exception|Exception" | tail -3 || echo "   No hay errores visibles"
        
        # Probar diferentes puertos comunes
        echo "   Probando puertos comunes:"
        for test_port in 3000 3001 3002 3003 3004 80 8080; do
            if docker exec $CONTAINER wget -qO- --timeout=2 http://localhost:$test_port 2>&1 | head -1 | grep -q "<!DOCTYPE\|<html"; then
                echo "   ✅ Responde en puerto $test_port"
            fi
        done
    fi
    
    echo ""
done

echo "=== PROBANDO CONECTIVIDAD DESDE TRAEFIK ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "$s (puerto $PORT):"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -3 || echo "No responde"
done
