#!/bin/bash
# 🔍 Probar el servidor usando Node.js desde dentro del contenedor

echo "=============================================================="
echo "🔍 PROBANDO SERVIDOR CON NODE.JS"
echo "=============================================================="
echo ""

CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

# 1. Usar Node.js para hacer una petición HTTP desde dentro del contenedor
echo "1️⃣  Probando con Node.js desde dentro del contenedor:"
docker exec $CONTAINER_ID sh -c "node -e \"
const http = require('http');
const req = http.request({
    hostname: 'localhost',
    port: 3001,
    path: '/api/health',
    method: 'GET',
    timeout: 3000
}, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => { console.log('Respuesta:', data); });
});
req.on('error', (e) => { console.log('Error:', e.message); });
req.on('timeout', () => { console.log('Timeout'); req.destroy(); });
req.end();
\"" 2>&1
echo ""

# 2. Monitorear logs mientras hacemos una petición desde fuera
echo "2️⃣  Monitoreando logs mientras hacemos petición desde fuera:"
(timeout 5 curl -s --max-time 3 http://localhost:3001/api/health > /dev/null 2>&1 &)
sleep 1
docker logs $CONTAINER_ID --tail 10 2>&1 | grep -E 'GET|POST|health|/api|Error|error' || echo "No se encontraron logs relacionados"
echo ""

# 3. Verificar si Express está recibiendo las peticiones (agregar logging temporal)
echo "3️⃣  Verificando si hay algún middleware bloqueando:"
docker exec $CONTAINER_ID sh -c "grep -n 'app.use' /app/whatsapp-server-baileys.js | head -5" 2>/dev/null
echo ""

echo "=============================================================="
echo "✅ PRUEBA COMPLETADA"
echo "=============================================================="
echo ""
