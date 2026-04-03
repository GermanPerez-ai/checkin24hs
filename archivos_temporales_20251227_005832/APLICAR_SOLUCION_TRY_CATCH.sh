#!/bin/bash
# Aplicar solución con try-catch - código protegido

cd /root/checkin24hs

echo "=== APLICANDO SOLUCION TRY-CATCH ==="
echo ""

# Verificar líneas alrededor de 5150
echo "Líneas 5140-5160:"
sed -n '5140,5160p' deploy/dashboard.html

echo ""
echo "Aplicando a todos los contenedores..."
echo ""

for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "Copiando a $container..."
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    
    # Verificar
    echo "  Verificando líneas 5140-5160:"
    docker exec $container sed -n '5140,5160p' /app/dashboard.html 2>/dev/null | head -5
    
    docker restart $container 2>/dev/null
    echo "  ✅ Reiniciado"
    echo ""
done

echo "=== COMPLETADO ==="
echo ""
echo "El código ahora está protegido con try-catch"
echo "Abre en modo incognito: https://dashboard.checkin24hs.com/"
echo "Verifica que NO haya errores en la consola (F12)"

