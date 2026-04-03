#!/bin/bash
# Buscar el mensaje de inicio del servidor en los logs

echo "=== BUSCANDO MENSAJE DE INICIO DEL SERVIDOR ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    # Buscar mensaje de inicio
    echo "   Buscando mensaje 'Servidor corriendo' o 'running':"
    docker service logs $s 2>&1 | grep -E "Servidor corriendo|running on|puerto|port|PORT|listen" | head -5
    
    # Ver si hay errores
    echo "   Buscando errores:"
    docker service logs $s 2>&1 | grep -iE "error|Error|ERROR|failed|Failed|exception|Exception" | tail -5
    
    # Ver logs completos desde el inicio (primeras 50 líneas)
    echo "   Primeras líneas de logs:"
    docker service logs $s 2>&1 | head -30 | grep -v "^$" | head -10
    
    echo ""
done


















