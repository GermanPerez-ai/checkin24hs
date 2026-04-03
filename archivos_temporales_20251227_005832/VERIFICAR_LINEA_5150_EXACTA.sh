#!/bin/bash
# Verificar exactamente qué hay en la línea 5150

cd /root/checkin24hs

echo "=== Verificando archivo en servidor ==="
echo ""
echo "Líneas 5148-5156:"
sed -n '5148,5156p' deploy/dashboard.html | cat -A
echo ""

echo "=== Verificando contenedores activos ==="
echo ""

for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard" | head -3); do 
    echo "--- Contenedor: $container ---"
    echo "Líneas 5148-5156:"
    docker exec $container sed -n '5148,5156p' /app/dashboard.html 2>/dev/null | cat -A
    echo ""
    
    echo "Caracteres en línea 5150 (hex):"
    docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null | od -An -tx1 | head -1
    echo ""
done

echo "=== Verificando si hay caracteres problemáticos ==="
echo "Buscando caracteres especiales alrededor de línea 5150:"
sed -n '5148,5156p' deploy/dashboard.html | grep -o . | head -50




