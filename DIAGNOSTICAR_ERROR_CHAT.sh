#!/bin/bash
set -e

echo "=========================================="
echo "🔍 DIAGNOSTICANDO ERROR AL VER CHATS"
echo "=========================================="

DASHBOARD_CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $DASHBOARD_CONTAINER"
echo ""

# 1. Verificar que getWhatsAppMessages existe y está correcto
echo "=== 1. Verificando función getWhatsAppMessages ==="
GET_MESSAGES_CODE=$(docker exec "$DASHBOARD_CONTAINER" grep -A 20 "getWhatsAppMessages" /app/dashboard.html | head -30)
if [ -z "$GET_MESSAGES_CODE" ]; then
    echo "❌ No se encontró la función getWhatsAppMessages en dashboard.html"
else
    echo "✅ Función getWhatsAppMessages encontrada"
    echo "$GET_MESSAGES_CODE" | head -10
fi

# 2. Verificar que se usa is_from_me correctamente
echo ""
echo "=== 2. Verificando uso de is_from_me ==="
IS_FROM_ME_COUNT=$(docker exec "$DASHBOARD_CONTAINER" grep -c "is_from_me" /app/dashboard.html || echo "0")
FROM_ME_COUNT=$(docker exec "$DASHBOARD_CONTAINER" grep -c "from_me[^_]" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" || echo "0")
echo "Referencias a is_from_me: $IS_FROM_ME_COUNT"
echo "Referencias problemáticas a from_me: $FROM_ME_COUNT"

if [ "$FROM_ME_COUNT" -gt 0 ]; then
    echo "⚠️ Se encontraron referencias problemáticas a from_me:"
    docker exec "$DASHBOARD_CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -5
fi

# 3. Verificar que no hay consultas directas problemáticas
echo ""
echo "=== 3. Verificando consultas directas problemáticas ==="
DIRECT_QUERIES=$(docker exec "$DASHBOARD_CONTAINER" grep -n "whatsapp_messages.*select" /app/dashboard.html | grep -v "getWhatsAppMessages" | head -5)
if [ -z "$DIRECT_QUERIES" ]; then
    echo "✅ No se encontraron consultas directas problemáticas"
else
    echo "⚠️ Se encontraron consultas directas:"
    echo "$DIRECT_QUERIES"
fi

# 4. Verificar logs del contenedor para errores recientes
echo ""
echo "=== 4. Verificando logs recientes del contenedor ==="
docker logs "$DASHBOARD_CONTAINER" --tail 50 | grep -i "error\|failed\|exception\|cannot\|refused\|from_me" | tail -10 || echo "✅ No se encontraron errores recientes en los logs"

# 5. Verificar estructura de la función selectChat
echo ""
echo "=== 5. Verificando función selectChat ==="
SELECT_CHAT_CODE=$(docker exec "$DASHBOARD_CONTAINER" grep -A 50 "async function selectChat\|async selectChat" /app/dashboard.html | head -60)
if [ -z "$SELECT_CHAT_CODE" ]; then
    echo "⚠️ No se encontró la función selectChat"
else
    echo "✅ Función selectChat encontrada"
    # Buscar llamadas a getWhatsAppMessages
    if echo "$SELECT_CHAT_CODE" | grep -q "getWhatsAppMessages"; then
        echo "✅ selectChat usa getWhatsAppMessages (correcto)"
    else
        echo "❌ selectChat NO usa getWhatsAppMessages"
    fi
    # Buscar consultas directas
    if echo "$SELECT_CHAT_CODE" | grep -q "whatsapp_messages.*select"; then
        echo "⚠️ selectChat tiene consultas directas a whatsapp_messages"
    else
        echo "✅ selectChat no tiene consultas directas problemáticas"
    fi
fi

# 6. Verificar que supabase-client.js está correcto
echo ""
echo "=== 6. Verificando supabase-client.js ==="
if docker exec "$DASHBOARD_CONTAINER" test -f /app/supabase-client.js; then
    SUPABASE_GET_MESSAGES=$(docker exec "$DASHBOARD_CONTAINER" grep -A 15 "getWhatsAppMessages" /app/supabase-client.js | head -20)
    if [ -z "$SUPABASE_GET_MESSAGES" ]; then
        echo "❌ No se encontró getWhatsAppMessages en supabase-client.js"
    else
        echo "✅ getWhatsAppMessages encontrado en supabase-client.js"
        if echo "$SUPABASE_GET_MESSAGES" | grep -q "is_from_me"; then
            echo "✅ Usa is_from_me correctamente"
        else
            echo "❌ NO usa is_from_me correctamente"
        fi
    fi
else
    echo "⚠️ supabase-client.js no encontrado en el contenedor"
fi

echo ""
echo "=========================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=========================================="

echo ""
echo "📋 Resumen:"
echo "  - Referencias a is_from_me: $IS_FROM_ME_COUNT"
echo "  - Referencias problemáticas a from_me: $FROM_ME_COUNT"
echo ""
echo "💡 Si hay errores, ejecuta MEJORAR_FILTRO_SPAM_Y_CORREGIR_ERRORES.sh para corregirlos"


