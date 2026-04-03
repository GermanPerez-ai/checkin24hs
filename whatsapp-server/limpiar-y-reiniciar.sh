#!/bin/bash
# 🧹 Limpiar Sesión y Reiniciar Servicio

INSTANCE="${1:-1}"
SERVICE_NAME="checkin24hs_whatsapp"

echo "=============================================================="
echo "🧹 LIMPIEZA Y REINICIO DE WHATSAPP"
echo "=============================================================="
echo ""

# 1. Encontrar contenedor actual
echo "1️⃣  Buscando contenedor actual..."
CONTAINER_ID=$(docker ps | grep ${SERVICE_NAME} | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "   Contenedor: $CONTAINER_ID"
echo ""

# 2. Limpiar sesión
echo "2️⃣  Limpiando sesión..."
docker exec $CONTAINER_ID rm -rf /app/auth_info_baileys_${INSTANCE} 2>/dev/null

if [ $? -eq 0 ]; then
    echo "   ✅ Sesión limpiada"
else
    echo "   ⚠️  Error limpiando (puede que no exista)"
fi
echo ""

# 3. Reiniciar servicio
echo "3️⃣  Reiniciando servicio..."
docker service update --force ${SERVICE_NAME} >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "   ✅ Servicio reiniciado"
else
    echo "   ❌ Error reiniciando servicio"
    exit 1
fi
echo ""

# 4. Esperar
echo "4️⃣  Esperando 30 segundos para que se genere el QR..."
sleep 30
echo "   ✅ Listo"
echo ""

# 5. Verificar
echo "5️⃣  Verificando estado..."
STATUS=$(curl -s http://localhost:3001/api/status 2>/dev/null)
if echo "$STATUS" | grep -q "connected.*true"; then
    echo "   ✅ WhatsApp está conectado"
elif echo "$STATUS" | grep -q "waiting_scan"; then
    echo "   📱 QR disponible para escanear"
else
    echo "   ⏳ Esperando QR..."
fi
echo ""

echo "=============================================================="
echo "✅ COMPLETADO"
echo "=============================================================="
echo ""
echo "📱 PRÓXIMOS PASOS EN TU TELÉFONO:"
echo ""
echo "1. Abre WhatsApp"
echo "2. Ve a: Configuración → Dispositivos vinculados"
echo "3. Desconecta TODAS las sesiones"
echo "4. Cierra completamente WhatsApp"
echo "5. Espera 10 segundos"
echo "6. Vuelve a abrir WhatsApp"
echo "7. Desactiva WiFi, activa DATOS MÓVILES"
echo "8. Ve a: Dispositivos vinculados → Vincular un dispositivo"
echo "9. Abre: http://api1.checkin24hs.com:3001"
echo "10. Escanea el QR INMEDIATAMENTE (dentro de 2 minutos)"
echo "11. NO cierres WhatsApp durante la autenticación"
echo "12. Espera 2-5 minutos pacientemente"
echo ""
