#!/bin/bash
echo "=== DIAGNÓSTICO: ¿Por qué se cierran los servicios? ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    echo "   Estado actual:"
    docker service ps $s --no-trunc | head -3
    echo ""
    echo "   Últimos 30 logs (para ver errores):"
    docker service logs $s --tail 30 2>&1 | grep -E "Error|error|SIGTERM|Cerrando|listen|puerto|PORT|0.0.0.0" | tail -10
    echo ""
    echo "   Verificando código en contenedor:"
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER" ]; then
        LISTEN_LINE=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
        echo "   $LISTEN_LINE"
        
        # Verificar si el proceso está corriendo
        PROCESS=$(docker exec $CONTAINER ps aux 2>/dev/null | grep "node whatsapp" | grep -v grep)
        if [ ! -z "$PROCESS" ]; then
            echo "   ✅ Proceso Node.js está corriendo"
        else
            echo "   ❌ Proceso Node.js NO está corriendo"
        fi
        
        # Verificar puertos escuchando
        PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
        PORT=$((PORT + 3000))
        LISTENING=$(docker exec $CONTAINER netstat -tuln 2>/dev/null | grep ":$PORT " || docker exec $CONTAINER ss -tuln 2>/dev/null | grep ":$PORT ")
        if [ ! -z "$LISTENING" ]; then
            echo "   ✅ Escuchando en puerto $PORT"
        else
            echo "   ⚠️  No escucha en puerto $PORT"
        fi
    fi
    echo ""
    echo "---"
    echo ""
done

echo "=== VERIFICANDO REDES ==="
docker network ls | grep easypanel
echo ""

echo "=== VERIFICANDO TRAEFIK ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "✅ Traefik container: $TRAEFIK_CONTAINER"
else
    echo "❌ Traefik no encontrado"
fi

echo ""
echo "=== VERIFICANDO LOGS COMPLETOS DE UN SERVICIO (whatsapp1) ==="
docker service logs checkin24hs_whatsapp1 --tail 50 2>&1 | tail -20
