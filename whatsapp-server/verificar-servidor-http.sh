#!/bin/bash
# 🔍 Verificar Servidor HTTP

echo "=============================================================="
echo "🔍 VERIFICANDO SERVIDOR HTTP"
echo "=============================================================="
echo ""

# 1. Ver logs recientes
echo "1️⃣  Últimos 15 logs del servicio..."
echo "--------------------------------------------------------------"
docker service logs checkin24hs_whatsapp --tail 15 2>&1 | tail -15
echo ""

# 2. Verificar qué devuelve curl exactamente
echo "2️⃣  Probando conexión HTTP..."
echo "--------------------------------------------------------------"
echo "Probando /api/health:"
RESPONSE=$(timeout 10 curl -v --max-time 5 http://localhost:3001/api/health 2>&1)
echo "$RESPONSE"
echo ""

# 3. Verificar puerto desde el host
echo "3️⃣  Verificando puerto 3001 desde el host..."
netstat -tuln | grep 3001 || ss -tuln | grep 3001 || echo "   ⚠️  Puerto 3001 no está escuchando en el host"
echo ""

# 4. Verificar contenedor
echo "4️⃣  Verificando contenedor..."
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "   Contenedor: $CONTAINER_ID"
echo ""

# 5. Verificar puerto dentro del contenedor (si tiene netstat/ss)
echo "5️⃣  Intentando verificar puerto dentro del contenedor..."
docker exec $CONTAINER_ID sh -c "netstat -tuln 2>/dev/null | grep 3001 || ss -tuln 2>/dev/null | grep 3001 || echo 'No se pudo verificar (comando no disponible)'" 2>&1
echo ""

# 6. Verificar si hay errores en los logs
echo "6️⃣  Buscando errores en los logs..."
docker service logs checkin24hs_whatsapp --tail 50 2>&1 | grep -iE "error|fail|exception|crash|syntax" | tail -10 || echo "   ✅ No se encontraron errores obvios"
echo ""

# 7. Verificar variables de entorno
echo "7️⃣  Verificando variables de entorno..."
docker exec $CONTAINER_ID sh -c "env | grep -E 'PORT|INSTANCE' | head -5" 2>&1
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
