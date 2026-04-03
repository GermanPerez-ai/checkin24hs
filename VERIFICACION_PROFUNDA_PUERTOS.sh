#!/bin/bash
echo "=== VERIFICACIÓN PROFUNDA DE PUERTOS 3001-3004 ==="
echo ""

echo "1️⃣ Verificando TODOS los contenedores Docker (activos y detenidos):"
echo "   Contenedores activos:"
docker ps --format "{{.ID}}\t{{.Names}}\t{{.Ports}}" | grep -E "3001|3002|3003|3004" || echo "   Ninguno"
echo ""
echo "   Contenedores detenidos:"
docker ps -a --format "{{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "3001|3002|3003|3004" || echo "   Ninguno"

echo ""
echo "2️⃣ Verificando TODOS los servicios Docker Swarm:"
docker service ls --format "{{.Name}}\t{{.Ports}}" | grep -E "3001|3002|3003|3004" || echo "   Ninguno"

echo ""
echo "3️⃣ Verificando procesos del sistema que escuchan en los puertos:"
for port in 3001 3002 3003 3004; do
    echo "   Puerto $port:"
    # Método 1: netstat
    netstat -tulpn 2>/dev/null | grep ":$port " || echo "      netstat: no encontrado"
    # Método 2: ss
    ss -tulpn 2>/dev/null | grep ":$port " || echo "      ss: no encontrado"
    # Método 3: lsof
    lsof -i :$port 2>/dev/null || echo "      lsof: no encontrado"
    # Método 4: fuser
    fuser $port/tcp 2>/dev/null || echo "      fuser: no encontrado"
done

echo ""
echo "4️⃣ Verificando procesos de Node.js en el sistema:"
ps aux | grep -E "node|whatsapp" | grep -v grep || echo "   No hay procesos de Node.js"

echo ""
echo "5️⃣ Verificando desde dentro de contenedores Docker si escuchan en esos puertos:"
for container in $(docker ps --format "{{.ID}}"); do
    CONTAINER_NAME=$(docker ps --format "{{.Names}}" --filter "id=$container")
    echo "   Contenedor: $CONTAINER_NAME ($container)"
    for port in 3001 3002 3003 3004; do
        LISTENING=$(docker exec $container netstat -tuln 2>/dev/null | grep ":$port " || docker exec $container ss -tuln 2>/dev/null | grep ":$port ")
        if [ ! -z "$LISTENING" ]; then
            echo "      ⚠️  Puerto $port está siendo usado por este contenedor"
            echo "      $LISTENING"
        fi
    done
done

echo ""
echo "6️⃣ Verificando redes Docker y sus contenedores:"
for network in $(docker network ls --format "{{.Name}}" | grep -E "easypanel|overlay"); do
    echo "   Red: $network"
    docker network inspect $network --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | grep -E "whatsapp|300[1-4]" || echo "      No hay contenedores relacionados"
done

echo ""
echo "7️⃣ Verificando procesos huérfanos de Docker:"
docker ps -a --filter "status=exited" --format "{{.ID}}\t{{.Names}}\t{{.Ports}}" | grep -E "3001|3002|3003|3004|whatsapp" || echo "   No hay contenedores huérfanos relacionados"

echo ""
echo "8️⃣ Verificando si hay procesos escuchando en todas las interfaces:"
for port in 3001 3002 3003 3004; do
    echo "   Puerto $port:"
    # Verificar en todas las interfaces
    netstat -tuln 2>/dev/null | grep -E ":$port |::$port " || echo "      No encontrado"
done

echo ""
echo "9️⃣ Verificando procesos relacionados con Docker que puedan estar usando los puertos:"
ps aux | grep -E "docker.*300[1-4]|dockerd.*300[1-4]" | grep -v grep || echo "   No hay procesos de Docker relacionados"

echo ""
echo "🔟 Verificando si los puertos están en estado TIME_WAIT (conexiones cerradas recientemente):"
netstat -an 2>/dev/null | grep -E ":300[1-4].*TIME_WAIT" || echo "   No hay conexiones en TIME_WAIT"

echo ""
echo "=== RESUMEN FINAL ==="
for port in 3001 3002 3003 3004; do
    if netstat -tuln 2>/dev/null | grep ":$port " || ss -tuln 2>/dev/null | grep ":$port "; then
        echo "⚠️  Puerto $port: EN USO"
    else
        echo "✅ Puerto $port: LIBRE"
    fi
done
