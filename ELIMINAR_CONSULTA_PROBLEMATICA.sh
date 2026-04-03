#!/bin/bash

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró el contenedor del dashboard"
    exit 1
fi

echo "=== Contenedor encontrado: $CONTAINER ==="
echo ""

# 1. Copiar archivo actualizado desde deploy/
echo "=== Copiando dashboard.html actualizado ==="
docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"

# 2. Buscar y eliminar cualquier consulta problemática con from_me
echo ""
echo "=== Buscando consultas problemáticas ==="
docker exec "$CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -10

# 3. Eliminar cualquier bloque de código que haga "verificación directa" con from_me
echo ""
echo "=== Eliminando consultas problemáticas ==="

# Buscar líneas que contengan la consulta problemática y eliminarlas
docker exec "$CONTAINER" sed -i '/verificación directa/,/Error en verificación directa/d' /app/dashboard.html 2>/dev/null || true

# Reemplazar cualquier instancia restante de from_me en select
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# 4. Verificar que se eliminó
echo ""
echo "=== Verificación final ==="
docker exec "$CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -5 || echo "✅ No se encontraron consultas problemáticas"

# 5. Verificar que la línea 24521 está correcta
echo ""
echo "=== Verificando línea 24521 ==="
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html

# 6. Reiniciar contenedor
echo ""
echo "=== Reiniciando contenedor ==="
docker restart "$CONTAINER"
echo "Esperando 25 segundos..."
sleep 25
echo "✅ Completado"


