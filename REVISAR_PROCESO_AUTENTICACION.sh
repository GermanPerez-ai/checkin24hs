#!/bin/bash

echo "=========================================="
echo "🔍 REVISANDO PROCESO DE AUTENTICACIÓN"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

echo "1️⃣ Logs completos de los últimos 10 minutos:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | tail -50
echo ""

echo "2️⃣ Secuencia de eventos (QR → Pairing → Conexión → Error):"
echo "----------------------------------------"
echo "📱 QR Codes:"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(QR Code recibido|QR Code generado)" | tail -5
echo ""

echo "🔗 Pairing:"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(pairing configured|logging in)" | tail -5
echo ""

echo "✅ Conexiones exitosas:"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(WhatsApp conectado|Teléfono conectado|opened connection)" | tail -5
echo ""

echo "❌ Desconexiones:"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(Conexión cerrada|connection errored|device_removed|515|428)" | tail -10
echo ""

echo "🔄 Reconexiones:"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(Reconectando|Iniciando reconexión|restart required)" | tail -10
echo ""

echo "3️⃣ Sincronización del app state:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(syncing|resyncing|app state|history notification)" | tail -10
echo ""

echo "4️⃣ Errores específicos:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(Error|error|Timed Out|timeout)" | tail -10
echo ""

echo "5️⃣ Estado actual del servidor:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/api/status',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>{try{const data=JSON.parse(d);console.log('Estado:',data.whatsapp||data.connected?'Conectado':'Desconectado');console.log('QR:',!!data.qrCode?'Disponible':'No disponible');console.log('Teléfono:',data.phone||'N/A')}catch(e){console.log('Error:',e.message)}})}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),3000);\"" 2>&1
echo ""

echo "6️⃣ Timeline de eventos (últimos intentos):"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(QR Code|pairing|logging in|WhatsApp conectado|Conexión cerrada|515|401|device_removed)" | tail -20
echo ""

echo "=========================================="
echo "💡 ANÁLISIS"
echo "=========================================="
echo ""
echo "Busca en los logs:"
echo "  1. Si aparece 'pairing configured successfully'"
echo "  2. Si aparece error 515 'restart required' (normal)"
echo "  3. Si aparece 'WhatsApp conectado exitosamente'"
echo "  4. Si aparece error 401 'device_removed' después de conectarse"
echo "  5. Cuánto tiempo pasa entre cada evento"
echo ""
echo "El problema puede ser:"
echo "  - El error 515 está interrumpiendo la autenticación"
echo "  - La sincronización del app state está tomando demasiado tiempo"
echo "  - WhatsApp detecta múltiples sesiones durante la sincronización"
echo ""
