#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO DESCONEXIÓN DE WHATSAPP"
echo "=========================================="
echo ""

CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor de WhatsApp 1"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# 1. Verificar estado del contenedor
echo "1️⃣ Estado del contenedor:"
echo "=========================================="
docker ps --filter "name=whatsapp.1" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 2. Ver logs recientes del contenedor
echo "2️⃣ Logs recientes (últimas 50 líneas):"
echo "=========================================="
docker logs "$CONTAINER" --tail 50 2>&1 | tail -30
echo ""

# 3. Verificar si el servidor responde internamente
echo "3️⃣ Verificando respuesta interna del servidor:"
echo "=========================================="
docker exec "$CONTAINER" node -e "require('http').get('http://localhost:3001/api/status?card=1', (r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>console.log('Status:',r.statusCode,'Respuesta:',d.substring(0,200)))}).on('error',e=>console.error('Error:',e.message))" 2>&1
echo ""

# 4. Verificar respuesta externa
echo "4️⃣ Verificando respuesta externa (a través de Traefik):"
echo "=========================================="
curl -s https://api1.checkin24hs.com/api/status?card=1 | head -3
echo ""

# 5. Verificar logs de Traefik
echo "5️⃣ Verificando logs de Traefik (últimas 10 líneas):"
echo "=========================================="
TRAEFIK=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK" ]; then
    docker logs "$TRAEFIK" --tail 10 2>&1 | grep -i "api1\|whatsapp\|error\|502" | tail -5
else
    echo "⚠️ No se encontró contenedor de Traefik"
fi
echo ""

# 6. Verificar si WhatsApp está conectado según el servidor
echo "6️⃣ Estado de WhatsApp según el servidor:"
echo "=========================================="
docker logs "$CONTAINER" --tail 100 2>&1 | grep -i "conectado\|connected\|ready\|authenticated\|disconnected" | tail -5
echo ""

echo "=========================================="
echo "📋 DIAGNÓSTICO:"
echo "=========================================="
echo ""
echo "Si el servidor interno responde pero el externo da 502:"
echo "  - Problema con Traefik o configuración de routing"
echo ""
echo "Si el servidor interno NO responde:"
echo "  - El contenedor puede estar iniciando o tener un error"
echo "  - Verifica los logs completos del contenedor"
echo ""
echo "Si WhatsApp está desconectado según los logs:"
echo "  - Puede ser una desconexión temporal"
echo "  - El servidor debería reconectar automáticamente"
echo ""



