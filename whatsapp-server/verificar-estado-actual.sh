#!/bin/bash
# ✅ Verificar Estado Actual del Servicio WhatsApp

echo "=============================================================="
echo "🔍 VERIFICANDO ESTADO ACTUAL DE WHATSAPP"
echo "=============================================================="
echo ""

# 1. Ver estado del API
echo "1️⃣  Estado del API:"
echo "--------------------------------------------------------------"
STATUS=$(curl -s http://localhost:3001/api/status 2>/dev/null)
if [ -n "$STATUS" ]; then
    echo "$STATUS" | python3 -m json.tool 2>/dev/null || echo "$STATUS"
else
    echo "❌ No se pudo obtener el estado"
fi
echo ""

# 2. Ver contenedor actual
echo "2️⃣  Contenedor actual:"
echo "--------------------------------------------------------------"
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | awk '{print $1}' | head -1)
if [ -n "$CONTAINER_ID" ]; then
    echo "   Contenedor: $CONTAINER_ID"
    echo "   Estado: $(docker ps | grep $CONTAINER_ID | awk '{print $7}')"
else
    echo "   ❌ No se encontró contenedor corriendo"
fi
echo ""

# 3. Ver logs más recientes
echo "3️⃣  Últimos 20 logs:"
echo "--------------------------------------------------------------"
docker service logs checkin24hs_whatsapp --tail 20 2>&1 | tail -20
echo ""

# 4. Buscar si está conectado
echo "4️⃣  Buscando estado de conexión:"
echo "--------------------------------------------------------------"
RECENT_LOGS=$(docker service logs checkin24hs_whatsapp --tail 100 2>&1)

if echo "$RECENT_LOGS" | grep -qi "conectado exitosamente"; then
    echo "   ✅ WhatsApp está conectado"
    PHONE=$(echo "$RECENT_LOGS" | grep -i "Teléfono conectado" | tail -1 | grep -oE "[0-9]+" | head -1)
    if [ -n "$PHONE" ]; then
        echo "   📱 Teléfono: $PHONE"
    fi
elif echo "$RECENT_LOGS" | grep -qi "QR escaneado"; then
    echo "   ⏳ QR escaneado, esperando autenticación..."
elif echo "$RECENT_LOGS" | grep -qi "QR Code generado"; then
    echo "   📱 QR disponible para escanear"
else
    echo "   ⚠️  Estado desconocido"
fi
echo ""

# 5. Verificar si hay sesión
echo "5️⃣  Verificando sesión:"
echo "--------------------------------------------------------------"
if [ -n "$CONTAINER_ID" ]; then
    AUTH_EXISTS=$(docker exec $CONTAINER_ID test -d /app/auth_info_baileys_1 && echo "yes" || echo "no")
    if [ "$AUTH_EXISTS" = "yes" ]; then
        echo "   ✅ Sesión existe"
        AUTH_SIZE=$(docker exec $CONTAINER_ID du -sh /app/auth_info_baileys_1 2>/dev/null | cut -f1)
        echo "   💾 Tamaño: $AUTH_SIZE"
    else
        echo "   ❌ No hay sesión (necesita escanear QR)"
    fi
fi
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
