#!/bin/bash
# 🔍 Diagnóstico Completo del Servicio

echo "=============================================================="
echo "🔍 DIAGNÓSTICO COMPLETO"
echo "=============================================================="
echo ""

# 1. Verificar contenedor
echo "1️⃣  Verificando contenedor..."
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    echo ""
    echo "Verificando servicios..."
    docker service ls | grep whatsapp
    exit 1
fi

echo "   ✅ Contenedor: $CONTAINER_ID"
echo ""

# 2. Ver logs completos recientes
echo "2️⃣  Últimos 50 logs del servicio..."
echo "--------------------------------------------------------------"
docker service logs checkin24hs_whatsapp --tail 50 2>&1 | tail -50
echo ""

# 3. Verificar proceso Node
echo "3️⃣  Verificando proceso Node.js..."
docker exec $CONTAINER_ID ps aux 2>/dev/null | grep -E "node|PID" | head -5
echo ""

# 4. Verificar puerto dentro del contenedor
echo "4️⃣  Verificando puerto 3001 dentro del contenedor..."
docker exec $CONTAINER_ID netstat -tuln 2>/dev/null | grep 3001 || docker exec $CONTAINER_ID ss -tuln 2>/dev/null | grep 3001 || echo "   ⚠️  Puerto 3001 no está escuchando"
echo ""

# 5. Verificar archivos de sesión
echo "5️⃣  Verificando archivos de sesión..."
docker exec $CONTAINER_ID ls -la /app/auth_info_baileys_1 2>/dev/null | head -5 || echo "   ✅ No hay sesión (esto es bueno para generar nuevo QR)"
echo ""

# 6. Verificar variables de entorno
echo "6️⃣  Verificando variables de entorno críticas..."
docker exec $CONTAINER_ID env | grep -E "PORT|INSTANCE|BASE_URL" | head -5
echo ""

# 7. Intentar conexión desde dentro del contenedor
echo "7️⃣  Intentando conexión desde dentro del contenedor..."
docker exec $CONTAINER_ID curl -s --max-time 3 http://localhost:3001/api/health 2>&1 || echo "   ⚠️  No responde desde dentro del contenedor"
echo ""

# 8. Verificar si hay errores en los logs
echo "8️⃣  Buscando errores en los logs..."
docker service logs checkin24hs_whatsapp --tail 100 2>&1 | grep -iE "error|fail|exception|crash" | tail -10 || echo "   ✅ No se encontraron errores obvios"
echo ""

echo "=============================================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=============================================================="
echo ""
