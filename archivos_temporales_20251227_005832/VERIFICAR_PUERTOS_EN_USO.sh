#!/bin/bash
echo "=== VERIFICANDO QUÉ ESTÁ USANDO LOS PUERTOS ==="
echo ""

for port in 3001 3002 3003 3004; do
    echo "📋 Puerto $port:"
    
    # Ver qué proceso está usando el puerto
    PID=$(lsof -ti:$port 2>/dev/null || fuser $port/tcp 2>/dev/null | awk '{print $1}' || netstat -tulpn 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | head -1)
    
    if [ ! -z "$PID" ] && [ "$PID" != "-" ]; then
        echo "   PID: $PID"
        
        # Ver información del proceso
        if ps -p $PID > /dev/null 2>&1; then
            echo "   Proceso:"
            ps -p $PID -o pid,cmd --no-headers 2>/dev/null | head -1
        fi
        
        # Ver si es un contenedor Docker
        CONTAINER=$(docker ps --format "{{.ID}}\t{{.Names}}" | grep -E "whatsapp|300$port" | head -1)
        if [ ! -z "$CONTAINER" ]; then
            echo "   Contenedor Docker:"
            echo "   $CONTAINER"
        fi
    else
        echo "   ⚠️  No se pudo identificar el proceso"
        echo "   Información del puerto:"
        netstat -tulpn 2>/dev/null | grep ":$port " || ss -tulpn 2>/dev/null | grep ":$port "
    fi
    echo ""
done

echo "=== VERIFICANDO CONTENEDORES DOCKER ACTIVOS ==="
docker ps --format "{{.ID}}\t{{.Names}}\t{{.Ports}}" | grep -E "3001|3002|3003|3004|whatsapp" || echo "No hay contenedores relacionados"

echo ""
echo "=== VERIFICANDO SERVICIOS DOCKER SWARM ==="
docker service ls | grep -E "whatsapp|3001|3002|3003|3004" || echo "No hay servicios relacionados"
