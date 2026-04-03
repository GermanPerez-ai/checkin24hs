#!/bin/bash
# Verificar acceso al dashboard después de configurar dominio en EasyPanel

echo "=========================================="
echo "🔍 Verificando acceso al Dashboard"
echo "=========================================="
echo ""

DOMAIN="dashboard.checkin24hs.com"
DASHBOARD_SERVICE="checkin24hs_dashboard"

echo "1️⃣ Verificando que el servicio está corriendo..."
SERVICE_STATUS=$(docker service ls | grep "$DASHBOARD_SERVICE" | awk '{print $4}')

if [ -z "$SERVICE_STATUS" ]; then
    echo "❌ El servicio NO está corriendo"
    exit 1
else
    echo "✅ Servicio está: $SERVICE_STATUS"
fi

echo ""
echo "2️⃣ Verificando acceso directo al contenedor..."
FIRST_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$FIRST_CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $FIRST_CONTAINER"
echo "Probando http://127.0.0.1:3000/ desde dentro del contenedor..."

docker exec "$FIRST_CONTAINER" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', {family: 4, timeout: 5000}, (res) => {
    console.log('✅ Status:', res.statusCode);
    if (res.statusCode === 200) {
        console.log('✅ El servidor responde correctamente');
        process.exit(0);
    } else {
        console.log('⚠️ Status inesperado:', res.statusCode);
        process.exit(1);
    }
}).on('error', (err) => {
    console.error('❌ Error:', err.message);
    process.exit(1);
});
" 2>&1

if [ $? -eq 0 ]; then
    echo "✅ El servidor responde correctamente"
else
    echo "❌ El servidor NO responde"
    exit 1
fi

echo ""
echo "3️⃣ Verificando acceso a través de Traefik (desde el host)..."
echo "Probando https://$DOMAIN..."

# Intentar con curl si está disponible
if command -v curl &> /dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$DOMAIN" 2>&1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Dashboard accesible a través de Traefik (HTTP 200)"
    elif [ "$HTTP_CODE" = "000" ]; then
        echo "⚠️ No se pudo conectar (posible problema de DNS o Traefik)"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "❌ Error 404 - Traefik no está enrutando correctamente"
        echo "   Las etiquetas Traefik probablemente no están aplicadas"
    elif [ "$HTTP_CODE" = "502" ] || [ "$HTTP_CODE" = "503" ]; then
        echo "⚠️ Error $HTTP_CODE - Traefik no puede alcanzar el servicio"
    else
        echo "⚠️ Código HTTP: $HTTP_CODE"
    fi
else
    echo "⚠️ curl no está disponible, no se puede verificar acceso externo"
    echo "   Prueba manualmente: https://$DOMAIN"
fi

echo ""
echo "4️⃣ Verificando etiquetas Traefik..."
SERVICE_JSON=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' 2>/dev/null)
TRAEFIK_LABELS=$(echo "$SERVICE_JSON" | jq -r 'to_entries[] | select(.key | contains("traefik")) | "\(.key)=\(.value)"' 2>/dev/null)

if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ NO hay etiquetas Traefik"
    echo ""
    echo "✅ ACCIÓN REQUERIDA:"
    echo "   Configura el dominio desde EasyPanel:"
    echo "   1. Ve a: http://72.61.58.240:3000"
    echo "   2. Proyecto: checkin24hs → Servicio: dashboard"
    echo "   3. Pestaña: '🔗 Dominios' o 'Domains'"
    echo "   4. Agrega: dashboard.checkin24hs.com"
    echo "   5. Puerto: 3000, Ruta: /, HTTPS: Activado"
    echo "   6. Guarda y espera 1-2 minutos"
else
    echo "✅ Etiquetas Traefik encontradas:"
    echo "$TRAEFIK_LABELS" | head -5
fi

echo ""
echo "5️⃣ Verificando logs de Traefik (últimas 10 líneas)..."
TRAEFIK_LOGS=$(docker service logs traefik --tail 10 2>&1 | grep -iE "(dashboard|error|router)" | tail -5)

if [ -z "$TRAEFIK_LOGS" ]; then
    echo "✅ No hay errores relevantes en Traefik"
else
    echo "⚠️ Logs de Traefik:"
    echo "$TRAEFIK_LOGS"
fi

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""

if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ PROBLEMA: Las etiquetas Traefik NO están aplicadas"
    echo ""
    echo "✅ SOLUCIÓN: Configura el dominio desde EasyPanel (pasos arriba)"
    echo ""
    echo "Después de configurar, ejecuta este script nuevamente para verificar"
else
    echo "✅ Las etiquetas Traefik están aplicadas"
    echo ""
    echo "⏳ Si aún no funciona, espera 1-2 minutos y prueba:"
    echo "   https://$DOMAIN"
fi

echo ""
