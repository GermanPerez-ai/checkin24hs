#!/bin/bash
echo "=== BUSCANDO MENSAJE DE INICIO ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s:"
    
    # Buscar mensaje de inicio
    echo "   Mensaje de inicio:"
    docker service logs $s 2>&1 | grep -E "Servidor corriendo|running|puerto|port|listen|Servidor WhatsApp" | head -5
    
    # Ver errores
    echo "   Errores:"
    docker service logs $s 2>&1 | grep -iE "error|failed|exception" | tail -3
    
    # Ver primeras líneas
    echo "   Primeras 20 líneas:"
    docker service logs $s 2>&1 | head -20
    
    echo ""
done
