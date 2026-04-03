#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO POR QUÉ NO SE GENERA QR"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

echo "1️⃣ Estado del contenedor:"
echo "----------------------------------------"
docker ps --filter "id=$CONTAINER_ID" --format "table {{.ID}}\t{{.Status}}\t{{.Names}}"
echo ""

echo "2️⃣ Logs completos (últimas 30 líneas):"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --tail 30 2>&1
echo ""

echo "3️⃣ Buscando errores:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --tail 100 2>&1 | grep -i "error\|fail\|exception" | tail -10
echo ""

echo "4️⃣ Buscando eventos de conexión:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --tail 100 2>&1 | grep -E "(connected to WA|QR Code|pairing|logging in)" | tail -10
echo ""

echo "5️⃣ Verificando si el servidor está respondiendo:"
echo "----------------------------------------"
echo "📊 /api/status:"
docker exec "$CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/api/status',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>{try{const data=JSON.parse(d);console.log('Estado:',data.whatsapp);console.log('QR disponible:',!!data.qrCode);console.log('Conectado:',data.connected)}catch(e){console.log('Error:',e.message)}})}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),3000);\"" 2>&1
echo ""

echo "6️⃣ Verificando proceso Node.js:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" sh -c "ps aux 2>/dev/null | grep node | grep -v grep || echo '⚠️ No se encontró proceso Node.js'"
echo ""

echo "7️⃣ Verificando puerto 3001:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" sh -c "netstat -tuln 2>/dev/null | grep 3001 || ss -tuln 2>/dev/null | grep 3001 || echo '⚠️ netstat/ss no disponible'"
echo ""

echo "=========================================="
echo "💡 DIAGNÓSTICO"
echo "=========================================="
echo ""
echo "Si no ves 'QR Code recibido' en los logs, el servidor puede estar:"
echo "  1. Esperando conexión a WhatsApp"
echo "  2. Bloqueado por un error"
echo "  3. En proceso de reconexión"
echo ""
echo "Si ves errores, comparte los logs para diagnosticar"
echo ""
