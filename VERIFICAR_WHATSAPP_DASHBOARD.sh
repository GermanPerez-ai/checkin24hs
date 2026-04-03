#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔍 VERIFICANDO CAMBIOS DE WHATSAPP"
echo "=========================================="
echo ""

# 1. Verificar archivo local
echo "=== 1. Verificando archivo local ==="
if [ -f "deploy/dashboard.html" ]; then
    echo "✅ Archivo local existe"
    
    if grep -q "buildApiUrl (updateStatus) - URL recibida" deploy/dashboard.html; then
        echo "✅ Tiene logs de depuración de buildApiUrl"
    else
        echo "❌ NO tiene logs de depuración"
    fi
    
    if grep -q "domainParts.slice(-2)" deploy/dashboard.html; then
        echo "✅ Tiene lógica de extracción de dominio base"
    else
        echo "❌ NO tiene lógica de extracción"
    fi
    
    if grep -q "dominio base sin puerto ni rutas" deploy/dashboard.html; then
        echo "✅ Tiene normalización de URL mejorada"
    else
        echo "❌ NO tiene normalización mejorada"
    fi
else
    echo "❌ Archivo local NO existe"
    exit 1
fi

echo ""
echo "=== 2. Actualizando contenedor ==="
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
DASHBOARD_PATH="/app/dashboard.html"
docker exec $CONTAINER_ID test -f "$DASHBOARD_PATH" || DASHBOARD_PATH="/usr/share/nginx/html/dashboard.html"
echo "✅ Ruta: $DASHBOARD_PATH"

echo "📤 Copiando archivo al contenedor..."
docker cp deploy/dashboard.html "${CONTAINER_ID}:${DASHBOARD_PATH}"

echo "🔄 Reiniciando contenedor..."
docker restart $CONTAINER_ID
sleep 5

echo ""
echo "=== 3. Verificando actualización ==="
if docker exec $CONTAINER_ID grep -q "buildApiUrl (updateStatus) - URL recibida" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Contenedor tiene logs de depuración"
else
    echo "❌ Contenedor NO tiene logs de depuración"
fi

if docker exec $CONTAINER_ID grep -q "domainParts.slice(-2)" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Contenedor tiene lógica de extracción"
else
    echo "❌ Contenedor NO tiene lógica de extracción"
fi

if docker exec $CONTAINER_ID grep -q "dominio base sin puerto ni rutas" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Contenedor tiene normalización mejorada"
else
    echo "❌ Contenedor NO tiene normalización mejorada"
fi

echo ""
echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "📋 Próximos pasos:"
echo "1. Limpia localStorage: localStorage.removeItem('whatsapp_server_url')"
echo "2. Recarga la página con Ctrl+Shift+R"
echo "3. Guarda la URL: https://api1.checkin24hs.com (sin puerto, sin rutas)"
echo "4. Verifica los logs en la consola del navegador"



