#!/bin/bash
# 🔍 Diagnosticar por qué el servidor no responde

echo "=============================================================="
echo "🔍 DIAGNÓSTICO: SERVIDOR NO RESPONDE"
echo "=============================================================="
echo ""

# 1. Ver logs completos recientes
echo "1️⃣  Últimos 30 logs del servicio..."
echo "--------------------------------------------------------------"
docker service logs checkin24hs_whatsapp --tail 30 2>&1 | tail -30
echo ""

# 2. Verificar contenedor
echo "2️⃣  Verificando contenedor..."
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "   Contenedor: $CONTAINER_ID"
echo ""

# 3. Verificar código dentro del contenedor (función start)
echo "3️⃣  Verificando código dentro del contenedor (líneas 1215-1235)..."
docker exec $CONTAINER_ID cat /app/whatsapp-server-baileys.js 2>/dev/null | sed -n '1215,1235p' || echo "   ⚠️  No se pudo leer el archivo"
echo ""

# 4. Verificar si hay errores de sintaxis
echo "4️⃣  Verificando sintaxis del código..."
docker exec $CONTAINER_ID node -c /app/whatsapp-server-baileys.js 2>&1 || echo "   ⚠️  Error de sintaxis"
echo ""

# 5. Verificar si el proceso Node está corriendo
echo "5️⃣  Verificando procesos Node..."
docker exec $CONTAINER_ID sh -c "ps aux | grep node | head -5" 2>&1 || echo "   ⚠️  No se pudo verificar procesos"
echo ""

# 6. Intentar conexión desde dentro del contenedor
echo "6️⃣  Intentando conexión desde dentro del contenedor..."
docker exec $CONTAINER_ID sh -c "wget -qO- --timeout=3 http://localhost:3001/api/health 2>&1 || echo 'No responde'" 2>&1
echo ""

# 7. Verificar puerto desde el host
echo "7️⃣  Verificando puerto 3001 desde el host..."
netstat -tuln 2>/dev/null | grep 3001 || ss -tuln 2>/dev/null | grep 3001 || echo "   ⚠️  Puerto 3001 no está escuchando"
echo ""

# 8. Ver logs de errores
echo "8️⃣  Buscando errores en los logs..."
docker service logs checkin24hs_whatsapp --tail 100 2>&1 | grep -iE "error|exception|crash|failed|cannot" | tail -10 || echo "   ✅ No se encontraron errores obvios"
echo ""

echo "=============================================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=============================================================="
echo ""
