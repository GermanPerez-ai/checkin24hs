#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔍 BUSCANDO Y ELIMINANDO CONSULTA DIRECTA CON FROM_ME"
echo "=========================================="
echo ""

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# Crear backup
BACKUP_FILE="/app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
docker exec "$CONTAINER" cp /app/dashboard.html "$BACKUP_FILE" 2>/dev/null || true
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

# Buscar TODAS las referencias a "verificación directa" o consultas con from_me
echo "=== Buscando código de 'verificación directa' ==="
docker exec "$CONTAINER" grep -n "verificación directa\|Error en verificación\|msgCheck\|checkError" /app/dashboard.html | head -10
echo ""

# Buscar consultas directas a whatsapp_messages con from_me
echo "=== Buscando consultas directas con from_me ==="
docker exec "$CONTAINER" grep -B 5 -A 5 "whatsapp_messages.*select.*from_me" /app/dashboard.html | head -20
echo ""

# Buscar cualquier línea que contenga una consulta con from_me ANTES de getWhatsAppMessages
echo "=== Buscando consultas ANTES de getWhatsAppMessages ==="
docker exec "$CONTAINER" awk '/Buscando mensajes para chat_id/,/getWhatsAppMessages/ {print NR": "$0}' /app/dashboard.html | grep -i "from_me\|select\|\.from\|whatsapp_messages" | head -20
echo ""

# Ver el contexto completo alrededor de la línea 24515-24530
echo "=== Contexto completo de líneas 24510-24535 ==="
docker exec "$CONTAINER" sed -n '24510,24535p' /app/dashboard.html
echo ""

# Buscar cualquier bloque try-catch que haga consultas directas
echo "=== Buscando bloques try-catch con consultas directas ==="
docker exec "$CONTAINER" awk '/try {/,/} catch/ {if (/whatsapp_messages/ || /from_me/) print NR": "$0}' /app/dashboard.html | head -30
echo ""

# Copiar archivo correcto
if [ -f "deploy/dashboard.html" ]; then
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    echo "✅ Archivo correcto copiado desde deploy/dashboard.html"
fi

# Eliminar TODAS las consultas problemáticas
echo ""
echo "=== Eliminando consultas problemáticas ==="
docker exec "$CONTAINER" sed -i '/select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true
docker exec "$CONTAINER" sed -i '/\.select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true
docker exec "$CONTAINER" sed -i '/whatsapp_messages.*select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true

# Reemplazar cualquier from_me restante
docker exec "$CONTAINER" sed -i 's/from_me\([^_]\)/is_from_me\1/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me"/is_from_me"/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/from_me'/is_from_me'/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me)/is_from_me)/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me,/is_from_me,/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me&/is_from_me&/g' /app/dashboard.html

echo "✅ Correcciones aplicadas"
echo ""

# Verificar que se eliminó
echo "=== Verificación final ==="
REMAINING=$(docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | wc -l)
if [ "$REMAINING" -eq 0 ]; then
    echo "✅ No quedan consultas problemáticas con 'from_me'"
else
    echo "⚠️ Aún quedan $REMAINING referencias problemáticas:"
    docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -10
fi

# Verificar línea 24526 específicamente
echo ""
echo "=== Verificando línea 24526 ==="
docker exec "$CONTAINER" sed -n '24520,24530p' /app/dashboard.html
echo ""

# Reiniciar contenedor
echo "=== Reiniciando contenedor ==="
docker restart "$CONTAINER"
sleep 25

echo ""
echo "=========================================="
echo "✅ COMPLETADO"
echo "=========================================="
echo ""
echo "📋 IMPORTANTE:"
echo "  1. Limpia COMPLETAMENTE el caché del navegador"
echo "  2. O mejor aún, abre en modo incógnito"
echo "  3. Prueba seleccionar un chat"
echo ""


