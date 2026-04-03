#!/bin/bash
# Solución permanente: Asegurar que el servidor escuche en 0.0.0.0

echo "=== SOLUCIÓN PERMANENTE ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "🔧 $s:"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Buscar archivo en todas las ubicaciones posibles
        FILE=$(docker exec $CONTAINER sh -c "find /app /root /home /usr/src -name 'whatsapp-server.js' 2>/dev/null" | head -1)
        
        if [ -z "$FILE" ]; then
            # Si no se encuentra, buscar en el directorio actual
            WORKDIR=$(docker exec $CONTAINER pwd 2>/dev/null)
            FILE=$(docker exec $CONTAINER ls -la whatsapp-server.js 2>/dev/null | awk '{print $NF}' | head -1)
            if [ ! -z "$FILE" ]; then
                FILE="$WORKDIR/$FILE"
            fi
        fi
        
        if [ ! -z "$FILE" ]; then
            echo "   Archivo: $FILE"
            
            # Verificar contenido actual
            CURRENT=$(docker exec $CONTAINER grep "server.listen" $FILE | head -1)
            echo "   Línea actual: $CURRENT"
            
            # Aplicar cambio de múltiples formas posibles
            docker exec $CONTAINER sh -c "
                sed -i \"s/server\.listen(CONFIG\.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g\" $FILE
                sed -i \"s/server\.listen(CONFIG\.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g\" $FILE
                sed -i \"s/server\.listen(CONFIG\.PORT,/server.listen(CONFIG.PORT, '0.0.0.0',/g\" $FILE
            "
            
            # Verificar que se aplicó
            NEW_LINE=$(docker exec $CONTAINER grep "server.listen" $FILE | head -1)
            echo "   Nueva línea: $NEW_LINE"
            
            if echo "$NEW_LINE" | grep -q "0.0.0.0"; then
                echo "   ✅ Cambio aplicado correctamente"
            else
                echo "   ⚠️  El cambio no se aplicó, intentando método alternativo..."
                # Método alternativo: reemplazar toda la línea
                docker exec $CONTAINER sh -c "
                    sed -i \"s/server\.listen(CONFIG\.PORT, async () => {/server.listen(CONFIG.PORT, '0.0.0.0', async () => {/g\" $FILE
                "
            fi
            
            # Reiniciar servicio
            echo "   🔄 Reiniciando servicio..."
            docker service update --force $s
        else
            echo "   ❌ No se encontró el archivo whatsapp-server.js"
            echo "   Buscando archivos .js en /app:"
            docker exec $CONTAINER find /app -name "*.js" 2>/dev/null | head -5
        fi
    fi
    
    echo ""
done

echo "⏳ Esperando 40 segundos para que los servicios se reinicien completamente..."
sleep 40

echo ""
echo "=== VERIFICACIÓN FINAL ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    # Verificar que el cambio está aplicado
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER" ]; then
        FILE=$(docker exec $CONTAINER sh -c "find /app /root /home /usr/src -name 'whatsapp-server.js' 2>/dev/null" | head -1)
        if [ ! -z "$FILE" ]; then
            if docker exec $CONTAINER grep -q "0.0.0.0" $FILE 2>/dev/null; then
                echo "   ✅ Configurado para 0.0.0.0"
            else
                echo "   ❌ Aún no tiene 0.0.0.0"
            fi
        fi
    fi
    
    # Probar conectividad
    echo "   Probando conectividad:"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -3 || echo "   ⚠️  No responde"
    
    echo ""
done






