#!/bin/bash

cd /root/checkin24hs

# Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró el contenedor"
    exit 1
fi

echo "=== Contenedor encontrado: $CONTAINER ==="

# Copiar archivo correcto
echo "=== Copiando dashboard.html correcto ==="
docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"

# Verificar que la línea 24521 tenga is_from_me
echo "=== Verificando línea 24521 ==="
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html

# Buscar TODAS las instancias de from_me (excepto comentarios y variables)
echo "=== Buscando instancias incorrectas de from_me ==="
docker exec "$CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//"

# Corregir cualquier instancia que quede
echo "=== Corrigiendo cualquier instancia restante ==="
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# Verificar nuevamente
echo "=== Verificación final ==="
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html
docker exec "$CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//"

# Reiniciar contenedor
echo "=== Reiniciando contenedor ==="
docker restart "$CONTAINER"

echo "Esperando 20 segundos..."
sleep 20

echo "✅ Completado"
echo ""
echo "⚠️ IMPORTANTE: En el navegador:"
echo "1. Cierra TODAS las pestañas del dashboard"
echo "2. Presiona Ctrl+Shift+Delete"
echo "3. Selecciona 'Cached images and files'"
echo "4. Selecciona 'All time'"
echo "5. Haz clic en 'Clear data'"
echo "6. Abre el dashboard en modo incógnito (Ctrl+Shift+N)"
echo "7. Presiona Ctrl+Shift+R para forzar recarga"


