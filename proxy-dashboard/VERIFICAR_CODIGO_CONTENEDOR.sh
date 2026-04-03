#!/bin/bash

# Verificar si el código actualizado está en el contenedor

echo "=== Verificando código en el contenedor ==="
DASHBOARD_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)

if [ -z "$DASHBOARD_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor ID: $DASHBOARD_ID"
echo ""

# Verificar si tiene la lógica para cargar cotizaciones
echo "=== Verificando lógica de cotizaciones ==="
if docker exec $DASHBOARD_ID grep -q "if (section === 'quotes')" /app/dashboard.html 2>/dev/null; then
    echo "✅ El código tiene la lógica para cargar cotizaciones"
    docker exec $DASHBOARD_ID grep -A 5 "if (section === 'quotes')" /app/dashboard.html | head -10
else
    echo "❌ El código NO tiene la lógica para cargar cotizaciones"
    echo ""
    echo "=== Verificando versión del archivo ==="
    docker exec $DASHBOARD_ID ls -lh /app/dashboard.html 2>/dev/null
    echo ""
    echo "💡 Necesitas reconstruir la imagen o actualizar el servicio"
fi

echo ""
echo "=== Verificando lógica de gastos ==="
if docker exec $DASHBOARD_ID grep -q "if (section === 'expenses')" /app/dashboard.html 2>/dev/null; then
    echo "✅ El código tiene la lógica para cargar gastos"
else
    echo "❌ El código NO tiene la lógica para cargar gastos"
fi
