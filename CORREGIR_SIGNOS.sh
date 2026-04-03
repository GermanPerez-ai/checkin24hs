#!/bin/bash
DASHBOARD_PATH="/root/checkin24hs/dashboard.html"
BACKUP_FILE="/root/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

echo "=== Crear backup ==="
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup: $BACKUP_FILE"
echo ""

echo "=== Corregir codificación UTF-8 ==="
sed -i 's/verificaciÃ³n/verificación/g' "$DASHBOARD_PATH"
sed -i 's/funciÃ³n/función/g' "$DASHBOARD_PATH"
sed -i 's/estÃ¡/está/g' "$DASHBOARD_PATH"
sed -i 's/cargÃ³/cargó/g' "$DASHBOARD_PATH"
sed -i 's/contraseÃ±a/contraseña/g' "$DASHBOARD_PATH"
sed -i 's/cÃ³digo/código/g' "$DASHBOARD_PATH"
sed -i 's/nuevo estÃ¡/nuevo está/g' "$DASHBOARD_PATH"
sed -i 's/NO se cargÃ³/NO se cargó/g' "$DASHBOARD_PATH"
echo "✅ Codificación corregida"
echo ""

echo "=== Corregir signos '?' ==="
sed -i "s/console\.log('? Variable/console.log('✅ Variable/g" "$DASHBOARD_PATH"
sed -i "s/console\.log('??/console.log('🔍/g" "$DASHBOARD_PATH"
sed -i 's/console\.log("??/console.log("🔍/g' "$DASHBOARD_PATH"
sed -i "s/console\.log('? Todas/console.log('✅ Todas/g" "$DASHBOARD_PATH"
sed -i "s/console\.error('? Variable/console.error('⚠️ Variable/g" "$DASHBOARD_PATH"
echo "✅ Signos '?' corregidos"
echo ""

echo "=== Copiar al contenedor ==="
CONTAINER=$(docker service ps checkin24hs_dashboard --format "{{.Name}}" --no-trunc | head -1)
if [ -n "$CONTAINER" ]; then
    docker cp "$DASHBOARD_PATH" "$CONTAINER:/app/dashboard.html"
    echo "✅ Copiado al contenedor: $CONTAINER"
else
    echo "⚠️  Contenedor no encontrado"
fi
echo ""

echo "=== Reiniciar servicio ==="
docker service update --force checkin24hs_dashboard
echo "✅ Servicio reiniciado"
echo ""

echo "✅ Corrección completada"
echo "Recarga la página con Ctrl+F5"
