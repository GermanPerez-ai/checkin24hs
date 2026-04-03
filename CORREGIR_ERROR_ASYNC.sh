#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "CORRECCIÓN DE ERROR ASYNC EN DASHBOARD"
echo "=========================================="
echo ""

# 1. Verificar archivo en servidor
echo "1. Verificando archivo en servidor..."
if grep -q "async function showWhatsAppConfig" deploy/dashboard.html; then
    echo "✅ Archivo en servidor tiene 'async function'"
else
    echo "❌ ERROR: Archivo en servidor NO tiene 'async function'"
    exit 1
fi

echo ""
echo "Línea 9005 en servidor:"
sed -n '9005p' deploy/dashboard.html
echo ""

# 2. Verificar archivo en contenedor
echo "2. Verificando archivo en contenedor..."
CONTAINER=$(docker ps --format '{{.Names}}' | grep checkin24hs_dashboard | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró ningún contenedor activo"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo "Línea 9005 en contenedor:"
docker exec $CONTAINER sed -n '9005p' /app/dashboard.html

if docker exec $CONTAINER grep -q "async function showWhatsAppConfig" /app/dashboard.html; then
    echo "✅ Contenedor tiene 'async function'"
    echo ""
    echo "⚠️ El problema podría ser caché del navegador."
    echo "Intenta: Ctrl+Shift+Delete para limpiar caché, luego Ctrl+Shift+R"
    exit 0
else
    echo "❌ Contenedor NO tiene 'async function' - Necesita corrección"
fi

echo ""
echo "3. Aplicando corrección..."

# Detener todos los contenedores
echo "   Deteniendo contenedores..."
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard") 2>/dev/null
sleep 3

# Copiar archivo a todos los contenedores
echo "   Copiando archivo corregido..."
CONTAINERS=$(docker ps -a --format '{{.Names}}' | grep checkin24hs_dashboard)
COUNT=0
for c in $CONTAINERS; do
    docker cp deploy/dashboard.html $c:/app/dashboard.html
    echo "   ✅ Copiado a $c"
    COUNT=$((COUNT + 1))
done

echo "   Total contenedores actualizados: $COUNT"

# Reiniciar contenedores
echo "   Reiniciando contenedores..."
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard") 2>/dev/null
sleep 5

# Verificar corrección
echo ""
echo "4. Verificando corrección..."
NEW_CONTAINER=$(docker ps --format '{{.Names}}' | grep checkin24hs_dashboard | head -1)
echo "Línea 9005 en contenedor actualizado:"
docker exec $NEW_CONTAINER sed -n '9005p' /app/dashboard.html

if docker exec $NEW_CONTAINER grep -q "async function showWhatsAppConfig" /app/dashboard.html; then
    echo "✅ CORRECCIÓN APLICADA EXITOSAMENTE"
else
    echo "❌ ERROR: La corrección no se aplicó correctamente"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
