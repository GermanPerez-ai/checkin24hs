#!/bin/bash

echo "=========================================="
echo "Verificar que el Dashboard es Accesible"
echo "=========================================="
echo ""

# 1. Obtener contenedor
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No hay contenedor corriendo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

# 2. Probar acceso interno
echo "=== Probar acceso interno ==="
echo "Probando http://localhost:3000..."
RESPONSE=$(docker exec $CONTAINER_ID wget -qO- --timeout=5 http://localhost:3000 2>&1)
if [ $? -eq 0 ]; then
    echo "✅ El servidor responde"
    echo "Primeras 10 líneas de la respuesta:"
    echo "$RESPONSE" | head -10
else
    echo "❌ El servidor no responde"
    echo "$RESPONSE"
fi
echo ""

# 3. Verificar que dashboard.html existe y tiene contenido
echo "=== Verificar dashboard.html ==="
SIZE=$(docker exec $CONTAINER_ID stat -c%s /app/dashboard.html 2>/dev/null || docker exec $CONTAINER_ID stat -f%z /app/dashboard.html 2>/dev/null)
if [ ! -z "$SIZE" ]; then
    echo "✅ dashboard.html existe: $(echo "scale=2; $SIZE/1024" | bc) KB"
    echo "Primeras líneas:"
    docker exec $CONTAINER_ID head -5 /app/dashboard.html
else
    echo "❌ dashboard.html no existe o no se puede leer"
fi
echo ""

# 4. Verificar que server.js sirve dashboard.html
echo "=== Verificar ruta principal ==="
echo "Probando ruta /..."
docker exec $CONTAINER_ID wget -qO- --timeout=5 http://localhost:3000/ 2>&1 | head -5
echo ""

# 5. Verificar acceso desde el host
echo "=== Verificar acceso desde el host ==="
CONTAINER_IP=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
echo "IP del contenedor: $CONTAINER_IP"
curl -I --connect-timeout 5 http://$CONTAINER_IP:3000 2>&1 | head -5
echo ""

# 6. Verificar acceso a través del dominio
echo "=== Verificar acceso a través del dominio ==="
curl -I --connect-timeout 5 http://dashboard.checkin24hs.com 2>&1 | head -10
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
echo ""




