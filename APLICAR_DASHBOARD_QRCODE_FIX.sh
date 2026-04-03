#!/bin/bash
# Script para aplicar corrección de QRCode a todos los contenedores del dashboard

cd /root/checkin24hs

echo "=== APLICANDO CORRECCIÓN DE QRCODE ==="
echo ""

# Aplicar a todos los contenedores activos
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do
    echo "Aplicando a $container..."
    docker cp deploy/dashboard.html $container:/app/dashboard.html
    docker restart $container >/dev/null 2>&1
    sleep 2
    echo "✅ $container actualizado"
done

echo ""
echo "=== VERIFICACIÓN ==="
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do
    echo "✅ $container: Activo"
done

echo ""
echo "✅ Corrección aplicada a todos los contenedores"
echo ""
echo "Ahora recarga la página del dashboard y prueba generar el QR code."








