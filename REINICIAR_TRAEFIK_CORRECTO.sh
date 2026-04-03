#!/bin/bash
# Reiniciar Traefik correctamente

echo "=== REINICIANDO TRAEFIK ==="
echo ""

# Buscar el servicio de Traefik
echo "1️⃣ Buscando servicio de Traefik..."
TRAEFIK_SERVICE=$(docker service ls --format "{{.Name}}" | grep -i traefik | head -1)

if [ -z "$TRAEFIK_SERVICE" ]; then
    echo "❌ No se encontró servicio de Traefik"
    echo ""
    echo "Servicios disponibles:"
    docker service ls --format "{{.Name}}" | head -10
    exit 1
fi

echo "✅ Servicio encontrado: $TRAEFIK_SERVICE"
echo ""
echo "2️⃣ Reiniciando Traefik..."
docker service update --force $TRAEFIK_SERVICE

if [ $? -eq 0 ]; then
    echo "✅ Traefik reiniciado"
    echo ""
    echo "⏳ Espera 30-60 segundos para que Traefik se reinicie y detecte los servicios"
else
    echo "❌ Error al reiniciar Traefik"
    exit 1
fi

echo ""
echo "3️⃣ Verificando estado de Traefik..."
sleep 5
docker service ls | grep -i traefik

echo ""
echo "✅ Proceso completado"
echo ""
echo "Ahora espera 1-2 minutos y prueba:"
echo "   https://whatsapp.checkin24hs.com/status"
echo "   https://whatsapp.checkin24hs.com/qr"
echo ""
