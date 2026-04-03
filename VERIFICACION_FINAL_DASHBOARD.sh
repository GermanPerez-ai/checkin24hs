#!/bin/bash

echo "=========================================="
echo "VERIFICACIÓN FINAL DEL DASHBOARD"
echo "=========================================="
echo ""

# 1. Verificar servicio
echo "1. Estado del servicio:"
docker service ps checkin24hs_dashboard --no-trunc | head -3
echo ""

# 2. Verificar contenedor actual
echo "2. Contenedor actual:"
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "   ✅ Contenedor: $CONTAINER_ID"
    echo ""
    echo "   Archivos en el contenedor:"
    docker exec $CONTAINER_ID ls -lh /app/dashboard.html /app/supabase-client.js /app/supabase-config.js 2>/dev/null
else
    echo "   ❌ No se encontró contenedor"
fi
echo ""

# 3. Comparar tamaños
echo "3. Comparando archivos local vs contenedor:"
if [ -f "/root/checkin24hs/dashboard.html" ]; then
    LOCAL_SIZE=$(ls -lh /root/checkin24hs/dashboard.html | awk '{print $5}')
    CONTAINER_SIZE=$(docker exec $CONTAINER_ID ls -lh /app/dashboard.html 2>/dev/null | awk '{print $5}')
    echo "   Local: $LOCAL_SIZE"
    echo "   Contenedor: $CONTAINER_SIZE"
    if [ "$LOCAL_SIZE" = "$CONTAINER_SIZE" ]; then
        echo "   ✅ Los tamaños coinciden"
    else
        echo "   ⚠️  Los tamaños NO coinciden"
    fi
fi
echo ""

# 4. Probar acceso HTTP
echo "4. Probando acceso HTTP:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
HTML_SIZE=$(curl -s http://localhost:3000 | wc -c)

echo "   Código HTTP: $HTTP_CODE"
echo "   Tamaño HTML servido: $HTML_SIZE bytes"

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Servidor respondiendo correctamente"
else
    echo "   ❌ Error HTTP: $HTTP_CODE"
fi

if [ "$HTML_SIZE" -gt "1000000" ]; then
    echo "   ✅ HTML tiene tamaño correcto (>1MB)"
else
    echo "   ⚠️  HTML muy pequeño ($HTML_SIZE bytes)"
fi
echo ""

# 5. Verificar contenido HTML
echo "5. Verificando contenido HTML:"
LOGIN_COUNT=$(curl -s http://localhost:3000 | grep -o "login-container" | wc -l)
AUTHENTICATED_COUNT=$(curl -s http://localhost:3000 | grep -o "authenticated" | wc -l)

echo "   Ocurrencias de 'login-container': $LOGIN_COUNT"
echo "   Ocurrencias de 'authenticated': $AUTHENTICATED_COUNT"

if [ "$LOGIN_COUNT" -eq "0" ]; then
    echo "   ✅ No se encontró login-container en el HTML"
else
    echo "   ⚠️  Se encontró login-container ($LOGIN_COUNT veces)"
fi
echo ""

# 6. Verificar logs del servicio
echo "6. Últimos logs del servicio:"
docker service logs checkin24hs_dashboard --tail 10 2>&1 | tail -10
echo ""

echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo ""

if [ "$HTTP_CODE" = "200" ] && [ "$HTML_SIZE" -gt "1000000" ] && [ "$LOGIN_COUNT" -eq "0" ]; then
    echo "✅ TODO CORRECTO"
    echo ""
    echo "El dashboard debería estar funcionando correctamente."
    echo "Prueba acceder a:"
    echo "  - http://72.61.58.240:3000"
    echo "  - http://dashboard.checkin24hs.com"
else
    echo "⚠️  HAY PROBLEMAS"
    echo ""
    if [ "$HTTP_CODE" != "200" ]; then
        echo "  - El servidor no responde correctamente (HTTP $HTTP_CODE)"
    fi
    if [ "$HTML_SIZE" -le "1000000" ]; then
        echo "  - El HTML es muy pequeño ($HTML_SIZE bytes)"
    fi
    if [ "$LOGIN_COUNT" -gt "0" ]; then
        echo "  - Aún se encuentra login-container en el HTML"
    fi
fi

echo ""

