#!/bin/bash
# Verificar acceso directo al servicio

SERVICE_NAME="checkin24hs_whatsapp"

echo "=== VERIFICANDO ACCESO DIRECTO ==="
echo ""

# Obtener contenedor
CONTAINER_ID=$(docker service ps $SERVICE_NAME --format "{{.ID}}" --no-trunc | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"

# Obtener IP
CONTAINER_IP=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
if [ -z "$CONTAINER_IP" ]; then
    echo "❌ No se pudo obtener IP"
    exit 1
fi

echo "IP: $CONTAINER_IP"
echo ""

# Probar acceso
echo "Probando http://$CONTAINER_IP:3001/api/status..."
curl -s -w "\nHTTP Status: %{http_code}\n" http://$CONTAINER_IP:3001/api/status | head -5

echo ""
echo "Si responde 200, el servicio funciona pero Traefik no lo enruta"
echo "Si no responde, el servicio tiene problemas"
