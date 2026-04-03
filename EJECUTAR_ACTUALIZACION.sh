#!/bin/bash
cd /root/checkin24hs

echo "=== 1. Verificar archivo local ==="
ls -lh dashboard.html
echo ""

echo "=== 2. Verificar emojis en archivo local ==="
grep -c "🎫\|🤖\|✅\|💾" dashboard.html 2>&1 || echo "0 emojis ✅"
echo ""

echo "=== 3. Verificar showSection en archivo local ==="
grep -c "window.showSection = function" dashboard.html
echo ""

echo "=== 4. Obtener contenedor ==="
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
echo "Contenedor: $CONTAINER_ID"
echo ""

echo "=== 5. Verificar archivo actual en contenedor ==="
docker exec $CONTAINER_ID ls -lh /app/dashboard.html
docker exec $CONTAINER_ID grep -c "🎫\|🤖\|✅\|💾" /app/dashboard.html 2>&1 || echo "0"
echo ""

echo "=== 6. Copiar archivo ==="
docker cp dashboard.html $CONTAINER_ID:/app/dashboard.html
echo "✅ Archivo copiado"
echo ""

echo "=== 7. Verificar archivo copiado ==="
docker exec $CONTAINER_ID ls -lh /app/dashboard.html
docker exec $CONTAINER_ID grep -c "🎫\|🤖\|✅\|💾" /app/dashboard.html 2>&1 || echo "0 emojis ✅"
docker exec $CONTAINER_ID grep -n "window.showSection = function" /app/dashboard.html | head -3
echo ""

echo "=== 8. Verificar línea 5150 ==="
docker exec $CONTAINER_ID sed -n '5150p' /app/dashboard.html
echo ""

echo "=== 9. Reiniciar servicio ==="
docker service update --force checkin24hs_dashboard
echo "✅ Servicio reiniciado"
echo ""

echo "Esperando 30 segundos..."
sleep 30

echo "=== 10. Copiar al nuevo contenedor ==="
NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
echo "Nuevo contenedor: $NEW_CONTAINER_ID"
docker cp dashboard.html $NEW_CONTAINER_ID:/app/dashboard.html
echo "✅ Archivo copiado al nuevo contenedor"
echo ""

echo "=== 11. Verificar nuevo contenedor ==="
docker exec $NEW_CONTAINER_ID grep -c "🎫\|🤖\|✅\|💾" /app/dashboard.html 2>&1 || echo "0 emojis ✅"
docker exec $NEW_CONTAINER_ID grep -n "window.showSection = function" /app/dashboard.html | head -3
echo ""

echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "IMPORTANTE:"
echo "1. Recarga la pagina con Ctrl+Shift+R (recarga forzada sin caché)"
echo "2. O abre en modo incógnito: Ctrl+Shift+N"
echo ""




