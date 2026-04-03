#!/bin/bash
echo "=== LIBERANDO PUERTOS 3001-3004 ==="
echo ""

echo "1️⃣ Verificando todos los contenedores Docker (incluyendo detenidos):"
docker ps -a --format "{{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "3001|3002|3003|3004|whatsapp" || echo "No hay contenedores relacionados"

echo ""
echo "2️⃣ Eliminando contenedores huérfanos de WhatsApp:"
docker ps -a --format "{{.ID}}\t{{.Names}}" | grep -i whatsapp | awk '{print $1}' | while read id; do
    if [ ! -z "$id" ]; then
        echo "   Eliminando contenedor $id..."
        docker rm -f $id 2>/dev/null || echo "   No se pudo eliminar $id"
    fi
done

echo ""
echo "3️⃣ Verificando procesos de Node.js relacionados:"
ps aux | grep -E "whatsapp|node.*300[1-4]" | grep -v grep || echo "No hay procesos relacionados"

echo ""
echo "4️⃣ Matando procesos que puedan estar usando los puertos:"
for port in 3001 3002 3003 3004; do
    # Intentar múltiples métodos para encontrar y matar el proceso
    PID=$(netstat -tulpn 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | head -1)
    if [ ! -z "$PID" ] && [ "$PID" != "-" ]; then
        echo "   Puerto $port: PID $PID"
        kill -9 $PID 2>/dev/null || echo "   No se pudo matar PID $PID"
    else
        # Intentar con fuser
        PID=$(fuser $port/tcp 2>/dev/null | awk '{print $1}')
        if [ ! -z "$PID" ]; then
            echo "   Puerto $port: PID $PID (fuser)"
            kill -9 $PID 2>/dev/null || echo "   No se pudo matar PID $PID"
        fi
    fi
done

echo ""
echo "5️⃣ Esperando 5 segundos..."
sleep 5

echo ""
echo "6️⃣ Verificando puertos nuevamente:"
for port in 3001 3002 3003 3004; do
    if netstat -tuln 2>/dev/null | grep ":$port " || ss -tuln 2>/dev/null | grep ":$port "; then
        echo "   ⚠️  Puerto $port aún está en uso"
    else
        echo "   ✅ Puerto $port está libre"
    fi
done

echo ""
echo "=== LIMPIEZA COMPLETADA ==="
