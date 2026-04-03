#!/bin/bash
# Probar el endpoint directamente desde el host

echo "=========================================="
echo "🔍 Probando endpoint /api/version directamente"
echo "=========================================="
echo ""

DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $DASHBOARD_CONTAINER"
echo ""

# Obtener IP del contenedor
CONTAINER_IP=$(docker inspect "$DASHBOARD_CONTAINER" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')

if [ -z "$CONTAINER_IP" ]; then
    echo "⚠️  No se pudo obtener la IP del contenedor"
    echo "Probando con localhost..."
    CONTAINER_IP="localhost"
fi

echo "IP del contenedor: $CONTAINER_IP"
echo ""

echo "1️⃣ Probando acceso directo al contenedor desde el host..."
echo "   URL: http://$CONTAINER_IP:3000/api/version"
echo ""

# Probar con wget o curl desde el host
if command -v curl &> /dev/null; then
    echo "Usando curl..."
    curl -s "http://$CONTAINER_IP:3000/api/version" && echo "" || echo "❌ Error al acceder"
elif command -v wget &> /dev/null; then
    echo "Usando wget..."
    wget -qO- "http://$CONTAINER_IP:3000/api/version" && echo "" || echo "❌ Error al acceder"
else
    echo "⚠️  No se encontró curl ni wget"
fi

echo ""
echo "2️⃣ Probando desde dentro del contenedor usando node..."
docker exec "$DASHBOARD_CONTAINER" node -e "
const http = require('http');
http.get('http://localhost:3000/api/version', (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
        console.log('Respuesta:', data);
        process.exit(res.statusCode === 200 ? 0 : 1);
    });
}).on('error', (err) => {
    console.error('Error:', err.message);
    process.exit(1);
});
"

echo ""
echo "3️⃣ Verificando si el problema es con express.static..."
echo "   Verificando el orden de las rutas en server.js..."
docker exec "$DASHBOARD_CONTAINER" grep -n "express.static\|/api/version" /app/server.js | head -5

echo ""
echo "4️⃣ Verificando logs del servidor cuando se hace una petición..."
echo "   (Haz una petición manualmente y revisa los logs)"
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
echo ""
echo "Si el endpoint responde desde el host pero no desde Traefik,"
echo "el problema está en la configuración de Traefik."
echo ""
