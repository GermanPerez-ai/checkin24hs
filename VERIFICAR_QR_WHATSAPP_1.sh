#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO QR CODE DE WHATSAPP 1"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi

echo "1️⃣ Verificando logs más recientes (últimas 20 líneas):"
docker logs "$CONTAINER_ID" --tail 20 2>&1

echo ""
echo "2️⃣ Buscando QR codes generados:"
docker logs "$CONTAINER_ID" --tail 100 2>&1 | grep -E "(QR Code recibido|QR Code generado|QR Code imagen generada)" | tail -5

echo ""
echo "3️⃣ Verificando estado de conexión:"
docker logs "$CONTAINER_ID" --tail 50 2>&1 | grep -E "(connected to WA|Reconectando|Conexión cerrada)" | tail -5

echo ""
echo "4️⃣ Verificando si hay errores recientes:"
docker logs "$CONTAINER_ID" --tail 50 2>&1 | grep -i "error\|fail" | tail -5

echo ""
echo "5️⃣ Probando API directamente:"
echo "   (usando wget en lugar de curl)"
docker exec "$CONTAINER_ID" sh -c "wget -qO- http://localhost:3001/api/status 2>/dev/null || echo 'Error: wget no disponible'"

echo ""
echo "6️⃣ Verificando si el proceso está corriendo:"
docker exec "$CONTAINER_ID" sh -c "ps aux | grep -E 'node|whatsapp' | grep -v grep"

echo ""
echo "=========================================="
echo "💡 Si no ves 'QR Code generado', espera 30-60 segundos"
echo "   El servidor puede estar reconectando después de limpiar la sesión"
echo "=========================================="
