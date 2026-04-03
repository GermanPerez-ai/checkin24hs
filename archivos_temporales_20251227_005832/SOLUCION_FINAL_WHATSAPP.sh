#!/bin/bash
echo "=== SOLUCIÓN FINAL: Verificar y corregir WhatsApp ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Verificar logs para ver si hay errores de inicio
        echo "   Buscando mensaje 'Servidor corriendo':"
        docker service logs $s 2>&1 | grep "Servidor corriendo" | tail -1 || echo "   ⚠️  No se encontró mensaje de inicio"
        
        echo "   Buscando errores:"
        docker service logs $s 2>&1 | grep -iE "error|exception|failed|cannot" | tail -3 || echo "   ✅ No hay errores visibles"
        
        # Verificar todos los puertos escuchando
        echo "   Todos los puertos escuchando:"
        docker exec $CONTAINER netstat -tuln 2>/dev/null | grep LISTEN || docker exec $CONTAINER ss -tuln 2>/dev/null | grep LISTEN || echo "   ⚠️  No hay puertos escuchando"
        
        # Probar conectividad local
        echo "   Probando localhost:$PORT:"
        docker exec $CONTAINER wget -qO- --timeout=3 http://localhost:$PORT 2>&1 | head -1 || echo "   ⚠️  No responde en localhost"
    else
        echo "   ⚠️  Sin contenedor activo"
    fi
    echo ""
done

echo "=== VERIFICANDO CONECTIVIDAD DESDE TRAEFIK ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
EASYPANEL_NET=$(docker network ls --format "{{.ID}}\t{{.Name}}" | grep "^easypanel$" | awk '{print $1}')

if [ ! -z "$TRAEFIK_CONTAINER" ] && [ ! -z "$EASYPANEL_NET" ]; then
    for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
        PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
        PORT=$((PORT + 3000))
        
        CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
        if [ ! -z "$CONTAINER" ]; then
            CONTAINER_IP=$(docker inspect $CONTAINER --format "{{range .NetworkSettings.Networks}}{{if eq .NetworkID \"$EASYPANEL_NET\"}}{{.IPAddress}}{{end}}{{end}}" 2>/dev/null)
            
            if [ ! -z "$CONTAINER_IP" ] && [ "$CONTAINER_IP" != "<no value>" ]; then
                echo "$s (IP: $CONTAINER_IP, Puerto: $PORT):"
                RESPONSE=$(docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://$CONTAINER_IP:$PORT 2>&1 | head -1)
                if [ ! -z "$RESPONSE" ] && [ "$RESPONSE" != "wget: can't connect" ]; then
                    echo "   ✅ Traefik puede conectarse"
                else
                    echo "   ❌ Traefik NO puede conectarse"
                fi
            fi
        fi
    done
fi






