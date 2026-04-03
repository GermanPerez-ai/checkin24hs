#!/bin/bash

echo "=========================================="
echo "🔧 SOLUCIONANDO ERROR 502 WHATSAPP"
echo "=========================================="
echo ""

CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor de WhatsApp 1"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# 1. Verificar si el proceso Node.js está corriendo
echo "1️⃣ Verificando proceso Node.js..."
PROCESSES=$(docker exec "$CONTAINER" ps aux | grep -E "node.*whatsapp-server" | grep -v grep | wc -l)
if [ "$PROCESSES" -eq 0 ]; then
    echo "❌ No se encontró proceso Node.js corriendo"
    echo "   Reiniciando contenedor..."
    docker restart "$CONTAINER"
    sleep 5
    echo "✅ Contenedor reiniciado"
else
    echo "✅ Proceso Node.js está corriendo"
fi
echo ""

# 2. Verificar puerto usando node directamente
echo "2️⃣ Verificando si el servidor responde en el puerto 3001..."
docker exec "$CONTAINER" node -e "
const http = require('http');
const options = {
    hostname: 'localhost',
    port: 3001,
    path: '/api/status?card=1',
    method: 'GET',
    timeout: 3000
};

const req = http.request(options, (res) => {
    console.log('✅ Servidor responde - Status:', res.statusCode);
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
        console.log('Respuesta:', data.substring(0, 200));
    });
});

req.on('error', (e) => {
    console.error('❌ Error conectando:', e.message);
});

req.on('timeout', () => {
    console.error('❌ Timeout - El servidor no responde');
    req.destroy();
});

req.end();
" 2>&1
echo ""

# 3. Verificar logs recientes
echo "3️⃣ Últimos logs del servidor:"
echo "=========================================="
docker logs "$CONTAINER" --tail 30 2>&1 | tail -30
echo ""

# 4. Verificar errores específicos
echo "4️⃣ Buscando errores específicos:"
echo "=========================================="
docker logs "$CONTAINER" --tail 200 2>&1 | grep -i "error\|failed\|exception\|cannot\|eaddrinuse\|port.*in use\|listen" | tail -15
echo ""

# 5. Verificar configuración del puerto
echo "5️⃣ Verificando configuración del puerto:"
echo "=========================================="
docker exec "$CONTAINER" grep -n "PORT\|listen\|3001" /app/whatsapp-server.js | head -5
echo ""

# 6. Verificar variables de entorno
echo "6️⃣ Variables de entorno relacionadas con puerto:"
echo "=========================================="
docker exec "$CONTAINER" env | grep -E "PORT|INSTANCE"
echo ""

# 7. Verificar puertos expuestos
echo "7️⃣ Puertos expuestos del contenedor:"
echo "=========================================="
docker port "$CONTAINER"
echo ""

echo "=========================================="
echo "📋 DIAGNÓSTICO Y SOLUCIONES:"
echo "=========================================="
echo ""
echo "Si el servidor NO responde internamente:"
echo "  1. El servidor puede estar crasheando al iniciar"
echo "  2. Revisa los logs completos: docker logs $CONTAINER --tail 100"
echo "  3. Verifica que todas las dependencias estén instaladas"
echo ""
echo "Si el servidor responde internamente pero da 502 externamente:"
echo "  1. Problema con nginx/proxy delante del servidor"
echo "  2. Verifica configuración de nginx para api1.checkin24hs.com"
echo "  3. Verifica que el proxy esté apuntando al puerto correcto (3001)"
echo ""
echo "Para reiniciar completamente:"
echo "  docker restart $CONTAINER"
echo "  sleep 10"
echo "  docker logs $CONTAINER --tail 50"
echo ""



