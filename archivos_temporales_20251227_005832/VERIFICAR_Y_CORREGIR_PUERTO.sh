#!/bin/bash
# Verificar que el servidor responde en puerto 3004 y corregir configuración

echo "=== VERIFICANDO QUE EL SERVIDOR RESPONDE ==="
echo ""

CONTAINER=$(docker ps --filter "name=checkin24hs_whatsapp4" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER" ]; then
    echo "Probando puerto 3004 en whatsapp4:"
    RESPONSE=$(docker exec $CONTAINER curl -sI --max-time 5 http://localhost:3004 2>&1)
    echo "$RESPONSE" | head -5
    
    if echo "$RESPONSE" | grep -q "HTTP"; then
        echo ""
        echo "✅ El servidor SÍ responde en puerto 3004"
        echo ""
        echo "=== SOLUCIÓN ==="
        echo ""
        echo "El problema es que en EasyPanel, el dominio está configurado con puerto 80."
        echo "Debes cambiarlo a puerto 3004:"
        echo ""
        echo "1. Ve a EasyPanel → whatsapp4 → Dominios"
        echo "2. Edita whatsapp4.checkin24hs.com"
        echo "3. Cambia el puerto de 80 a 3004"
        echo "4. Guarda"
        echo ""
        echo "Repite lo mismo para:"
        echo "  - whatsapp1.checkin24hs.com → puerto 3001"
        echo "  - whatsapp2.checkin24hs.com → puerto 3002"
        echo "  - whatsapp3.checkin24hs.com → puerto 3003"
        echo "  - whatsapp4.checkin24hs.com → puerto 3004"
    else
        echo ""
        echo "⚠️  El servidor no responde en puerto 3004"
        echo "Verificando si escucha en otro puerto..."
    fi
fi

echo ""
echo "=== VERIFICANDO TODOS LOS SERVICIOS ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "📋 $s debería estar en puerto $PORT:"
    docker service logs $s 2>&1 | grep "Servidor corriendo en puerto" | head -1
done






