#!/bin/bash

echo "=========================================="
echo "Aplicar Corrección showSection"
echo "=========================================="
echo ""

cd /root/checkin24hs

# Buscar contenedor
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# Copiar dashboard.html
echo "Copiando dashboard.html actualizado..."
docker cp dashboard.html $CONTAINER_ID:/app/dashboard.html

if [ $? -eq 0 ]; then
    echo "✅ dashboard.html copiado"
else
    echo "❌ Error al copiar"
    exit 1
fi

# Verificar
echo ""
echo "Verificando archivo en el contenedor:"
docker exec $CONTAINER_ID ls -lh /app/dashboard.html

echo ""
echo "=========================================="
echo "✅ Archivo aplicado"
echo "=========================================="
echo ""
echo "Recarga la página en tu navegador (Ctrl+F5 para forzar recarga)"
echo "Los botones del menú deberían funcionar ahora."
echo ""

