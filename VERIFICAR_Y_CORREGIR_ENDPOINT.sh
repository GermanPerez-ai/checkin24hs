#!/bin/bash
# Verificar y corregir el problema del endpoint /api/version

echo "=========================================="
echo "🔍 Verificando problema del endpoint /api/version"
echo "=========================================="
echo ""

DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $DASHBOARD_CONTAINER"
echo ""

echo "1️⃣ Verificando si el servidor está corriendo..."
docker exec "$DASHBOARD_CONTAINER" ps aux | grep node | grep -v grep

echo ""
echo "2️⃣ Verificando en qué puerto está escuchando el servidor..."
docker exec "$DASHBOARD_CONTAINER" netstat -tuln 2>/dev/null | grep LISTEN || docker exec "$DASHBOARD_CONTAINER" ss -tuln 2>/dev/null | grep LISTEN

echo ""
echo "3️⃣ Probando con IPv4 explícitamente..."
docker exec "$DASHBOARD_CONTAINER" node -e "
const http = require('http');
const options = {
    hostname: '127.0.0.1',
    port: 3000,
    path: '/api/version',
    method: 'GET',
    family: 4
};
const req = http.request(options, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
        console.log('Status:', res.statusCode);
        console.log('Response:', data);
        process.exit(res.statusCode === 200 ? 0 : 1);
    });
});
req.on('error', (err) => {
    console.error('Error:', err.message);
    process.exit(1);
});
req.end();
"

echo ""
echo "4️⃣ Verificando si hay un archivo /api/version que esté interfiriendo..."
docker exec "$DASHBOARD_CONTAINER" test -f /app/api/version && echo "⚠️  Existe un archivo /app/api/version que puede estar interfiriendo" || echo "✅ No hay archivo /app/api/version"

echo ""
echo "5️⃣ Verificando el orden exacto de las rutas en server.js..."
docker exec "$DASHBOARD_CONTAINER" grep -n "app.get\|app.use\|express.static" /app/server.js | head -15

echo ""
echo "6️⃣ Verificando si express.static está capturando la ruta antes..."
echo "   Si express.static está antes de /api/version, puede estar sirviendo un archivo estático"
echo "   en lugar de la ruta de la API."

echo ""
echo "7️⃣ Probando acceso a la ruta raíz para verificar que el servidor responde..."
docker exec "$DASHBOARD_CONTAINER" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', {family: 4}, (res) => {
    console.log('Status raíz:', res.statusCode);
    process.exit(res.statusCode === 200 ? 0 : 1);
}).on('error', (err) => {
    console.error('Error:', err.message);
    process.exit(1);
});
"

echo ""
echo "=========================================="
echo "📋 Análisis"
echo "=========================================="
echo ""
echo "Si el servidor responde en la ruta raíz pero no en /api/version,"
echo "el problema puede ser:"
echo "  1. express.static está capturando la ruta antes"
echo "  2. Hay un archivo estático en /app/api/version"
echo "  3. El orden de las rutas no es correcto"
echo ""
