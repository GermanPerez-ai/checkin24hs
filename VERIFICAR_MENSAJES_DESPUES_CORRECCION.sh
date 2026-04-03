#!/bin/bash
set -e

echo "=========================================="
echo "🔍 VERIFICANDO SI LOS MENSAJES SE GUARDAN DESPUÉS DE LA CORRECCIÓN"
echo "=========================================="

# Buscar contenedores de WhatsApp
CONTAINER=$(docker ps --filter "name=whatsapp" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

echo "=== 1. Verificando que el código usa 'body' ==="
if docker exec "$CONTAINER" grep -q "body: message" /app/whatsapp-server.js; then
    echo "✅ El código usa 'body: message' correctamente"
else
    echo "❌ El código NO usa 'body: message'"
fi

echo ""
echo "=== 2. Buscando la función saveMessageToSupabase ==="
docker exec "$CONTAINER" grep -A 15 "async function saveMessageToSupabase" /app/whatsapp-server.js | head -20

echo ""
echo "=== 3. Verificando errores recientes al guardar mensajes ==="
docker logs "$CONTAINER" --tail 50 2>&1 | grep -i "error\|guardando mensaje\|whatsapp_messages\|insert" | tail -20 || echo "✅ No se encontraron errores recientes"

echo ""
echo "=== 4. Verificando mensajes guardados exitosamente ==="
docker logs "$CONTAINER" --tail 100 2>&1 | grep -i "✅ Mensaje guardado\|mensaje guardado en supabase" | tail -10 || echo "⚠️ No se encontraron mensajes guardados exitosamente"

echo ""
echo "=== 5. Verificando si se está llamando a saveMessageToSupabase ==="
docker logs "$CONTAINER" --tail 100 2>&1 | grep -i "saveMessageToSupabase\|guardando mensaje" | tail -10 || echo "⚠️ No se encontraron llamadas a saveMessageToSupabase"

echo ""
echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📋 Próximos pasos:"
echo "  1. Envía un mensaje de prueba a WhatsApp AHORA"
echo "  2. Espera 5 segundos"
echo "  3. Ejecuta este script de nuevo para ver si se guardó"
echo "  4. Verifica en Supabase (Table Editor -> whatsapp_messages) si aparece el mensaje"


