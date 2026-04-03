#!/bin/bash
# Script para verificar que el rebuild se completó correctamente

echo "=========================================="
echo "✅ VERIFICACIÓN POST-REBUILD"
echo "=========================================="
echo ""

# Esperar un poco para que el servicio termine de iniciar
echo "⏳ Esperando 15 segundos para que el servicio termine de iniciar..."
sleep 15
echo ""

# 1. Verificar contenedor actual
echo "1️⃣ Verificando contenedor actual..."
CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No hay contenedor activo"
    echo "   Verificando estado del servicio..."
    docker service ps checkin24hs_dashboard --no-trunc | head -5
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

# 2. Verificar versión del dashboard
echo "2️⃣ Verificando versión del dashboard..."
BUILD_NUMBER=$(docker exec "$CONTAINER_ID" grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" /app/dashboard.html 2>/dev/null | head -1)

if [ -z "$BUILD_NUMBER" ]; then
    echo "⚠️ No se pudo obtener BUILD_NUMBER"
    echo "   Verificando archivo..."
    docker exec "$CONTAINER_ID" ls -lh /app/dashboard.html
else
    echo "   Build en contenedor: #$BUILD_NUMBER"
fi

# Verificar versión en GitHub
GITHUB_BUILD=$(curl -s -L "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html" 2>/dev/null | grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" | head -1)
echo "   Build en GitHub: #$GITHUB_BUILD"
echo ""

# 3. Verificar que el servidor responde
echo "3️⃣ Verificando que el servidor responde..."
SERVER_CODE=$(docker exec "$CONTAINER_ID" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', (res) => {
    process.exit(res.statusCode === 200 ? 0 : 1);
}).on('error', () => process.exit(1));
" 2>/dev/null && echo "200" || echo "error")

if [ "$SERVER_CODE" = "200" ]; then
    echo "✅ Servidor responde correctamente"
else
    echo "⚠️ Servidor puede no estar listo aún"
fi
echo ""

# 4. Verificar acceso externo
echo "4️⃣ Verificando acceso externo..."
EXTERNAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" -k https://dashboard.checkin24hs.com 2>/dev/null || echo "error")
echo "   Código HTTP: $EXTERNAL_CODE"

if [ "$EXTERNAL_CODE" = "200" ]; then
    echo "✅ Dashboard accesible externamente"
    
    # Verificar versión servida
    SERVED_BUILD=$(curl -s -k -L https://dashboard.checkin24hs.com 2>/dev/null | grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" | head -1)
    if [ -n "$SERVED_BUILD" ]; then
        echo "   Build servido: #$SERVED_BUILD"
    fi
else
    echo "⚠️ Código: $EXTERNAL_CODE"
fi
echo ""

# 5. Resumen
echo "=========================================="
echo "📊 RESUMEN"
echo "=========================================="
echo "Contenedor: $CONTAINER_ID"
echo "Build en contenedor: #${BUILD_NUMBER:-unknown}"
echo "Build en GitHub: #$GITHUB_BUILD"
echo "Build servido: #${SERVED_BUILD:-unknown}"
echo "Acceso externo: HTTP $EXTERNAL_CODE"
echo ""

if [ "$EXTERNAL_CODE" = "200" ] && [ "$BUILD_NUMBER" = "$GITHUB_BUILD" ]; then
    echo "✅ ¡TODO ESTÁ CORRECTO!"
    echo ""
    echo "   - El rebuild se completó exitosamente"
    echo "   - El dashboard tiene la versión correcta (Build #$BUILD_NUMBER)"
    echo "   - El dashboard es accesible en https://dashboard.checkin24hs.com"
    echo ""
    echo "📋 Próximos pasos:"
    echo "   1. Abre https://dashboard.checkin24hs.com en tu navegador"
    echo "   2. Limpia la caché si es necesario (Ctrl+Shift+R)"
    echo "   3. Verifica que todo funcione correctamente"
elif [ "$EXTERNAL_CODE" = "200" ]; then
    echo "⚠️ El dashboard es accesible pero puede tener una versión diferente"
    echo "   Espera 1-2 minutos más y vuelve a verificar"
else
    echo "⚠️ Hay problemas de acceso"
    echo "   Verifica los logs: docker logs $CONTAINER_ID --tail 30"
fi

echo ""
echo "=========================================="
