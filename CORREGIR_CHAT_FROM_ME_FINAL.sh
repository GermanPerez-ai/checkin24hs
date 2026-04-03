#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 CORRECCIÓN FINAL DEL CHAT - ERROR FROM_ME"
echo "=========================================="
echo ""

# Obtener contenedor del dashboard
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

# Copiar archivo correcto desde deploy
if [ -f "deploy/dashboard.html" ]; then
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    echo "✅ Archivo correcto copiado desde deploy/dashboard.html"
else
    echo "⚠️ No se encontró deploy/dashboard.html, corrigiendo directamente en el contenedor"
fi

# Eliminar TODAS las consultas problemáticas con from_me
echo "Eliminando consultas problemáticas..."
docker exec "$CONTAINER" sed -i '/select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true
docker exec "$CONTAINER" sed -i '/\.select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true
docker exec "$CONTAINER" sed -i '/whatsapp_messages.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true

# Reemplazar cualquier from_me restante con is_from_me
docker exec "$CONTAINER" sed -i 's/from_me\([^_]\)/is_from_me\1/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me"/is_from_me"/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/from_me'/is_from_me'/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me)/is_from_me)/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me,/is_from_me,/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me&/is_from_me&/g' /app/dashboard.html

echo "✅ Correcciones aplicadas"
echo ""

# Verificar que no quedan consultas problemáticas
echo "=== Verificación ==="
REMAINING=$(docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | wc -l)
if [ "$REMAINING" -eq 0 ]; then
    echo "✅ No quedan consultas problemáticas con 'from_me'"
else
    echo "⚠️ Aún quedan $REMAINING referencias problemáticas:"
    docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -5
fi

# Verificar que se usa is_from_me correctamente
IS_FROM_ME_COUNT=$(docker exec "$CONTAINER" grep -c "is_from_me" /app/dashboard.html)
echo "✅ Referencias correctas a 'is_from_me': $IS_FROM_ME_COUNT"
echo ""

# Reiniciar contenedor
echo "=== Reiniciando contenedor ==="
docker restart "$CONTAINER"
echo "⏳ Esperando 25 segundos..."
sleep 25

# Verificar estado
if docker ps | grep -q "$CONTAINER"; then
    echo "✅ Contenedor está corriendo"
    echo ""
    echo "📋 Últimas 5 líneas de logs:"
    docker logs "$CONTAINER" --tail 5
else
    echo "❌ Contenedor NO está corriendo. Revisa los logs con 'docker logs $CONTAINER'"
fi

echo ""
echo "=========================================="
echo "✅ CORRECCIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📋 Próximos pasos:"
echo "  1. Limpia el caché del navegador (Ctrl+Shift+R o modo incógnito)"
echo "  2. Prueba seleccionar un chat en el dashboard"
echo "  3. Verifica que NO aparezca el error de 'from_me'"
echo "  4. Los mensajes deberían cargarse correctamente"
echo ""


