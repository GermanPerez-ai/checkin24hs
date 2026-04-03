#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 APLICANDO CORRECCIÓN DE MENSAJES"
echo "=========================================="
echo ""

# Encontrar todos los contenedores de WhatsApp
WHATSAPP_CONTAINERS=($(docker ps --filter "name=whatsapp" --format "{{.Names}}"))

if [ ${#WHATSAPP_CONTAINERS[@]} -eq 0 ]; then
    echo "❌ No se encontraron contenedores de WhatsApp"
    exit 1
fi

echo "✅ Se encontraron ${#WHATSAPP_CONTAINERS[@]} contenedores de WhatsApp:"
for container in "${WHATSAPP_CONTAINERS[@]}"; do
    echo "   - $container"
done
echo ""

# Para cada contenedor
for CONTAINER in "${WHATSAPP_CONTAINERS[@]}"; do
    echo "=== Procesando contenedor: $CONTAINER ==="
    
    # 1. Crear backup
    BACKUP_FILE="/app/whatsapp-server.js.backup.$(date +%Y%m%d_%H%M%S)"
    docker exec "$CONTAINER" cp /app/whatsapp-server.js "$BACKUP_FILE" 2>/dev/null || true
    echo "✅ Backup creado: $BACKUP_FILE"
    
    # 2. Copiar archivo corregido
    if [ -f "whatsapp-server/whatsapp-server.js" ]; then
        docker cp whatsapp-server/whatsapp-server.js "${CONTAINER}:/app/whatsapp-server.js"
        echo "✅ Archivo corregido copiado"
    else
        echo "⚠️ No se encontró whatsapp-server/whatsapp-server.js localmente"
        echo "   Aplicando corrección directamente en el contenedor..."
        
        # Corregir directamente en el contenedor usando sed
        docker exec "$CONTAINER" sed -i "s/message: message,/body: message || '',/g" /app/whatsapp-server.js
        docker exec "$CONTAINER" sed -i "s/'message': message/'body': message || ''/g" /app/whatsapp-server.js
        docker exec "$CONTAINER" sed -i 's/"message": message/"body": message || ""/g' /app/whatsapp-server.js
        
        # Corregir campos booleanos
        docker exec "$CONTAINER" sed -i 's/success: true/success: Boolean(true)/g' /app/whatsapp-server.js
        docker exec "$CONTAINER" sed -i 's/used_ai: usedAI/used_ai: Boolean(usedAI)/g' /app/whatsapp-server.js
        
        echo "✅ Correcciones aplicadas con sed"
    fi
    
    # 3. Verificar corrección
    echo ""
    echo "Verificando corrección..."
    if docker exec "$CONTAINER" grep -q "body: message" /app/whatsapp-server.js; then
        echo "✅ Corrección verificada: se encontró 'body: message'"
    else
        echo "⚠️ No se encontró 'body: message', puede que necesite revisión manual"
    fi
    
    # 4. Reiniciar contenedor
    echo ""
    echo "Reiniciando contenedor..."
    docker restart "$CONTAINER"
    echo "⏳ Esperando 15 segundos..."
    sleep 15
    
    # 5. Verificar que está corriendo
    if docker ps --format "{{.Names}}" | grep -q "$CONTAINER"; then
        echo "✅ Contenedor $CONTAINER está corriendo"
        echo "📋 Últimas 3 líneas de logs:"
        docker logs "$CONTAINER" --tail 3 2>&1 | tail -3
    else
        echo "❌ El contenedor $CONTAINER no está corriendo"
        echo "📋 Últimas 10 líneas de logs:"
        docker logs "$CONTAINER" --tail 10 2>&1 | tail -10
    fi
    
    echo ""
    echo "---"
    echo ""
done

echo "=========================================="
echo "✅ CORRECCIÓN COMPLETA"
echo "=========================================="
echo ""
echo "📋 Resumen:"
echo "  - Contenedores procesados: ${#WHATSAPP_CONTAINERS[@]}"
echo ""
echo "🔍 Próximos pasos:"
echo "  1. Envía un mensaje de prueba a WhatsApp"
echo "  2. Verifica los logs del contenedor (no deberían aparecer errores)"
echo "  3. Verifica en Supabase que los mensajes se están guardando:"
echo "     SELECT COUNT(*) FROM whatsapp_messages;"
echo ""
