#!/bin/bash
# Script para verificar qué código tiene realmente el contenedor

echo "=========================================="
echo "🔍 VERIFICACIÓN DEL CÓDIGO EN CONTENEDOR"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

echo "1️⃣ Verificando si dashboard.html existe..."
if docker exec "$CONTAINER_ID" test -f "/app/dashboard.html" 2>/dev/null; then
    echo "✅ Archivo existe"
    
    echo ""
    echo "2️⃣ Tamaño del archivo:"
    docker exec "$CONTAINER_ID" ls -lh /app/dashboard.html 2>/dev/null
    
    echo ""
    echo "3️⃣ Primeras 30 líneas del archivo:"
    docker exec "$CONTAINER_ID" head -30 /app/dashboard.html 2>/dev/null
    
    echo ""
    echo "4️⃣ Buscando BUILD_TIMESTAMP (múltiples métodos):"
    
    # Método 1: grep simple
    echo "   Método 1 (grep simple):"
    docker exec "$CONTAINER_ID" grep -i "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -3
    
    # Método 2: grep con contexto
    echo "   Método 2 (grep con contexto):"
    docker exec "$CONTAINER_ID" grep -A 2 -B 2 "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -5
    
    # Método 3: buscar window.BUILD
    echo "   Método 3 (buscar window.BUILD):"
    docker exec "$CONTAINER_ID" grep "window.BUILD" /app/dashboard.html 2>/dev/null | head -3
    
    echo ""
    echo "5️⃣ Buscando DASHBOARD_VERSION:"
    docker exec "$CONTAINER_ID" grep -i "DASHBOARD_VERSION" /app/dashboard.html 2>/dev/null | head -3
    
    echo ""
    echo "6️⃣ Verificando fecha de modificación del archivo:"
    docker exec "$CONTAINER_ID" stat /app/dashboard.html 2>/dev/null | grep -i "modify\|change"
    
else
    echo "❌ Archivo NO existe en /app/dashboard.html"
    echo ""
    echo "📋 Listando archivos en /app:"
    docker exec "$CONTAINER_ID" ls -la /app 2>/dev/null
fi

echo ""
echo "7️⃣ Verificando server.js:"
if docker exec "$CONTAINER_ID" test -f "/app/server.js" 2>/dev/null; then
    echo "✅ server.js existe"
    echo "   Tamaño:"
    docker exec "$CONTAINER_ID" ls -lh /app/server.js 2>/dev/null
    echo "   Buscando manejo de favicon:"
    docker exec "$CONTAINER_ID" grep -i "favicon" /app/server.js 2>/dev/null | head -3
else
    echo "❌ server.js NO existe"
fi

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
