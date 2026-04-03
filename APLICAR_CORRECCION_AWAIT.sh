#!/bin/bash
cd /root/checkin24hs

echo "=== APLICAR CORRECCIÓN ERROR AWAIT ==="
echo ""

# Verificar archivo
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ Error: No se encontró deploy/dashboard.html"
    exit 1
fi

echo "✅ Archivo encontrado"
echo ""

# Detener contenedores
echo "🛑 Deteniendo contenedores..."
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard") 2>/dev/null
sleep 3
echo "✅ Detenidos"
echo ""

# Copiar archivo
echo "📋 Copiando archivo corregido..."
for c in $(docker ps -a --format '{{.Names}}' | grep checkin24hs_dashboard); do
    echo "  Copiando a: $c"
    if docker cp deploy/dashboard.html "$c:/app/dashboard.html" 2>/dev/null; then
        echo "    ✅ Copiado a /app/dashboard.html"
    elif docker cp deploy/dashboard.html "$c:/usr/share/nginx/html/dashboard.html" 2>/dev/null; then
        echo "    ✅ Copiado a /usr/share/nginx/html/dashboard.html"
    else
        echo "    ❌ Error"
    fi
done
echo ""

# Reiniciar
echo "🚀 Reiniciando contenedores..."
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard") 2>/dev/null
sleep 3
echo "✅ Reiniciados"
echo ""

echo "✅ Corrección aplicada!"
echo "Espera 10 segundos y prueba el dashboard con Ctrl+F5"










