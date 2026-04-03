#!/bin/bash
# Solución completa para el 404 con EasyPanel

echo "=== SOLUCIÓN COMPLETA PARA ERROR 404 ==="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"
DOMAIN="whatsapp.checkin24hs.com"

# 1. Verificar nombre exacto del servicio
echo "1️⃣ Nombre del servicio..."
echo "=========================================="
docker service ls --format "{{.Name}}" | grep whatsapp

# 2. Verificar si el servicio está en la red easypanel
echo ""
echo "2️⃣ Verificando red easypanel..."
echo "=========================================="
NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}')
echo "$NETWORKS" | while read net; do
    net_name=$(docker network inspect $net --format '{{.Name}}' 2>/dev/null)
    echo "   $net -> $net_name"
done

# 3. Verificar puerto
echo ""
echo "3️⃣ Puerto del servicio..."
echo "=========================================="
PORT=$(docker service inspect $SERVICE_NAME --format '{{range .Endpoint.Ports}}{{.TargetPort}}{{end}}' 2>/dev/null | head -1)
echo "Puerto: ${PORT:-3001}"

# 4. Verificar acceso directo
echo ""
echo "4️⃣ Verificando acceso directo..."
echo "=========================================="
FIRST_NETWORK=$(echo "$NETWORKS" | head -1)
if [ -n "$FIRST_NETWORK" ]; then
    echo "Probando desde red: $FIRST_NETWORK"
    docker run --rm --network $FIRST_NETWORK curlimages/curl:latest curl -s -w "\nHTTP Status: %{http_code}\n" http://${SERVICE_NAME}:${PORT:-3001}/api/status | head -3
fi

echo ""
echo "=========================================="
echo "📋 INSTRUCCIONES PARA EASYPANEL"
echo "=========================================="
echo ""
echo "El problema es que EasyPanel no está aplicando la configuración del dominio a Traefik."
echo ""
echo "SOLUCIÓN:"
echo "1. Ve a EasyPanel → Servicio 'whatsapp' → Pestaña 'Dominios'"
echo "2. ELIMINA el dominio 'whatsapp.checkin24hs.com'"
echo "3. Espera 30 segundos"
echo "4. AGREGA el dominio de nuevo:"
echo "   - Host: whatsapp.checkin24hs.com"
echo "   - Ruta: /"
echo "   - Protocolo: HTTP"
echo "   - Puerto: ${PORT:-3001}"
echo "   - Ruta destino: /"
echo "5. GUARDA los cambios"
echo "6. Espera 2-3 minutos"
echo ""
echo "Si después de esto sigue dando 404, puede ser que EasyPanel necesite:"
echo "- Un campo 'Target Service' que apunte a: $SERVICE_NAME"
echo "- O que el servicio tenga un nombre diferente en EasyPanel"
echo ""
