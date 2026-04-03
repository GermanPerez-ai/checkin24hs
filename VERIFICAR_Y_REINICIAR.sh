#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICAR Y REINICIAR"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Encontrar contenedor
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
DASHBOARD_PATH="/app/dashboard.html"

echo "📦 Contenedor: $CONTAINER"
echo "📁 Ruta: $DASHBOARD_PATH"
echo ""

# 2. Verificar que tiene header-left
echo "=== 1. VERIFICAR COPIA ==="
if docker exec "$CONTAINER" grep -q "header-left" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ El archivo en el contenedor tiene 'header-left'"
    docker exec "$CONTAINER" grep -c "header-left" "$DASHBOARD_PATH" 2>/dev/null
else
    echo "❌ El archivo en el contenedor NO tiene 'header-left'"
fi
echo ""

# 3. Verificar '??' problemáticos (que no sean operadores JavaScript)
echo "=== 2. VERIFICAR '??' PROBLEMÁTICOS ==="
# Buscar '??' que no sean operadores JavaScript (como ?? en console.log sin contexto)
PROBLEMATICOS=$(docker exec "$CONTAINER" grep -n "??" "$DASHBOARD_PATH" 2>/dev/null | grep -v "console.log.*??" | grep -v "??.*console.log" | grep -v "??=" | grep -v "??\s*:" | head -5)
if [ -n "$PROBLEMATICOS" ]; then
    echo "⚠️  Se encontraron '??' que podrían ser problemáticos:"
    echo "$PROBLEMATICOS"
else
    echo "✅ Los '??' encontrados parecen ser operadores JavaScript válidos"
fi
echo ""

# 4. Reiniciar contenedor
echo "=== 3. REINICIAR CONTENEDOR ==="
echo "🔄 Reiniciando contenedor..."
docker restart "$CONTAINER"
if [ $? -eq 0 ]; then
    echo "✅ Contenedor reiniciado exitosamente"
else
    echo "❌ Error al reiniciar contenedor"
    exit 1
fi
echo ""

# 5. Esperar a que el servicio se levante
echo "=== 4. ESPERAR SERVICIO ==="
echo "⏳ Esperando 15 segundos para que el servicio se levante..."
sleep 15
echo "✅ Servicio debería estar funcionando"
echo ""

echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "📋 Próximos pasos:"
echo "1. Abre https://dashboard.checkin24hs.com"
echo "2. Presiona Ctrl+F5 (forzar recarga sin caché)"
echo "3. Verifica que el header está horizontal"
echo "4. Verifica los textos (si aún hay '??' problemáticos, necesitamos subir el archivo desde tu computadora)"
echo ""
