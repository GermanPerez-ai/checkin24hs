#!/bin/bash
# Verificar conflictos de puertos

echo "=== VERIFICANDO CONFIGURACIÓN DE PUERTOS ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto esperado: $PORT):"
    
    # Ver configuración de puertos del servicio
    echo "   Puertos configurados:"
    docker service inspect $s --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}} ({{.Protocol}}){{println}}{{end}}' 2>/dev/null
    
    # Ver modo de publicación
    echo "   Modo de publicación:"
    docker service inspect $s --format '{{range .Endpoint.Ports}}{{.PublishMode}}{{println}}{{end}}' 2>/dev/null | head -1
    
    echo ""
done

echo "=== PUERTOS EN USO EN EL HOST ==="
netstat -tuln 2>/dev/null | grep -E ":300[1-4] " || ss -tuln 2>/dev/null | grep -E ":300[1-4] "






