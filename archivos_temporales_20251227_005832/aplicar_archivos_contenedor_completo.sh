#!/bin/bash

echo "=========================================="
echo "Aplicar archivos al contenedor Docker"
echo "=========================================="
echo ""

cd /root/checkin24hs

# Verificar que los archivos existen
echo "1. Verificando archivos locales..."
if [ ! -f "dashboard.html" ]; then
    echo "❌ Error: dashboard.html no existe"
    exit 1
fi
if [ ! -f "supabase-client.js" ]; then
    echo "❌ Error: supabase-client.js no existe"
    exit 1
fi
if [ ! -f "supabase-config.js" ]; then
    echo "⚠️  Advertencia: supabase-config.js no existe"
fi

echo "✅ Archivos verificados"
ls -lh dashboard.html supabase-client.js supabase-config.js 2>/dev/null
echo ""

# Buscar contenedor
echo "2. Buscando contenedor..."
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
echo "3. Copiando archivos al contenedor..."

echo "   Copiando dashboard.html..."
docker cp dashboard.html $CONTAINER_ID:/app/dashboard.html
if [ $? -eq 0 ]; then
    echo "   ✅ dashboard.html copiado"
else
    echo "   ❌ Error al copiar dashboard.html"
    exit 1
fi

echo "   Copiando supabase-client.js..."
docker cp supabase-client.js $CONTAINER_ID:/app/supabase-client.js
if [ $? -eq 0 ]; then
    echo "   ✅ supabase-client.js copiado"
else
    echo "   ⚠️  Advertencia: Error al copiar supabase-client.js"
fi

if [ -f "supabase-config.js" ]; then
    echo "   Copiando supabase-config.js..."
    docker cp supabase-config.js $CONTAINER_ID:/app/supabase-config.js
    if [ $? -eq 0 ]; then
        echo "   ✅ supabase-config.js copiado"
    else
        echo "   ⚠️  Advertencia: Error al copiar supabase-config.js"
    fi
fi

echo ""

# Verificar archivos en el contenedor
echo "4. Verificando archivos en el contenedor:"
docker exec $CONTAINER_ID ls -lh /app/dashboard.html /app/supabase-client.js /app/supabase-config.js 2>/dev/null || echo "   ⚠️  Algunos archivos no se encontraron"

echo ""

# Reiniciar servicio
echo "5. Reiniciando servicio..."
docker service update --force checkin24hs_dashboard

if [ $? -eq 0 ]; then
    echo "✅ Servicio reiniciado"
else
    echo "❌ Error al reiniciar el servicio"
    exit 1
fi

echo ""
echo "Esperando 20 segundos para que el servicio se inicie completamente..."
sleep 20

echo ""
echo "6. Verificando estado del servicio:"
docker service ps checkin24hs_dashboard --no-trunc | head -5

echo ""
echo "7. Probando acceso HTTP:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Servidor respondiendo correctamente (HTTP $HTTP_CODE)"
else
    echo "   ⚠️  Servidor respondió con código HTTP $HTTP_CODE"
fi

echo ""
echo "8. Verificando tamaño del HTML servido:"
HTML_SIZE=$(curl -s http://localhost:3000 | wc -c)
echo "   Tamaño: $HTML_SIZE bytes"
if [ "$HTML_SIZE" -gt "1000000" ]; then
    echo "   ✅ El HTML tiene el tamaño correcto (>1MB)"
else
    echo "   ⚠️  El HTML es muy pequeño, puede que no se haya aplicado correctamente"
fi

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "Ahora prueba acceder a:"
echo "  - http://72.61.58.240:3000"
echo "  - http://dashboard.checkin24hs.com"
echo ""

