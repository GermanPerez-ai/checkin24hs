#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO ESTADO DE WHATSAPP 1"
echo "=========================================="
echo ""

# 1. Encontrar el contenedor activo
CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi

echo "1️⃣ Contenedor activo: $CONTAINER_ID"
echo ""

# 2. Ver logs recientes
echo "2️⃣ Logs recientes (últimas 50 líneas):"
docker logs "$CONTAINER_ID" --tail 50 2>&1 | grep -E "(QR Code|Chrome|Servidor iniciado|connected to WA|initializing|error|Error)" | tail -20

echo ""
echo "3️⃣ Verificando si hay QR code en el servidor:"
docker exec "$CONTAINER_ID" sh -c "ls -la /app/auth_info_baileys_1/ 2>/dev/null || echo 'Directorio no existe'"

echo ""
echo "4️⃣ Verificando proceso Node.js:"
docker exec "$CONTAINER_ID" sh -c "ps aux | grep node | grep -v grep"

echo ""
echo "5️⃣ Verificando conexión directa al puerto 3001:"
docker exec "$CONTAINER_ID" sh -c "curl -s http://localhost:3001/api/status | head -5"

echo ""
echo "6️⃣ Verificando si hay errores en los logs completos:"
docker logs "$CONTAINER_ID" --tail 100 2>&1 | grep -i "error\|fail\|exception" | tail -10

echo ""
echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=========================================="
