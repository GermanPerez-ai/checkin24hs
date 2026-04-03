#!/bin/bash
# Actualiza cotizador y fuerza og:image con ?v=2 para cache de WhatsApp

echo "=========================================="
echo "🔄 ACTUALIZANDO COTIZADOR CON IMAGEN ?v=2"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_cotizador"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)
[ -z "$CONTAINER_ID" ] && { echo "❌ Contenedor no encontrado"; exit 1; }

TEMP_DIR="/tmp/cotizador_$(date +%s)"
mkdir -p "$TEMP_DIR" && cd "$TEMP_DIR"

echo "1️⃣ Clonando desde GitHub..."
git clone --depth 1 https://github.com/GermanPerez-ai/checkin24hs.git 2>&1 | tail -3

[ ! -f "checkin24hs/cotizador-cliente.html" ] && { echo "❌ cotizador-cliente.html no encontrado"; exit 1; }

cd checkin24hs

echo "2️⃣ Aplicando ?v=2 a URLs de imagen..."
# Asegurar que og:image y twitter:image tengan ?v=2
sed -i 's|og-cotizar.jpg"|og-cotizar.jpg?v=2"|g' cotizador-cliente.html
sed -i 's|og-cotizar.jpg?v=2?v=2"|og-cotizar.jpg?v=2"|g' cotizador-cliente.html

echo "3️⃣ Verificando..."
grep "og-cotizar.jpg" cotizador-cliente.html | head -2

echo ""
echo "4️⃣ Copiando al contenedor..."
docker cp cotizador-cliente.html "$CONTAINER_ID:/usr/share/nginx/html/index.html"

echo "5️⃣ Reiniciando servicio..."
docker service update --force "$SERVICE_NAME" > /dev/null 2>&1

cd / && rm -rf "$TEMP_DIR"

echo ""
echo "✅ Cotizador actualizado con og-cotizar.jpg?v=2"
echo ""
echo "Verifica: curl -s https://cotizar.checkin24hs.com/ | grep og-cotizar"
echo "Debe mostrar: og-cotizar.jpg?v=2"
echo ""
