#!/bin/bash

echo "=========================================="
echo "🔄 FORZANDO RECONEXIÓN DE WHATSAPP"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

echo "1️⃣ Verificando logs completos (últimas 50 líneas):"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --tail 50 2>&1 | tail -30
echo ""

echo "2️⃣ Buscando intentos de reconexión:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --tail 100 2>&1 | grep -E "(Reconectando|Iniciando reconexión|connectToWhatsApp)" | tail -10
echo ""

echo "3️⃣ Verificando si hay sesión guardada:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" sh -c "ls -la /app/auth_info_baileys_1/ 2>/dev/null | head -10 || echo '⚠️ Directorio de autenticación no existe o está vacío'"
echo ""

echo "4️⃣ Reiniciando el servicio para forzar reconexión:"
echo "----------------------------------------"
SERVICE_NAME=$(docker service ls --filter "name=checkin24hs_whatsapp" --format "{{.Name}}" | head -1)

if [ -n "$SERVICE_NAME" ]; then
    echo "✅ Servicio encontrado: $SERVICE_NAME"
    echo "🔄 Reiniciando servicio..."
    docker service update --force "$SERVICE_NAME" 2>&1
    echo ""
    echo "⏳ Esperando 30 segundos para que el servicio se reinicie..."
    sleep 30
    echo ""
    echo "5️⃣ Verificando logs después del reinicio:"
    echo "----------------------------------------"
    NEW_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}" | head -1)
    if [ -n "$NEW_CONTAINER_ID" ]; then
        echo "✅ Nuevo contenedor: $NEW_CONTAINER_ID"
        echo ""
        docker logs "$NEW_CONTAINER_ID" --tail 20 2>&1
        echo ""
        echo "6️⃣ Verificando si se generó QR code:"
        echo "----------------------------------------"
        docker logs "$NEW_CONTAINER_ID" --tail 30 2>&1 | grep -E "(QR Code recibido|QR Code generado|connected to WA)" | tail -5
    else
        echo "⚠️ No se encontró nuevo contenedor aún"
    fi
else
    echo "⚠️ No se encontró servicio Docker Swarm"
    echo "   Intentando reiniciar contenedor directamente..."
    docker restart "$CONTAINER_ID" 2>&1
    echo ""
    echo "⏳ Esperando 20 segundos..."
    sleep 20
    echo ""
    docker logs "$CONTAINER_ID" --tail 20 2>&1
fi

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
echo "✅ Servicio reiniciado"
echo "💡 Espera 30-60 segundos más y verifica si aparece el QR code"
echo "   Abre https://api1.checkin24hs.com/ en el navegador"
echo ""
