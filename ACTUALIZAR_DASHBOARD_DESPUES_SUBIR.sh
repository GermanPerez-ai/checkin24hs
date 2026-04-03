#!/bin/bash
# Aplicar dashboard después de subir vía scp (o descarga GitHub).
# Ejecutar EN EL SERVIDOR. Asume dashboard.html en /root/checkin24hs/

echo "=========================================="
echo "  Aplicar dashboard actualizado"
echo "=========================================="
echo ""

BIND_MOUNT="/root/checkin24hs/dashboard.html"
SERVICE_NAME=""

# Buscar servicio dashboard
SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -i dashboard | grep -v proxy | head -1)

if [ -z "$SERVICE_NAME" ]; then
    echo "No se encontró servicio dashboard."
    echo "Servicios:"
    docker service ls --format "{{.Name}}" | head -15
    exit 1
fi

echo "Servicio: $SERVICE_NAME"
echo ""

# Verificar archivo
if [ -f "$BIND_MOUNT" ]; then
    BUILD=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "$BIND_MOUNT" 2>/dev/null | head -1)
    echo "Build en archivo: #${BUILD:-?}"
    SIZE=$(wc -c < "$BIND_MOUNT")
    echo "Tamaño: $SIZE bytes"
else
    echo "No se encuentra $BIND_MOUNT"
    echo "¿Usas bind mount? Si el dashboard está en el contenedor, usa REVISAR_Y_ACTUALIZAR_DASHBOARD.sh"
    exit 1
fi

echo ""
echo "Reiniciando servicio..."
docker service update --force $SERVICE_NAME >/dev/null 2>&1 || true
echo "OK"
echo ""

echo "Espera 30-60 segundos y verifica:"
echo "  https://dashboard.checkin24hs.com"
echo ""
echo "Comprobar build en vivo:"
echo "  curl -s -k -L https://dashboard.checkin24hs.com | grep -oP 'DASHBOARD_BUILD_NUMBER = \\K\\d+' | head -1"
echo ""
