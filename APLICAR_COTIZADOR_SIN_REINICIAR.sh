#!/bin/bash
# Copia cotizador con ?v=2 SIN reiniciar el servicio (para que no se pierda el archivo)

echo "=========================================="
echo "🔄 APLICANDO COTIZADOR CON ?v=2 (sin reiniciar)"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_cotizador"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)
[ -z "$CONTAINER_ID" ] && { echo "❌ Contenedor no encontrado"; exit 1; }

echo "✅ Contenedor actual: $CONTAINER_ID"
echo ""

TEMP_DIR="/tmp/cotizador_$(date +%s)"
mkdir -p "$TEMP_DIR" && cd "$TEMP_DIR"

echo "1️⃣ Clonando desde GitHub..."
git clone --depth 1 https://github.com/GermanPerez-ai/checkin24hs.git 2>&1 | tail -3

[ ! -f "checkin24hs/cotizador-cliente.html" ] && { echo "❌ cotizador-cliente.html no encontrado"; exit 1; }

cd checkin24hs

echo "2️⃣ Aplicando ?v=2 a URLs de imagen..."
sed -i 's|og-cotizar.jpg"|og-cotizar.jpg?v=2"|g' cotizador-cliente.html
sed -i 's|og-cotizar.jpg?v=2?v=2"|og-cotizar.jpg?v=2"|g' cotizador-cliente.html

echo "3️⃣ Copiando al contenedor (SIN reiniciar servicio)..."
docker cp cotizador-cliente.html "$CONTAINER_ID:/usr/share/nginx/html/index.html"

cd / && rm -rf "$TEMP_DIR"

echo ""
echo "✅ Archivo copiado. No se reinició el servicio para que el cambio persista."
echo ""
echo "Verifica: curl -s https://cotizar.checkin24hs.com/ | grep og-cotizar"
echo "Debe mostrar: og-cotizar.jpg?v=2"
echo ""
