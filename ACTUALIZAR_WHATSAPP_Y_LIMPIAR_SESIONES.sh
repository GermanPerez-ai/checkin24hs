#!/bin/bash

echo "=========================================="
echo "🔄 ACTUALIZANDO WHATSAPP Y LIMPIANDO SESIONES"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# 1. Actualizar código desde GitHub
echo "1️⃣ Actualizando código desde GitHub..."
cd ~/checkin24hs
git pull origin main

# 2. Limpiar sesiones existentes
echo ""
echo "2️⃣ Limpiando sesiones WhatsApp existentes..."
CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}" | head -1)

if [ ! -z "$CONTAINER_ID" ]; then
    echo "   Limpiando sesión en contenedor $CONTAINER_ID..."
    docker exec "$CONTAINER_ID" sh -c "rm -rf /app/auth_info_baileys_1/* /app/auth_info_baileys_2/* /app/auth_info_baileys_3/* /app/auth_info_baileys_4/* 2>/dev/null || true"
    echo "   ✅ Sesiones limpiadas"
else
    echo "   ⚠️ No se encontró contenedor activo"
fi

# 3. Forzar actualización del servicio (esto reconstruirá con el nuevo código)
echo ""
echo "3️⃣ Forzando actualización del servicio (esto puede tomar unos minutos)..."
docker service update --force "$SERVICE_NAME"

echo ""
echo "4️⃣ Esperando a que el servicio se actualice..."
sleep 10

# 4. Verificar que el nuevo código está corriendo
echo ""
echo "5️⃣ Verificando logs del nuevo contenedor..."
echo "   (Buscando 'Chrome' en browser config - esto indica el nuevo código)"
docker service logs "$SERVICE_NAME" --tail 30 | grep -E "(Chrome|QR Code recibido|QR Code imagen generada)" | tail -5

echo ""
echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo "1. Espera 1-2 minutos para que se genere un nuevo QR code"
echo "2. Ve a https://api1.checkin24hs.com/"
echo "3. Escanea el QR code con tu teléfono"
echo ""
echo "💡 Si el QR code no aparece, verifica los logs con:"
echo "   docker service logs $SERVICE_NAME --tail 50"
echo ""
