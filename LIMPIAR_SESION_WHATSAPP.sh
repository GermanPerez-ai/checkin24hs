#!/bin/bash
# Limpiar sesión de WhatsApp y forzar nuevo QR
# Útil cuando hay problemas de vinculación

SERVICE_NAME="checkin24hs_whatsapp"

echo "=========================================="
echo "🧹 LIMPIAR SESIÓN WHATSAPP"
echo "=========================================="
echo ""

# Encontrar el contenedor
CONTAINER_ID=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró el contenedor del servicio"
    echo ""
    echo "Intentando con docker service..."
    # Intentar con docker service exec
    docker service ps $SERVICE_NAME --no-trunc | head -5
    echo ""
    echo "💡 Ejecuta manualmente:"
    echo "   docker exec <CONTAINER_ID> rm -rf /app/auth_info_baileys_1"
    echo "   docker service update --force $SERVICE_NAME"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# Verificar si hay archivos de autenticación
echo "📋 Verificando archivos de autenticación..."
AUTH_DIR="/app/auth_info_baileys_1"
FILES_COUNT=$(docker exec $CONTAINER_ID ls -la $AUTH_DIR 2>/dev/null | wc -l)

if [ "$FILES_COUNT" -gt 3 ]; then
    echo "   ⚠️  Se encontraron $((FILES_COUNT - 3)) archivos de autenticación"
    echo ""
    echo "🗑️  Eliminando archivos de autenticación..."
    docker exec $CONTAINER_ID rm -rf $AUTH_DIR
    echo "   ✅ Archivos eliminados"
else
    echo "   ℹ️  No hay archivos de autenticación (normal si nunca se escaneó el QR)"
fi

echo ""
echo "🔄 Forzando reinicio del servicio..."
docker service update --force $SERVICE_NAME

echo ""
echo "✅ Proceso completado"
echo ""
echo "⏳ Espera 30-60 segundos para que se genere un nuevo QR"
echo "🌐 Luego accede a: https://whatsapp.checkin24hs.com/qr"
echo ""
echo "💡 IMPORTANTE: Escanea el QR inmediatamente después de generarse (dentro de 2 minutos)"
