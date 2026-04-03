#!/bin/bash
# 🔍 Diagnosticar problemas después del redeploy

echo "=============================================================="
echo "🔍 DIAGNÓSTICO POST-REDEPLOY"
echo "=============================================================="
echo ""

cd /root/checkin24hs

# 1. Verificar contenedor
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "1️⃣  Contenedor: $CONTAINER_ID"
echo ""

# 2. Ver TODOS los logs desde el inicio
echo "2️⃣  Logs completos desde el inicio:"
docker logs $CONTAINER_ID 2>&1 | head -50
echo ""

# 3. Buscar mensaje de inicio del servidor
echo "3️⃣  Buscando mensaje 'Servidor iniciado':"
docker logs $CONTAINER_ID 2>&1 | grep "Servidor iniciado"
if [ $? -eq 0 ]; then
    echo "   ✅ Servidor inició correctamente"
else
    echo "   ❌ Servidor NO inició (no se encontró el mensaje)"
fi
echo ""

# 4. Buscar errores
echo "4️⃣  Errores en logs:"
docker logs $CONTAINER_ID 2>&1 | grep -iE "error|exception|failed" | tail -10
echo ""

# 5. Verificar si el servidor responde
echo "5️⃣  Verificando respuesta del servidor:"
RESPONSE=$(timeout 5 curl -s --max-time 3 http://127.0.0.1:3001/api/health 2>&1)
if [ -n "$RESPONSE" ] && [ "$RESPONSE" != "" ]; then
    echo "   ✅ Servidor responde: $RESPONSE"
else
    echo "   ❌ Servidor NO responde"
    echo "   Intentando desde dentro del contenedor..."
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
fi
echo ""

# 6. Verificar puerto
echo "6️⃣  Verificando puerto 3001:"
ss -tuln | grep 3001 && echo "   ✅ Puerto escuchando" || echo "   ❌ Puerto no escuchando"
echo ""

# 7. Verificar procesos
echo "7️⃣  Procesos Node.js:"
docker top $CONTAINER_ID 2>/dev/null | grep node || echo "   ⚠️  No se pueden ver procesos"
echo ""

echo "=============================================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=============================================================="
echo ""
