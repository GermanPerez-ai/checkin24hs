#!/bin/bash
# Corregir ruta de dashboard.html para que coincida con server.js

echo "=== CORRIGIENDO RUTA DE DASHBOARD ==="
echo ""

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "📦 Contenedor: $CONTAINER"
echo ""

# 1. Encontrar server.js
echo "🔍 1. Buscando server.js..."
SERVER_PATH=$(docker exec "$CONTAINER" find / -name "server.js" -type f 2>/dev/null | grep -v node_modules | head -1)

if [ -z "$SERVER_PATH" ]; then
    echo "   ❌ No se encontró server.js"
    exit 1
fi

SERVER_DIR=$(dirname "$SERVER_PATH")
echo "   ✅ server.js encontrado en: $SERVER_PATH"
echo "   📁 Directorio: $SERVER_DIR"
echo ""

# 2. Verificar archivos en ese directorio
echo "🔍 2. Archivos en el directorio de server.js:"
docker exec "$CONTAINER" ls -lah "$SERVER_DIR" 2>/dev/null | head -10
echo ""

# 3. Verificar si dashboard.html existe ahí
DASHBOARD_IN_SERVER_DIR="$SERVER_DIR/dashboard.html"
echo "🔍 3. Verificando dashboard.html en el directorio de server.js..."
if docker exec "$CONTAINER" test -f "$DASHBOARD_IN_SERVER_DIR" 2>/dev/null; then
    echo "   ✅ dashboard.html existe en: $DASHBOARD_IN_SERVER_DIR"
    echo "   Verificando contenido:"
    docker exec "$CONTAINER" grep -q "whatsapp-config-button-main" "$DASHBOARD_IN_SERVER_DIR" 2>/dev/null && \
        echo "      ✅ Contiene botones" || \
        echo "      ❌ NO contiene botones"
else
    echo "   ❌ dashboard.html NO existe en: $DASHBOARD_IN_SERVER_DIR"
fi
echo ""

# 4. Buscar dashboard.html actual
echo "🔍 4. Buscando dashboard.html actual..."
CURRENT_DASHBOARD=$(docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)

if [ -n "$CURRENT_DASHBOARD" ]; then
    echo "   Encontrado en: $CURRENT_DASHBOARD"
    echo "   Verificando contenido:"
    docker exec "$CONTAINER" grep -q "whatsapp-config-button-main" "$CURRENT_DASHBOARD" 2>/dev/null && \
        echo "      ✅ Contiene botones" || \
        echo "      ❌ NO contiene botones"
    
    # 5. Copiar al directorio de server.js
    if [ "$CURRENT_DASHBOARD" != "$DASHBOARD_IN_SERVER_DIR" ]; then
        echo ""
        echo "📤 5. Copiando dashboard.html al directorio de server.js..."
        docker cp "$CURRENT_DASHBOARD" "${CONTAINER}:${DASHBOARD_IN_SERVER_DIR}" 2>/dev/null || \
            docker cp deploy/dashboard.html "${CONTAINER}:${DASHBOARD_IN_SERVER_DIR}" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "   ✅ Copiado exitosamente"
            
            # Verificar después de copiar
            docker exec "$CONTAINER" grep -q "whatsapp-config-button-main" "$DASHBOARD_IN_SERVER_DIR" 2>/dev/null && \
                echo "   ✅ Verificado: contiene botones" || \
                echo "   ⚠️  Verificado: NO contiene botones"
        else
            echo "   ❌ Error al copiar"
        fi
    else
        echo "   ✅ Ya está en el directorio correcto"
    fi
else
    echo "   ⚠️  No se encontró dashboard.html"
    echo "   Copiando desde deploy/dashboard.html..."
    docker cp deploy/dashboard.html "${CONTAINER}:${DASHBOARD_IN_SERVER_DIR}" 2>/dev/null && \
        echo "   ✅ Copiado" || \
        echo "   ❌ Error al copiar"
fi

echo ""

# 6. Reiniciar servicio
echo "🔄 6. Reiniciando servicio..."
docker service update --force checkin24hs_dashboard 2>&1 | grep -v "update paused\|update in progress" || true

echo ""
echo "⏳ Esperando 25 segundos..."
sleep 25

# 7. Verificar contenido servido
echo ""
echo "🌍 7. Verificando contenido servido:"
curl -s https://dashboard.checkin24hs.com 2>&1 | grep -q "whatsapp-config-button-main" && \
    echo "   ✅ Servidor sirviendo versión con botones" || \
    echo "   ❌ Servidor NO sirviendo versión con botones"

echo ""
echo "=== COMPLETADO ==="





