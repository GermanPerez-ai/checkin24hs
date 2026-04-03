#!/bin/bash
# Aplicar fix directamente en el servidor

echo "=== APLICANDO FIX: Servidor debe escuchar en 0.0.0.0 ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "🔧 Aplicando fix en $s..."
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Verificar si el archivo existe
        if docker exec $CONTAINER test -f /app/whatsapp-server.js 2>/dev/null; then
            FILE_PATH="/app/whatsapp-server.js"
        elif docker exec $CONTAINER test -f whatsapp-server.js 2>/dev/null; then
            FILE_PATH="whatsapp-server.js"
        else
            echo "   ⚠️  No se encontró whatsapp-server.js"
            continue
        fi
        
        # Aplicar el cambio
        docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" $FILE_PATH
        
        if [ $? -eq 0 ]; then
            echo "   ✅ Fix aplicado"
            echo "   🔄 Reiniciando servicio..."
            docker service update --force $s
            sleep 5
        else
            echo "   ❌ Error al aplicar fix"
        fi
    else
        echo "   ⚠️  No se encontró contenedor activo"
    fi
    
    echo ""
done

echo "⏳ Esperando 30 segundos para que los servicios se reinicien..."
sleep 30

echo ""
echo "=== VERIFICANDO QUE LOS SERVICIOS ESTÁN ESCUCHANDO EN 0.0.0.0 ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER" ]; then
        # Verificar que el cambio se aplicó
        if docker exec $CONTAINER grep -q "server.listen(CONFIG.PORT, '0.0.0.0'" whatsapp-server.js 2>/dev/null || docker exec $CONTAINER grep -q "server.listen(CONFIG.PORT, '0.0.0.0'" /app/whatsapp-server.js 2>/dev/null; then
            echo "   ✅ Cambio aplicado correctamente"
        else
            echo "   ⚠️  El cambio no se aplicó"
        fi
        
        # Probar conectividad desde Traefik
        TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
        if [ ! -z "$TRAEFIK_CONTAINER" ]; then
            echo "   🔍 Probando conectividad desde Traefik:"
            docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -3 || echo "   ⚠️  Aún no responde (puede tardar unos segundos más)"
        fi
    fi
    echo ""
done






