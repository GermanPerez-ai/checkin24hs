#!/bin/bash

echo "🔄 REINICIANDO TRAEFIK"
echo "======================"
echo ""

# 1. Encontrar servicio Traefik
echo "1️⃣ Buscando servicio Traefik..."
TRAEFIK_SERVICE=$(docker service ls | grep -i traefik | awk '{print $1}' | head -1)
TRAEFIK_NAME=$(docker service ls | grep -i traefik | awk '{print $2}' | head -1)

if [ -z "$TRAEFIK_SERVICE" ]; then
    echo "❌ No se encontró servicio Traefik"
    echo "📋 Servicios disponibles:"
    docker service ls
    exit 1
fi

echo "✅ Traefik encontrado: $TRAEFIK_NAME ($TRAEFIK_SERVICE)"
echo ""

# 2. Reiniciar Traefik
echo "2️⃣ Reiniciando Traefik..."
docker service update --force $TRAEFIK_SERVICE

if [ $? -eq 0 ]; then
    echo "✅ Traefik reiniciado correctamente"
else
    echo "❌ Error al reiniciar Traefik"
    exit 1
fi
echo ""

# 3. Esperar a que Traefik se reinicie
echo "3️⃣ Esperando 30 segundos para que Traefik se reinicie completamente..."
sleep 30

# 4. Verificar estado de Traefik
echo "4️⃣ Verificando estado de Traefik..."
docker service ps $TRAEFIK_SERVICE --no-trunc | head -5
echo ""

# 5. Ver logs de Traefik
echo "5️⃣ Últimos logs de Traefik (últimas 20 líneas)..."
docker service logs $TRAEFIK_SERVICE --tail 20 2>&1 | tail -20
echo ""

echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "📋 Resumen:"
echo "   - Traefik: $TRAEFIK_NAME (reiniciado)"
echo ""
echo "⏳ PRÓXIMOS PASOS:"
echo "   1. Espera 1-2 minutos más para que Traefik detecte completamente los cambios"
echo "   2. Prueba acceder a: https://dashboard.checkin24hs.com/"
echo "   3. Si aún hay problemas, verifica los logs:"
echo "      docker service logs $TRAEFIK_NAME --tail 50"
echo ""
