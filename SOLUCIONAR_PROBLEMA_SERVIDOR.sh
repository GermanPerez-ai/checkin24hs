#!/bin/bash
# Solucionar problema del servidor Node.js

echo "=== SOLUCIONANDO PROBLEMA DEL SERVIDOR ==="
echo ""

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "📦 Contenedor: $CONTAINER"
echo ""

# 1. Ver qué está devolviendo realmente el servidor
echo "🔍 1. Verificando qué está devolviendo el servidor:"
RESPONSE=$(docker exec "$CONTAINER" curl -s http://localhost:3000/ 2>&1)
echo "$RESPONSE" | head -20
echo ""
echo "Tamaño de respuesta: $(echo "$RESPONSE" | wc -c) bytes"
echo ""

# 2. Verificar que el archivo existe y tiene el tamaño correcto
echo "🔍 2. Verificando archivo en disco:"
if docker exec "$CONTAINER" test -f /app/dashboard.html 2>/dev/null; then
    FILE_SIZE=$(docker exec "$CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER" stat -f%z /app/dashboard.html 2>/dev/null)
    echo "   ✅ Archivo existe"
    echo "   Tamaño: $FILE_SIZE bytes"
    
    docker exec "$CONTAINER" grep -q "whatsapp-config-button-main" /app/dashboard.html 2>/dev/null && \
        echo "   ✅ Contiene botones" || \
        echo "   ❌ NO contiene botones"
else
    echo "   ❌ Archivo NO existe en /app/dashboard.html"
fi
echo ""

# 3. Verificar __dirname en server.js
echo "🔍 3. Verificando __dirname en server.js:"
docker exec "$CONTAINER" node -e "console.log(__dirname)" 2>/dev/null || \
    docker exec "$CONTAINER" sh -c "cd /app && node -e 'console.log(__dirname)'" 2>/dev/null
echo ""

# 4. Verificar que server.js puede leer el archivo
echo "🔍 4. Verificando que server.js puede leer el archivo:"
docker exec "$CONTAINER" node -e "const fs = require('fs'); const path = require('path'); const filePath = path.join(__dirname, 'dashboard.html'); console.log('Ruta:', filePath); console.log('Existe:', fs.existsSync(filePath)); if (fs.existsSync(filePath)) { const stats = fs.statSync(filePath); console.log('Tamaño:', stats.size); }" 2>/dev/null || \
    docker exec "$CONTAINER" sh -c "cd /app && node -e \"const fs = require('fs'); const path = require('path'); const filePath = path.join(__dirname, 'dashboard.html'); console.log('Ruta:', filePath); console.log('Existe:', fs.existsSync(filePath)); if (fs.existsSync(filePath)) { const stats = fs.statSync(filePath); console.log('Tamaño:', stats.size); }\"" 2>/dev/null
echo ""

# 5. Copiar archivo nuevamente y verificar
echo "📤 5. Copiando archivo nuevamente..."
docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
echo "✅ Copiado"
echo ""

# 6. Verificar tamaño después de copiar
NEW_SIZE=$(docker exec "$CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER" stat -f%z /app/dashboard.html 2>/dev/null)
echo "Tamaño después de copiar: $NEW_SIZE bytes"
echo ""

# 7. Reiniciar servicio completamente
echo "🔄 6. Reiniciando servicio completamente..."
docker service scale checkin24hs_dashboard=0
sleep 5
docker service scale checkin24hs_dashboard=1
sleep 30

# 8. Verificar nuevo contenedor
NEW_CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
echo "📦 Nuevo contenedor: $NEW_CONTAINER"
echo ""

# 9. Verificar archivo en nuevo contenedor
if [ -n "$NEW_CONTAINER" ]; then
    echo "🔍 7. Verificando archivo en nuevo contenedor:"
    docker exec "$NEW_CONTAINER" test -f /app/dashboard.html 2>/dev/null && \
        echo "   ✅ Archivo existe" || \
        echo "   ❌ Archivo NO existe"
    
    NEW_FILE_SIZE=$(docker exec "$NEW_CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$NEW_CONTAINER" stat -f%z /app/dashboard.html 2>/dev/null)
    echo "   Tamaño: $NEW_FILE_SIZE bytes"
    
    docker exec "$NEW_CONTAINER" grep -q "whatsapp-config-button-main" /app/dashboard.html 2>/dev/null && \
        echo "   ✅ Contiene botones" || \
        echo "   ❌ NO contiene botones"
    
    echo ""
    echo "🔍 8. Probando acceso directo:"
    docker exec "$NEW_CONTAINER" curl -s http://localhost:3000/ 2>&1 | grep -q "whatsapp-config-button-main" && \
        echo "   ✅ Contiene botones" || \
        echo "   ❌ NO contiene botones"
fi

echo ""
echo "=== COMPLETADO ==="





