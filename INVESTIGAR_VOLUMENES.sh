#!/bin/bash

echo "=========================================="
echo "🔍 INVESTIGAR VOLÚMENES Y RUTA REAL"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Encontrar contenedor
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
echo "📦 Contenedor: $CONTAINER"
echo ""

# 2. Verificar volúmenes montados
echo "=== 1. VOLÚMENES MONTADOS ==="
docker inspect "$CONTAINER" --format '{{range .Mounts}}{{.Source}} -> {{.Destination}} ({{.Type}}){{"\n"}}{{end}}' 2>/dev/null
echo ""

# 3. Buscar todos los dashboard.html en el contenedor
echo "=== 2. TODOS LOS dashboard.html EN EL CONTENEDOR ==="
docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules
echo ""

# 4. Verificar cuál tiene header-left
echo "=== 3. VERIFICAR CUÁL TIENE header-left ==="
for path in $(docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules); do
    echo "📁 Verificando: $path"
    if docker exec "$CONTAINER" grep -q "header-left" "$path" 2>/dev/null; then
        echo "   ✅ TIENE header-left"
    else
        echo "   ❌ NO tiene header-left"
    fi
    echo ""
done

# 5. Verificar proceso del servicio (qué archivo está usando)
echo "=== 4. PROCESO DEL SERVICIO ==="
docker exec "$CONTAINER" ps aux | grep -E "node|npm|dashboard" | grep -v grep
echo ""

# 6. Verificar si hay archivo en /app
echo "=== 5. ARCHIVO EN /app ==="
docker exec "$CONTAINER" ls -lah /app/dashboard.html 2>/dev/null || echo "❌ No existe /app/dashboard.html"
echo ""

# 7. Verificar si el archivo local está en un volumen
echo "=== 6. VERIFICAR SI /root/checkin24hs ESTÁ MONTADO ==="
if docker inspect "$CONTAINER" --format '{{range .Mounts}}{{.Destination}}{{end}}' 2>/dev/null | grep -q "/root/checkin24hs\|/app"; then
    echo "⚠️  Hay un volumen montado que podría estar sobrescribiendo el archivo"
    docker inspect "$CONTAINER" --format '{{range .Mounts}}{{if or (eq .Destination "/app") (eq .Destination "/root/checkin24hs")}}{{.Source}} -> {{.Destination}}{{end}}{{end}}' 2>/dev/null
else
    echo "✅ No hay volumen montado en /app o /root/checkin24hs"
fi
echo ""

echo "=========================================="
echo "✅ Investigación completada"
echo "=========================================="
