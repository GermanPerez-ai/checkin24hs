#!/bin/bash

echo "=========================================="
echo "🔍 REVISANDO AUTENTICACIÓN INCOMPLETA"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp.1" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp 1"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

echo "1️⃣ Timeline completo de eventos (últimos 10 minutos):"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(QR Code|pairing|logging in|connected to WA|WhatsApp conectado|Teléfono conectado|Conexión cerrada|device_removed|515|428|401|syncing|resyncing|app state)" | tail -30
echo ""

echo "2️⃣ Proceso de autenticación paso a paso:"
echo "----------------------------------------"
echo "📱 QR Code escaneado:"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(QR Code recibido|QR escaneado)" | tail -3
echo ""

echo "🔗 Pairing:"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(pairing configured|logging in)" | tail -3
echo ""

echo "✅ Conexión establecida:"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(WhatsApp conectado|Teléfono conectado|opened connection)" | tail -3
echo ""

echo "⏳ Sincronización del app state:"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(syncing|resyncing|app state|history notification|injecting)" | tail -10
echo ""

echo "❌ Errores o desconexiones:"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(Conexión cerrada|device_removed|401|515|428|Error|error)" | tail -10
echo ""

echo "3️⃣ Estado actual del servidor:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/api/status',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>{try{const data=JSON.parse(d);console.log('Estado WhatsApp:',data.whatsapp||data.connected?'Conectado':'Desconectado');console.log('QR disponible:',!!data.qrCode);console.log('Teléfono:',data.phone||'N/A');console.log('Nombre:',data.name||'N/A')}catch(e){console.log('Error:',e.message)}})}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),3000);\"" 2>&1
echo ""

echo "4️⃣ Tiempo transcurrido desde la conexión:"
echo "----------------------------------------"
LAST_CONNECTION=$(docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(WhatsApp conectado|Teléfono conectado)" | tail -1)
if [ -n "$LAST_CONNECTION" ]; then
    echo "Última conexión exitosa:"
    echo "$LAST_CONNECTION"
    echo ""
    echo "Logs desde entonces:"
    docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -A 20 "$LAST_CONNECTION" | tail -20
else
    echo "⚠️  No se encontró conexión exitosa reciente"
fi
echo ""

echo "5️⃣ Verificando si hay errores de sincronización:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(timeout|Timed Out|failed|error.*sync)" | tail -10
echo ""

echo "=========================================="
echo "💡 DIAGNÓSTICO"
echo "=========================================="
echo ""
echo "Si ves 'WhatsApp conectado' pero luego 'device_removed' o '401',"
echo "significa que WhatsApp detecta múltiples sesiones activas."
echo ""
echo "Si ves 'syncing' o 'resyncing' pero luego se desconecta,"
echo "puede ser que la sincronización esté tomando demasiado tiempo."
echo ""
echo "Si el estado muestra 'Conectado' pero sin teléfono,"
echo "la sesión está incompleta o corrupta."
echo ""
