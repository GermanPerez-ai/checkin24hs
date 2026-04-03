#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICAR ACCESO DIRECTO AL SERVICIO"
echo "=========================================="
echo ""

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)

echo "📦 Contenedor: $CONTAINER"
echo ""

# 1. Verificar IP del contenedor
echo "=== 1. IP DEL CONTENEDOR ==="
CONTAINER_IP=$(docker inspect "$CONTAINER" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
echo "IP: $CONTAINER_IP"
echo ""

# 2. Probar conexión directa al contenedor
echo "=== 2. PRUEBA DE CONEXIÓN DIRECTA ==="
echo "Probando http://$CONTAINER_IP:3000"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$CONTAINER_IP:3000" 2>/dev/null)
echo "HTTP Status Code: $HTTP_CODE"
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ El servicio responde correctamente"
else
    echo "❌ El servicio NO responde (HTTP $HTTP_CODE)"
fi
echo ""

# 3. Verificar puerto del contenedor
echo "=== 3. PUERTO DEL CONTENEDOR ==="
docker port "$CONTAINER" 2>/dev/null
echo ""

# 4. Verificar red del contenedor
echo "=== 4. RED DEL CONTENEDOR ==="
docker inspect "$CONTAINER" --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{"\n"}}{{end}}' 2>/dev/null
echo ""

# 5. Verificar si hay algún error en los logs recientes
echo "=== 5. LOGS RECIENTES (últimas 10 líneas) ==="
docker logs "$CONTAINER" --tail 10 2>&1 | tail -10
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
echo ""
echo "💡 Si el servicio responde directamente pero Traefik da 404,"
echo "   el problema está en la configuración de Traefik o en las labels del servicio"
echo ""
