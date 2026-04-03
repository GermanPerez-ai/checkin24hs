#!/bin/bash

echo "🔍 BUSCANDO SERVICIO DASHBOARD"
echo "=========================================="
echo ""

echo "📋 1. Contenedores corriendo (todos):"
docker ps
echo ""

echo "📋 2. Contenedores detenidos también:"
docker ps -a | head -20
echo ""

echo "📋 3. Servicios Docker Swarm:"
docker service ls 2>/dev/null || echo "   (No hay servicios Swarm o Docker no está en modo Swarm)"
echo ""

echo "📋 4. Procesos Node.js:"
ps aux | grep node | grep -v grep | head -5
echo ""

echo "📋 5. Puertos en uso (3000, 80, 443):"
netstat -tulpn | grep -E "3000|80|443" | head -10
echo ""

echo "📋 6. Buscar archivos dashboard.html en contenedores:"
for container in $(docker ps -q); do
    echo "   Contenedor $container:"
    docker exec $container find / -name "dashboard.html" 2>/dev/null | head -3
done
echo ""

echo "✅ Búsqueda completada"
echo ""
echo "💡 Si no encuentras el contenedor, el servicio puede estar:"
echo "   - Corriendo como servicio Docker Swarm"
echo "   - Corriendo directamente con Node.js (sin Docker)"
echo "   - Detenido o no desplegado"

