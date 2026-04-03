#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 ELIMINANDO CONSULTA DIRECTA CON FROM_ME"
echo "=========================================="
echo ""

DASHBOARD_CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $DASHBOARD_CONTAINER"
echo ""

# Crear backup
BACKUP_FILE="/app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
docker exec "$DASHBOARD_CONTAINER" cp /app/dashboard.html "$BACKUP_FILE" 2>/dev/null || true
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

# Buscar la línea problemática
echo "=== Buscando consulta problemática ==="
docker exec "$DASHBOARD_CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -10
echo ""

# Buscar el contexto alrededor de la línea 24515-24526
echo "=== Revisando contexto de la consulta ==="
docker exec "$DASHBOARD_CONTAINER" sed -n '24510,24535p' /app/dashboard.html
echo ""

# Buscar cualquier bloque try-catch que haga consultas directas ANTES de getWhatsAppMessages
echo "=== Buscando bloques problemáticos ==="
docker exec "$DASHBOARD_CONTAINER" awk '/Buscando mensajes para chat_id/,/getWhatsAppMessages/ {print NR": "$0}' /app/dashboard.html | head -20
echo ""

# Buscar consultas directas a whatsapp_messages que usen from_me
echo "=== Buscando consultas directas ==="
docker exec "$DASHBOARD_CONTAINER" grep -B 5 -A 5 "whatsapp_messages.*select.*from_me" /app/dashboard.html | head -20 || echo "No se encontraron consultas directas obvias"
echo ""

# Buscar cualquier línea que contenga una URL con from_me en el código
echo "=== Buscando URLs con from_me ==="
docker exec "$DASHBOARD_CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -10
echo ""

# Eliminar cualquier línea que contenga una consulta directa con from_me
echo "=== Eliminando consultas problemáticas ==="

# Buscar y eliminar líneas que contengan consultas directas con from_me
docker exec "$DASHBOARD_CONTAINER" sed -i '/\.select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true
docker exec "$DASHBOARD_CONTAINER" sed -i '/select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true
docker exec "$DASHBOARD_CONTAINER" sed -i '/whatsapp_messages.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true

# Reemplazar cualquier from_me restante con is_from_me
docker exec "$DASHBOARD_CONTAINER" sed -i 's/from_me\([^_]\)/is_from_me\1/g' /app/dashboard.html
docker exec "$DASHBOARD_CONTAINER" sed -i 's/from_me"/is_from_me"/g' /app/dashboard.html
docker exec "$DASHBOARD_CONTAINER" sed -i "s/from_me'/is_from_me'/g" /app/dashboard.html
docker exec "$DASHBOARD_CONTAINER" sed -i 's/from_me)/is_from_me)/g' /app/dashboard.html
docker exec "$DASHBOARD_CONTAINER" sed -i 's/from_me&/is_from_me&/g' /app/dashboard.html
docker exec "$DASHBOARD_CONTAINER" sed -i 's/from_me,/is_from_me,/g' /app/dashboard.html

echo "✅ Correcciones aplicadas"
echo ""

# Verificar que se eliminó
echo "=== Verificación final ==="
REMAINING=$(docker exec "$DASHBOARD_CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | wc -l)
if [ "$REMAINING" -eq 0 ]; then
    echo "✅ No quedan referencias problemáticas a from_me"
else
    echo "⚠️ Aún quedan $REMAINING referencias problemáticas:"
    docker exec "$DASHBOARD_CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -5
fi

# Verificar línea 24526 específicamente
echo ""
echo "=== Verificando línea 24526 ==="
docker exec "$DASHBOARD_CONTAINER" sed -n '24520,24530p' /app/dashboard.html
echo ""

# Reiniciar contenedor
echo "=== Reiniciando contenedor ==="
docker restart "$DASHBOARD_CONTAINER"
echo "⏳ Esperando 25 segundos..."
sleep 25
echo "✅ Completado"
echo ""

echo "=========================================="
echo "📋 INSTRUCCIONES"
echo "=========================================="
echo ""
echo "1. Limpia el caché del navegador (Ctrl+Shift+R)"
echo "2. Prueba seleccionar un chat"
echo "3. Verifica que no aparezca el error de 'from_me'"
echo ""


