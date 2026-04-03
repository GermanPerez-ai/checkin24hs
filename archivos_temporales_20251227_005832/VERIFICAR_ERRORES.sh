#!/bin/bash
# Script para verificar errores en el contenedor

echo "=========================================="
echo "Verificando errores en el contenedor"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No hay contenedor corriendo"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Verificar línea 5168
echo "1. Verificando linea 5168..."
docker exec $CONTAINER_ID sed -n '5165,5175p' /app/dashboard.html | cat -n
echo ""

# 2. Verificar si las funciones globales están definidas
echo "2. Verificando funciones globales..."
docker exec $CONTAINER_ID grep -n "window.loadAIConfigFromSupabase" /app/dashboard.html | head -3
docker exec $CONTAINER_ID grep -n "window.loadWhatsAppCards" /app/dashboard.html | head -3
echo ""

# 3. Verificar dónde se llaman estas funciones
echo "3. Verificando donde se llaman las funciones..."
docker exec $CONTAINER_ID grep -n "loadAIConfigFromSupabase()" /app/dashboard.html | head -5
docker exec $CONTAINER_ID grep -n "loadWhatsAppCards()" /app/dashboard.html | head -5
echo ""

# 4. Verificar línea 22994 donde se llama loadAIConfigFromSupabase
echo "4. Verificando linea 22994 (donde se llama loadAIConfigFromSupabase)..."
docker exec $CONTAINER_ID sed -n '22990,23000p' /app/dashboard.html | cat -n
echo ""

# 5. Verificar línea 21615 donde se llama loadWhatsAppCards
echo "5. Verificando linea 21615 (donde se llama loadWhatsAppCards)..."
docker exec $CONTAINER_ID sed -n '21610,21620p' /app/dashboard.html | cat -n
echo ""

# 6. Comparar archivo local vs contenedor
echo "6. Comparando tamaños de archivos..."
echo "   Local:"
ls -lh /root/checkin24hs/dashboard.html | awk '{print $5}'
echo "   Contenedor:"
docker exec $CONTAINER_ID ls -lh /app/dashboard.html | awk '{print $5}'
echo ""

echo "=========================================="
echo "Verificacion completada"
echo "=========================================="


