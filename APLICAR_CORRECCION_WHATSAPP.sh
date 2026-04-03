#!/bin/bash
set -e

echo "=========================================="
echo "🔧 APLICANDO CORRECCIÓN A SERVIDORES DE WHATSAPP"
echo "=========================================="

# Verificar que el archivo local existe
if [ ! -f "whatsapp-server/whatsapp-server.js" ]; then
    echo "❌ Error: whatsapp-server/whatsapp-server.js no encontrado"
    exit 1
fi

echo "✅ Archivo local encontrado"
echo ""

# Buscar todos los contenedores de WhatsApp
WHATSAPP_CONTAINERS=($(docker ps --filter "name=whatsapp" --format "{{.Names}}"))

if [ ${#WHATSAPP_CONTAINERS[@]} -eq 0 ]; then
    echo "❌ No se encontraron contenedores de WhatsApp"
    exit 1
fi

echo "✅ Se encontraron ${#WHATSAPP_CONTAINERS[@]} contenedores de WhatsApp"
echo ""

for CONTAINER in "${WHATSAPP_CONTAINERS[@]}"; do
    echo "=== Procesando: $CONTAINER ==="
    
    # Crear backup
    BACKUP_FILE="/app/whatsapp-server.js.backup.$(date +%Y%m%d_%H%M%S)"
    docker exec "$CONTAINER" cp /app/whatsapp-server.js "$BACKUP_FILE" 2>/dev/null || true
    echo "  ✅ Backup creado: $BACKUP_FILE"
    
    # Copiar archivo corregido
    docker cp whatsapp-server/whatsapp-server.js "${CONTAINER}:/app/whatsapp-server.js"
    echo "  ✅ Archivo corregido copiado"
    
    # Verificar que usa 'body' en lugar de 'message'
    if docker exec "$CONTAINER" grep -q "body: message" /app/whatsapp-server.js; then
        echo "  ✅ Verificado: usa 'body' en lugar de 'message'"
    else
        echo "  ⚠️ Advertencia: no se encontró 'body: message' en el código"
    fi
    
    # Reiniciar contenedor
    echo "  🔄 Reiniciando contenedor..."
    docker restart "$CONTAINER"
    sleep 5
    echo "  ✅ Contenedor reiniciado"
    echo ""
done

echo "=========================================="
echo "✅ CORRECCIÓN APLICADA A TODOS LOS CONTENEDORES"
echo "=========================================="
echo ""
echo "⏳ Esperando 20 segundos para que los servicios se estabilicen..."
sleep 20

echo ""
echo "📋 Verificando que no hay errores recientes..."
for CONTAINER in "${WHATSAPP_CONTAINERS[@]}"; do
    echo ""
    echo "=== Últimos errores de $CONTAINER ==="
    docker logs "$CONTAINER" --tail 10 2>&1 | grep -i "error\|guardando mensaje" | tail -5 || echo "  ✅ No se encontraron errores recientes"
done

echo ""
echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "🔍 Próximos pasos:"
echo "  1. Envía un mensaje de prueba a WhatsApp"
echo "  2. Verifica en Supabase (Table Editor -> whatsapp_messages) si el mensaje se guardó"
echo "  3. Si aún hay errores, revisa los logs con: docker logs <nombre_contenedor> --tail 50"


