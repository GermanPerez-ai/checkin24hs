#!/bin/bash

cd /root/checkin24hs

echo "🔍 Verificando sintaxis alrededor de línea 21403..."
python3 << 'PYEOF'
file_path = "deploy/dashboard.html"
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

start = max(0, 21400 - 5)
end = min(len(lines), 21410)

print(f"\n📋 Líneas {start+1} a {end}:")
for i in range(start, end):
    line = lines[i]
    if '<' in line and 'script' not in line.lower() and 'html' not in line.lower() and 'console' not in line.lower():
        print(f"⚠️ Línea {i+1} tiene '<' sospechoso: {line.strip()[:100]}")
    else:
        print(f"✅ Línea {i+1}: {line.strip()[:80]}")
PYEOF

echo ""
echo "📤 Actualizando contenedor..."

CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor dashboard"
    exit 1
fi

DASHBOARD_PATH="/app/dashboard.html"
docker exec $CONTAINER_ID test -f "$DASHBOARD_PATH" || DASHBOARD_PATH="/usr/share/nginx/html/dashboard.html"

echo "📦 Contenedor: $CONTAINER_ID"
echo "📁 Ruta: $DASHBOARD_PATH"

echo "📤 Copiando archivo..."
docker cp deploy/dashboard.html "${CONTAINER_ID}:${DASHBOARD_PATH}"

echo "🔄 Reiniciando contenedor..."
docker restart $CONTAINER_ID
sleep 5

echo "✅ Verificando en contenedor..."
docker exec $CONTAINER_ID head -n 21410 "$DASHBOARD_PATH" | tail -n 10

echo ""
echo "✅ Actualización completada"


