#!/bin/bash

cd /root/checkin24hs

echo "=== Solución definitiva para el problema de caché ==="
echo ""

# 1. Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró el contenedor"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# 2. Copiar archivo correcto
echo "=== 1. Copiando archivo correcto ==="
docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"

# 3. Verificar y corregir línea 24521
echo ""
echo "=== 2. Verificando línea 24521 ==="
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html

# 4. Corregir TODAS las instancias de from_me
echo ""
echo "=== 3. Corrigiendo todas las instancias de from_me ==="
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# 5. Verificar corrección
echo ""
echo "=== 4. Verificación final ==="
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html
echo ""
echo "Buscando instancias incorrectas (NO debería aparecer nada):"
docker exec "$CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -5

# 6. Agregar timestamp al HTML para forzar recarga
echo ""
echo "=== 5. Agregando timestamp para forzar recarga del navegador ==="
TIMESTAMP=$(date +%s)
# Agregar parámetro de versión a los scripts
docker exec "$CONTAINER" sed -i "s|<script|<script data-version=\"$TIMESTAMP\"|g" /app/dashboard.html
docker exec "$CONTAINER" sed -i "s|supabase-client.js?v=|supabase-client.js?v=$TIMESTAMP\&|g" /app/dashboard.html

# 7. Reiniciar contenedor
echo ""
echo "=== 6. Reiniciando contenedor ==="
docker restart "$CONTAINER"

echo "Esperando 25 segundos..."
sleep 25

echo ""
echo "✅ COMPLETADO"
echo ""
echo "⚠️ IMPORTANTE - En TODAS las computadoras:"
echo "1. Cierra TODAS las pestañas del dashboard"
echo "2. Presiona Ctrl+Shift+Delete"
echo "3. Selecciona 'Cached images and files'"
echo "4. Selecciona 'All time'"
echo "5. Haz clic en 'Clear data'"
echo "6. Cierra completamente el navegador"
echo "7. Abre el navegador de nuevo"
echo "8. Abre el dashboard en modo incógnito (Ctrl+Shift+N)"
echo "9. Con DevTools abierto (F12), ve a Network"
echo "10. Marca 'Disable cache'"
echo "11. Recarga la página (F5)"


