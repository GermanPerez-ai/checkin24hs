#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO SESIONES EN EL SERVIDOR"
echo "=========================================="
echo ""

# 1. Verificar contenedores de WhatsApp
echo "1️⃣ Contenedores de WhatsApp activos:"
echo "----------------------------------------"
docker ps --filter "name=checkin24hs_whatsapp" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
echo ""

# 2. Verificar servicios de WhatsApp
echo "2️⃣ Servicios de WhatsApp en Docker Swarm:"
echo "----------------------------------------"
docker service ls --filter "name=whatsapp" --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"
echo ""

# 3. Verificar sesiones guardadas en cada contenedor
echo "3️⃣ Sesiones de autenticación guardadas:"
echo "----------------------------------------"
CONTAINERS=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}")

for CONTAINER_ID in $CONTAINERS; do
    echo "📦 Contenedor: $CONTAINER_ID"
    echo "   Directorios de autenticación:"
    docker exec "$CONTAINER_ID" sh -c "ls -la /app/auth_info_baileys_* 2>/dev/null | head -20 || echo '   ⚠️ No se encontraron directorios de autenticación'"
    echo ""
    echo "   Archivos en cada directorio:"
    for AUTH_DIR in $(docker exec "$CONTAINER_ID" sh -c "ls -d /app/auth_info_baileys_* 2>/dev/null"); do
        echo "   📁 $AUTH_DIR:"
        docker exec "$CONTAINER_ID" sh -c "find $AUTH_DIR -type f 2>/dev/null | head -10 || echo '      (vacío)'"
        echo ""
    done
    echo ""
done

# 4. Verificar si hay múltiples instancias conectadas
echo "4️⃣ Estado de conexión de cada instancia:"
echo "----------------------------------------"
for CONTAINER_ID in $CONTAINERS; do
    echo "📦 Contenedor: $CONTAINER_ID"
    docker exec "$CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/api/status',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>{try{const data=JSON.parse(d);console.log('   Estado:',data.whatsapp||data.connected?'Conectado':'Desconectado');console.log('   Instancia:',data.instance||'N/A');console.log('   Teléfono:',data.phone||'N/A');console.log('   QR:',!!data.qrCode?'Disponible':'No disponible')}catch(e){console.log('   Error:',e.message)}})}).on('error',e=>console.error('   Error:',e.message));setTimeout(()=>process.exit(0),3000);\"" 2>&1
    echo ""
done

# 5. Verificar logs recientes para ver conexiones activas
echo "5️⃣ Últimas conexiones exitosas (últimos 30 minutos):"
echo "----------------------------------------"
for CONTAINER_ID in $CONTAINERS; do
    echo "📦 Contenedor: $CONTAINER_ID"
    docker logs "$CONTAINER_ID" --since 30m 2>&1 | grep -E "(WhatsApp conectado|Teléfono conectado|opened connection)" | tail -5
    echo ""
done

# 6. Verificar si hay procesos de WhatsApp duplicados
echo "6️⃣ Procesos Node.js relacionados con WhatsApp:"
echo "----------------------------------------"
for CONTAINER_ID in $CONTAINERS; do
    echo "📦 Contenedor: $CONTAINER_ID"
    docker exec "$CONTAINER_ID" sh -c "ps aux 2>/dev/null | grep -E '(node|whatsapp)' | grep -v grep || echo '   ⚠️ No se encontraron procesos'"
    echo ""
done

# 7. Verificar variables de entorno para instancias
echo "7️⃣ Variables de entorno (INSTANCE_NUMBER):"
echo "----------------------------------------"
for CONTAINER_ID in $CONTAINERS; do
    echo "📦 Contenedor: $CONTAINER_ID"
    docker exec "$CONTAINER_ID" sh -c "env | grep -E '(INSTANCE|WHATSAPP)' || echo '   ⚠️ No se encontraron variables de instancia'"
    echo ""
done

echo "=========================================="
echo "💡 RESUMEN"
echo "=========================================="
echo ""
echo "Si ves múltiples contenedores con el mismo número de teléfono,"
echo "eso puede causar conflictos de sesión."
echo ""
echo "Si ves archivos de autenticación en múltiples directorios,"
echo "puede haber sesiones guardadas que están causando conflictos."
echo ""
