#!/bin/bash
# 🔍 Verificar mapeo de puertos después del redeploy

echo "=============================================================="
echo "🔍 VERIFICANDO MAPEO DE PUERTOS POST-REDEPLOY"
echo "=============================================================="
echo ""

# 1. Verificar mapeo de puertos del servicio
echo "1️⃣  Mapeo de puertos del servicio:"
docker service inspect checkin24hs_whatsapp --format '{{json .Endpoint.Ports}}' | python3 -m json.tool
echo ""

# 2. Verificar puerto en el host
echo "2️⃣  Puerto escuchando en el host:"
ss -tuln | grep 3001 || echo "   ❌ Puerto 3001 NO está escuchando"
echo ""

# 3. Verificar contenedor
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "3️⃣  Contenedor: $CONTAINER_ID"
echo ""

# 4. Probar desde dentro del contenedor
echo "4️⃣  Probando desde dentro del contenedor:"
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
    res.on('end', () => { console.log('✅ Respuesta:', data); });
});
req.on('error', (e) => { console.log('❌ Error:', e.message); });
req.on('timeout', () => { console.log('⏱️ Timeout'); req.destroy(); });
req.end();
\"" 2>&1
echo ""

# 5. Si el puerto no está mapeado, mapearlo
if ! ss -tuln | grep -q 3001; then
    echo "5️⃣  ⚠️  Puerto no está mapeado. Mapeando ahora..."
    docker service update --publish-add published=3001,target=3001,protocol=tcp checkin24hs_whatsapp
    echo "   ✅ Comando de mapeo ejecutado"
    echo ""
    echo "   Esperando 30 segundos..."
    sleep 30
    echo ""
    echo "   Verificando nuevamente:"
    ss -tuln | grep 3001 && echo "   ✅ Puerto ahora está escuchando" || echo "   ❌ Puerto aún no está escuchando"
else
    echo "5️⃣  ✅ Puerto está mapeado correctamente"
fi
echo ""

# 6. Probar conexión final
echo "6️⃣  Probando conexión final:"
timeout 5 curl -s --max-time 3 http://127.0.0.1:3001/api/health && echo "   ✅ Servidor responde" || echo "   ❌ Servidor no responde"
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
