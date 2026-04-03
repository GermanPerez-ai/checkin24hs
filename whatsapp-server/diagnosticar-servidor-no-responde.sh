#!/bin/bash
# 🔍 Diagnosticar por qué el servidor no responde

echo "=============================================================="
echo "🔍 DIAGNÓSTICO: SERVIDOR NO RESPONDE"
echo "=============================================================="
echo ""

# 1. Verificar contenedor
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "1️⃣  Contenedor: $CONTAINER_ID"
echo ""

# 2. Verificar si el proceso Node.js está corriendo
echo "2️⃣  Procesos Node.js en el contenedor:"
docker exec $CONTAINER_ID sh -c "ps aux | grep node" 2>/dev/null || echo "   ⚠️  No se pueden ver procesos"
echo ""

# 3. Verificar si el puerto está escuchando dentro del contenedor
echo "3️⃣  Puertos escuchando dentro del contenedor:"
docker exec $CONTAINER_ID sh -c "netstat -tuln 2>/dev/null | grep 3001 || ss -tuln 2>/dev/null | grep 3001" || echo "   ⚠️  Puerto 3001 no está escuchando"
echo ""

# 4. Ver logs completos recientes (últimos 50)
echo "4️⃣  Logs recientes (últimos 50):"
docker service logs checkin24hs_whatsapp --tail 50
echo ""

# 5. Intentar conexión desde dentro del contenedor
echo "5️⃣  Intentando conexión desde dentro del contenedor:"
docker exec $CONTAINER_ID sh -c "curl -s --max-time 3 http://localhost:3001/api/health 2>&1" || echo "   ⚠️  No responde desde dentro del contenedor"
echo ""

# 6. Verificar variables de entorno
echo "6️⃣  Variables de entorno importantes:"
docker exec $CONTAINER_ID sh -c "env | grep -E 'PORT|INSTANCE_NUMBER|BASE_URL'" 2>/dev/null || echo "   ⚠️  No se pueden ver variables"
echo ""

# 7. Verificar archivo principal
echo "7️⃣  Verificando archivo principal:"
docker exec $CONTAINER_ID sh -c "ls -la /app/whatsapp-server-baileys.js 2>/dev/null && wc -l /app/whatsapp-server-baileys.js" || echo "   ⚠️  Archivo no encontrado"
echo ""

# 8. Verificar si hay errores de sintaxis
echo "8️⃣  Verificando sintaxis del archivo:"
docker exec $CONTAINER_ID sh -c "node -c /app/whatsapp-server-baileys.js 2>&1" || echo "   ⚠️  Error de sintaxis detectado"
echo ""

echo "=============================================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=============================================================="
echo ""
