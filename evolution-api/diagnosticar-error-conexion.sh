#!/bin/bash

cd /root/checkin24hs/evolution-api

API_KEY="checkin24hs-secret-key-2024"
BASE_URL="http://localhost:8081"

echo "🔍 DIAGNÓSTICO: ERROR AL INICIAR SESIÓN"
echo "========================================"
echo ""

echo "1️⃣  Verificando estado de las instancias..."
echo ""

# Ver todas las instancias
INSTANCES=$(curl -s -X GET ${BASE_URL}/instance/fetchInstances \
  -H "apikey: ${API_KEY}" 2>/dev/null)

echo "📱 Instancias encontradas:"
echo "$INSTANCES" | grep -o '"instanceName":"[^"]*"' | sed 's/"instanceName":"//g' | sed 's/"//g' | nl -w2 -s'. '
echo ""

# Verificar estado de cada instancia
for i in 1 2 3 4; do
    INSTANCE_NAME="whatsapp-${i}"
    if echo "$INSTANCES" | grep -q "$INSTANCE_NAME"; then
        echo "📋 Estado de ${INSTANCE_NAME}:"
        echo "$INSTANCES" | grep -A 20 "\"instanceName\":\"$INSTANCE_NAME\"" | grep -E "status|state|connection" | head -5
        echo ""
    fi
done

echo ""
echo "2️⃣  Verificando logs del contenedor (últimos errores)..."
echo ""

# Buscar errores específicos en logs
echo "🔍 Buscando errores 'device_removed' o '401':"
docker logs evolution-api-checkin24hs 2>&1 | grep -iE "device_removed|401|conflict|stream errored" | tail -10
echo ""

echo "🔍 Buscando errores de conexión:"
docker logs evolution-api-checkin24hs 2>&1 | grep -iE "connection|timeout|failed|error" | tail -10
echo ""

echo ""
echo "3️⃣  Verificando logs en tiempo real..."
echo ""
echo "⚠️  Intenta conectar WhatsApp AHORA (escanear QR)"
echo "   Mientras tanto, veré los logs en tiempo real..."
echo "   (Presiona Ctrl+C después de intentar conectar)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Monitorear logs en tiempo real
docker logs -f evolution-api-checkin24hs 2>&1 | grep -iE "device_removed|401|conflict|stream|connection|connecting|open|close|error" --line-buffered
