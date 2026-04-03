#!/bin/bash

cd /root/checkin24hs

# Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró el contenedor"
    exit 1
fi

echo "=== Contenedor encontrado: $CONTAINER ==="

# 1. Copiar archivo correcto
echo "=== 1. Copiando dashboard.html correcto ==="
docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"

# 2. Verificar línea 24521 ANTES de corregir
echo "=== 2. Verificando línea 24521 ANTES ==="
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html

# 3. Buscar TODAS las instancias de from_me en select (sin is_)
echo "=== 3. Buscando instancias incorrectas de from_me ==="
docker exec "$CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -10

# 4. Corregir TODAS las instancias posibles (múltiples variaciones)
echo "=== 4. Corrigiendo todas las instancias ==="
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# 5. Verificar línea 24521 DESPUÉS de corregir
echo "=== 5. Verificando línea 24521 DESPUÉS ==="
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html

# 6. Verificar que NO hay más instancias incorrectas
echo "=== 6. Verificación final (NO debería aparecer nada) ==="
docker exec "$CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -5

# 7. Agregar timestamp al HTML para forzar recarga del navegador
echo "=== 7. Agregando timestamp para forzar recarga ==="
TIMESTAMP=$(date +%s)
docker exec "$CONTAINER" sed -i "s|<script|<script data-version=\"$TIMESTAMP\"|g" /app/dashboard.html

# 8. Reiniciar contenedor
echo "=== 8. Reiniciando contenedor ==="
docker restart "$CONTAINER"

echo "Esperando 25 segundos..."
sleep 25

echo ""
echo "✅ CORRECCIÓN COMPLETADA EN EL SERVIDOR"
echo ""
echo "⚠️ AHORA DEBES LIMPIAR EL CACHÉ DEL NAVEGADOR:"
echo ""
echo "OPCIÓN 1 (Recomendada - Chrome/Edge):"
echo "1. Abre DevTools (F12)"
echo "2. Ve a la pestaña 'Network' (Red)"
echo "3. Marca la casilla 'Disable cache' (Deshabilitar caché)"
echo "4. Cierra TODAS las pestañas del dashboard"
echo "5. Presiona Ctrl+Shift+Delete"
echo "6. Selecciona 'Cached images and files'"
echo "7. Selecciona 'All time'"
echo "8. Haz clic en 'Clear data'"
echo "9. Abre el dashboard en modo incógnito (Ctrl+Shift+N)"
echo "10. Con DevTools abierto y 'Disable cache' marcado, recarga (F5)"
echo ""
echo "OPCIÓN 2 (Si la opción 1 no funciona):"
echo "1. Cierra completamente el navegador"
echo "2. Elimina la carpeta de caché del navegador manualmente"
echo "3. Abre el navegador de nuevo"
echo "4. Abre el dashboard en modo incógnito"
