#!/bin/bash

echo "🔍 Diagnosticando el contenedor..."
echo ""

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró ningún contenedor activo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER"
echo ""

# Verificar si el archivo existe
echo "=== Verificando si el archivo existe ==="
docker exec $CONTAINER ls -lh /app/dashboard.html 2>/dev/null || echo "❌ Archivo no encontrado en /app/dashboard.html"

# Verificar otras ubicaciones posibles
echo ""
echo "=== Buscando dashboard.html en el contenedor ==="
docker exec $CONTAINER find / -name "dashboard.html" 2>/dev/null | head -5

# Verificar el contenido del archivo (primeras líneas)
echo ""
echo "=== Primeras líneas del archivo ==="
docker exec $CONTAINER head -20 /app/dashboard.html 2>/dev/null | grep -i "buildServerURL\|getServerURL" || echo "No se encontraron referencias"

# Verificar si hay un volumen montado
echo ""
echo "=== Verificando volúmenes montados ==="
docker inspect $CONTAINER --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' | grep -i dashboard || echo "No hay volúmenes relacionados con dashboard"

echo ""
echo "✅ Diagnóstico completado"








