#!/bin/bash

echo "=========================================="
echo "🧹 LIMPIANDO SESIÓN DE INSTANCIA 1"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp.1" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp 1"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

echo "1️⃣ Limpiando directorio de autenticación de instancia 1..."
echo "----------------------------------------"
docker exec "$CONTAINER_ID" sh -c "rm -rf /app/auth_info_baileys_1/* 2>/dev/null && echo '✅ Directorio limpiado' || echo '⚠️  Error al limpiar'"
echo ""

echo "2️⃣ Verificando que el directorio está vacío..."
echo "----------------------------------------"
FILE_COUNT=$(docker exec "$CONTAINER_ID" sh -c "find /app/auth_info_baileys_1 -type f 2>/dev/null | wc -l")
if [ "$FILE_COUNT" -eq "0" ]; then
    echo "✅ Directorio vacío correctamente"
else
    echo "⚠️  Directorio todavía tiene $FILE_COUNT archivo(s)"
    docker exec "$CONTAINER_ID" sh -c "find /app/auth_info_baileys_1 -type f 2>/dev/null"
fi
echo ""

echo "3️⃣ Reiniciando servicio para aplicar cambios..."
echo "----------------------------------------"
SERVICE_NAME=$(docker service ls --filter "name=checkin24hs_whatsapp" --format "{{.Name}}" | head -1)

if [ -n "$SERVICE_NAME" ]; then
    echo "✅ Servicio encontrado: $SERVICE_NAME"
    echo "🔄 Reiniciando servicio..."
    docker service update --force "$SERVICE_NAME" 2>&1 | grep -E "(updated|converged)" || echo "   ⚠️  Error al reiniciar"
    echo ""
    echo "⏳ Esperando 30 segundos para que el servicio se reinicie..."
    sleep 30
    echo ""
    echo "4️⃣ Verificando estado después del reinicio..."
    echo "----------------------------------------"
    NEW_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp.1" --format "{{.ID}}" | head -1)
    if [ -n "$NEW_CONTAINER_ID" ]; then
        echo "✅ Nuevo contenedor: $NEW_CONTAINER_ID"
        echo ""
        echo "📊 Estado del servidor:"
        docker exec "$NEW_CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/api/status',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>{try{const data=JSON.parse(d);console.log('Estado:',data.whatsapp||data.connected?'Conectado':'Desconectado');console.log('QR:',!!data.qrCode?'Disponible':'No disponible')}catch(e){console.log('Error:',e.message)}})}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),3000);\"" 2>&1
        echo ""
        echo "📋 Logs recientes:"
        docker logs "$NEW_CONTAINER_ID" --tail 10 2>&1 | grep -E "(QR Code|WhatsApp conectado|Conexión cerrada)" | tail -5
    else
        echo "⚠️  No se encontró nuevo contenedor aún"
    fi
else
    echo "⚠️  No se encontró servicio Docker Swarm"
fi

echo ""
echo "=========================================="
echo "✅ LIMPIEZA COMPLETA"
echo "=========================================="
echo ""
echo "✅ Sesión de instancia 1 limpiada"
echo "✅ Servicio reiniciado"
echo ""
echo "💡 Ahora puedes:"
echo "   1. Esperar 30-60 segundos más"
echo "   2. Abrir https://api1.checkin24hs.com/"
echo "   3. Escanear el nuevo QR code"
echo "   4. Asegurarte de que NO hay WhatsApp Web abierto"
echo "   5. Asegurarte de que NO hay otros dispositivos vinculados"
echo ""
