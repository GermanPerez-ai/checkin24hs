#!/bin/bash
# Script para verificar que el dashboard funciona correctamente en línea

echo "=== VERIFICACIÓN DEL DASHBOARD EN LÍNEA ==="
echo ""

DASHBOARD_URL="https://dashboard.checkin24hs.com"

echo "1. Verificando accesibilidad básica..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 $DASHBOARD_URL 2>&1)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ HTTP 200 - Dashboard accesible"
else
    echo "❌ HTTP $HTTP_CODE - Dashboard no accesible"
    exit 1
fi

echo ""
echo "2. Verificando headers anti-caché..."
HEADERS=$(curl -s -I $DASHBOARD_URL 2>&1)
if echo "$HEADERS" | grep -qi "cache-control.*no-cache"; then
    echo "✅ Headers anti-caché presentes"
else
    echo "⚠️ Headers anti-caché no encontrados (puede ser normal si usa Traefik)"
fi

echo ""
echo "3. Verificando contenido HTML..."
HTML_CONTENT=$(curl -s $DASHBOARD_URL 2>&1 | head -c 1000)
if echo "$HTML_CONTENT" | grep -qi "Checkin24hs\|Panel de Administración"; then
    echo "✅ Contenido HTML válido"
else
    echo "❌ Contenido HTML no válido o no encontrado"
fi

echo ""
echo "4. Verificando meta tags anti-caché en HTML..."
if echo "$HTML_CONTENT" | grep -qi "Cache-Control.*no-cache"; then
    echo "✅ Meta tags anti-caché presentes en HTML"
else
    echo "⚠️ Meta tags anti-caché no encontrados"
fi

echo ""
echo "5. Verificando certificado SSL..."
SSL_INFO=$(echo | openssl s_client -servername dashboard.checkin24hs.com -connect dashboard.checkin24hs.com:443 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null)
if [ -n "$SSL_INFO" ]; then
    echo "✅ Certificado SSL válido:"
    echo "$SSL_INFO" | head -2
else
    echo "⚠️ No se pudo verificar certificado SSL"
fi

echo ""
echo "6. Verificando tiempo de respuesta..."
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" --max-time 10 $DASHBOARD_URL 2>&1)
echo "⏱️ Tiempo de respuesta: ${RESPONSE_TIME}s"

echo ""
echo "=== RESUMEN ==="
echo "✅ Dashboard accesible en: $DASHBOARD_URL"
echo ""
echo "📝 Para probar desde otros ordenadores:"
echo "   1. Abre el navegador en otro ordenador/dispositivo"
echo "   2. Ve a: $DASHBOARD_URL"
echo "   3. Verifica que carga correctamente"
echo ""
echo "🌐 Herramientas online para probar:"
echo "   - https://www.uptrends.com/tools/uptime"
echo "   - https://www.site24x7.com/tools/website-monitoring.html"
echo "   - https://downforeveryoneorjustme.com/dashboard.checkin24hs.com"
echo ""






