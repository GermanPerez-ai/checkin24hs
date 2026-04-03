#!/bin/bash
# Verificar acceso al servicio en Docker Swarm

SERVICE_NAME="checkin24hs_whatsapp"

echo "=== VERIFICANDO ACCESO AL SERVICIO ==="
echo ""

# 1. Verificar estado del servicio
echo "1️⃣ Estado del servicio..."
docker service ls | grep "$SERVICE_NAME"

# 2. Obtener información del contenedor
echo ""
echo "2️⃣ Información del contenedor..."
CONTAINER_NAME=$(docker service ps $SERVICE_NAME --format "{{.Name}}" --no-trunc | head -1)
echo "Nombre del contenedor: $CONTAINER_NAME"

# 3. Obtener redes del servicio
echo ""
echo "3️⃣ Redes del servicio..."
NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}')
echo "$NETWORKS"

# 4. Probar acceso usando el nombre del servicio en la red
echo ""
echo "4️⃣ Probando acceso usando nombre del servicio..."
# Intentar desde un contenedor temporal en la misma red
FIRST_NETWORK=$(echo "$NETWORKS" | head -1)
if [ -n "$FIRST_NETWORK" ]; then
    echo "   Red: $FIRST_NETWORK"
    echo "   Probando http://${SERVICE_NAME}:3001/api/status..."
    docker run --rm --network $FIRST_NETWORK curlimages/curl:latest curl -s -w "\nHTTP Status: %{http_code}\n" http://${SERVICE_NAME}:3001/api/status | head -10
else
    echo "   ⚠️  No se encontró red"
fi

# 5. Verificar puertos
echo ""
echo "5️⃣ Puertos del servicio..."
docker service inspect $SERVICE_NAME --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}} ({{.Protocol}}){{println}}{{end}}'

# 6. Verificar logs recientes
echo ""
echo "6️⃣ Últimos logs..."
docker service logs $SERVICE_NAME --tail 5 2>&1 | tail -3

echo ""
echo "=========================================="
echo "📋 INTERPRETACIÓN"
echo "=========================================="
echo ""
echo "Si el servicio responde (HTTP 200):"
echo "   → El servicio funciona, el problema es Traefik/EasyPanel"
echo ""
echo "Si el servicio NO responde:"
echo "   → Revisa los logs del servicio"
echo ""
