#!/bin/bash
# Verificar si el servicio responde directamente

echo "=== VERIFICANDO ACCESO DIRECTO AL SERVICIO ==="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# 1. Obtener información del contenedor
echo "1️⃣ Información del contenedor..."
CONTAINER_ID=$(docker service ps $SERVICE_NAME --format "{{.ID}}" --no-trunc | head -1)
if [ -n "$CONTAINER_ID" ]; then
    echo "✅ Contenedor ID: $CONTAINER_ID"
    
    # Obtener IP del contenedor
    CONTAINER_IP=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
    if [ -n "$CONTAINER_IP" ]; then
        echo "✅ IP del contenedor: $CONTAINER_IP"
        
        echo ""
        echo "2️⃣ Probando acceso directo al servicio (puerto 3001)..."
        echo "=========================================="
        # Intentar acceder directamente
        curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://$CONTAINER_IP:3001/api/status || echo "   ❌ No se pudo conectar"
        
        echo ""
        echo "3️⃣ Probando desde dentro de la red Docker..."
        echo "=========================================="
        # Intentar desde un contenedor temporal en la misma red
        NETWORK=$(docker inspect $CONTAINER_ID --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' 2>/dev/null | head -1)
        if [ -n "$NETWORK" ]; then
            echo "   Red: $NETWORK"
            echo "   Probando acceso..."
            docker run --rm --network $NETWORK curlimages/curl:latest curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://$CONTAINER_IP:3001/api/status || echo "   ❌ No se pudo conectar"
        fi
    else
        echo "⚠️  No se pudo obtener IP del contenedor"
    fi
else
    echo "❌ No se encontró contenedor del servicio"
fi

# 4. Verificar puertos publicados
echo ""
echo "4️⃣ Puertos publicados del servicio..."
echo "=========================================="
docker service inspect $SERVICE_NAME --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}} ({{.Protocol}}){{println}}{{end}}'

# 5. Verificar logs del servicio
echo ""
echo "5️⃣ Últimos logs del servicio..."
echo "=========================================="
docker service logs $SERVICE_NAME --tail 10 2>&1 | tail -5

echo ""
echo "=========================================="
echo "📋 INTERPRETACIÓN"
echo "=========================================="
echo ""
echo "Si el servicio responde directamente pero Traefik da 404:"
echo "   → El problema es de configuración de Traefik/EasyPanel"
echo ""
echo "Si el servicio NO responde directamente:"
echo "   → El problema es del servicio mismo"
echo ""
