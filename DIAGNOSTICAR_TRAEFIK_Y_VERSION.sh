#!/bin/bash
# Script completo para diagnosticar Traefik y versión del dashboard

echo "==========================================="
echo "🔍 Diagnóstico Completo: Traefik y Versión"
echo "==========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"

# 1. Verificar versión del dashboard en el contenedor
echo "1️⃣ Verificando versión del dashboard en el contenedor..."
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -n "$CONTAINER_ID" ]; then
    echo "   Contenedor: $CONTAINER_ID"
    echo ""
    echo "   Build timestamp en dashboard.html:"
    docker exec "$CONTAINER_ID" grep -o 'window.BUILD_TIMESTAMP = "[^"]*"' /app/dashboard.html 2>/dev/null | head -1 || echo "   ❌ No se encontró BUILD_TIMESTAMP"
    echo ""
    echo "   Versión en dashboard.html:"
    docker exec "$CONTAINER_ID" grep -o 'window.DASHBOARD_VERSION = "[^"]*"' /app/dashboard.html 2>/dev/null | head -1 || echo "   ❌ No se encontró DASHBOARD_VERSION"
else
    echo "   ❌ No se encontró contenedor del dashboard"
fi

echo ""
echo "2️⃣ Verificando etiquetas Traefik (método 1: .Spec.Labels)..."
LABELS_1=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range $k, $v := .Spec.Labels}}{{if contains $k "traefik"}}{{printf "%s=%s\n" $k $v}}{{end}}{{end}}' 2>/dev/null)

if [ -n "$LABELS_1" ]; then
    echo "   ✅ Etiquetas encontradas:"
    echo "$LABELS_1" | sed 's/^/      /'
else
    echo "   ❌ No se encontraron etiquetas"
fi

echo ""
echo "3️⃣ Verificando etiquetas Traefik (método 2: JSON)..."
JSON_LABELS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.Labels}}' 2>/dev/null)

if [ -n "$JSON_LABELS" ] && [ "$JSON_LABELS" != "null" ] && [ "$JSON_LABELS" != "{}" ]; then
    TRAEFIK_JSON=$(echo "$JSON_LABELS" | jq -r 'to_entries[] | select(.key | contains("traefik")) | "\(.key)=\(.value)"' 2>/dev/null)
    if [ -n "$TRAEFIK_JSON" ]; then
        echo "   ✅ Etiquetas encontradas en JSON:"
        echo "$TRAEFIK_JSON" | sed 's/^/      /'
    else
        echo "   ❌ No se encontraron etiquetas Traefik en JSON"
        echo "   Todas las etiquetas:"
        echo "$JSON_LABELS" | jq '.' 2>/dev/null | head -20 | sed 's/^/      /'
    fi
else
    echo "   ❌ El servicio no tiene etiquetas en .Spec.Labels"
fi

echo ""
echo "4️⃣ Verificando logs de Traefik (últimos 30 líneas)..."
TRAEFIK_SERVICE=$(docker service ls --format "{{.Name}}" | grep -i "traefik" | head -1)

if [ -n "$TRAEFIK_SERVICE" ]; then
    echo "   Servicio: $TRAEFIK_SERVICE"
    echo ""
    echo "   Logs relacionados con dashboard:"
    docker service logs "$TRAEFIK_SERVICE" --tail 30 2>&1 | grep -iE "dashboard|checkin24hs" | tail -10 | sed 's/^/      /' || echo "      (sin logs relevantes)"
    echo ""
    echo "   Últimos errores de Traefik:"
    docker service logs "$TRAEFIK_SERVICE" --tail 30 2>&1 | grep -i "error" | tail -5 | sed 's/^/      /' || echo "      (sin errores)"
else
    echo "   ❌ No se encontró servicio Traefik"
fi

echo ""
echo "5️⃣ Verificando estado del servicio dashboard..."
SERVICE_STATUS=$(docker service ps "$DASHBOARD_SERVICE" --format "{{.CurrentState}}" | head -1)
echo "   Estado: $SERVICE_STATUS"

echo ""
echo "6️⃣ Verificando acceso directo al servidor..."
if [ -n "$CONTAINER_ID" ]; then
    echo "   Probando http://127.0.0.1:3000/..."
    HTTP_STATUS=$(docker exec "$CONTAINER_ID" node -e "
        const http = require('http');
        http.get('http://127.0.0.1:3000/', {family: 4}, (res) => {
            console.log(res.statusCode);
            process.exit(0);
        }).on('error', (err) => {
            console.log('ERROR: ' + err.message);
            process.exit(1);
        });
    " 2>/dev/null || echo "ERROR")
    
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "   ✅ El servidor responde correctamente (200)"
    else
        echo "   ❌ El servidor no responde correctamente: $HTTP_STATUS"
    fi
fi

echo ""
echo "==========================================="
echo "📋 Resumen"
echo "==========================================="
echo ""
if [ -n "$LABELS_1" ] || [ -n "$TRAEFIK_JSON" ]; then
    echo "✅ Las etiquetas Traefik ESTÁN aplicadas"
else
    echo "❌ Las etiquetas Traefik NO están aplicadas"
    echo ""
    echo "🔧 Solución recomendada:"
    echo "   1. Ejecuta: ./ACTUALIZAR_TRAEFIK_MANUAL.sh"
    echo "   2. O configura el dominio desde EasyPanel"
fi

echo ""
echo "Para verificar manualmente las etiquetas:"
echo "  docker service inspect $DASHBOARD_SERVICE --format '{{json .Spec.Labels}}' | jq"
echo ""
echo "Para ver la versión del dashboard:"
if [ -n "$CONTAINER_ID" ]; then
    echo "  docker exec $CONTAINER_ID grep 'BUILD_TIMESTAMP' /app/dashboard.html | head -1"
fi
echo ""
