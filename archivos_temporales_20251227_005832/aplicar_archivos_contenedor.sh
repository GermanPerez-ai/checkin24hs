#!/bin/bash

echo "=========================================="
echo "Aplicar archivos al contenedor Docker"
echo "=========================================="
echo ""

cd /root/checkin24hs

# Buscar contenedor
echo "1. Buscando contenedor..."
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "⚠️  No se encontró contenedor corriendo. Esperando 5 segundos..."
    sleep 5
    CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor después de esperar"
    echo "Verifica que el servicio esté corriendo:"
    docker service ls | grep dashboard
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# Copiar archivos
echo "2. Copiando archivos al contenedor..."

docker cp dashboard.html $CONTAINER_ID:/app/dashboard.html
if [ $? -eq 0 ]; then
    echo "   ✅ dashboard.html copiado"
else
    echo "   ❌ Error al copiar dashboard.html"
    exit 1
fi

docker cp supabase-client.js $CONTAINER_ID:/app/supabase-client.js
if [ $? -eq 0 ]; then
    echo "   ✅ supabase-client.js copiado"
else
    echo "   ⚠️  Advertencia: Error al copiar supabase-client.js"
fi

docker cp supabase-config.js $CONTAINER_ID:/app/supabase-config.js
if [ $? -eq 0 ]; then
    echo "   ✅ supabase-config.js copiado"
else
    echo "   ⚠️  Advertencia: Error al copiar supabase-config.js"
fi

echo ""

# Verificar archivos
echo "3. Verificando archivos en el contenedor:"
docker exec $CONTAINER_ID ls -lh /app/dashboard.html /app/supabase-client.js /app/supabase-config.js 2>/dev/null || echo "   ⚠️  Algunos archivos no se encontraron"

echo ""

# Reiniciar servicio
echo "4. Reiniciando servicio..."
docker service update --force checkin24hs_dashboard

if [ $? -eq 0 ]; then
    echo "✅ Servicio reiniciado"
else
    echo "❌ Error al reiniciar el servicio"
    exit 1
fi

echo ""
echo "Esperando 15 segundos para que el servicio se inicie..."
sleep 15

echo ""
echo "5. Verificando estado del servicio:"
docker service ps checkin24hs_dashboard --no-trunc | head -3

echo ""
echo "6. Probando acceso:"
curl -s -I http://localhost:3000 | head -5

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "Ahora prueba acceder a:"
echo "  - http://72.61.58.240:3000"
echo "  - http://dashboard.checkin24hs.com"
echo ""

