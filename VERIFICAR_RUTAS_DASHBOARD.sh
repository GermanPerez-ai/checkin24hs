#!/bin/bash
# Script para verificar qué ruta tiene la versión más reciente de dashboard.html

echo "=========================================="
echo "🔍 Verificando Versiones en Diferentes Rutas"
echo "=========================================="
echo ""

# Rutas encontradas
RUTAS=(
    "/root/checkin24hs/dashboard.html"
    "/root/checkin24hs/deploy/dashboard.html"
    "/root/checkin24hs/backups/backup_2025-08-06_11-04-23/dashboard.html"
    "/root/checkin24hs/backups/estado1/dashboard.html"
)

echo "Verificando cada ruta..."
echo ""

for RUTA in "${RUTAS[@]}"; do
    if [ -f "$RUTA" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📁 $RUTA"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Tamaño del archivo
        SIZE=$(stat -c%s "$RUTA" 2>/dev/null || stat -f%z "$RUTA" 2>/dev/null)
        SIZE_MB=$(echo "scale=2; $SIZE / 1024 / 1024" | bc 2>/dev/null || echo "N/A")
        echo "   Tamaño: $SIZE bytes ($SIZE_MB MB)"
        
        # Fecha de modificación
        MOD_DATE=$(stat -c %y "$RUTA" 2>/dev/null | cut -d' ' -f1 || stat -f%Sm -t "%Y-%m-%d" "$RUTA" 2>/dev/null)
        MOD_TIME=$(stat -c %y "$RUTA" 2>/dev/null | cut -d' ' -f2 | cut -d'.' -f1 || echo "")
        echo "   Modificado: $MOD_DATE $MOD_TIME"
        
        # Verificar BUILD_TIMESTAMP
        BUILD_TS=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" "$RUTA" 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
        if [ ! -z "$BUILD_TS" ]; then
            BUILD_DATE=$(echo "$BUILD_TS" | cut -d'T' -f1)
            BUILD_TIME=$(echo "$BUILD_TS" | cut -d'T' -f2 | cut -d'Z' -f1)
            echo "   ✅ BUILD_TIMESTAMP: $BUILD_DATE $BUILD_TIME"
        else
            echo "   ❌ No tiene BUILD_TIMESTAMP (versión muy antigua)"
        fi
        
        # Verificar DASHBOARD_VERSION
        VERSION=$(grep -oP "window\.DASHBOARD_VERSION = ['\"]([^'\"]+)['\"]" "$RUTA" 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
        if [ ! -z "$VERSION" ]; then
            echo "   ✅ DASHBOARD_VERSION: $VERSION"
        else
            echo "   ❌ No tiene DASHBOARD_VERSION"
        fi
        
        # Verificar si tiene caracteres especiales correctos (UTF-8)
        if grep -q "VERSIÓN:" "$RUTA" 2>/dev/null; then
            echo "   ✅ UTF-8 correcto (tiene 'VERSIÓN')"
        elif grep -q "VERSI?N:" "$RUTA" 2>/dev/null; then
            echo "   ❌ UTF-8 incorrecto (tiene 'VERSI?N')"
        else
            echo "   ⚠️ No se pudo verificar UTF-8"
        fi
        
        echo ""
    else
        echo "❌ $RUTA - NO EXISTE"
        echo ""
    fi
done

echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""

# Encontrar la ruta más reciente
MOST_RECENT=""
MOST_RECENT_DATE=""
MOST_RECENT_BUILD=""

for RUTA in "${RUTAS[@]}"; do
    if [ -f "$RUTA" ]; then
        BUILD_TS=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" "$RUTA" 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
        if [ ! -z "$BUILD_TS" ]; then
            if [ -z "$MOST_RECENT_BUILD" ] || [ "$BUILD_TS" \> "$MOST_RECENT_BUILD" ]; then
                MOST_RECENT="$RUTA"
                MOST_RECENT_BUILD="$BUILD_TS"
                MOST_RECENT_DATE=$(stat -c %y "$RUTA" 2>/dev/null | cut -d' ' -f1 || echo "")
            fi
        fi
    fi
done

if [ ! -z "$MOST_RECENT" ]; then
    echo "✅ VERSIÓN MÁS RECIENTE:"
    echo "   $MOST_RECENT"
    echo "   BUILD_TIMESTAMP: $MOST_RECENT_BUILD"
    echo ""
    echo "📋 Para copiar esta versión al contenedor:"
    echo "   docker cp $MOST_RECENT <CONTAINER_ID>:/app/dashboard.html"
    echo ""
    echo "   O ejecuta el script automático:"
    echo "   ./ACTUALIZAR_DASHBOARD_DIRECTO_CONTENEDOR.sh"
else
    echo "⚠️ No se encontró ninguna versión con BUILD_TIMESTAMP"
    echo "   Todas las versiones son muy antiguas"
    echo ""
    echo "📋 SOLUCIÓN: Usar el script que descarga desde GitHub:"
    echo "   ./ACTUALIZAR_DASHBOARD_DIRECTO_CONTENEDOR.sh"
fi

echo ""
