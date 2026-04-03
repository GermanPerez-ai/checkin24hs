#!/bin/bash

echo "=========================================="
echo "🧹 LIMPIANDO CONTENEDORES ANTIGUOS DE WHATSAPP"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# 1. Verificar contenedores activos
echo "1️⃣ Contenedores activos actualmente:"
docker ps --filter "name=checkin24hs_whatsapp" --format "table {{.ID}}\t{{.Status}}\t{{.Names}}"

echo ""
echo "2️⃣ Verificando qué contenedores usan el código nuevo (Chrome) vs viejo (Checkin24hs)..."
echo ""

# Obtener IDs de contenedores
CONTAINER_IDS=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}")

for CONTAINER_ID in $CONTAINER_IDS; do
    echo "   Verificando contenedor $CONTAINER_ID..."
    LOGS=$(docker logs "$CONTAINER_ID" --tail 100 2>&1 | grep -E "browser.*Chrome|browser.*Checkin24hs" | tail -1)
    if echo "$LOGS" | grep -q "Chrome"; then
        echo "   ✅ $CONTAINER_ID - Usa código NUEVO (Chrome)"
    elif echo "$LOGS" | grep -q "Checkin24hs"; then
        echo "   ⚠️  $CONTAINER_ID - Usa código VIEJO (Checkin24hs) - Se detendrá automáticamente"
    else
        echo "   ❓ $CONTAINER_ID - No se pudo determinar"
    fi
done

echo ""
echo "3️⃣ Docker Swarm automáticamente detendrá los contenedores antiguos."
echo "   Esperando 30 segundos para que se estabilice..."
sleep 30

echo ""
echo "4️⃣ Verificando estado final:"
docker ps --filter "name=checkin24hs_whatsapp" --format "table {{.ID}}\t{{.Status}}\t{{.Names}}"

echo ""
echo "5️⃣ Verificando logs del contenedor activo más reciente:"
LATEST_CONTAINER=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}" | head -1)
if [ ! -z "$LATEST_CONTAINER" ]; then
    echo "   Contenedor: $LATEST_CONTAINER"
    docker logs "$LATEST_CONTAINER" --tail 10 2>&1 | grep -E "(Chrome|QR Code recibido|QR Code imagen generada)" | tail -3
else
    echo "   ⚠️ No se encontró contenedor activo"
fi

echo ""
echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo "1. Ve a https://api1.checkin24hs.com/"
echo "2. Deberías ver un QR code limpio y válido"
echo "3. Escanea el QR code con tu teléfono INMEDIATAMENTE (expira en ~60 segundos)"
echo ""
echo "💡 Si WhatsApp sigue rechazando:"
echo "   - Espera 5-10 minutos antes de intentar de nuevo"
echo "   - WhatsApp puede estar bloqueando por demasiados intentos"
echo ""
