#!/bin/bash
# Aplicar corrección línea 5150 - código simplificado sin emojis

cd /root/checkin24hs

echo "=== APLICANDO CORRECCION LINEA 5150 ==="
echo ""

# Verificar línea 5150
echo "Línea 5150 actual:"
sed -n '5150p' deploy/dashboard.html

echo ""
echo "Líneas 5140-5155:"
sed -n '5140,5155p' deploy/dashboard.html

echo ""
echo "Aplicando a todos los contenedores..."
echo ""

for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "Copiando a $container..."
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    
    # Verificar línea 5150
    LINE_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
    echo "  Línea 5150: $LINE_5150"
    
    docker restart $container 2>/dev/null
    echo "  ✅ Reiniciado"
    echo ""
done

echo "=== COMPLETADO ==="
echo ""
echo "Abre en modo incognito: https://dashboard.checkin24hs.com/"
echo "Verifica que NO haya errores en la consola (F12)"

