#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO TRAEFIK Y ENDPOINTS"
echo "=========================================="
echo ""

# Esperar un poco más para que Traefik procese los cambios
echo "⏳ Esperando 10 segundos adicionales para que Traefik procese los cambios..."
sleep 10

echo ""
echo "1️⃣ Verificando labels de Traefik:"
echo "----------------------------------------"
SERVICE_NAME="checkin24hs_whatsapp"
TRAEFIK_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' 2>/dev/null | grep -E "traefik")
if [ -n "$TRAEFIK_LABELS" ]; then
    echo "✅ Labels de Traefik:"
    echo "$TRAEFIK_LABELS"
else
    echo "❌ No se encontraron labels de Traefik"
fi
echo ""

echo "2️⃣ Probando endpoints externos:"
echo "----------------------------------------"

echo "📊 /api/health:"
HEALTH_RESPONSE=$(curl -s -k -w "\nHTTP_STATUS:%{http_code}" https://api1.checkin24hs.com/api/health 2>&1)
HEALTH_STATUS=$(echo "$HEALTH_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
HEALTH_BODY=$(echo "$HEALTH_RESPONSE" | grep -v "HTTP_STATUS")
if [ "$HEALTH_STATUS" = "200" ]; then
    echo "✅ HTTP Status: $HEALTH_STATUS"
    echo "$HEALTH_BODY" | python3 -m json.tool 2>/dev/null || echo "$HEALTH_BODY"
else
    echo "❌ HTTP Status: $HEALTH_STATUS"
    echo "$HEALTH_BODY" | head -3
fi
echo ""

echo "📊 /api/status:"
STATUS_RESPONSE=$(curl -s -k -w "\nHTTP_STATUS:%{http_code}" https://api1.checkin24hs.com/api/status 2>&1)
STATUS_CODE=$(echo "$STATUS_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
STATUS_BODY=$(echo "$STATUS_RESPONSE" | grep -v "HTTP_STATUS")
if [ "$STATUS_CODE" = "200" ]; then
    echo "✅ HTTP Status: $STATUS_CODE"
    echo "$STATUS_BODY" | python3 -m json.tool 2>/dev/null | head -15 || echo "$STATUS_BODY" | head -10
else
    echo "❌ HTTP Status: $STATUS_CODE"
    echo "$STATUS_BODY" | head -3
fi
echo ""

echo "📊 / (root - página HTML):"
ROOT_RESPONSE=$(curl -s -k -w "\nHTTP_STATUS:%{http_code}" https://api1.checkin24hs.com/ 2>&1)
ROOT_STATUS=$(echo "$ROOT_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
if [ "$ROOT_STATUS" = "200" ]; then
    echo "✅ HTTP Status: $ROOT_STATUS (Página HTML disponible)"
    echo "   Puedes abrir https://api1.checkin24hs.com/ en tu navegador"
else
    echo "❌ HTTP Status: $ROOT_STATUS"
fi
echo ""

echo "3️⃣ Verificando logs de Traefik:"
echo "----------------------------------------"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "✅ Contenedor Traefik: $TRAEFIK_CONTAINER"
    echo "📋 Logs recientes relacionados con api1:"
    docker logs "$TRAEFIK_CONTAINER" --tail 30 2>&1 | grep -i "api1\|whatsapp" | tail -5 || echo "   No se encontraron logs relacionados"
else
    echo "⚠️ No se encontró contenedor de Traefik"
fi
echo ""

echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
if [ "$HEALTH_STATUS" = "200" ] && [ "$STATUS_CODE" = "200" ] && [ "$ROOT_STATUS" = "200" ]; then
    echo "✅ Todos los endpoints funcionan correctamente"
    echo "✅ Traefik está configurado y funcionando"
    echo ""
    echo "🌐 Puedes abrir: https://api1.checkin24hs.com/"
    echo "   para ver el QR code y conectar WhatsApp"
else
    echo "⚠️ Algunos endpoints no están respondiendo correctamente"
    echo "   Espera 30 segundos más y ejecuta este script nuevamente"
fi
echo ""
