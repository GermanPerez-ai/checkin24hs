#!/bin/bash
# Script para actualizar dashboard a Build #61 después de un rebuild de EasyPanel
# Este script actualiza el archivo manualmente si EasyPanel no descargó la versión correcta

echo "=========================================="
echo "🔄 ACTUALIZAR DASHBOARD A BUILD #61"
echo "=========================================="
echo ""

# Buscar contenedor
CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    echo "   Verifica que el servicio esté corriendo: docker service ps checkin24hs_dashboard"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# Verificar Build actual
BUILD_LINE=$(docker exec "$CONTAINER_ID" grep "DASHBOARD_BUILD_NUMBER" /app/dashboard.html 2>/dev/null | head -1)
BUILD_NUM=$(echo "$BUILD_LINE" | sed -n 's/.*DASHBOARD_BUILD_NUMBER = \([0-9]*\).*/\1/p')

echo "Build actual en contenedor: #$BUILD_NUM"
echo ""

if [ "$BUILD_NUM" = "61" ]; then
    echo "✅ El contenedor ya tiene Build #61"
    echo ""
    echo "Verificando Build servido..."
    SERVED_BUILD=$(curl -s -k -L https://dashboard.checkin24hs.com 2>/dev/null | grep "DASHBOARD_BUILD_NUMBER" | sed -n 's/.*DASHBOARD_BUILD_NUMBER = \([0-9]*\).*/\1/p')
    if [ "$SERVED_BUILD" = "61" ]; then
        echo "✅ ¡PERFECTO! Dashboard está sirviendo Build #61"
        exit 0
    else
        echo "⚠️ Build servido: #$SERVED_BUILD (puede necesitar reinicio)"
    fi
    exit 0
fi

echo "⚠️ El contenedor tiene Build #$BUILD_NUM, actualizando a #61..."
echo ""

# Descargar desde GitHub
echo "📥 Descargando Build #61 desde GitHub..."
TEMP_FILE="/tmp/dashboard_build61_$$.html"
curl -s -L "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html" -o "$TEMP_FILE"

if [ ! -f "$TEMP_FILE" ] || [ ! -s "$TEMP_FILE" ]; then
    echo "❌ Error al descargar desde GitHub"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Verificar que tiene Build #61
DOWNLOADED_BUILD=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "$TEMP_FILE" | head -1)
echo "   Build en archivo descargado: #$DOWNLOADED_BUILD"

if [ "$DOWNLOADED_BUILD" != "61" ]; then
    echo "⚠️ El archivo descargado tiene Build #$DOWNLOADED_BUILD, no #61"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo "✅ Archivo tiene Build #61"
echo ""

# Crear backup
echo "💾 Creando backup..."
BACKUP_NAME="dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
docker exec "$CONTAINER_ID" cp /app/dashboard.html "/app/$BACKUP_NAME" 2>/dev/null && echo "✅ Backup creado: $BACKUP_NAME" || echo "⚠️ No se pudo crear backup"
echo ""

# Detener Node.js temporalmente
echo "🔄 Deteniendo Node.js temporalmente para liberar el archivo..."
docker exec "$CONTAINER_ID" pkill -f "node.*server.js" 2>/dev/null
sleep 3
echo ""

# Copiar archivo
echo "📤 Copiando archivo al contenedor..."
docker cp "$TEMP_FILE" "${CONTAINER_ID}:/app/dashboard.html"

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado"
    echo ""
    
    # Verificar
    sleep 2
    NEW_BUILD_LINE=$(docker exec "$CONTAINER_ID" grep "DASHBOARD_BUILD_NUMBER" /app/dashboard.html 2>/dev/null | head -1)
    NEW_BUILD_NUM=$(echo "$NEW_BUILD_LINE" | sed -n 's/.*DASHBOARD_BUILD_NUMBER = \([0-9]*\).*/\1/p')
    
    if [ "$NEW_BUILD_NUM" = "61" ]; then
        echo "✅ Verificación: Build #$NEW_BUILD_NUM en el contenedor"
        echo ""
        echo "⏳ El servidor Node.js se reiniciará automáticamente"
        echo "   Espera 15-20 segundos y verifica el dashboard"
        echo ""
        echo "📋 Para verificar:"
        echo "   curl -s -k -L https://dashboard.checkin24hs.com | grep DASHBOARD_BUILD_NUMBER"
    else
        echo "⚠️ Verificación: Build #$NEW_BUILD_NUM (esperado: #61)"
        echo "   Puede necesitar reiniciar el contenedor manualmente"
    fi
else
    echo "❌ Error al copiar archivo"
    echo ""
    echo "💡 Solución alternativa:"
    echo "   1. Reinicia el servicio: docker service update --force checkin24hs_dashboard"
    echo "   2. Espera 2-3 minutos"
    echo "   3. Ejecuta este script nuevamente"
fi

# Limpiar
rm -f "$TEMP_FILE"

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
