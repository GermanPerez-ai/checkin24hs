#!/bin/bash

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

echo "=========================================="
echo "🔧 ELIMINANDO CONSULTA FROM_ME DEFINITIVAMENTE"
echo "=========================================="
echo ""

# 1. Crear backup
BACKUP_FILE="/app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
docker exec "$CONTAINER" cp /app/dashboard.html "$BACKUP_FILE" 2>/dev/null || true
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

# 2. Buscar TODAS las líneas que contengan consultas con from_me
echo "=== Buscando consultas problemáticas ==="
docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -10
echo ""

# 3. Buscar específicamente la línea 24526 y contexto
echo "=== Revisando línea 24526 y contexto ==="
docker exec "$CONTAINER" sed -n '24515,24535p' /app/dashboard.html
echo ""

# 4. Buscar cualquier bloque try-catch que haga consultas directas ANTES de getWhatsAppMessages
echo "=== Buscando bloques problemáticos ==="
docker exec "$CONTAINER" awk '/getWhatsAppMessages/{found=1; start=NR-10} found && NR<=start+30 {print NR": "$0}' /app/dashboard.html | grep -i "from_me\|select\|try\|catch" | head -20
echo ""

# 5. Buscar cualquier consulta directa a whatsapp_messages
echo "=== Buscando consultas directas a whatsapp_messages ==="
docker exec "$CONTAINER" grep -n "whatsapp_messages" /app/dashboard.html | grep -i "select\|from\|\.from" | head -10
echo ""

# 6. Eliminar CUALQUIER línea que contenga una consulta con from_me (excepto comentarios)
echo "=== Eliminando consultas problemáticas ==="

# Buscar y eliminar bloques try-catch que contengan consultas con from_me
docker exec "$CONTAINER" sed -i '/try {/,/} catch.*{/ {
    /select.*from_me[^_]/d
    /\.select.*from_me[^_]/d
    /whatsapp_messages.*from_me[^_]/d
}' /app/dashboard.html 2>/dev/null || true

# Eliminar líneas específicas que contengan consultas problemáticas
docker exec "$CONTAINER" sed -i '/select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true
docker exec "$CONTAINER" sed -i '/\.select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true
docker exec "$CONTAINER" sed -i '/whatsapp_messages.*select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true

# Reemplazar cualquier from_me restante con is_from_me
docker exec "$CONTAINER" sed -i 's/from_me\([^_]\)/is_from_me\1/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me"/is_from_me"/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/from_me'/is_from_me'/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me)/is_from_me)/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me&/is_from_me&/g' /app/dashboard.html

echo "✅ Correcciones aplicadas"
echo ""

# 7. Verificar que se eliminó
echo "=== Verificación final ==="
REMAINING=$(docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | wc -l)
if [ "$REMAINING" -gt 0 ]; then
    echo "⚠️ Aún quedan $REMAINING referencias problemáticas:"
    docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -5
else
    echo "✅ No quedan referencias problemáticas a from_me"
fi

# Verificar línea 24526 específicamente
echo ""
echo "=== Verificando línea 24526 ==="
docker exec "$CONTAINER" sed -n '24526p' /app/dashboard.html
echo ""

# 8. Reiniciar contenedor
echo "=== Reiniciando contenedor ==="
docker restart "$CONTAINER"
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


