#!/bin/bash
# Solucionar problema device_removed en Evolution API

cd /root/checkin24hs/evolution-api

API_KEY="checkin24hs-secret-key-2024"
BASE_URL="http://localhost:8081"

echo "🔧 SOLUCIONANDO PROBLEMA DEVICE_REMOVED"
echo "=============================================================="
echo ""
echo "⚠️  IMPORTANTE: Este problema ocurre cuando WhatsApp detecta"
echo "    múltiples sesiones activas en tu teléfono"
echo ""
echo "📋 PASOS OBLIGATORIOS ANTES DE CONTINUAR:"
echo ""
echo "   1. EN TU TELÉFONO:"
echo "      → Abre WhatsApp"
echo "      → Ve a Configuración → Dispositivos vinculados"
echo "      → DESVINCULA TODOS los dispositivos"
echo "      → Espera 1 minuto"
echo ""
echo "   2. Cierra WhatsApp Web si está abierto en tu computadora"
echo ""
echo "   3. Cierra y vuelve a abrir WhatsApp en tu teléfono"
echo ""
echo "   4. Espera 30 segundos más"
echo ""
read -p "¿Ya hiciste estos pasos? (s/n): " CONFIRM

if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
    echo ""
    echo "⚠️  Por favor, completa los pasos primero"
    echo "   Luego vuelve a ejecutar este script"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗑️  Limpiando instancias para empezar limpio..."
echo ""

# Eliminar todas las instancias
for i in 1 2 3 4; do
    echo "Eliminando whatsapp-${i}..."
    curl -s -X DELETE ${BASE_URL}/instance/delete/whatsapp-${i} \
      -H "apikey: ${API_KEY}" > /dev/null
    sleep 1
done

echo ""
echo "⏳ Esperando 5 segundos..."
sleep 5

echo ""
echo "📱 Recreando instancias limpias..."
echo ""

# Recrear instancias
for i in 1 2 3 4; do
    echo "Creando whatsapp-${i}..."
    curl -s -X POST ${BASE_URL}/instance/create \
      -H "apikey: ${API_KEY}" \
      -H "Content-Type: application/json" \
      -d "{
        \"instanceName\": \"whatsapp-${i}\",
        \"qrcode\": true,
        \"integration\": \"WHATSAPP-BAILEYS\"
      }" > /dev/null
    sleep 2
done

echo ""
echo "✅ Instancias recreadas"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 AHORA:"
echo ""
echo "   1. Abre el panel web:"
echo "      http://72.61.58.240:8081/manager"
echo ""
echo "   2. Haz clic en una instancia (ej: whatsapp-1)"
echo ""
echo "   3. Haz clic en 'Get QR Code'"
echo ""
echo "   4. INMEDIATAMENTE escanea el QR con WhatsApp"
echo "      (DENTRO DE LOS PRIMEROS 10 SEGUNDOS)"
echo ""
echo "   5. ESPERA 2-3 MINUTOS sin hacer nada"
echo "      - No desvincules desde el teléfono"
echo "      - No abras WhatsApp Web en otro lugar"
echo "      - Solo espera pacientemente"
echo ""
echo "   6. Si después de 3 minutos aún no conecta,"
echo "      comparte los logs con:"
echo "      docker logs evolution-api-checkin24hs --tail 30"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
