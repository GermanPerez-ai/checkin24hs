#!/bin/bash
# 🔍 Diagnosticar Servicio Lento o Bloqueado

echo "=============================================================="
echo "🔍 DIAGNÓSTICO DE SERVICIO LENTO"
echo "=============================================================="
echo ""

# 1. Verificar contenedor
echo "1️⃣  Verificando contenedor..."
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "   Contenedor: $CONTAINER_ID"
echo "   Estado: $(docker ps | grep $CONTAINER_ID | awk '{print $7}')"
echo ""

# 2. Verificar logs recientes
echo "2️⃣  Últimos 20 logs del servicio..."
echo "--------------------------------------------------------------"
docker service logs checkin24hs_whatsapp --tail 20 2>&1 | tail -20
echo ""

# 3. Verificar proceso dentro del contenedor
echo "3️⃣  Verificando procesos dentro del contenedor..."
docker exec $CONTAINER_ID ps aux 2>/dev/null | head -10
echo ""

# 4. Verificar puerto
echo "4️⃣  Verificando si el puerto 3001 está escuchando..."
docker exec $CONTAINER_ID netstat -tuln 2>/dev/null | grep 3001 || docker exec $CONTAINER_ID ss -tuln 2>/dev/null | grep 3001
echo ""

# 5. Intentar conexión directa con timeout
echo "5️⃣  Intentando conexión con timeout de 5 segundos..."
timeout 5 curl -s http://localhost:3001/api/health 2>&1 || echo "   ⚠️  No responde en 5 segundos"
echo ""

# 6. Verificar uso de recursos
echo "6️⃣  Uso de recursos del contenedor..."
docker stats $CONTAINER_ID --no-stream 2>/dev/null || echo "   ⚠️  No se pudo obtener estadísticas"
echo ""

echo "=============================================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=============================================================="
echo ""
