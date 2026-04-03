#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔍 VERIFICANDO CAMBIOS EN DASHBOARD"
echo "=========================================="
echo ""

# 1. Verificar archivo local en servidor
echo "=== 1. Verificando archivo local en servidor ==="
if [ -f "deploy/dashboard.html" ]; then
    echo "✅ Archivo local existe"
    
    # Verificar cambios específicos
    if grep -q "domainParts.slice(-2)" deploy/dashboard.html; then
        echo "✅ Tiene lógica de extracción de dominio base (domainParts.slice(-2))"
    else
        echo "❌ NO tiene lógica de extracción de dominio base"
    fi
    
    if grep -q "Últimas 2 partes" deploy/dashboard.html; then
        echo "✅ Tiene comentario de 'Últimas 2 partes'"
    else
        echo "❌ NO tiene comentario de 'Últimas 2 partes'"
    fi
    
    # Contar instancias de buildApiUrl
    BUILD_COUNT=$(grep -c "buildApiUrl.*baseUrl.*instanceNum" deploy/dashboard.html 2>/dev/null || echo "0")
    echo "📊 Instancias de buildApiUrl encontradas: $BUILD_COUNT"
else
    echo "❌ Archivo local NO existe"
fi

echo ""
echo "=== 2. Verificando contenedor ==="
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
else
    echo "✅ Contenedor: $CONTAINER_ID"
    
    # Buscar ruta
    DASHBOARD_PATH="/app/dashboard.html"
    docker exec $CONTAINER_ID test -f "$DASHBOARD_PATH" || DASHBOARD_PATH="/usr/share/nginx/html/dashboard.html"
    echo "✅ Ruta: $DASHBOARD_PATH"
    
    # Verificar cambios en el contenedor
    if docker exec $CONTAINER_ID grep -q "domainParts.slice(-2)" "$DASHBOARD_PATH" 2>/dev/null; then
        echo "✅ Contenedor tiene lógica de extracción de dominio base"
    else
        echo "❌ Contenedor NO tiene lógica de extracción - NECESITA ACTUALIZACIÓN"
    fi
    
    if docker exec $CONTAINER_ID grep -q "Últimas 2 partes" "$DASHBOARD_PATH" 2>/dev/null; then
        echo "✅ Contenedor tiene comentario de 'Últimas 2 partes'"
    else
        echo "❌ Contenedor NO tiene comentario - NECESITA ACTUALIZACIÓN"
    fi
    
    # Comparar timestamps
    echo ""
    echo "=== 3. Comparando timestamps ==="
    LOCAL_TIME=$(stat -c %Y deploy/dashboard.html 2>/dev/null || stat -f %m deploy/dashboard.html 2>/dev/null)
    CONTAINER_TIME=$(docker exec $CONTAINER_ID stat -c %Y "$DASHBOARD_PATH" 2>/dev/null || echo "0")
    
    if [ "$LOCAL_TIME" -gt "$CONTAINER_TIME" ]; then
        echo "⚠️  Archivo local es MÁS RECIENTE que el del contenedor"
        echo "   Archivo local: $(date -d @$LOCAL_TIME 2>/dev/null || date -r $LOCAL_TIME 2>/dev/null)"
        echo "   Contenedor: $(date -d @$CONTAINER_TIME 2>/dev/null || date -r $CONTAINER_TIME 2>/dev/null)"
        echo "   → NECESITA ACTUALIZACIÓN"
    else
        echo "✅ Contenedor está actualizado"
    fi
fi

echo ""
echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETA"
echo "=========================================="



